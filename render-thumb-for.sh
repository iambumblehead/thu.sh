#!/usr/bin/env bash
#
# ex,
# ./render-thumb-for.sh /path/to/file.png 800 400
# ./render-thumb-for.sh /path/to/file.pdf
# ./render-thumb-for.sh /path/to/file.ttf
# ./render-thumb-for.sh /path/to/file.mp4 1020 780

is_cmd_mutool=$(command -v mutool)
is_cmd_pdftoppm=$(command -v pdftoppm)
is_cmd_convert=$(command -v convert)
is_cmd_exiftool=$(command -v exiftool)
is_cmd_identify=$(command -v identify)
is_cmd_ffmpeg=$(command -v ffmpeg)
is_cmd_unzip=$(command -v unzip)

mimeTypeSVG="svg"
mimeTypeIMAGE="imgage"
mimeTypeVIDEO="video"
mimeTypeAUDIO="audio"
mimeTypeFONT="font"
mimeTypeEPUB="epub"
mimeTypePDF="pdf"

timecode_re="([[:digit:]]{2}[:][[:digit:]]{2}[:][[:digit:]]{2})"
resolution_re="([[:digit:]]{2,8}[x][[:digit:]]{2,8})"
fullpathattr_re="full-path=['\"]([^'\"]*)['\"]"
contentattr_re="content=['\"]([^'\"]*)['\"]"
hrefattr_re="href=['\"]([^'\"]*)['\"]"

cachedir="$HOME/.config/render-thumb-for"
if [ -n "${XDG_CONFIG_HOME}" ]; then
    cachedir="$XDG_CONFIG_HOME/render-thumb-for"
fi

regex() {
    # Usage: regex "string" "regex"
    [[ $1 =~ $2 ]] && printf '%s\n' "${BASH_REMATCH[1]}"
}

zip_read_file () {
    if [[ -z "$is_cmd_unzip" ]]; then
        echo "'unzip' command not found";
        exit 1
    fi

    unzip -p "$1" "$2"
}

zip_move_file_out () {
    if [[ -z "$is_cmd_unzip" ]]; then
        echo "'unzip' command not found";
        exit 1
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
    pathwh="${3/ /x}"
    pathextn="${4:1}" #remove dot eg .jpg -> jpg
    pathname="$pathbase.$pathwh.$pathextn"
    
    echo "$cachedir/$pathname"
}

file_type_get () {
    mime=$(file -b --mime-type "$1")

    # font, pdf, video, audio, epub
    if [[ $mime =~ ^"image/svg" ]]; then
        echo "$mimeTypeSVG"
    elif [[ $mime =~ ^"image/" ]]; then
        echo "$mimeTypeIMAGE"
    elif [[ $mime =~ ^"video/" ]]; then
        echo "$mimeTypeVIDEO"
    elif [[ $mime =~ ^"audio/" ]]; then
        echo "$mimeTypeAUDIO"
    elif [[ $mime =~ ^"application/pdf" ]]; then
        echo "$mimeTypePDF"
    elif [[ $mime =~ (ttf|truetype|opentype|woff|woff2|sfnt)$ ]]; then
        echo "$mimeTypeFONT"
    elif [[ $mime =~ ^"application/epub" ]]; then
        echo "$mimeTypeEPUB"
    else
        echo "unsupported"
    fi
}

wh_start_get () {
    w="$1"
    h="$2"
    w_mul=$([ -n "$3" ] && echo "$3" || echo "1")
    h_mul=$([ -n "$4" ] && echo "$4" || echo "1")

    [[ -z "$w" ]] && w="1000"
    [[ -z "$h" ]] && h="$w"

    echo "$(("$w"*"$w_mul")) $(("$h"*"$h_mul"))"
}

wh_max_get () {
    IFS=" " read -r -a wh <<< "$1"

    echo "$((${wh[0]} > ${wh[1]} ? ${wh[0]} : ${wh[1]}))"
}

wh_pointsize_get () {
    IFS=" " read -r -a wh <<< "$1"

    min=$((${wh[0]} > ${wh[1]} ? ${wh[1]} : ${wh[0]}))
    mul=$((${wh[0]} > ${wh[1]} ? 9 : 10))

    echo "$(($min / $mul))"
}

wh_scaled_get () {
    IFS=" " read -r -a wh_bgn <<< "$1"
    IFS=" " read -r -a wh_max <<< "$2"
    w_bgn=${wh_bgn[0]}
    w_max=${wh_max[0]}
    h_bgn=${wh_bgn[1]}
    h_max=${wh_max[1]}

    # if image is smaller, return native wh
    if [ "$w_max" -gt "$w_bgn" ] && [ "$h_max" -gt "$h_bgn" ]; then
        echo "$w_bgn $h_bgn"
        return 1
    fi

    # multiply and divide by 100 to convert decimal and int
    fin_h=$h_max
    fin_w=$((($w_bgn * (($fin_h * 100) / $h_bgn)) / 100))
    if [ "$fin_w" -ge "$w_max" ]; then
        fin_w=$w_max
        fin_h=$((($h_bgn * (($fin_w * 100) / $w_bgn)) / 100))
    fi

    echo "$fin_w $fin_h"
}

img_wh_exiftool_get () {  # shellcheck disable=SC2016
    exiftool -p '$ImageWidth $ImageHeight' "$1"
}

