"""Tests using rules_testing."""

load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_testing//lib:analysis_test.bzl", "analysis_test", "test_suite")
load("@rules_testing//lib:truth.bzl", "matching")
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

def _argv0_binaries(name):
    util.helper_target(
        sh_binary,
        name = "%s_binary" % name,
        srcs = ["program.sh"],
    )
    util.helper_target(
        sh_binary,
        name = "%s_alt" % name,
        srcs = ["alt_program.sh"],
    )

    util.helper_target(
        appimage,
        name = "%s.appimage" % name,
        argv0_binaries = {"alt": ":%s_alt" % name},
        binary = ":%s_binary" % name,
    )

    analysis_test(
        name = name,
        impl = _argv0_binaries_impl,
        target = ":%s.appimage" % name,
    )

def _argv0_binaries_impl(env, target):
    inputs = env.expect.that_target(target).action_named("AppImage").inputs()
    inputs.contains("tests/analysis_tests/argv0_binaries_alt")
    inputs.contains("tests/analysis_tests/alt_program.sh")

def _argv0_binaries_invalid_name(name):
    util.helper_target(
        sh_binary,
        name = "%s_binary" % name,
        srcs = ["program.sh"],
    )

    util.helper_target(
        appimage,
        name = "%s.appimage" % name,
        argv0_binaries = {"sub/dir": ":%s_binary" % name},
        binary = ":%s_binary" % name,
    )

    analysis_test(
        name = name,
        impl = _argv0_binaries_invalid_name_impl,
        target = ":%s.appimage" % name,
        expect_failure = True,
    )

def _argv0_binaries_invalid_name_impl(env, target):
    env.expect.that_target(target).failures().contains_predicate(
        matching.str_matches('*"sub/dir" is not a valid file name*'),
    )

def _argv0_binaries_own_name(name):
    util.helper_target(
        sh_binary,
        name = "%s_binary" % name,
        srcs = ["program.sh"],
    )

    util.helper_target(
        appimage,
        name = "%s.appimage" % name,
        argv0_binaries = {"%s.appimage" % name: ":%s_binary" % name},
        binary = ":%s_binary" % name,
    )

    analysis_test(
        name = name,
        impl = _argv0_binaries_own_name_impl,
        target = ":%s.appimage" % name,
        expect_failure = True,
    )

def _argv0_binaries_own_name_impl(env, target):
    env.expect.that_target(target).failures().contains_predicate(
        matching.str_matches("*is the name of the appimage itself*"),
    )

def _argv0_binaries_not_executable(name):
    util.helper_target(
        sh_binary,
        name = "%s_binary" % name,
        srcs = ["program.sh"],
    )
    util.helper_target(
        native.filegroup,
        name = "%s_data" % name,
        srcs = [
            "alt_program.sh",
            "program.sh",
        ],
    )

    util.helper_target(
        appimage,
        name = "%s.appimage" % name,
        argv0_binaries = {"data": ":%s_data" % name},
        binary = ":%s_binary" % name,
    )

    analysis_test(
        name = name,
        impl = _argv0_binaries_not_executable_impl,
        target = ":%s.appimage" % name,
        expect_failure = True,
    )

def _argv0_binaries_not_executable_impl(env, target):
    env.expect.that_target(target).failures().contains_predicate(
        matching.str_matches('*argv0_binaries["data"]:*argv0_binaries_not_executable_data is not executable*'),
    )

def appimage_test_suite(name):
    test_suite(
        name = name,
        tests = [
            _basic,
            _argv0_binaries,
            _argv0_binaries_invalid_name,
            _argv0_binaries_own_name,
            _argv0_binaries_not_executable,
        ],
    )
