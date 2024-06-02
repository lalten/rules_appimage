load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "runtime",
    srcs = ["src/runtime/runtime.c"],
    copts = [
        "-Wno-int-conversion",
        "-Wno-unused-variable",
        "-Wno-unused-value",
        "-Wno-unused-result",
        "-Wno-pointer-sign",
        "-Wno-stringop-truncation",
        "-Wno-format-overflow",
        "-Os",
    ],
    features = ["fully_static_link"],
    linkopts = [
        "-ffunction-sections",
        "-fdata-sections",
    ],
    local_defines = [
        "FUSE_USE_VERSION=316",
        'GIT_COMMIT=\\"redacted\\"',
    ],
    visibility = ["//visibility:public"],
    deps = [
        "@libfuse",
        "@squashfuse",
    ],
)
