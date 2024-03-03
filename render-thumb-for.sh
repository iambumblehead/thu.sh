#!/usr/bin/env bash

is_cmd_exiftool=$(command -v exiftool)
is_cmd_identify=$(command -v identify)
is_cmd_ffmpeg=$(command -v ffmpeg)

img_dir="$HOME/.config/render-thumb-for"
if [ -n "${XDG_CONFIG_HOME}" ]; then
  img_dir="$XDG_CONFIG_HOME/render-thumb-for"
fi

# Returns duration (in seconds) of a video $1 (uses ffmpeg).
video_duration_get () {
  OUTPUT=$(ffmpeg -i "$1" -vframes 1 -f rawvideo -y /dev/null 2>&1) ||
    { debug -e "get_video_duration: error running ffmpeg:\n$OUTPUT"; return 1; }

  # output includes duration formatted hours:minutes:seconds:deciseconds,
  # ```
  # Duration: 00:58:54.59, start: 0.000000, bitrate: 3833 kb/s
  # ```
  DURATION=$(echo "$OUTPUT" | grep -m1 "^[[:space:]]*Duration:" |
    cut -d":" -f2- | cut -d"," -f1 | sed "s/[:\.]/ /g") ||
    { debug -e "get_video_duration: error parsing duration:\n$OUTPUT"; return 1; }

  # remove deciseconds with ::-3
  IFS=" " read -r HOURS MINUTES SECONDS <<< "${DURATION::-3}"

  echo $((10#$HOURS * 3600 + 10#$MINUTES * 60 + 10#$SECONDS))
}

video_wh_get () {
    ffmpeg -i "$1" 2>&1 | grep Video: | grep -Po '\d{3,5}x\d{3,5}' | sed -r 's/x/ /'
}

wh_scaled_get () {
    IFS=" " read -r -a wh_bgn <<< $1
    IFS=" " read -r -a wh_max <<< $2
    w_bgn=${wh_bgn[0]}
    w_max=${wh_max[0]}
    h_bgn=${wh_bgn[1]}
    h_max=${wh_max[1]}

    # if image is smaller
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

# shellcheck disable=2086
imgfile_whget () {
    imgfilepath=$1

    if [[ -n "$is_cmd_exiftool" ]]; then # shellcheck disable=SC2016
        img_wh=$(exiftool -p '$ImageWidth $ImageHeight' "$imgfilepath")
    elif [[ -n "$is_cmd_identify" ]]; then
        img_wh=$(identify -format "%w %h" $imgfilepath)
    else
        echo "'exiftool' or 'identify' commands not found"
    fi

    echo "$img_wh"
}

show_img_paint () {
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

show_img () {
    imgfile_path=$1
    imgfile_wh_native=$(imgfile_whget "$imgfile_path")
    imgfile_wh_max=$2
    imgfile_wh_scaled=$(wh_scaled_get "$imgfile_wh_native" "$imgfile_wh_max")

    show_img_paint "$imgfile_path" "$imgfile_wh_scaled"
}

show_video () {
    file_video_path=$1
    file_video_duration_ss=$(video_duration_get "$1")
    file_video_frame_ss=$(($file_video_duration_ss / 5))
    file_video_wh_native=$(video_wh_get "$1")
    file_video_wh_max=$2
    file_video_wh_scaled=$(wh_scaled_get "$file_video_wh_native" "$file_video_wh_max")

    ffmpeg \
        -ss "$file_video_frame_ss" \
        -i "$file_video_path" \
        -frames:v 1 \
        -s "${file_video_wh_scaled/ /x}" \
        -pattern_type none \
        -update true \
        -f image2 \
        -loglevel error \
        -hide_banner \
        -y screenshot.png

    show_img_paint "screenshot.png" "$file_video_wh_scaled"
}

start () {
    img_path="$1"
    img_mimetype=$(file -b --mime-type "$img_path")
    max_wh="$2 $3"

    if [ ! -d "${img_dir}" ]; then
        mkdir -p "${img_dir}"
    fi

    # font, pdf, video, audio, epub
    if [[ $img_mimetype =~ ^"image/svg" ]]; then
        show_img_paint "$img_path" "$max_wh"
    elif [[ $img_mimetype =~ ^"image/" ]]; then
        show_img "$img_path" "$max_wh"
    elif [[ $img_mimetype =~ ^"video/" ]]; then
        show_video "$img_path" "$max_wh"
    fi
}

start "/home/bumble/software/Guix_logo.png" 800 400
start "/home/bumble/software/Guix_logo.svg" 800 800
start "/home/bumble/ビデオ/#338 - The Commissioning of Truth [stream_19213].mp4" 800 400
# ffmpeg -i "/home/bumble/ビデオ/#338 - The Commissioning of Truth [stream_19213].mp4" -vframes 1 -f rawvideo -y /dev/null 2>&1
