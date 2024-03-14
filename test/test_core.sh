#!/usr/bin/env bash
#
# bash_unit test/test_core.sh

regex() {
    # Usage: regex "string" "regex"
    [[ $1 =~ $2 ]] && printf '%s\n' "${BASH_REMATCH[1]}"
}

test_assert_succeed () {
    assert true
}

test_asset_latest_version_number_used () {
    version_changelog_re="\* ([[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*)"
    version_script_re="\version=([[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*)"
    version_changelog=$(regex "$(cat ../CHANGELOG.md)" "$version_changelog_re")
    version_script=$(regex "$(cat ../render-thumb-for.sh)" "$version_script_re")

    assert_equals "$version_changelog" "$version_script" \
                  "should use same version, script and changelog"
}
