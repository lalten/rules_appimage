load("@rules_python//python/pip_install:requirements.bzl", "compile_pip_requirements")

# platform definition for testing
platform(
    name = "linux_x86_64",
    constraint_values = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
)

compile_pip_requirements(
    name = "requirements",
    extra_args = ["--resolver=backtracking"],
)
