load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")

_COPTS = [
    "-O2",  # squashfs-tools/Makefile#L219
    "-std=gnu17",  # GNU extensions are at play
    "--no-warnings",  # We don't care about third-party warnings
]

_DEFINES = [
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
]

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
    copts = _COPTS,
    defines = _DEFINES,
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
    copts = _COPTS,
    defines = _DEFINES,
    visibility = ["//visibility:public"],
    deps = [":common"],
)

cc_binary(
    name = "unsquashfs",
    srcs = glob(["unsquash*"]),
    copts = _COPTS,
    defines = _DEFINES,
    visibility = ["//visibility:public"],
    deps = [":common"],
)
