workspace(name = "rules_appimage")

load("//:deps.bzl", "rules_appimage_deps")

# TODO(lgarbarini): delete me once we have a better source for mksquashfs for darwin
new_local_repository(
    name = "mksquashfs_aarch64_darwin",
    path = "/opt/homebrew/bin",
    build_file_content = """
exports_files(["mksquashfs"])
""",
)

rules_appimage_deps()

register_toolchains("//appimage:all")

# Below this is the Python setup for testing the rules_appimage Python rules.
# This is _not_ required for _using_ the rules_appimage rules.

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

maybe(
    http_archive,
    name = "rules_python",
    sha256 = "5868e73107a8e85d8f323806e60cad7283f34b32163ea6ff1020cf27abef6036",
    strip_prefix = "rules_python-0.25.0",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.25.0/rules_python-0.25.0.tar.gz",
)

load("@rules_python//python:repositories.bzl", "py_repositories", "python_register_toolchains")

py_repositories()

python_register_toolchains(
    name = "rules_appimage_python",
    python_version = "3.11",
)

load("@rules_appimage_python//:defs.bzl", "interpreter")
load("@rules_python//python:pip.bzl", "pip_parse")

pip_parse(
    name = "rules_appimage_py_deps",
    python_interpreter_target = interpreter,
    requirements_lock = "//:requirements.txt",
)

load("@rules_appimage_py_deps//:requirements.bzl", "install_deps")

install_deps()
