#!/usr/bin/env bash

test_assert_succeeds() {
  assert true || fail 'assert should succeed'
}
