"""Tests using rules_testing."""

load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_testing//lib:analysis_test.bzl", "analysis_test", "test_suite")
load("@rules_testing//lib:util.bzl", "util")
load("//appimage:appimage.bzl", "appimage")

def _basic(name):
    util.helper_target(
        sh_binary,
        name = "%s_binary" % name,
        srcs = ["program.sh"],
    )

    util.helper_target(
        appimage,
        name = "%s.appimage" % name,
        binary = ":%s_binary" % name,
    )

    analysis_test(
        name = name,
        impl = _basic_impl,
        target = ":%s.appimage" % name,
    )

def _basic_impl(env, target):
    env.expect.that_target(target).default_outputs().contains_exactly([
        "tests/analysis_tests/basic.appimage",
    ])

def appimage_test_suite(name):
    test_suite(
        name = name,
        tests = [_basic],
    )
