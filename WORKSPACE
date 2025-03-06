workspace(name = "rules_appimage")

load("//:deps.bzl", "rules_appimage_deps", "rules_appimage_development_deps")

rules_appimage_deps()

rules_appimage_development_deps()

load("@rules_shell//shell:repositories.bzl", "rules_shell_dependencies", "rules_shell_toolchains")

rules_shell_dependencies()

rules_shell_toolchains()

load("@container_structure_test//:repositories.bzl", "container_structure_test_register_toolchain")
load("@rules_oci//oci:dependencies.bzl", "rules_oci_dependencies")

rules_oci_dependencies()

load("@rules_oci//oci:repositories.bzl", "oci_register_toolchains")

oci_register_toolchains(name = "oci")

container_structure_test_register_toolchain(name = "cst")

load("@rules_oci//oci:pull.bzl", "oci_pull")

# Keep in sync with MODULE.bazel
oci_pull(
    name = "python3-slim",
    digest = "sha256:69ce3aed05675d284bee807e7c45e560e98db21fb1e4c670252b4ee0f2496b6d",  # "3.12-slim" as of 2025-01-25
    image = "docker.io/library/python",
    platforms = ["linux/amd64"],
)
oci_pull(
    name = "debian-12",
    digest = "sha256:35286826a88dc879b4f438b645ba574a55a14187b483d09213a024dc0c0a64ed",  # "12" as of 2025-03-03
    image = "docker.io/library/debian",
    platforms = ["linux/amd64"],
)

load("@rules_python//python:repositories.bzl", "py_repositories", "python_register_toolchains")

py_repositories()

python_register_toolchains(
    name = "rules_appimage_python",
    python_version = "3.12",
)

load("@rules_python//python:pip.bzl", "pip_parse")

pip_parse(
    name = "rules_appimage_py_deps",
    python_interpreter_target = "@python_3_12_host//:python",
    requirements_lock = "@rules_appimage//:requirements.txt",
)

load("@rules_appimage_py_deps//:requirements.bzl", "install_deps")

install_deps()

register_toolchains("@rules_appimage//appimage:all")
