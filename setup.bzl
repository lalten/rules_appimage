"""Set up for rules_appimage."""

load("@rules_python//python:pip.bzl", "pip_install")

def rules_appimage_setup():
    # Create a central external repo, @py_deps, that contains Bazel targets for all the
    # third-party packages specified in the requirements.txt file.
    pip_install(
        name = "py_deps",
        requirements = "@rules_appimage//:requirements.txt",
    )
