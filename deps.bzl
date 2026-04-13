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
        sha256 = "547b7b7f4d2e44bf91b6fc554664850c69563701deab9fd9cd7e21f694c88ea6",
        strip_prefix = "squashfs-tools-4.7.5/squashfs-tools",
        url = "https://github.com/plougher/squashfs-tools/releases/download/4.7.5/squashfs-tools-4.7.5.tar.gz",
    )

    # zlib is a dep of squashfs-tools
    maybe(
        http_archive,
        name = "zlib",
        build_file = "@rules_appimage//third_party:zlib.BUILD",
        sha256 = "bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16",
        strip_prefix = "zlib-1.3.2",
        url = "https://github.com/madler/zlib/releases/download/v1.3.2/zlib-1.3.2.tar.gz",
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
        sha256 = "098ba13578e796c00c853a2161f382647f32eb9a77099e1c88bc5299333d0d6e",
        strip_prefix = "rules_python-1.9.0",
        url = "https://github.com/bazel-contrib/rules_python/releases/download/1.9.0/rules_python-1.9.0.tar.gz",
    )

def rules_appimage_development_deps():
    """Declare http_archive deps needed to run tests of rules_appimage."""

    # bazel_features is needed by with_cfg.bzl
    maybe(
        http_archive,
        name = "bazel_features",
        sha256 = "adfdb3cffab3a99a63363d844d559a81965d2b61a6062dd51a3d2478d416768f",
        strip_prefix = "bazel_features-1.45.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.45.0/bazel_features-v1.45.0.tar.gz",
    )

    # jq.bzl is needed by bazel_lib
    maybe(
        http_archive,
        name = "jq.bzl",
        sha256 = "e2eab5410b2eecc72f01d73590c58aefeddbb696ddf9d9c34dcee02dd79625ab",
        strip_prefix = "jq.bzl-0.6.1",
        url = "https://github.com/bazel-contrib/jq.bzl/releases/download/v0.6.1/jq.bzl-v0.6.1.tar.gz",
    )

    # bazel_lib is needed by rules_pycross (which is not used by tests in WORKSPACE) and with_cfg.bzl
    maybe(
        http_archive,
        name = "bazel_lib",
        sha256 = "3d62bf30b95b71a566d9ebca50ee78d370b12522d244235b41166f65b142705d",
        strip_prefix = "bazel-lib-3.2.2",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v3.2.2/bazel-lib-v3.2.2.tar.gz",
    )
    maybe(
        http_archive,
        name = "platforms",
        url = "https://github.com/bazelbuild/platforms/releases/download/1.0.0/platforms-1.0.0.tar.gz",
        sha256 = "3384eb1c30762704fbe38e440204e114154086c8fc8a8c2e3e28441028c019a8",
    )
    maybe(
        http_archive,
        name = "rules_cc",
        sha256 = "283fa1cdaaf172337898749cf4b9b1ef5ea269da59540954e51fba0e7b8f277a",
        strip_prefix = "rules_cc-0.2.17",
        url = "https://github.com/bazelbuild/rules_cc/releases/download/0.2.17/rules_cc-0.2.17.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_oci",
        sha256 = "6d47e0bb9d3c269695cbb35abb603d1db08434376a1210867da8f6f4a9c630ba",
        strip_prefix = "rules_oci-2.3.1",
        url = "https://github.com/bazel-contrib/rules_oci/releases/download/v2.3.1/rules_oci-v2.3.1.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_shell",
        sha256 = "3709d1745ba4be4ef054449647b62e424267066eca887bb00dd29242cb8463a0",
        strip_prefix = "rules_shell-0.7.1",
        url = "https://github.com/bazelbuild/rules_shell/releases/download/v0.7.1/rules_shell-v0.7.1.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_testing",
        sha256 = "281b69eed71e2b95cefc284ee5a1a9f7c5088141b58f2508be910eb22f13b986",
        strip_prefix = "rules_testing-0.9.0",
        url = "https://github.com/bazelbuild/rules_testing/releases/download/v0.9.0/rules_testing-v0.9.0.tar.gz",
    )
    maybe(
        http_archive,
        name = "with_cfg.bzl",
        sha256 = "87852e133c3755a5642fe10543ee20eda700dae14d30d13dac96e22ea5106d07",
        strip_prefix = "with_cfg.bzl-0.14.6",
        url = "https://github.com/fmeum/with_cfg.bzl/releases/download/v0.14.6/with_cfg.bzl-v0.14.6.tar.gz",
    )
    maybe(
        http_archive,
        name = "container_structure_test",
        sha256 = "186bb1493ebb3c597e53b2a7abd5460c683c63d404e44a64223d26bb3315841d",
        strip_prefix = "container-structure-test-1.22.1",
        url = "https://github.com/GoogleContainerTools/container-structure-test/archive/refs/tags/v1.22.1.tar.gz",
    )
