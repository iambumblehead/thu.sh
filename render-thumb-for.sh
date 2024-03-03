#!/usr/bin/env bash

is_cmd_exiftool=$(command -v exiftool)
is_cmd_identify=$(command -v identify)
is_cmd_ffmpeg=$(command -v ffmpeg)

timecode_re="([[:digit:]]{2}[:][[:digit:]]{2}[:][[:digit:]]{2})"
resolution_re="([[:digit:]]{2,8}[x][[:digit:]]{2,8})"

mime_video_re="video/"
mime_svg_re="image/svg"
mime_img_re="image/"
mime_audio_re="audio/"

img_dir="$HOME/.config/render-thumb-for"
if [ -n "${XDG_CONFIG_HOME}" ]; then
  img_dir="$XDG_CONFIG_HOME/render-thumb-for"
fi

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
    elif [[ -n "$is_cmd_exiftool" ]]; then # shellcheck disable=SC2016
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

show_video () {
    vid_path=$1
    vid_wh_max=$2
    vid_ffmpeg_output=$(ffmpeg -i "$1" 2>&1)
    vid_duration_ss=$(video_duration_ffmpeg_parse_ss "$vid_ffmpeg_output")
    vid_wh_native=$(video_resolution_ffmpeg_parse "$vid_ffmpeg_output")
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

    img_sixel_paint "screenshot.png" "$vid_wh_scaled"
}

show_audio () {
    aud_path=$1
    aud_wh_max=$2
    aud_ffmpeg_output=$(ffmpeg -i "$1" 2>&1)
    aud_wh_native=$(video_resolution_ffmpeg_parse "$aud_ffmpeg_output")
    aud_wh_scaled=$(wh_scaled_get "$aud_wh_native" "$aud_wh_max")

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
        -y audioshot.png

    img_sixel_paint "audioshot.png" "$aud_wh_scaled"
}

start () {
    img_path=$1
    max_wh="$2 $3"
    img_mimetype=$(file -b --mime-type "$img_path")

    if [ ! -d "${img_dir}" ]; then
        mkdir -p "${img_dir}"
    fi

    # font, pdf, video, audio, epub
    if [[ $img_mimetype =~ ^$mime_svg_re ]]; then
        img_sixel_paint "$img_path" "$max_wh"
    elif [[ $img_mimetype =~ ^$mime_img_re ]]; then
        img_sixel_paint_downscale "$img_path" "$max_wh"
    elif [[ $img_mimetype =~ ^$mime_video_re ]]; then
        show_video "$img_path" "$max_wh"
    elif [[ $img_mimetype =~ ^$mime_audio_re ]]; then
        show_audio "$img_path" "$max_wh"
    fi
}

#start "/home/bumble/software/Guix_logo.png" 800 400
#start "/home/bumble/software/Guix_logo.svg" 800 800
#start "/home/bumble/ビデオ/#338 - The Commissioning of Truth [stream_19213].mp4" 800 400
start "/home/bumble/音楽/language/日本語 - Assimil/Assimil 10 テレビ.flac" 800 400
echo "$is_cmd_ffmpeg"
# ffmpeg -i "/home/bumble/ビデオ/#338 - The Commissioning of Truth [stream_19213].mp4" -vframes 1 -f rawvideo -y /dev/null 2>&1
