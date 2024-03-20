#!/usr/bin/env bash
#
# ex,
# ./render-thumb-for.sh /path/to/file.png 800 400
# ./render-thumb-for.sh /path/to/file.pdf
# ./render-thumb-for.sh /path/to/file.ttf
# ./render-thumb-for.sh /path/to/file.mp4 1020 780
#
# Exit code 0 Success
# Exit code 1 General errors, Miscellaneous errors
# Exit code 2 Misuse of shell builtins
#
is_cmd_kitten=$(command -v kitten)
[ "$is_cmd_kitten" ] &&
    is_cmd_kitten_icat_support=$(kitten icat --detect-support 2>&1)
is_cmd_mutool=$(command -v mutool)
is_cmd_pdftoppm=$(command -v pdftoppm)
is_cmd_magick=$(command -v magick) # imagemagick 7
is_cmd_convert=$(command -v convert) # imagemagick 6
is_cmd_magick_any="$is_cmd_magick$is_cmd_convert"
is_cmd_exiftool=$(command -v exiftool)
is_cmd_identify=$(command -v identify)
is_cmd_ffmpeg=$(command -v ffmpeg)
is_cmd_unzip=$(command -v unzip)
is_stdout_blocked=""
[ ! -t 1 ] &&
    is_stdout_blocked="true"

mime_type_SVG="svg"
mime_type_IMAGE="imgage"
mime_type_VIDEO="video"
mime_type_AUDIO="audio"
mime_type_FONT="font"
mime_type_EPUB="epub"
mime_type_PDF="pdf"

format_type_SIXEL="SIXEL"
format_type_KITTY="KITTY"

# escape sequences used to query the terminal for details,
#   https://www.mankier.com/7/foot-ctlseqs
#   https://iterm2.com/documentation-escape-codes.html
#   https://github.com/dylanaraps/pure-bash-bible
#     ?tab=readme-ov-file#get-the-terminal-size-in-pixels
escXTERMsixelissupported=$(printf '%b' "\e[c")
escXTERMsixelmaxwh=$(printf '%b' "\e[?2;4;0S")
escXTERMtermsize=$(printf '%b' "\e[14t")
escXTERMcellsize=$(printf '%b' "\e[16t")
escXTERMtermsizeTMUX=$(printf '%b' "${TMUX:+\\ePtmux;\\e}\\e[14t${TMUX:+\\e\\\\}")

msg_cmds_not_found () {
    if [[ "$#" -gt 1 ]]; then
        printf "Error: %s\n" "commands not found: $*"
    else
        printf "Error: %s\n" "command not found: $*"
    fi
}
msg_cmd_not_found_pdfany=$(msg_cmds_not_found "mutool" "pdftoppm" "magick")
msg_cmd_not_found_ffmpeg=$(msg_cmds_not_found "ffmpeg")
msg_cmd_not_found_unzip=$(msg_cmds_not_found "unzip")
msg_cmd_not_found_magickany=$(msg_cmds_not_found "magick" "convert")
msg_cmd_not_found_identifyany=$(msg_cmds_not_found "exiftool" "identify")
msg_unsupported_width="unsupported width, :width"
msg_unsupported_height="unsupported height, :height"
msg_undetectable_cell_size="cell size undetectable, try -r option"
msg_unsupported_display="image display is not supported"
msg_unsupported_mime="mime type is not supported"
msg_unknown_win_size="window size is unknown and could not be detected"
msg_invalid_resolution="resolution invalid: :resolution"
msg_epub_cover_not_found="epub cover image could not be located"

timecode_re="([[:digit:]]{2}[:][[:digit:]]{2}[:][[:digit:]]{2})"
resolution_re="([[:digit:]]{2,8}[x][[:digit:]]{2,8})"
fullpathattr_re="full-path=['\"]([^'\"]*)['\"]"
contentattr_re="content=['\"]([^'\"]*)['\"]"
hrefattr_re="href=['\"]([^'\"]*)['\"]"
wxhstr_re="^[[:digit:]]+[x][[:digit:]]+$"
number_re="^[[:digit:]]+$"

cachedir="$HOME/.config/render-thumb-for"
[ -n "${XDG_CONFIG_HOME}" ] &&
    cachedir="$XDG_CONFIG_HOME/render-thumb-for"

# do not use 'set -e' to full exit script process
# generating ffmpeg output will trigger condition
#
# set -e

