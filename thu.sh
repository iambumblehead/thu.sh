#!/usr/bin/env bash
#
# ex,
# ./thu.sh /path/to/file.png 800 400
# ./thu.sh /path/to/file.pdf
# ./thu.sh /path/to/file.ttf
# ./thu.sh /path/to/file.mp4 1020 780
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
format_type_NONE="NONE"

color_RGBA_transp="rgba(0,0,0,0)"
color_RGBA_black="rgba(0,0,0,1)"
color_RGBA_cream="rgba(240,240,240,1)"

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
escITERM2cellsize=$(printf '%b' "\e]1337;ReportCellSize\a")

msg_cmd_not_found="commands not found:"
msg_cmd_not_found_pdfany="$msg_cmd_not_found 'mutool' 'pdftoppm' 'magick'"
msg_cmd_not_found_ffmpeg="$msg_cmd_not_found 'ffmpeg'"
msg_cmd_not_found_unzip="$msg_cmd_not_found 'unzip'"
msg_cmd_not_found_magickany="$msg_cmd_not_found 'magick' 'convert'"
msg_cmd_not_found_identifyany="$msg_cmd_not_found 'exiftool' 'identify'"
msg_unsupported_width="unsupported width, :width"
msg_unsupported_height="unsupported height, :height"
msg_undetectable_cell_size="cell size undetectable, try -r option"
msg_unsupported_display="image display is not supported"
msg_unsupported_mime="mime type is not supported"
msg_unknown_win_size="window size is unknown and could not be detected"
msg_invalid_resolution="resolution invalid: :resolution"
msg_invalid_zoom="resolution invalid: :zoom"
msg_epub_cover_not_found="epub cover image could not be located"
msg_could_not_generate_image="could not generate image"

timecode_re="([[:digit:]]{2}[:][[:digit:]]{2}[:][[:digit:]]{2})"
resolution_re="([[:digit:]]{2,8}[x][[:digit:]]{2,8})"
fullpathattr_re="full-path=['\"]([^'\"]*)['\"]"
contentattr_re="content=['\"]([^'\"]*)['\"]"
hrefattr_re="href=['\"]([^'\"]*)['\"]"
wxhstr_re="^[[:digit:]]+[x][[:digit:]]+$"
numint_re="^[[:digit:]]+$"
numfl_re="^[-+]?[[:digit:]]+\.?[[:digit:]]*$"
version_re="([[:digit:]]+[\.][[:digit:]]+[\.][[:digit:]]+)"
sesscellwh_re="cellwh=([[:digit:]]+[x][[:digit:]]+)"
sesssixelmaxwh_re="sixelmaxwh=([[:digit:]]+[x][[:digit:]]+)"
sessdisplayformat_re="displayformat=(SIXEL|KITTY|NONE)"

cachedir="$HOME/.config/thu"
[ -n "${XDG_CONFIG_HOME}" ] &&
    cachedir="$XDG_CONFIG_HOME/thu"

join () {
    local a=("${@:3}"); printf "%s" "$2" "${a[@]/#/$1}"
}

regex () { # Usage: regex "string" "regex"
    [[ $1 =~ $2 ]] && printf '%s\n' "${BASH_REMATCH[1]}"
}

parse_int () { # remove after decimal for now; `printf -v int` empty iterm2
    printf '%d\n' "${1%.*}"
}

fail () { # Send message to stderr, return code specified by $2, or 1 (default)
    printf '%s\n' "$1" >&2; exit "${2-1}"
}

error () { # Send message to stderr, no exit code
    printf '%s\n' "$1" >&2;
}

