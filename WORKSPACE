workspace(name = "rules_appimage")

load("//:deps.bzl", "rules_appimage_deps", "rules_appimage_development_deps")

rules_appimage_deps()

rules_appimage_development_deps()

load("@rules_python//python:repositories.bzl", "py_repositories", "python_register_toolchains")

py_repositories()

python_register_toolchains(
    name = "rules_appimage_python",
    python_version = "3.12",
)

load("@rules_appimage_python//:defs.bzl", rules_appimage_py_interpreter = "interpreter")
load("@rules_python//python:pip.bzl", "pip_parse")

pip_parse(
    name = "rules_appimage_py_deps",
    python_interpreter_target = rules_appimage_py_interpreter,
    requirements_lock = "@rules_appimage//:requirements.txt",
)

load("@rules_appimage_py_deps//:requirements.bzl", "install_deps")

install_deps()

register_toolchains("@rules_appimage//appimage:all")
