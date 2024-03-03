#!/usr/bin/env bash

is_cmd_exiftool=$(command -v exiftool)
is_cmd_identify=$(command -v identify)
is_cmd_ffmpeg=$(command -v ffmpeg)

img_dir="$HOME/.config/render-thumb-for"
if [ -n "${XDG_CONFIG_HOME}" ]; then
  img_dir="$XDG_CONFIG_HOME/render-thumb-for"
fi

ffmpeg_parse_video_duration_ss () {
    duration_regex="([[:digit:]]{2}[:][[:digit:]]{2}[:][[:digit:]]{2})"
    duration_match=""
    
    while IFS=$'\n' read -r line; do
        if [[ $line == *" Duration:"* && $line =~ $duration_regex ]]; then
            duration_match="${BASH_REMATCH[1]}"
            break
        fi
    done < <(printf '%s\n' "$1")

    IFS=" " read -r HOURS MINUTES SECONDS <<< "${duration_match//:/ }"
    
    echo $((10#$HOURS * 3600 + 10#$MINUTES * 60 + 10#$SECONDS))
}

# extracts resolution from ffmpeg output without grep
ffmpeg_parse_video_resolution () {
    resolution_regex="([[:digit:]]{2,8}[x][[:digit:]]{2,8})"
    resolution_match=""

    while IFS=$'\n' read -r line; do
        if [[ $line == *"Video:"* && $line =~ $resolution_regex ]]; then
            resolution_match="${BASH_REMATCH[1]}"
            break
        fi
    done < <(printf '%s\n' "$1")

    echo "${resolution_match/x/ }"
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

img_wh_get () {
    imgfilepath=$1

    if [[ -n "$is_cmd_exiftool" ]]; then # shellcheck disable=SC2016
        img_wh=$(exiftool -p '$ImageWidth $ImageHeight' "$imgfilepath")
    elif [[ -n "$is_cmd_identify" ]]; then
        img_wh=$(identify -format "%w %h" "$imgfilepath")
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
    img_path=$1
    img_wh_max=$2
    img_wh_native=$(img_wh_get "$img_path")
    img_wh_scaled=$(wh_scaled_get "$img_wh_native" "$img_wh_max")

    show_img_paint "$img_path" "$img_wh_scaled"
}

show_video () {
    vid_path=$1
    vid_wh_max=$2
    vid_ffmpeg_output=$(ffmpeg -i "$1" 2>&1)
    vid_duration_ss=$(ffmpeg_parse_video_duration_ss "$vid_ffmpeg_output")
    vid_wh_native=$(ffmpeg_parse_video_resolution "$vid_ffmpeg_output")
    vid_wh_scaled=$(wh_scaled_get "$vid_wh_native" "$vid_wh_max")
    vid_frame_ss=$(($vid_duration_ss / 5))

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
        -y screenshot.png

    show_img_paint "screenshot.png" "$vid_wh_scaled"
}

start () {
    img_path=$1
    max_wh="$2 $3"
    img_mimetype=$(file -b --mime-type "$img_path")


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
echo "$is_cmd_ffmpeg"
# ffmpeg -i "/home/bumble/ビデオ/#338 - The Commissioning of Truth [stream_19213].mp4" -vframes 1 -f rawvideo -y /dev/null 2>&1
