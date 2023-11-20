load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")

cc_library(
    name = "common",
    srcs = glob(
        [
            "*.c",
            "*.h",
        ],
        exclude = [
            "mksquashfs.c",
            "unsquash*",
            "lz4*",
            "lzma*",
            "lzo*",
            "xz*",
        ],
    ),
    hdrs = ["squashfs_fs.h"],
    copts = [
        "-Wno-gnu-pointer-arith",
        "-Wno-gnu-statement-expression-from-macro-expansion",
        "-Wno-gnu-zero-variadic-macro-arguments",
        "-Wno-missing-field-initializers",
        "-Wno-pedantic",
        "-Wno-sign-compare",
        "-Wno-unused-parameter",
        "-Wno-variadic-macros",
        "-Wno-zero-length-array",
    ],
    defines = [
        'COMP_DEFAULT=\\"gzip\\"',
        'DATE=\\"redacted\\"',
        'VERSION=\\"redacted\\"',
        'YEAR=\\"redacted\\"',
        "_FILE_OFFSET_BITS=64",
        "_GNU_SOURCE",
        "_LARGEFILE_SOURCE",
        "GZIP_SUPPORT",
        "REPRODUCIBLE_DEFAULT",
        "XATTR_DEFAULT",
        "XATTR_SUPPORT",
        "ZSTD_SUPPORT",
    ],
    deps = [
        "@bazel_tools//third_party/zlib",
        "@zstd",
    ],
)

cc_binary(
    name = "mksquashfs",
    srcs = [
        "mksquashfs.c",
        "mksquashfs.h",
        "mksquashfs_error.h",
    ],
    visibility = ["//visibility:public"],
    deps = [":common"],
)

cc_binary(
    name = "unsquashfs",
    srcs = glob(["unsquash*"]),
    visibility = ["//visibility:public"],
    deps = [":common"],
)