print_help () {
    echo "-c cell, proces width and height as cell columns and lines"
    echo "-e error, show errors normally hidden during image-generation flow"
    echo "-r resolution, cell pixel resolution mostly for foot@1.16.2 ex, 10x21"
    echo "-i id, define sesson 'id'"
    echo "-b blocked, define stdout blocked (ncurses), send esc queries to tty"
    echo "-j skip main behaviour, write session data"
    echo "-k define session from string (same format seen with '-j')"
    echo "-l define session from previous '-j' generated session data"
    echo "-s configure cache ex, -s true"
    echo "-t timeout, use custom timeout (seconds) w/ shell query functions"
    echo "-v version, show version ($version)"
    echo "-w wipe, clear kitten icat display image"
    echo "-z zoom, zoom number applied to cell area, ex '1' or '2'"
}

# do not use 'set -e' to full exit script process
# generating ffmpeg output will trigger condition
#
# set -e

# printf -v TODAY "%(%F)T"; printf '%s\n' "$TODAY"
# mstimestamp () {
#     # millisecond timestamp ex, 1710459031.000
#     printf "%.3f\n" $((${EPOCHREALTIME/.} / 1000000))
# }

sessid="sessdefault"
zoom=
cells=
sess=""
wipe=""
show_error=
cache="true"
timeoutssint=2 # must be integer for darwin/mac variant of 'read'
sessbuild=""
defaultw=10000
version=0.1.0
while getopts "cer:bkl:jstivwz:h" opt; do
    case "${opt}" in
        c) cells="true";;
        e) show_error="true";;
        r) resolution="${OPTARG}"
           if [[ ! "$resolution" =~ $wxhstr_re ]]; then
               fail "${msg_invalid_resolution/:resolution/${OPTARG}}"
           fi ;;
        i) sessid="${OPTARG}";;
        b) is_stdout_blocked="true";;
        j) sessbuild="true";;
        k) sess=$(cat "$cachedir/thu.sh.sess");;
        l) sess="${OPTARG}";;
        s) cache="true";;
        t) timeoutssint="${OPTARG}";;
        w) wipe="true";;
        z) zoom=$(parse_int "$OPTARG") # remove after decimal for now
           if [[ ! "$zoom" =~ $numfl_re ]]; then
               fail "${msg_invalid_zoom/:zoom/${OPTARG}}"
           fi ;;
        v) echo "$version"; exit 0;;
        h|*) print_help; exit 0;;
    esac
done
shift $(($OPTIND - 1))

is_foot_lte_1_16_2_get () {
    if [[ $TERM == "foot" ]]; then
        foot_details=$(foot --version)
        foot_version=$(regex "$foot_details" "$version_re")

        if [[ -n "$foot_version" ]]; then
            IFS="." read -ra semver <<< "$foot_version"
            major="${semver[0]}"
            minor="${semver[1]}"
            patch="${semver[2]}"

            if [[ "$major" -lt 1 ]]; then
                echo "true"
            elif [[ "$major" -eq 1 ]]; then
                if [[ "$minor" -lt 16 ]]; then
                    echo "true"
                elif [[ "$minor" -eq 16 ]]; then
                    if [[ "$patch" -le 2 ]]; then
                        echo "true"
                    fi
                fi
            fi
        fi
    fi
}

