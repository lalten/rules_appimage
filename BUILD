load("@rules_python//python/pip_install:requirements.bzl", "compile_pip_requirements")
load("//:deps.bzl", "RUNTIME_SHAS")

# platform definitions for cross-compiling
[platform(
    name = "linux_" + arch,
    constraint_values = [
        "@platforms//os:linux",
        "@platforms//cpu:" + arch,
    ],
) for arch in RUNTIME_SHAS.keys()]

compile_pip_requirements(
    name = "requirements",
    extra_args = ["--resolver=backtracking"],
)