img_wh_identify_get () {
    identify -format "%w %h" "$1"
}

img_wh_get () {
    if [[ -z "$is_cmd_exiftool" ]] && \
           [[ -z "$is_cmd_identify" ]]; then
        echo "'exiftool' or 'identify' commands not found";
        exit 1
    elif [[ -n "$is_cmd_exiftool" ]]; then
        img_wh_exiftool_get "$1"
    elif [[ -n "$is_cmd_identify" ]]; then
        img_wh_identify_get "$1"
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

    echo "${resolution_match/x/ }"
}

img_sixel_paint () {
    img_path=$1
    img_wh=$2

    export MAGICK_OCL_DEVICE=true
    convert \
        -channel rgba \
        -background "rgba(0,0,0,0)" \
        -geometry "${img_wh/ /x}" \
        "$img_path" sixel:-

    echo ""
}

img_sixel_paint_downscale () {
    img_path=$1
    img_wh_max=$2
    img_wh_native=$(img_wh_get "$img_path")
    img_wh_scaled=$(wh_scaled_get "$img_wh_native" "$img_wh_max")

    img_sixel_paint "$img_path" "$img_wh_scaled"
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

        img_sixel_paint_downscale "$epub_manifest_cover_dest" "$epub_wh_max"
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
        echo "'ffmpeg' command not found";
        exit 1
    fi

    ffmpeg \
        -ss "$vid_frame_ss" \
        -i "$vid_path" \
        -frames:v 1 \
        -s "${vid_wh_scaled/ /x}" \
        -pattern_type none \
        -update true \
        -f image2 \
        -loglevel error \
        -hide_banner \
        -y "$vid_thumb_path"

    img_sixel_paint "$vid_thumb_path" "$vid_wh_scaled"
}

show_audio () {
    aud_path=$1
    aud_wh_max=$2
    aud_ffmpeg_output=$(ffmpeg -i "$1" 2>&1)
    aud_wh_native=$(video_resolution_ffmpeg_parse "$aud_ffmpeg_output")
    aud_wh_scaled=$(wh_scaled_get "$aud_wh_native" "$aud_wh_max")
    aud_thumb_path=$(cachedir_path_get "$cachedir" "audio" "w h" ".png")

    if [[ -z "$is_cmd_ffmpeg" ]]; then
        echo "'ffmpeg' command not found";
        exit 1
    fi

    ffmpeg \
        -ss "00:00:00" \
        -i "$aud_path" \
        -frames:v 1 \
        -s "${aud_wh_scaled/ /x}" \
        -pattern_type none \
        -update true \
        -f image2 \
        -loglevel error \
        -hide_banner \
        -y "$aud_thumb_path"

    img_sixel_paint "$aud_thumb_path" "$aud_wh_scaled"
}

show_pdf () {
    pdf_path=$1
    pdf_wh_max=$2
    pdf_thumb_path=""

    if [[ -z "$is_cmd_mutool" ]] && \
           [[ -z "$is_cmd_pdftoppm" ]]; then
        echo "'mutool' or 'pdftoppm' commands not found";
        exit 1
    elif [[ -n "$is_cmd_mutool" ]]; then
        pdf_thumb_path=$(cachedir_path_get "$cachedir" "pdf" "w h" ".png")
        mutool \
            draw -i -F png \
            -o "$pdf_thumb_path" "$pdf_path" 1 &> /dev/null
    elif [[ -n "$is_cmd_pdftoppm" ]]; then
        pdf_thumb_path=$(cachedir_path_get "$cachedir" "pdf" "w h" ".jpg")
        # extension needs to be removed from output path "pattern" used here
        pdftoppm \
            -singlefile \
            -f 1 -l 1 \
            -scale-to "$(wh_max_get "$2")" \
            -jpeg "$pdf_path" "${pdf_thumb_path%.*}"
    fi

    img_sixel_paint "$pdf_thumb_path" "$pdf_wh_max"
}

# shellcheck disable=SC2116
show_font () {
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

    if [[ -z "$is_cmd_convert" ]]; then
        echo "'convert' command not found (imagemagick)";
        exit 1
    fi

    convert \
        -size "${font_wh_max/ /x}" \
        -background "$font_bg_color" \
        -fill "$font_fg_color" \
        -font "$font_path" \
        -pointsize "$font_pointsize" \
        -gravity Center \
        "label:${font_preview_multiline}" \
        "$font_thumb_path"

    img_sixel_paint "$font_thumb_path" "$font_wh_max"
}

start () {
    path=$1
    start_wh=$(wh_start_get "$2" "$3" "$4" "$5")

    cachedir_calibrate "$cachedir"

    case $(file_type_get "$path") in
        "$mimeTypeSVG")
            img_sixel_paint "$path" "$start_wh";;
        "$mimeTypeIMAGE")
            img_sixel_paint_downscale "$path" "$start_wh";;
        "$mimeTypeVIDEO")
            show_video "$path" "$start_wh";;
        "$mimeTypeAUDIO")
            show_audio "$path" "$start_wh";;
        "$mimeTypeEPUB")
            show_epub "$path" "$start_wh";;
        "$mimeTypePDF")
            show_pdf "$path" "$start_wh";;
        "$mimeTypeFONT")
x            show_font "$path" "$start_wh";;
        *)
    esac
}
start "$@"