is_foot_lte_1_16_2_message_get () {
    join $'\n' \
         "WARNING: foot <= v1.16.2 returns incorrect scaled-window values:" \
         "https://codeberg.org/dnkl/foot/issues/1643" \
         "" \
         "To supress this message, define zoom scale using \"-z \$SCALE\"." \
         "The value of \$SCALE will correspond to the window scale used." \
         "  If no window scaling, use \"-z 1\"." \
         "  If a 3x window scaling is used, use \"-z 3\"."
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

escquery_cellwh_get_iterm2 () {
    esc="$escITERM2cellsize"
    if [[ -n "$is_stdout_blocked" ]]; then
        echo -e "$esc" > /dev/tty
        IFS=";" read -d "\^G" -sra REPLY -t "$timeoutssint" < /dev/tty
    else
        IFS=";" read -d "\^G" -sra REPLY -t "$timeoutssint" -p "$esc" >&2
    fi

    if [[ "${REPLY[2]}" =~ $numfl_re ]]; then
        itermcellz=$(parse_int "${REPLY[3]}")
        itermcellw=$(($(parse_int "${REPLY[1]##*=}")*${itermcellz}))
        itermcellh=$(($(parse_int "${REPLY[2]}")*${itermcellz}))

        printf '%s\n' "${itermcellw}x${itermcellh}"
    fi
}

escquery_cellwh_get_xterm () {
    esc="$escXTERMcellsize"
    if [[ -n "$is_stdout_blocked" ]]; then
        echo -e "$esc" > /dev/tty
        IFS=";" read -d t -sra REPLY -t "$timeoutssint" < /dev/tty
    else
        IFS=";" read -d t -sra REPLY -t "$timeoutssint" -p "$esc" >&2
    fi

    if [[ "${REPLY[1]}" =~ $numint_re ]]; then
        printf '%s\n' "${REPLY[2]}x${REPLY[1]}"
    fi
}

escquery_cellwh_get () {
    wh=$(escquery_cellwh_get_xterm)
    if [[ -z "$wh" ]]; then
        wh=$(escquery_cellwh_get_iterm2)
    fi

    if [[ -n "$wh" ]]; then
        printf '%s\n' "$wh"
    else
        fail "$msg_undetectable_cell_size"
    fi
}

# empty return value if sixel is not-supported
escquery_sixel_maxwh_get () {
    if [[ -z $(escquery_sixel_issupport_get) ]]; then
        exit 0
    fi

    esc="$escXTERMsixelmaxwh"
    if [[ -n "$is_stdout_blocked" ]]; then
        echo -e "$esc" > /dev/tty
        IFS=";" read -d 'S' -sra REPLY -t "$timeoutssint" < /dev/tty
    else
        IFS=";" read -d 'S' -sra REPLY -t "$timeoutssint" -p "$esc" >&2
    fi

    if [[ "${REPLY[1]}" =~ $numint_re ]]; then
        printf '%s\n' "${REPLY[2]}x${REPLY[3]}"
    fi
}

image_display_format_get () {
    sessdisplayformat=$(regex "$1" "$sessdisplayformat_re")
    if [[ -n "$sessdisplayformat" ]]; then
        printf '%s\n' "$sessdisplayformat"
    elif [[ -n "$(escquery_sixel_issupport_get)" ]]; then
        printf '%s\n' "$format_type_SIXEL"
    elif [[ -n "$is_cmd_kitten_icat_support" ]]; then
        printf '%s\n' "$format_type_KITTY"
    else
        printf '%s\n' "$format_type_NONE"
    fi
}

zip_read_file () {
    if [[ -z "$is_cmd_unzip" ]]; then
        fail "$msg_cmd_not_found_unzip";
    fi

    # extract files to pipe (stdout). Nothing but the file data sent to stdout,
    # and files always extracted in binary, just as stored (no conversions).
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
    img_wh=$3

    export MAGICK_OCL_DEVICE=true
    if [[ -n "$is_cmd_magick" ]]; then
        magick \
            -background "$color_RGBA_transp" \
            "$img_path" \
            -geometry "$img_wh" \
            sixel:-
        echo ""
    elif [[ -n "$is_cmd_convert" ]]; then
        convert \
            -channel rgba \
            -background "$color_RGBA_transp" \
            -geometry "$img_wh" \
            "$img_path" \
            sixel:-
        echo ""
    else
        fail "$msg_cmd_not_found_magickany"
    fi
}

image_to_kittenicat () {
    img_path=$1
    img_tl=$2
    img_wh=$3
    wh_cell=$5

    # kitten does not provide a 'geometry' option
    # so image must have been preprocessed to fit desired geometry
    # or must be exactly placed AND sized
    # --place `<width>x<height>@<left>x<top>`
    # --use-window-size `cells_width,cells_height,pixels_width,pixels_height`
    # https://github.com/kovidgoyal/kitty/discussions/7275
    if [[ -n "$is_stdout_blocked" ]]; then
        kitten icat \
               --place "${img_wh}@${img_tl}" \
               --align left \
               --stdin=no \
               --transfer-mode=stream "$img_path" >/dev/tty </dev/tty
    else
        kitten icat --align left "$img_path"
    fi
}

# paint $PATH $TL $WH $FORMAT
paint () {
    case "$4" in
        "$format_type_SIXEL")
            image_to_sixel_magick "$@";;
        "$format_type_KITTY")
            image_to_kittenicat "$@";;
        *)
            fail "$msg_unsupported_display, format_type: \"$3\""
    esac
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
    # term_resolution is from esc query, do not query unless needed
    wharea_pixels=$([ -z "$3" ] && wh_term_resolution_get)
    wharea_cells=$(wh_term_columnsrows_get)
    wharea_def=$([ -n "$3" ] && echo "$wharea_cells" || echo "$wharea_pixels")
    w=$([ -n "$1" ] && echo "$1" || echo "$((${wharea_def%%x*} * 80 / 100))")
    h=$([ -n "$2" ] && echo "$2" || echo "$((${wharea_def##*x} * 80 / 100))")

    if [[ ! $w =~ $numint_re ]]; then
        fail "${msg_unsupported_width/:width/$w}"
    fi

    if [[ ! $h =~ $numint_re ]]; then
        fail "${msg_unsupported_height/:height/$h}"
    fi

    wh="${w}x${h}"
    if [[ -n "$cells" ]]; then
        wh=$(wh_pixels_from_cells_get "$wh" "$whcell")
    fi

    echo "$wh"
}

