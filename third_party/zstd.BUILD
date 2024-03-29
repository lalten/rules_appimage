""" Builds zstd.

This is https://github.com/lalten/bazel-central-registry/blob/fix-zstd-include/modules/zstd/1.5.5.bcr.1/patches/add_build_file.patch#L132
https://github.com/bazelbuild/bazel-central-registry/pull/1394
"""

load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library", "cc_test")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "common_sources",
    srcs = glob([
        "lib/common/*.c",
        "lib/common/*.h",
    ]),
)

filegroup(
    name = "compress_sources",
    srcs = glob([
        "lib/compress/*.c",
        "lib/compress/*.h",
    ]),
)

filegroup(
    name = "decompress_sources",
    srcs = glob([
        "lib/decompress/*.c",
        "lib/decompress/*.h",
    ]) + select({
        "@platforms//os:windows": [],
        "//conditions:default": glob(["lib/decompress/*.S"]),
    }),
)

filegroup(
    name = "dictbuilder_sources",
    srcs = glob([
        "lib/dictBuilder/*.c",
        "lib/dictBuilder/*.h",
    ]),
)

cc_library(
    name = "zstd",
    srcs = [
        ":common_sources",
        ":compress_sources",
        ":decompress_sources",
        ":dictbuilder_sources",
    ],
    hdrs = [
        "lib/zdict.h",
        "lib/zstd.h",
        "lib/zstd_errors.h",
    ],
    includes = ["lib"],
    linkopts = ["-pthread"],
    linkstatic = True,
    local_defines = [
        "XXH_NAMESPACE=ZSTD_",
        "ZSTD_MULTITHREAD",
        "ZSTD_BUILD_SHARED=OFF",
        "ZSTD_BUILD_STATIC=ON",
    ] + select({
        "@platforms//os:windows": ["ZSTD_DISABLE_ASM"],
        "//conditions:default": [],
    }),
)

cc_library(
    name = "util",
    srcs = [
        "programs/platform.h",
        "programs/util.c",
    ],
    hdrs = [
        "lib/common/compiler.h",
        "lib/common/debug.h",
        "lib/common/mem.h",
        "lib/common/portability_macros.h",
        "lib/common/zstd_deps.h",
        "programs/util.h",
    ],
)

cc_library(
    name = "datagen",
    srcs = [
        "programs/datagen.c",
        "programs/platform.h",
    ],
    hdrs = ["programs/datagen.h"],
    deps = [":util"],
)

cc_binary(
    name = "datagen_cli",
    srcs = ["tests/datagencli.c"],
    includes = ["programs"],
    deps = [":datagen"],
)

cc_test(
    name = "fullbench",
    srcs = [
        "lib/decompress/zstd_decompress_internal.h",
        "programs/benchfn.c",
        "programs/benchfn.h",
        "programs/benchzstd.c",
        "programs/benchzstd.h",
        "programs/timefn.c",
        "programs/timefn.h",
        "tests/fullbench.c",
    ],
    copts = select({
        "@platforms//os:windows": [],
        "//conditions:default": ["-Wno-deprecated-declarations"],
    }),
    includes = [
        "lib/common",
        "programs",
    ],
    deps = [
        ":datagen",
        ":zstd",
    ],
)
