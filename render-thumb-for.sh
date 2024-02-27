#!/usr/bin/env bash

scaled_wh () {
    bgn_w=$1
    bgn_h=$2
    max_w=$3
    max_h=$4

    # multiply and divide by 100 to convert decimal and int
    fin_h=$max_h
    fin_w=$((($bgn_w * (($fin_h * 100) / $bgn_h)) / 100))
    if [ "$fin_w" -ge "$max_w" ]; then
        fin_w=$max_w
        fin_h=$((($bgn_h * (($fin_w * 100) / $bgn_w)) / 100))
    fi

    echo "$fin_w $fin_h"
}

#scaled="$(scaled_wh 640 1280 200 201)"
#fin_wh=($(scaled_wh 640 1280 200 201))
fin_wh=($(scaled_wh 640 480 200 201))
fin_w=${fin_wh[0]}
fin_h=${fin_wh[1]}

echo "$fin_w"
echo "$fin_h"
