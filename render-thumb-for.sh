#!/usr/bin/env bash

is_cmd_exiftool=0
if command -v exiftool &> /dev/null; then
    is_cmd_exiftool=1
fi

is_cmd_identify=0
if command -v identify &> /dev/null; then
    is_cmd_identify=1
fi

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
    echo "$(ffmpeg -i "$1" 2>&1 | grep Video: | grep -Po '\d{3,5}x\d{3,5}' | sed -r 's/x/ /')"
}

scaled_wh () {
    bgn_w=$1
    bgn_h=$2
    max_w=$3
    max_h=$4

    if [ "$max_w" -gt "$bgn_w" ] && [ "$max_h" -gt "$bgn_h" ]; then
        echo "$bgn_w $bgn_h"
        return 1
    fi

    # multiply and divide by 100 to convert decimal and int
    fin_h=$max_h
    fin_w=$((($bgn_w * (($fin_h * 100) / $bgn_h)) / 100))
    if [ "$fin_w" -ge "$max_w" ]; then
        fin_w=$max_w
        fin_h=$((($bgn_h * (($fin_w * 100) / $bgn_w)) / 100))
    fi

    echo "$fin_w $fin_h"
}

# shellcheck disable=2086
imgfile_whget () {
    imgfilepath=$1

    if [ "$is_cmd_exiftool" -ge 1 ]; then # shellcheck disable=SC2016
        img_wh=$(exiftool -p '$ImageWidth $ImageHeight' "$imgfilepath")
    elif [ "$is_cmd_identify" -ge 1 ]; then
        img_wh=$(identify -format "%w %h" $imgfilepath)
    else
        echo "'exiftool' or 'identify' commands not found"
    fi

    echo "$img_wh"
}

show_img_paint () {
    export MAGICK_OCL_DEVICE=true
    # exec convert or convert?

    convert \
        -channel rgba \
        -background "rgba(0,0,0,0)" \
        -geometry "${2}x${3}" \
        "$1" sixel:-

    echo ""
}

show_img () {
    imgfile_path=$1
    imgfile_wh=$(imgfile_whget "$imgfile_path")
    max_wh="$2 $3"

    # shellcheck disable=2086,2046
    IFS=" " read -r -a fin_wh <<< $(scaled_wh $imgfile_wh $max_wh)
    fin_w=${fin_wh[0]}
    fin_h=${fin_wh[1]}

    show_img_paint "$imgfile_path" "${fin_w}" "${fin_h}"
}

show_video () {
    file_video_path=$1
    # imgfile_wh=$(imgfile_whget "$imgfile_path")
    file_video_duration_ss=$(video_duration_get "$1")
    echo "duration $file_video_duration_ss"
    file_video_frame_ss=$(($file_video_duration_ss / 5))
    file_video_wh=$(video_wh_get "$1")
    #file_video_frame_wh="no"
    max_wh="$2 $3"


    IFS=" " read -r -a fin_wh <<< "$(scaled_wh $file_video_wh $max_wh)"
    fin_w=${fin_wh[0]}
    fin_h=${fin_wh[1]}
    file_video_frame_wh="${fin_w}x${fin_h}"

    echo "video $file_video_duration_ss $file_video_frame_ss $file_video_wh $file_video_frame_wh"
    # extract single frame
    #ffmpeg -ss 00:00:04 -i input.mp4 -frames:v 1 screenshot.png

    # resize frame
    # ffmpeg -i input.mp4 -s 640x480 %04d.jpg

    # scaling frame
    # ffmpeg -i input.mp4 -vf scale=640:-1 %04d.png
    #
    ffmpeg \
        -ss "$file_video_frame_ss" \
        -i "$file_video_path" \
        -frames:v 1 \
        -s "$file_video_frame_wh" \
        -pattern_type none \
        -update true \
        -f image2 \
        -loglevel error \
        -hide_banner \
        -y screenshot.png

    show_img_paint "screenshot.png" "${fin_w}" "${fin_h}"
    # ffmpeg -i input.mp4 -s 640x480 %04d.jpg
}

start () {
    img_path="$1"
    img_mimetype=$(file -b --mime-type "$img_path")
    max_w="$2"
    max_h="$3"

    echo $img_mimetype
    
    if [ ! -d "${img_dir}" ]; then
        mkdir -p "${img_dir}"
    fi

    # font, pdf, video, audio, epub
    if [[ $img_mimetype =~ ^"image/svg" ]]; then
        show_img_paint "$img_path" "${max_w}" "${max_h}"
    elif [[ $img_mimetype =~ ^"image/" ]]; then
        show_img "$img_path" "$max_w" "$max_h"
    elif [[ $img_mimetype =~ ^"video/" ]]; then
        show_video "$img_path" "$max_w" "$max_h"
    fi
}

#start "/home/bumble/software/Guix_logo.svg" 800 400
start "/home/bumble/ビデオ/#338 - The Commissioning of Truth [stream_19213].mp4" 800 400

# ffmpeg -i "/home/bumble/ビデオ/#338 - The Commissioning of Truth [stream_19213].mp4" -vframes 1 -f rawvideo -y /dev/null 2>&1