tl_start_get () {
    t=$([ -n "$1" ] && echo "$1" || echo "0")
    l=$([ -n "$2" ] && echo "$2" || echo "0")

    printf '%s\n' "${t}x${l}"
}

# wh_apply_zoom $WxH $zoom
wh_apply_zoom () {
    IFS="x" read -ra wh <<< "$1"
    z=$([ -n "$2" ] && echo "$2" || echo "1")

    printf '%s\n' "$((${wh[0]}*$z))x$((${wh[1]}*$z))"
}

# if cellwh can be probed from session string,
#   return session cellwh (ex, cellwh=10x21 => 10x21)
# else
#   use escape query to obtain cellwh from terminal
wh_cell_get () {
    sesscellwh=$(regex "$1" "$sesscellwh_re")
    if [[ -n "$sesscellwh" ]]; then
        cellwh="$sesscellwh"
    else
        cellwh=$(escquery_cellwh_get)
    fi

    wh_apply_zoom "$cellwh" "$zoom"
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
    sesssixelmaxwh=$(regex "$1" "$sesssixelmaxwh_re")
    if [[ -n "$sesssixelmaxwh" ]]; then
        echo "$sesssixelmaxwh"
    elif [[ -n "$is_cmd_kitten" ]]; then
        echo ""
    else
        wh_sixelmax_get
    fi
}

wh_max_get () {
    IFS="x" read -ra wh <<< "$1"

    echo "$((${wh[0]} > ${wh[1]} ? ${wh[0]} : ${wh[1]}))"
}

wh_pointsize_get () {
    IFS="x" read -ra wh <<< "$1"

    min=$((${wh[0]} > ${wh[1]} ? ${wh[1]} : ${wh[0]}))
    mul=$((${wh[0]} > ${wh[1]} ? 9 : 10))

    echo "$(($min / $mul))"
}