mstimestamp () {
    # millisecond timestamp ex, 1710459031.000
    printf "%.3f\n" $((${EPOCHREALTIME/.} / 1000000))
}

sessid=$(mstimestamp)
cells=
cache="true" # getopts hcm: would force 'm' to have params
timeoutss=1.2
preprocess=""
defaultw=1000
version=0.0.8
while getopts "cr:bpstivh" opt; do
    case "${opt}" in
        c) cells="true";;
        r) resolution="${OPTARG}"
           if [[ ! "$resolution" =~ $wxhstr_re ]]; then
               fail "${msg_invalid_resolution/:resolution/${OPTARG}}"
           fi ;;
        i) sessid="${OPTARG}";;
        b) is_stdout_blocked="";;
        p) preprocess="true";; # skip main behaviour, write preprocessed data
        s) cache="true";;
        t) timeoutss="${OPTARG}";;
        v) echo "$version"; exit 0;;
        h|*) # Display help.
            echo "-c proces width and height as cell columns and lines"
            echo "-r cell pixel resolution mostly for foot@1.16.2 ex, 10x21"
            echo "-i define sesson 'id'"
            echo "-b define stdout blocked (ncurses), send esc queries to tty"
            echo "-s configure cache ex, -s true"
            echo "-t use custom timeout (seconds) w/ shell query functions"
            echo "-v show version ($version)"
            exit 0;;
    esac
done
shift $(($OPTIND - 1))

