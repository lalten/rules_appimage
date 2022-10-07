workspace(name = "rules_appimage")

load("//:deps.bzl", "rules_appimage_deps")

rules_appimage_deps()

load("@rules_python//python:pip.bzl", "pip_install")

pip_install(
    name = "py_deps",
    requirements = "@rules_appimage//:requirements.txt",
)
