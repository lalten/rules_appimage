load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")

_COPTS = [
    "-std=gnu17",  # GNU extensions are at play
    "-pthread",
]

_LINKOPTS = [
    "-lpthread",
]

_COMPRESSORS = [
    "gzip",
    "lz4",
    "xz",
    "zstd",
    # "lzo",  # Not available on BCR yet
]

_DEFINES = [
    'COMP_DEFAULT=\\"gzip\\"',
    'COMPRESSORS=\\"' + "\\n".join(_COMPRESSORS) + '\\"',
    'DATE=\\"redacted\\"',
    'DECOMPRESSORS=\\"' + "\\n".join(_COMPRESSORS) + '\\"',
    'VERSION=\\"redacted\\"',
    'YEAR=\\"redacted\\"',
    "_FILE_OFFSET_BITS=64",
    "_GNU_SOURCE",
    "_LARGEFILE_SOURCE",
    "SMALL_READER_THREADS=4",
    "BLOCK_READER_THREADS=4",
    "MAX_READER_THREADS=1024",
    "XATTR_DEFAULT",
    "XATTR_SUPPORT",
    "XATTR_OS_SUPPORT",
] + [compressor.upper() + "_SUPPORT" for compressor in _COMPRESSORS]

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
            "lzo_wrapper.*",
            "lzma_wrapper.c",  # using lzma_xz_wrapper instead
            "xz_wrapper_extended.c",
        ],
    ),
    hdrs = ["squashfs_fs.h"],
    copts = _COPTS,
    linkopts = _LINKOPTS,
    local_defines = _DEFINES,
    deps = [
        "@lz4",
        "@lz4//:lz4_hc",
        "@xz",
        "@xz//:lzma",
        "@zlib",
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
    linkopts = _LINKOPTS,
    local_defines = _DEFINES,
    visibility = ["//visibility:public"],
    deps = [":common"],
)

cc_binary(
    name = "unsquashfs",
    srcs = glob(["unsquash*"]),
    copts = _COPTS,
    linkopts = _LINKOPTS,
    local_defines = _DEFINES,
    visibility = ["//visibility:public"],
    deps = [":common"],
)
