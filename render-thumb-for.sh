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
    imgfile_path=$1
    # imgfile_wh=$(imgfile_whget "$imgfile_path")
    max_wh="$2 $3"

    # extract single frame
    #ffmpeg -ss 00:00:04 -i input.mp4 -frames:v 1 screenshot.png

    # resize frame
    # ffmpeg -i input.mp4 -s 640x480 %04d.jpg

    # scaling frame
    # ffmpeg -i input.mp4 -vf scale=640:-1 %04d.png

    ffmpeg \
        -ss 00:00:04 \
        -i "$imgfile_path" \
        -frames:v 1 \
        -s 640x480 \
        -pattern_type none \
        -update true \
        -f image2 \
        -loglevel error \
        screenshot_%06d.png
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
start "/home/bumble/ビデオ/#338 - video.mp4" 800 400