fail () {
    printf '%s\n' "$1" >&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

# thank you @topcat001
# https://github.com/orgs/tmux/discussions/3565#discussioncomment-8713254
escquery_sixel_issupport_get () {
    esc="$escXTERMsixelissupported"

    if [[ -n "$is_stdout_blocked" ]]; then
        echo -e "$esc" > /dev/tty
        IFS=";" read -d "c" -sra REPLY < /dev/tty
    else
        IFS=";" read -d "c" -sra REPLY -p "$esc" >&2
    fi

    for code in "${REPLY[@]}"; do
        if [[ $code == 4 ]]; then
            printf '%s\n' "true"
            exit 0
        fi
    done
}

escquery_cellwh_get () {
    esc="$escXTERMcellsize"
    if [[ -n "$is_stdout_blocked" ]]; then
        echo -e "$esc" > /dev/tty
        IFS=";" read -d t -sra REPLY -t "$timeoutss" < /dev/tty
    else
        IFS=";" read -d t -sra REPLY -t "$timeoutss" -p "$esc" >&2
    fi

    if [[ "${REPLY[1]}" =~ $number_re ]]; then
        printf '%s\n' "${REPLY[2]}x${REPLY[1]}"
        exit 0
    fi

    fail "$msg_undetectable_cell_size"
}

# empty return value if sixel is not-supported
escquery_sixel_maxwh_get () {
    if [[ -z $(escquery_sixel_issupport_get) ]]; then
        exit 0
    fi

    esc="$escXTERMsixelmaxwh"
    if [[ -n "$is_stdout_blocked" ]]; then
        echo -e "$esc" > /dev/tty
        IFS=";" read -d 'S' -sra REPLY -t "$timeoutss" < /dev/tty
    else
        IFS=";" read -d 'S' -sra REPLY -t "$timeoutss" -p "$esc" >&2
    fi

    if [[ "${REPLY[1]}" =~ $number_re ]]; then
        printf '%s\n' "${REPLY[2]}x${REPLY[3]}"
    fi
}

image_display_format_get () {
    if [[ -n "$(escquery_sixel_issupport_get)" ]]; then
        printf '%s\n' "$format_type_SIXEL"
        exit 0
    fi

    if [[ -n "$is_cmd_kitten_icat_support" ]]; then
        printf '%s\n' "$format_type_KITTY"
        exit 0
    fi

    fail "$msg_unsupported_display"
}

regex() {
    # Usage: regex "string" "regex"
    [[ $1 =~ $2 ]] && printf '%s\n' "${BASH_REMATCH[1]}"
}

zip_read_file () {
    if [[ -z "$is_cmd_unzip" ]]; then
        fail "$msg_cmd_not_found_unzip";
    fi

    unzip -p "$1" "$2"
}

zip_move_file_out () {
    if [[ -z "$is_cmd_unzip" ]]; then
        fail "$msg_cmd_not_found_unzip";
    fi

    unzip -q -o -j "$1" "$2" -d "$3"
}

cachedir_calibrate () {
    cachedir="$1"

    if [ ! -d "$cachedir" ]; then
        mkdir -p "$cachedir"
    fi
}

# behaviour can be expanded later
cachedir_path_get () {
    cachedir="$1"
    pathbase="$2"
    pathwh="$3"
    pathextn="${4:1}" #remove dot eg .jpg -> jpg
    pathname="$pathbase.$pathwh.$pathextn"

    echo "$cachedir/$pathname"
}

file_type_get () {
    mime=$(file -b --mime-type "$1")

    # font, pdf, video, audio, epub
    if [[ $mime =~ ^"image/svg" ]]; then
        echo "$mime_type_SVG"
    elif [[ $mime =~ ^"image/" ]]; then
        echo "$mime_type_IMAGE"
    elif [[ $mime =~ ^"video/" ]]; then
        echo "$mime_type_VIDEO"
    elif [[ $mime =~ ^"audio/" ]]; then
        echo "$mime_type_AUDIO"
    elif [[ $mime =~ ^"application/pdf" ]]; then
        echo "$mime_type_PDF"
    elif [[ $mime =~ (ttf|truetype|opentype|woff|woff2|sfnt)$ ]]; then
        echo "$mime_type_FONT"
    elif [[ $mime =~ ^"application/epub" ]]; then
        echo "$mime_type_EPUB"
    else
        fail "$msg_unsupported_mime"
    fi
}

image_to_sixel_magick () {
    img_path=$1
    img_wh=$2

    if [[ -z "$is_cmd_magick" && -z "$is_cmd_convert" ]]; then
        fail "$msg_cmd_not_found_magickany"
    fi

    export MAGICK_OCL_DEVICE=true
    if [[ -n "$is_cmd_magick" ]]; then
        magick \
            -background "rgba(0,0,0,0)" \
            "$img_path" \
            -geometry "$img_wh" \
            sixel:-
        echo ""
        exit 0
    fi

    if [[ -n "$is_cmd_convert" ]]; then
        convert \
            -channel rgba \
            -background "rgba(0,0,0,0)" \
            -geometry "$img_wh" \
            "$img_path" \
            sixel:-
        echo ""
        exit 0
    fi
}

pdf_to_image_magick () {
    pdf_thumb_path=$1
    pdf_path=$2

    if [[ -z "$is_cmd_magick" && -z "$is_cmd_convert" ]]; then
        fail "$msg_cmd_not_found_magickany"
    fi

    if [[ -n "$is_cmd_magick" ]]; then
        magick \
            "$pdf_thumb_path" \
            -define pdf:thumbnail=true \
            "$pdf_path"
        exit 0
    fi

    if [[ -n "$is_cmd_convert" ]]; then
        convert \
            "$pdf_thumb_path" \
            -define pdf:thumbnail=true \
            "$pdf_path"
        exit 0
    fi
}

# shellcheck disable=SC2116
magick_font_to_image () {
    font_path=$1
    font_wh_max=$2
    font_pointsize="$(wh_pointsize_get "$2")"
    font_bg_color="rgba(0,0,0,1)"
    font_fg_color="rgba(240,240,240,1)"
    font_preview_text=$(
        echo "ABCDEFGHIJKLM" \
             "NOPQRSTUVWXYZ" \
             "abcdefghijklm" \
             "nopqrstuvwxyz" \
             "1234567890" \
             "!@$\%(){}[]")
    font_preview_multiline=${font_preview_text// /\\n}
    font_thumb_path=$(cachedir_path_get "$cachedir" "font" "w h" ".jpg")

    if [[ -n "$is_cmd_magick" ]]; then
        magick \
            -size "$font_wh_max" \
            -background "$font_bg_color" \
            -fill "$font_fg_color" \
            -font "$font_path" \
            -pointsize "$font_pointsize" \
            -gravity Center \
            "label:${font_preview_multiline}" \
            "$font_thumb_path"

        echo "$font_thumb_path"
        exit 0
    fi

    if [[ -n "$is_cmd_convert" ]]; then
        convert \
            -size "$font_wh_max" \
            -background "$font_bg_color" \
            -fill "$font_fg_color" \
            -font "$font_path" \
            -pointsize "$font_pointsize" \
            -gravity Center \
            "label:${font_preview_multiline}" \
            "$font_thumb_path"

        echo "$font_thumb_path"
        exit 0
    fi

    fail "$msg_cmd_not_found_magickany"
}

pdf_to_image () {
    pdf_path=$1
    pdf_wh_max=$2
    pdf_thumb_path=""

    if [[ -z "$is_cmd_mutool" && -z "$is_cmd_pdftoppm" &&
              -z "$is_cmd_magick_any" ]]; then
        fail "$msg_cmd_not_found_pdfany"
    fi

    if [[ -n "$is_cmd_mutool" ]]; then
        pdf_thumb_path=$(cachedir_path_get "$cachedir" "pdf" "w h" ".png")
        mutool \
            draw -i -F png \
            -o "$pdf_thumb_path" "$pdf_path" 1 &> /dev/null

        echo "$pdf_thumb_path"
        exit 0
    fi

    if [[ -n "$is_cmd_pdftoppm" ]]; then
        pdf_thumb_path=$(cachedir_path_get "$cachedir" "pdf" "w h" ".jpg")
        # extension needs to be removed from output path "pattern" used here
        pdftoppm \
            -singlefile \
            -f 1 -l 1 \
            -scale-to "$(wh_max_get "$2")" \
            -jpeg "$pdf_path" "${pdf_thumb_path%.*}"

        echo "$pdf_thumb_path"
        exit 0
    fi

    if [[ -n "$is_cmd_magick_any" ]]; then
        pdf_thumb_path=$(cachedir_path_get "$cachedir" "pdf" "w h" ".jpg")

        pdf_to_image_magick \
            "$pdf_thumb_path" "$pdf_path"

        echo "$pdf_thumb_path"
        exit 0
    fi
}

paint () {
    img_path=$1
    img_wh=$2

    if [[ "$3" == "$format_type_SIXEL" ]]; then
        image_to_sixel_magick "$img_path" "$img_wh"
        exit 0
    fi

    # kitten does not provide a 'geometry' option
    # so image must have been preprocessed to fit desired geometry
    if [[ "$3" == "$format_type_KITTY" ]]; then    
        kitten icat --align left "$img_path"
        exit 0
    fi

    fail "$msg_unsupported_display"
}

paint_downscale () {
    img_path=$1
    img_wh_max=$2
    img_wh_native=$(img_wh_get "$img_path")
    img_wh_scaled=$(wh_scaled_get "$img_wh_native" "$img_wh_max")

    paint "$img_path" "$img_wh_scaled" "$3"
}

wh_startOLD_get () {
    w="$1"
    h="$2"
    w_mul=$([ -n "$3" ] && echo "$3" || echo "1")
    h_mul=$([ -n "$4" ] && echo "$4" || echo "1")

    [[ -z "$w" ]] && w="$defaultw"
    [[ -z "$h" ]] && h="$w"

    echo "$((${w} * ${w_mul})) $((${h} * ${h_mul}))"
}

# returns a goal pixel width and height for target image,
#
# starting width and height integers are optional
# default uses %80 width of given view or terminal
#  
# (w, h, cells, wh_cell)
wh_start_get () {
    cells=$3
    whcell=$4
    wharea_pixels=$(wh_term_resolution_get)
    wharea_cells=$(wh_term_columnsrows_get)
    wharea_def=$([ -n "$3" ] && echo "$wharea_cells" || echo "$wharea_pixels")
    w=$([ -n "$1" ] && echo "$1" || echo "$((${wharea_def%%x*} * 80 / 100))")
    h=$([ -n "$2" ] && echo "$2" || echo "$((${wharea_def##*x} * 80 / 100))")

    if [[ ! $w =~ $number_re ]]; then
        fail "${msg_unsupported_width/:width/$w}"
    fi

    if [[ ! $h =~ $number_re ]]; then
        fail "${msg_unsupported_height/:height/$h}"
    fi

    wh="${w}x${h}"
    if [[ -n "$cells" ]]; then
        wh=$(wh_pixels_from_cells_get "$wh" "$whcell")
    fi

    echo "$wh"
}

wh_cell_get () {
    # if does not return for kitty...
    escquery_cellwh_get
}

wh_sixelmax_get () {
    sixelmaxwh=$(escquery_sixel_maxwh_get)
    if [[ $sixelmaxwh =~ $wxhstr_re ]]; then
        echo "$sixelmaxwh"
    else
        echo "${defaultw}x${defaultw}"
    fi
}

wh_imagemax_get () {
    if [[ -n "$is_cmd_kitten" ]]; then
        echo ""

        exit 0
    fi

    wh_sixelmax_get
}

wh_max_get () {
    IFS="x" read -r -a wh <<< "$1"

    echo "$((${wh[0]} > ${wh[1]} ? ${wh[0]} : ${wh[1]}))"
}

wh_pointsize_get () {
    IFS="x" read -r -a wh <<< "$1"

    min=$((${wh[0]} > ${wh[1]} ? ${wh[1]} : ${wh[0]}))
    mul=$((${wh[0]} > ${wh[1]} ? 9 : 10))

    echo "$(($min / $mul))"
}

wh_scaled_get () {
    IFS="x" read -r -a wh_bgn <<< "$1"
    IFS="x" read -r -a wh_max <<< "$2"
    w_bgn=${wh_bgn[0]}
    w_max=${wh_max[0]}
    h_bgn=${wh_bgn[1]}
    h_max=${wh_max[1]}

    # if image is smaller, return native wh
    if [[ "$w_max" -gt "$w_bgn" ]] && [[ "$h_max" -gt "$h_bgn" ]]; then
        echo "${w_bgn}x${h_bgn}"
        exit 0
    fi

    # multiply and divide by 100 to convert decimal and int
    fin_h=$h_max
    fin_w=$((($w_bgn * (($fin_h * 100) / $h_bgn)) / 100))
    if [ "$fin_w" -ge "$w_max" ]; then
        fin_w=$w_max
        fin_h=$((($h_bgn * (($fin_w * 100) / $w_bgn)) / 100))
    fi

    echo "${fin_w}x${fin_h}"
}

# https://github.com/dylanaraps/pure-bash-bible
#  ?tab=readme-ov-file#get-the-terminal-size-in-lines-and-columns-from-a-script
wh_term_columnsrows_get () {
    # (:;:) is a micro sleep to ensure the variables are
    # exported immediately.
    shopt -s checkwinsize; (:;:)
    printf '%s\n' "$(tput cols)x$(tput lines)"
}

wh_term_resolution_get () {
    esc="$escXTERMtermsize"
    if [[ -n "$is_stdout_blocked" ]]; then
        echo -e "$esc" > /dev/tty
        IFS=";" read -d t -sra REPLY -t "$timeoutss" < /dev/tty
    else
        IFS=";" read -d t -sra REPLY -t "$timeoutss" -p "$esc" >&2
    fi

    if [[ "${REPLY[1]}" =~ $number_re ]]; then
        printf '%s\n' "${REPLY[2]}x${REPLY[1]}"
        exit 0
    fi

    esc="$escXTERMtermsizeTMUX"
    if [[ -n "$is_stdout_blocked" ]]; then
        echo -e '\e[14t' > /dev/tty
        IFS=$';\t' read -d t -sra REPLY -t "$timeoutss" < /dev/tty
    else
        IFS=$';\t' read -d t -sra REPLY -t "$timeoutss" -p "$esc" >&2
    fi

    if [[ "${REPLY[1]}" =~ $number_re ]]; then
        printf '%s\n' "${REPLY[2]}x${REPLY[1]}"
        exit 0
    fi

    fail "$msg_unknown_win_size"
}

# get the width and height in pixels from columns and rows
#
# to avoid rounding issues that may result io too-small numbers,
# resolution is calculated from the full set of columns and rows
wh_pixels_from_cells_get () {
    IFS="x" read -r -a wh <<< "$1"
    IFS="x" read -r -a whcell <<< "$2"

    echo "$((${wh[0]} * ${whcell[0]}))x$((${wh[1]} * ${whcell[1]}))"
}

img_wh_exiftool_get () {  # shellcheck disable=SC2016
    exiftool -p '${ImageWidth}x${ImageHeight}' "$1"
}

img_wh_identify_get () {
    identify -format "%wx%h" "$1"
}

img_wh_get () {
    if [[ -n "$is_cmd_exiftool" ]]; then
        img_wh_exiftool_get "$1"
    elif [[ -n "$is_cmd_identify" ]]; then
        img_wh_identify_get "$1"
    else
        fail "$msg_cmd_not_found_identifyany"
    fi
}

video_duration_ffmpeg_parse_ss () {
    duration_match=""

    while IFS=$'\n' read -r line; do
        if [[ $line == *" Duration:"* && $line =~ $timecode_re ]]; then
            duration_match="${BASH_REMATCH[1]}"
            break
        fi
    done < <(printf '%s\n' "$1")

    IFS=" " read -r HOURS MINUTES SECONDS <<< "${duration_match//:/ }"

    echo $((10#$HOURS * 3600 + 10#$MINUTES * 60 + 10#$SECONDS))
}

video_resolution_ffmpeg_parse () {
    resolution_match=""

    while IFS=$'\n' read -r line; do
        if [[ $line == *"Video:"* && $line =~ $resolution_re ]]; then
            resolution_match="${BASH_REMATCH[1]}"
            break
        fi
    done < <(printf '%s\n' "$1")

    echo "$resolution_match"
}

epub_containerxml_parse_rootfiles () {
    while IFS=$'\n' read -r line; do
        [[ $extract && $line != "$3" ]] &&
            printf '%s\n' "$line"

        [[ $line =~ "<rootfiles>" ]] && extract=1
        [[ $line =~ "</rootfiles>" ]] && extract=
    done < <(printf '%s\n' "$1")
}

epub_rootxml_parse_manifest () {
    itemid=$2

    while IFS=$'\n' read -r line; do
        [[ $extract && $line =~ id=\"$itemid\" ]] &&
            printf '%s\n' "$line"

        [[ $line =~ "<manifest>" ]] && extract=1
        [[ $line =~ "</manifest>" ]] && extract=
    done < <(printf '%s\n' "$1")

}

epub_containerxml_parse_root_path () {
    rootfiles=$(epub_containerxml_parse_rootfiles "$1")

    regex "$rootfiles" "$fullpathattr_re"
}

epub_rootxml_parse_metacover_content () {
    metacover_match=""

    while IFS=$'\n' read -r line; do
        if [[ $line =~ "<meta"[[:space:]] && $line =~ "name=\"cover\"" ]]; then
            metacover_match=$(regex "$line" "$contentattr_re")

            break
        fi
    done < <(printf '%s\n' "$1")

    echo "$metacover_match"
}

epub_rootxmlpath_get () {
    epub_cxml=$(zip_read_file "$1" "META-INF/container.xml")

    epub_containerxml_parse_root_path "$epub_cxml"
}

epub_rootfile_manifestcover_get () {
    epub_rxmlpath=$(epub_rootxmlpath_get "$1")
    epub_rxml=$(zip_read_file "$1" "$epub_rxmlpath")
    epub_rxml_metacontentid=$(
        epub_rootxml_parse_metacover_content "$epub_rxml")
    epub_rxml_manifitem=$(
        epub_rootxml_parse_manifest "$epub_rxml" "$epub_rxml_metacontentid")
    epub_rxml_manifitemhref=$(
        regex "$epub_rxml_manifitem" "$hrefattr_re")

    if [[ -n "$epub_rxml_manifitemhref" ]]; then
        if [[ "$epub_rxml_manifitemhref" != /* ]]; then
            # if cover does not sstart on root path, attach to manifest path
            epub_rxml_dir=$(dirname "$epub_rxmlpath")
            epub_rxml_manifitemhref="$epub_rxml_dir/$epub_rxml_manifitemhref"
        fi
    fi

    echo "$epub_rxml_manifitemhref"
}

show_epub () {
    epub_path=$1
    epub_wh_max=$2
    #epub_ls=$(unzip -l "$1")
    epub_manifest_cover=$(epub_rootfile_manifestcover_get "$1")
    epub_manifest_cover_ext="${epub_manifest_cover##*.}"
    epub_manifest_cover_base=$(basename "$epub_manifest_cover")
    epub_manifest_cover_dest="$cachedir/$epub_manifest_cover_base"

    if [[ -n "$epub_manifest_cover" && -n "$epub_manifest_cover_ext" ]]; then
        zip_move_file_out \
            "$epub_path" \
            "$epub_manifest_cover" \
            "$cachedir"

        paint_downscale "$epub_manifest_cover_dest" "$epub_wh_max" "$3"
    else
        fail "$msg_epub_cover_not_found"
    fi
}

show_video () {
    vid_path=$1
    vid_wh_max=$2
    vid_ffmpeg_output=$(ffmpeg -i "$1" 2>&1)
    vid_duration_ss=$(video_duration_ffmpeg_parse_ss "$vid_ffmpeg_output")
    vid_wh_native=$(video_resolution_ffmpeg_parse "$vid_ffmpeg_output")
    vid_wh_scaled=$(wh_scaled_get "$vid_wh_native" "$vid_wh_max")
    vid_frame_ss=$(($vid_duration_ss / 5))
    vid_thumb_path=$(cachedir_path_get "$cachedir" "video" "w h" ".png")

    if [[ -z "$is_cmd_ffmpeg" ]]; then
        fail "$msg_cmd_not_found_ffmpeg";
    fi

    ffmpeg \
        -ss "$vid_frame_ss" \
        -i "$vid_path" \
        -frames:v 1 \
        -s "$vid_wh_scaled" \
        -pattern_type none \
        -update true \
        -f image2 \
        -loglevel error \
        -hide_banner \
        -y "$vid_thumb_path"

    paint "$vid_thumb_path" "$vid_wh_scaled" "$3"
}

show_audio () {
    aud_path=$1
    aud_wh_max=$2
    aud_ffmpeg_output=$(ffmpeg -i "$1" 2>&1)
    aud_wh_native=$(video_resolution_ffmpeg_parse "$aud_ffmpeg_output")
    aud_wh_scaled=$(wh_scaled_get "$aud_wh_native" "$aud_wh_max")
    aud_thumb_path=$(cachedir_path_get "$cachedir" "audio" "w h" ".png")

    if [[ -z "$is_cmd_ffmpeg" ]]; then
        fail "$msg_cmd_not_found_ffmpeg"
    fi

    ffmpeg \
        -ss "00:00:00" \
        -i "$aud_path" \
        -frames:v 1 \
        -s "$aud_wh_scaled" \
        -pattern_type none \
        -update true \
        -f image2 \
        -loglevel error \
        -hide_banner \
        -y "$aud_thumb_path"

    paint "$aud_thumb_path" "$aud_wh_scaled" "$3"
}

show_pdf () {
    pdf_path=$1
    pdf_wh_max=$2
    pdf_thumb_path=$(pdf_to_image "$pdf_path" "$pdf_wh_max")

    paint "$pdf_thumb_path" "$pdf_wh_max" "$3"
}

show_font () {
    font_path=$1
    font_wh_max=$2
    font_thumb_path=$(magick_font_to_image "$font_path" "$font_wh_max")

    paint "$font_thumb_path" "$font_wh_max" "$3"
}

preprocess_get () {
    sixel_maxwh=$(escquery_sixel_maxwh_get)
    sixel_maxwhseg="sixelmax-${sixel_maxwh}"
    cellwh=$(escquery_cellwh_get)
    cellwhseg="cell-${cellwh}"

    printf '%s\n' "v$version,$sessid,$cellwhseg,$sixel_maxwhseg"
}

start () {
    path=$1
    wh_cell=$(wh_cell_get)
    target_format=$(image_display_format_get)
    target_wh_max=$(wh_imagemax_get)
    target_wh_goal=$(wh_start_get "$2" "$3" "$cells" "$wh_cell")
    [[ $target_wh_max =~ $wxhstr_re ]] &&
        target_wh_goal=$(wh_scaled_get "$target_wh_goal" "$target_wh_max")

    if [ -n "$cache" ]; then
        cachedir_calibrate "$cachedir"
    fi

    case $(file_type_get "$path") in
        "$mime_type_SVG")
            paint "$path" "$target_wh_goal" "$target_format";;
        "$mime_type_IMAGE")
            paint_downscale "$path" "$target_wh_goal" "$target_format";;
        "$mime_type_VIDEO")
            show_video "$path" "$target_wh_goal" "$target_format";;
        "$mime_type_AUDIO")
            show_audio "$path" "$target_wh_goal" "$target_format";;
        "$mime_type_EPUB")
            show_epub "$path" "$target_wh_goal" "$target_format";;
        "$mime_type_PDF")
            show_pdf "$path" "$target_wh_goal" "$target_format";;
        "$mime_type_FONT")
            show_font "$path" "$target_wh_goal" "$target_format";;
        *)
    esac
}

# do not run main when sourcing the script
if [[ -n "$preprocess" ]]; then
    preprocess_get "$@"
elif [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    start "$@"
else
    true
fi
