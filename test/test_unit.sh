#!/usr/bin/env bash
#
# bash_unit test/test_core.sh

test_wh_scaled_get_scales_down_larger_dimensions () {
    wh_bgn="1000 1000"
    wh_max="640 480"

    wh_scaled=$(wh_scaled_get "$wh_bgn" "$wh_max")

    assert_equals "$wh_scaled" "480 480" \
                  "should scale down larger dimensions"    
}

setup_suite() {
    source ../render-thumb-for.sh
}
