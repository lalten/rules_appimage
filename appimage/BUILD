load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@rules_appimage//appimage:toolchain.bzl", "appimage_toolchain")
load("//:deps.bzl", "CPU_ARCHS")

package(default_visibility = ["//visibility:public"])

exports_files(
    glob(["*.bzl"]),
    visibility = ["//docs:__pkg__"],
)

bzl_library(
    name = "defs",
    srcs = ["defs.bzl"],
    deps = [
        ":appimage",
        ":toolchain",
    ],
)

bzl_library(
    name = "appimage",
    srcs = ["appimage.bzl"],
    deps = [
        "//appimage/private:mkapprun",
        "//appimage/private:runfiles",
    ],
)

bzl_library(
    name = "toolchain",
    srcs = ["toolchain.bzl"],
)

toolchain_type(name = "appimage_toolchain_type")

[appimage_toolchain(
    name = "appimage_linux_" + cpu,
    appimage_runtime = "@appimage_runtime_" + arch + "//file",
) for cpu, arch in CPU_ARCHS.items()]

# Deprecated: this toolchain is not constrained to any platform and hardcodes the mapping from target
# cpu to runtime at analysis time, so it cannot support platforms outside of CPU_ARCHS.
# Prefer the //appimage:appimage_linux_<cpu>_toolchain toolchains, which are registered by
# register_toolchains("@rules_appimage//appimage:all") and resolved for the actual target platform.
appimage_toolchain(
    name = "default_appimage",
    appimage_runtime = select(
        {"@platforms//cpu:" + cpu: "@appimage_runtime_" + arch + "//file" for cpu, arch in CPU_ARCHS.items()},
        no_match_error = "rules_appimage does not have an AppImage runtime for this target cpu. Supported cpus are: " +
                         ", ".join(sorted(CPU_ARCHS.keys())),
    ),
)

[toolchain(
    name = "appimage_linux_" + cpu + "_toolchain",
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:" + cpu,
    ],
    toolchain = ":appimage_linux_" + cpu,
    toolchain_type = ":appimage_toolchain_type",
) for cpu in CPU_ARCHS.keys()]

# Register toolchain for backwards compatibility
toolchain(
    name = "default_appimage_toolchain",
    toolchain = ":default_appimage",
    toolchain_type = ":appimage_toolchain_type",
)
