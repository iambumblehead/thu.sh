#!/usr/bin/env bash
#
# bash_unit test/test_core.sh

test_wh_scaled_get_scales_down_larger_dimensions () {
    assert_equals "$(wh_scaled_get "1000x1000" "640x480")" "480x480" \
                  "should scale down larger dimensions"    
}

setup_suite() {
    source ../render-thumb-for.sh
}
