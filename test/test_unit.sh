#!/usr/bin/env bash
#
# bash_unit test/test_core.sh

test_wh_scaled_get_scales_down_larger_dimensions () {
    assert_equals "480x480" "$(wh_scaled_get "1000x1000" "640x480")" \
                  "should scale down larger dimensions"
}

test_wh_identify_get_returns_WxH () {
    assert_equals "512x512" "$(img_wh_identify_get ./Guix_logo.png)" \
                  "should return \"WxH\" dimensions"
}

test_wh_exiftool_get_returns_WxH () {
    assert_equals "512x512" "$(img_wh_exiftool_get ./Guix_logo.png)" \
                  "should return \"WxH\" dimensions"
}

test_wh_get_returns_WxH () {
    assert_equals "512x512" "$(img_wh_get ./Guix_logo.png)" \
                  "should return \"WxH\" dimensions"
}

setup_suite() {
    source ../render-thumb-for.sh
}
