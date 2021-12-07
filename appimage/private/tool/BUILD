load("@rules_python//python:defs.bzl", "py_binary")
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")
load("@py_deps//:requirements.bzl", "requirement")

native_binary(
    name = "appimagetool",
    src = select({
        "@platforms//cpu:x86_64": "@appimagetool_release_x86_64//file",
        "@platforms//cpu:arm64": "@appimagetool_release_aarch64//file",
        "@platforms//cpu:armv7e-m": "@appimagetool_release_armhf//file",
        "@platforms//cpu:i386": "@appimagetool_release_i686//file",
    }),
    out = "appimagetool.bin",
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
)

py_binary(
    name = "tool",
    srcs = ["tool.py"],
    data = [":appimagetool"],
    python_version = "PY3",
    visibility = ["//visibility:public"],
    deps = [
        "@rules_python//python/runfiles",
        requirement("click"),
        requirement("dataclasses_json"),
    ],
)