wh_scaled_get () {
    IFS="x" read -ra wh_bgn <<< "$1"
    IFS="x" read -ra wh_max <<< "$2"
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

wh_term_resolution_get_xterm () {
    esc="$escXTERMtermsize"
    if [[ -n "$is_stdout_blocked" ]]; then
        echo -e "$esc" > /dev/tty
        IFS=";" read -d t -sra REPLY -t "$timeoutssint" < /dev/tty
    else
        IFS=";" read -d t -sra REPLY -t "$timeoutssint" -p "$esc" >&2
    fi

    if [[ "${REPLY[1]}" =~ $numint_re ]]; then
        printf '%s\n' "${REPLY[2]}x${REPLY[1]}"
    fi
}

wh_term_resolution_get_tmux () {
    esc="$escXTERMtermsizeTMUX"
    if [[ -n "$is_stdout_blocked" ]]; then
        echo -e '\e[14t' > /dev/tty
        IFS=$';\t' read -d t -sra REPLY -t "$timeoutssint" < /dev/tty
    else
        IFS=$';\t' read -d t -sra REPLY -t "$timeoutssint" -p "$esc" >&2
    fi

    if [[ "${REPLY[1]}" =~ $numint_re ]]; then
        printf '%s\n' "${REPLY[2]}x${REPLY[1]}"
    fi
}

wh_term_resolution_get () {
    whterm=$(wh_term_resolution_get_xterm)
    if [[ -z "$whterm" ]]; then
        whterm=$(wh_term_resolution_get_tmux)
    fi

    if [[ -n "$whterm" ]]; then
        printf '%s\n' "$whterm"
    else
        fail "$msg_unknown_win_size"
    fi
}

# get the width and height in pixels from columns and rows
#
# to avoid rounding issues that may result io too-small numbers,
# resolution is calculated from the full set of columns and rows
wh_pixels_from_cells_get () {
    IFS="x" read -ra wh <<< "$1"
    IFS="x" read -ra whcell <<< "$2"

    printf '%s\n' "$((${wh[0]} * ${whcell[0]}))x$((${wh[1]} * ${whcell[1]}))"
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

thumb_create_from_epub () {
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

        thumb_create_from_image "$epub_manifest_cover_dest" "$epub_wh_max"
    else
        fail "$msg_epub_cover_not_found"
    fi
}

thumb_create_from_video () {
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

    echo "$vid_thumb_path"
}

thumb_create_from_audio () {
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

    echo "$aud_thumb_path"
}


# thumb_create_from_pdf_magick $path $wh
thumb_create_from_pdf_magick () {
    pdf_path=$1
    pdf_target_wh=$2
    pdf_thumb_path=$(cachedir_path_get "$cachedir" "pdf" "$2" ".jpg")

    if [[ -n "$is_cmd_magick" ]]; then
        pdfimg_error=$(magick \
            "${pdf_path}[0]" \
            -define pdf:thumbnail=true \
            -resize "$pdf_target_wh" \
            "$pdf_thumb_path" 2>&1)
    elif [[ -n "$is_cmd_convert" ]]; then
        pdfimg_error=$(convert \
            "${pdf_path}[0]" \
            -define pdf:thumbnail=true \
            -resize "$pdf_target_wh" \
            "$pdf_thumb_path" 2>&1)
    else
        fail "$msg_cmd_not_found_magickany"
    fi

    if [[ -n "$pdfimg_error" && -n "$show_error" ]]; then
        error "pdfimg $pdfimg_error"
    fi

    echo "$pdf_thumb_path"
}

thumb_create_from_pdf_mutool () {
    pdf_path=$1
    pdf_target_wh=$2
    pdf_thumb_path=$(cachedir_path_get "$cachedir" "pdf" "w h" ".png")

    mutool \
        draw -i \
        -r 72 \
        -w "${pdf_target_wh%%x*}" \
        -h "${pdf_target_wh##*x}" \
        -F png \
        -o "$pdf_thumb_path" "$pdf_path" 1 &> /dev/null

    echo "$pdf_thumb_path"
}

thumb_create_from_pdf_pdftoppm () {
    pdf_path=$1
    pdf_target_wh=$2
    pdf_thumb_path=$(cachedir_path_get "$cachedir" "pdf" "w h" ".jpg")
    # extension needs to be removed from output path "pattern" used here
    pdftoppm \
        -singlefile \
        -f 1 -l 1 \
        -scale-to "$(wh_max_get "$2")" \
        -jpeg "$pdf_path" "${pdf_thumb_path%.*}"

    echo "$pdf_thumb_path"
}

thumb_create_from_font () {
    font_path=$1
    font_wh_max=$2
    font_pointsize="$(wh_pointsize_get "$2")"
    font_bg_color="$color_RGBA_black"
    font_fg_color="$color_RGBA_cream"
    font_preview_text=$(
        join $'\n' \
             "ABCDEFGHIJKLM" \
             "NOPQRSTUVWXYZ" \
             "abcdefghijklm" \
             "nopqrstuvwxyz" \
             "1234567890" \
             "!@$\%(){}[]")
    font_thumb_path=$(cachedir_path_get "$cachedir" "font" "w h" ".jpg")

    if [[ -n "$is_cmd_magick" ]]; then
        fontimg_error=$(magick \
            -size "$font_wh_max" \
            -background "$font_bg_color" \
            -fill "$font_fg_color" \
            -font "$font_path" \
            -pointsize "$font_pointsize" \
            -gravity Center \
            "label:${font_preview_text}" \
            "$font_thumb_path" 2>&1)
    elif [[ -n "$is_cmd_convert" ]]; then
        fontimg_error=$(convert \
            -size "$font_wh_max" \
            -background "$font_bg_color" \
            -fill "$font_fg_color" \
            -font "$font_path" \
            -pointsize "$font_pointsize" \
            -gravity Center \
            "label:${font_preview_text}" \
            "$font_thumb_path" 2>&1)
    else
        fail "$msg_cmd_not_found_magickany"
    fi

    if [[ -n "$fontimg_error" && -n "$show_error" ]]; then
        error "fontimg $fontimg_error"
    fi

    echo "$font_thumb_path"
}

# thumb_create_from_pdf $path $wh
thumb_create_from_pdf () {
    if [[ -n "$is_cmd_mutool" ]]; then
        thumb_create_from_pdf_mutool "$@"
    elif [[ -n "$is_cmd_pdftoppm" ]]; then
        thumb_create_from_pdf_pdftoppm "$@"
    elif [[ -n "$is_cmd_magick_any" ]]; then
        thumb_create_from_pdf_magick "$@"
    else
        fail "$msg_cmd_not_found_pdfany"
    fi
}

thumb_create_from_image () {
    oimg_path=$1
    oimg_target_wh=$2
    oimg_wh_native=$(img_wh_get "$oimg_path")
    oimg_wh_scaled=$(wh_scaled_get "$oimg_wh_native" "$oimg_target_wh")
    oimg_thumb_path=$(cachedir_path_get "$cachedir" "img" "$2" ".png")

    if [[ -n "$is_cmd_magick" ]]; then
        imgimg_error=$(magick \
            "$oimg_path" \
            -resize "$oimg_wh_scaled" \
            "$oimg_thumb_path" 2>&1)
    elif [[ -n "$is_cmd_convert" ]]; then
        imgimg_error=$(convert \
            "$oimg_path" \
            -resize "$oimg_wh_scaled" \
            "$oimg_thumb_path" 2>&1)
    else
        fail "$msg_cmd_not_found_magickany"
    fi

    if [[ -n "$imgimg_error" && -n "$show_error" ]]; then
        error "imgimg $imgimg_error"
    fi

    echo "$oimg_thumb_path"
}

thumb_create_from_svg () {
    svgimg_path=$1
    svgimg_target_wh=$2
    svgimg_thumb_path=$(cachedir_path_get "$cachedir" "svg" "$2" ".png")

    if [[ -n "$is_cmd_magick" ]]; then
        svgimg_error=$(magick \
            -background "$color_RGBA_transp" \
            "$svgimg_path" \
            -geometry "$svgimg_target_wh" \
            "$svgimg_thumb_path" 2>&1)
    elif [[ -n "$is_cmd_convert" ]]; then
        svgimg_error=$(convert \
            -quiet \
            -channel rgba \
            -background "$color_RGBA_transp" \
            -geometry "$svgimg_target_wh" \
            "$svgimg_path" \
            "$svgimg_thumb_path" 2>&1)
    else
        fail "$msg_cmd_not_found_magickany"
    fi

    if [[ -n "$svgimg_error" && -n "$show_error" ]]; then
        error "svgimg $svgimg_error"
    fi

    echo "$svgimg_thumb_path"
}

thumb_create_from () {
    path="$1"
    wh_goal="$2"

    case $(file_type_get "$path") in
        "$mime_type_SVG")
            thumb_create_from_svg "$path" "$wh_goal";;
        "$mime_type_IMAGE")
            thumb_create_from_image "$path" "$wh_goal";;
        "$mime_type_VIDEO")
            thumb_create_from_video "$path" "$wh_goal";;
        "$mime_type_AUDIO")
            thumb_create_from_audio "$path" "$wh_goal";;
        "$mime_type_EPUB")
            thumb_create_from_epub "$path" "$wh_goal";;
        "$mime_type_PDF")
            thumb_create_from_pdf "$path" "$wh_goal";;
        "$mime_type_FONT")
            thumb_create_from_font "$path" "$wh_goal";;
        *)
    esac
}

