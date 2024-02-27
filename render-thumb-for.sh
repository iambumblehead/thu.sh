#!/usr/bin/env bash

is_cmd_exiftool=0
if command -v exiftool &> /dev/null; then
    is_cmd_exiftool=1
fi

is_cmd_identify=0
if command -v identify &> /dev/null; then
    is_cmd_identify=1
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

go_test () {
    imgfile_path=$1
    imgfile_wh="$(imgfile_whget $imgfile_path)"
    max_wh="$2 $3"

    IFS=" " read -r -a fin_wh <<< "$(scaled_wh $imgfile_wh $max_wh)"
    fin_w=${fin_wh[0]}
    fin_h=${fin_wh[1]}

    echo "--width=$fin_w --height=$fin_h $imgfile_path"
    export MAGICK_OCL_DEVICE=true
    # exec convert or convert?
    convert "$imgfile_path" -geometry "${fin_w}x${fin_h}" sixel:-
    echo ""
}

go_test "/home/bumble/software/Guix_logo.png" 400 400
