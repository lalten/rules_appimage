load("@rules_python//python/pip_install:requirements.bzl", "compile_pip_requirements")
load("//:deps.bzl", "CPU_ARCHS")

# platform definitions for cross-compiling
[platform(
    name = "linux_" + cpu,
    constraint_values = [
        "@platforms//os:linux",
        "@platforms//cpu:" + cpu,
    ],
) for cpu in CPU_ARCHS.keys()]

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
