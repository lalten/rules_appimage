load("@rules_cc//cc:defs.bzl", "cc_library")

cc_library(
    name = "zstd",
    srcs = glob([
        "lib/common/*.c",
        "lib/common/*.h",
        "lib/compress/*.c",
        "lib/compress/*.h",
        "lib/decompress/*.c",
        "lib/decompress/*.h",
        "lib/decompress/*.S",
        "lib/dictBuilder/*.c",
        "lib/dictBuilder/*.h",
    ]),
    hdrs = [
        "lib/zdict.h",
        "lib/zstd.h",
        "lib/zstd_errors.h",
    ],
    defines = [
        "XXH_NAMESPACE=ZSTD_",
        "ZSTD_MULTITHREAD",
    ],
    strip_include_prefix = "lib",
    visibility = ["//visibility:public"],
)
