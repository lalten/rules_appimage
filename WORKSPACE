workspace(name = "rules_appimage")

load("//:deps.bzl", "rules_appimage_deps", "rules_appimage_development_deps")

rules_appimage_deps()

rules_appimage_development_deps()

load("@bazel_features//:deps.bzl", "bazel_features_deps")

bazel_features_deps()

load("@rules_cc//cc:extensions.bzl", "compatibility_proxy_repo")

compatibility_proxy_repo()

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
    digest = "sha256:fb83750094b46fd6b8adaa80f66e2302ecbe45d513f6cece637a841e1025b4ca",  # "3.14-slim" as of 2026-04-03
    image = "docker.io/library/python",
    platforms = [
        "linux/amd64",
        "linux/arm64/v8",
    ],
)

oci_pull(
    name = "distroless-cc",
    digest = "sha256:56aaf20ab2523a346a67c8e8f8e8dabe447447d0788b82284d14ad79cd5f93cc",  # "debug-nonroot" as of 2026-04-03
    image = "gcr.io/distroless/cc-debian13",
    platforms = [
        "linux/amd64",
        "linux/arm64/v8",
    ],
)

load("@rules_python//python:repositories.bzl", "py_repositories", "python_register_toolchains")

py_repositories()

python_register_toolchains(
    name = "rules_appimage_python",
    python_version = "3.14",
)

load("@rules_python//python:pip.bzl", "pip_parse")

pip_parse(
    name = "rules_appimage_py_deps",
    python_interpreter_target = "@python_3_14_host//:python",
    requirements_lock = "@rules_appimage//:requirements.txt",
)

load("@rules_appimage_py_deps//:requirements.bzl", "install_deps")

install_deps()

register_toolchains("@rules_appimage//appimage:all")
