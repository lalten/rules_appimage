load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("toolchain.bzl", "appimage_toolchain")

package(default_visibility = ["//visibility:public"])

toolchain_type(name = "appimage_toolchain_type")

# Toolchain for linux, x86_64
appimage_toolchain(
    name = "appimage_linux_x86_64",
    appimage_runtime = "@appimage_runtime_x86_64//file",
)

# Toolchain for linux, arm64
appimage_toolchain(
    name = "appimage_linux_arm64",
    appimage_runtime = "@appimage_runtime_aarch64//file",
)

# default toolchain for backwards compatability
appimage_toolchain(
    name = "default_appimage",
    appimage_runtime = select({
        "@platforms//cpu:arm64": "@appimage_runtime_aarch64//file",
        "@platforms//cpu:armv7e-m": "@appimage_runtime_armhf//file",
        "@platforms//cpu:i386": "@appimage_runtime_i686//file",
        "@platforms//cpu:x86_64": "@appimage_runtime_x86_64//file",
    }),
)

# Register toolchain for linux, x86_64
toolchain(
    name = "appimage_linux_x86_64_toolchain",
    toolchain_type = ":appimage_toolchain_type",
    target_compatible_with = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
    toolchain = ":appimage_linux_x86_64",
)

# Register toolchain for linux, arm64
toolchain(
    name = "appimage_linux_arm64_toolchain",
    toolchain_type = ":appimage_toolchain_type",
    target_compatible_with = ["@platforms//os:linux", "@platforms//cpu:arm64"],
    toolchain = ":appimage_linux_arm64",
)

# Register toolchain for backwards compatability
toolchain(
    name = "default_appimage_toolchain",
    toolchain_type = ":appimage_toolchain_type",
    toolchain = ":default_appimage",
)

bzl_library(
    name = "appimage",
    srcs = ["appimage.bzl"],
)
