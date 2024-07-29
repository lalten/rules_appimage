load("//:deps.bzl", "ARCHS")
load("toolchain.bzl", "appimage_toolchain")

package(default_visibility = ["//visibility:public"])

toolchain_type(name = "appimage_toolchain_type")

[appimage_toolchain(
    name = "appimage_linux_" + arch,
    appimage_runtime = "@appimage_runtime_" + arch + "//file",
) for arch in ARCHS.keys()]

# default toolchain for backwards compatibility
appimage_toolchain(
    name = "default_appimage",
    appimage_runtime = select({
        "@platforms//cpu:arm64": "@appimage_runtime_aarch64//file",
        "@platforms//cpu:armv7e-m": "@appimage_runtime_armhf//file",
        "@platforms//cpu:i386": "@appimage_runtime_i686//file",
        "@platforms//cpu:x86_64": "@appimage_runtime_x86_64//file",
    }),
)

[toolchain(
    name = "appimage_linux_" + arch + "_toolchain",
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:" + arch,
    ],
    toolchain = ":appimage_linux_" + arch,
    toolchain_type = ":appimage_toolchain_type",
) for arch in ARCHS.keys()]

# Register toolchain for backwards compatibility
toolchain(
    name = "default_appimage_toolchain",
    toolchain = ":default_appimage",
    toolchain_type = ":appimage_toolchain_type",
)
