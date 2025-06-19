"""Dependencies of rules_appimage."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

ARCHS = {"aarch64": "aarch64", "armv7e-m": "armhf", "i386": "i686", "x86_64": "x86_64"}

RUNTIME_SHAS = {
    "aarch64": "df1dcce6992a23cdf8728e88ed24f71b3c385f6384f3484ff66f45b9c97f00f2",
    "armhf": "dc6a546bd38a2df4cc6b14b0f2bcf925b0452e8a70d05b6027a631d60d26039b",
    "i686": "480017cfe6fa81785954c4ea39e4d06bc3b8fc287a55082ae781069c5d399116",
    "x86_64": "b86ac7572bb0b3ead120b09430a9dbeadde2f76ae54c1e30659cb54992d60ec1",
}

def rules_appimage_deps():
    """Declare http_archive deps needed in the WORKSPACE version of rules_appimage."""
    rules_appimage_common_deps()
    _rules_appimage_workspace_deps()

def rules_appimage_common_deps():
    """Declare http_archive deps needed for both the WORKSPACE and Bzlmod version of rules_appimage."""
    for arch, runtime_arch in ARCHS.items():
        maybe(
            http_file,
            name = "appimage_runtime_" + arch,
            executable = True,
            sha256 = RUNTIME_SHAS[runtime_arch],
            urls = ["https://github.com/lalten/type2-runtime/releases/download/build-2022-10-03-c5c7b07/runtime-{}".format(runtime_arch)],
        )

def _rules_appimage_workspace_deps():
    """Declare http_archive deps only needed in the WORKSPACE version of rules_appimage."""
    maybe(
        http_archive,
        name = "squashfs-tools",
        build_file = "@rules_appimage//third_party:squashfs-tools.BUILD",
        sha256 = "94201754b36121a9f022a190c75f718441df15402df32c2b520ca331a107511c",
        strip_prefix = "squashfs-tools-4.6.1/squashfs-tools",
        url = "https://github.com/plougher/squashfs-tools/releases/download/4.6.1/squashfs-tools-4.6.1.tar.gz",
    )

    # zstd is a dep of squashfs-tools
    maybe(
        http_archive,
        name = "zstd",
        build_file = "@rules_appimage//third_party:zstd.BUILD",
        sha256 = "eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3",
        strip_prefix = "zstd-1.5.7",
        url = "https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz",
    )

    # rules_python is needed to load py_binary and py_library rules. rules_appimage does not use pip packages outside of tests
    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "2cc26bbd53854ceb76dd42a834b1002cd4ba7f8df35440cf03482e045affc244",
        strip_prefix = "rules_python-1.3.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/1.3.0/rules_python-1.3.0.tar.gz",
    )

def rules_appimage_development_deps():
    """Declare http_archive deps needed to run tests of rules_appimage."""
    
    # aspect_bazel_lib is needed by rules_pycross (which is not used by tests in WORKSPACE) and with_cfg.bzl
    maybe(
        http_archive,
        name = "aspect_bazel_lib",
        sha256 = "40ba9d0f62deac87195723f0f891a9803a7b720d7b89206981ca5570ef9df15b",
        strip_prefix = "bazel-lib-2.14.0",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.14.0/bazel-lib-v2.14.0.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_cc",
        sha256 = "712d77868b3152dd618c4d64faaddefcc5965f90f5de6e6dd1d5ddcd0be82d42",
        strip_prefix = "rules_cc-0.1.1",
        url = "https://github.com/bazelbuild/rules_cc/releases/download/0.1.1/rules_cc-0.1.1.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_oci",
        sha256 = "361c417e8c95cd7c3d8b5cf4b202e76bac8d41532131534ff8e6fa43aa161142",
        strip_prefix = "rules_oci-2.2.5",
        url = "https://github.com/bazel-contrib/rules_oci/releases/download/v2.2.5/rules_oci-v2.2.5.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_shell",
        sha256 = "3e114424a5c7e4fd43e0133cc6ecdfe54e45ae8affa14fadd839f29901424043",
        strip_prefix = "rules_shell-0.4.0",
        url = "https://github.com/bazelbuild/rules_shell/releases/download/v0.4.0/rules_shell-v0.4.0.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_testing",
        sha256 = "89feaf18d6e2fc07ed7e34510058fc8d48e45e6d2ff8a817a718e8c8e4bcda0e",
        strip_prefix = "rules_testing-0.8.0",
        url = "https://github.com/bazelbuild/rules_testing/releases/download/v0.8.0/rules_testing-v0.8.0.tar.gz",
    )
    maybe(
        http_archive,
        name = "with_cfg.bzl",
        sha256 = "8cef6d78b169ebbab6601e95d9736d41254c02b7b6384edc8373808e4b1d7534",
        strip_prefix = "with_cfg.bzl-0.9.2",
        url = "https://github.com/fmeum/with_cfg.bzl/releases/download/v0.9.2/with_cfg.bzl-v0.9.2.tar.gz",
    )
    maybe(
        http_archive,
        name = "container_structure_test",
        sha256 = "c91a76f7b4949775941f8308ee7676285555ae4756ec1ec990c609c975a55f93",
        strip_prefix = "container-structure-test-1.19.3",
        url = "https://github.com/GoogleContainerTools/container-structure-test/archive/refs/tags/v1.19.3.tar.gz",
    )