sessbuild_get () {
    sess=$(
        join ',' \
             "thu.sh=v$version" \
             "sess=$sessid" \
             "displayformat=$(image_display_format_get)" \
             "sixelmaxwh=$(wh_sixelmax_get)" \
             "cellwh=$(wh_cell_get)")

    cachedir_calibrate "$cachedir" "$cache"

    # write session to file
    printf '%s\n' "$sess" > "$cachedir/thu.sh.sess"
    printf '%s\n' "$sess"
}

wipe_kittenicat () {
    if [[ -n "$is_stdout_blocked" ]]; then
        kitten icat --clear --silent >/dev/tty </dev/tty
    else
        kitten icat --clear --silent
    fi
}

wipe_get () {
    if [[ $TERM == "xterm-kitty" ]]; then
        wipe_kittenicat
    fi
}

start () {
    path=$1
    wh_cell=$(wh_cell_get "$sess")
    target_format=$(image_display_format_get "$sess")
    target_wh_max=$(wh_imagemax_get "$sess")
    target_wh_goal=$(wh_start_get "$4" "$5" "$cells" "$wh_cell")
    target_tl_goal=$(tl_start_get "$2" "$3")

    [[ $target_wh_max =~ $wxhstr_re ]] &&
        target_wh_goal=$(wh_scaled_get "$target_wh_goal" "$target_wh_max")

    if [[ -n $(is_foot_lte_1_16_2_get) && -z "$zoom" && -z "$sessbuild" ]]; then
        is_foot_lte_1_16_2_message_get
    fi

    cachedir_calibrate "$cachedir" "$cache"

    thumb_path=$(thumb_create_from "$path" "$target_wh_goal")
    if [[ -n "$thumb_path" && -f "$thumb_path" ]]; then
        paint \
            "$thumb_path" \
            "$target_tl_goal" \
            "$target_wh_goal" \
            "$target_format" \
            "$wh_cell"
    else 
        fail "${msg_could_not_generate_image}"
    fi
}

# test: thu.sh -ckz 3 ./Guix_logo.svg
# do not run main when sourcing the script
if [[ -n "$sessbuild" ]]; then
    sessbuild_get "$@"
elif [[ -n "$wipe" ]]; then
    wipe_get "$@"
elif [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    start "$@"
else
    true
fi
