load("@rules_python//python/pip_install:requirements.bzl", "compile_pip_requirements")
load("//:deps.bzl", "ARCHS")

# platform definitions for cross-compiling
[platform(
    name = "linux_" + arch,
    constraint_values = [
        "@platforms//os:linux",
        "@platforms//cpu:" + arch,
    ],
    visibility = ["//visibility:public"],
) for arch in ARCHS.keys()]

compile_pip_requirements(
    name = "requirements",
    src = "requirements.in",
    extra_args = [
        "--resolver=backtracking",
        "--strip-extras",
        "--upgrade",
    ],
    tags = ["manual"],
)
