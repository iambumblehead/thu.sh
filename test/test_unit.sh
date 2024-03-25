#!/usr/bin/env bash
# shellcheck disable=2317
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

test_image_display_format_get () {
    sessstr_KITTY="displayformat=KITTY"
    sessstr_SIXEL="displayformat=SIXEL"
    sessstr_NONE="displayformat=NONE"

    assert_equals "KITTY" "$(image_display_format_get $sessstr_KITTY)" \
                  "should return displayformat from sess string, KITTY"
    assert_equals "SIXEL" "$(image_display_format_get $sessstr_SIXEL)" \
                  "should return displayformat from sess string, SIXEL"
    assert_equals "NONE" "$(image_display_format_get $sessstr_NONE)" \
                  "should return displayformat from sess string, NONE"
}

test_zip_read_file () {
    filepath_not_exist="./path/not/exist.xml"
    zippath_not_exist="./path/not/exist.zip"

    assert_fail "$(zip_read_file "$filepath_not_exist" "$zippath_not_exist")" \
                "should fail if zippath does not exist"
}

test_zip_read_file () {
    filepath_container="META-INF/container.xml"
    zippath_testepub="./asset/test.epub"

    # <container
    #   version="1.0"
    #   xmlns="urn:oasis:names:tc:opendocument:xmlns:container" >
    #   <rootfiles>
    #     <rootfile
    #       full-path="OEBPS/content.opf"
    #       media-type="application/oebps-package+xml" />
    #   </rootfiles>
    # </container>
    container=$(zip_read_file "$zippath_testepub" "$filepath_container")
    containerurn="urn:oasis:names:tc:opendocument:xmlns:container"

    assert_matches "$containerurn" "$container"
}

test_zip_move_file_out () {
    filepath_container="META-INF/container.xml"
    zippath_testepub="./asset/test.epub"
    filepath_containeroutdir="./asset-out/"
    filepath_containerout="${filepath_containeroutdir}container.xml"

    # <container
    #   version="1.0"
    #   xmlns="urn:oasis:names:tc:opendocument:xmlns:container" >
    #   <rootfiles>
    #     <rootfile
    #       full-path="OEBPS/content.opf"
    #       media-type="application/oebps-package+xml" />
    #   </rootfiles>
    # </container>
    $(zip_move_file_out \
          "$zippath_testepub" \
          "$filepath_container" \
          "$filepath_containeroutdir")

    assert_matches "$containerurl" $(cat "$filepath_containerout")
}

setup_suite() {
    source ../thu.sh
}
