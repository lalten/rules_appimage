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
        url = "https://github.com/plougher/squashfs-tools/archive/refs/tags/4.6.1.tar.gz",
    )

    # zstd is a dep of squashfs-tools
    maybe(
        http_archive,
        name = "zstd",
        build_file = "@rules_appimage//third_party:zstd.BUILD",
        sha256 = "8c29e06cf42aacc1eafc4077ae2ec6c6fcb96a626157e0593d5e82a34fd403c1",
        strip_prefix = "zstd-1.5.6",
        url = "https://github.com/facebook/zstd/releases/download/v1.5.6/zstd-1.5.6.tar.gz",
    )

    # rules_python is needed to load py_binary and py_library rules. rules_appimage does not use pip packages outside of tests
    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "9c6e26911a79fbf510a8f06d8eedb40f412023cf7fa6d1461def27116bff022c",
        strip_prefix = "rules_python-1.1.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/1.1.0/rules_python-1.1.0.tar.gz",
    )

def rules_appimage_development_deps():
    """Declare http_archive deps needed to run tests of rules_appimage."""
    maybe(
        http_archive,
        name = "rules_testing",
        sha256 = "28c2d174471b587bf0df1fd3a10313f22c8906caf4050f8b46ec4648a79f90c3",
        strip_prefix = "rules_testing-0.7.0",
        url = "https://github.com/bazelbuild/rules_testing/releases/download/v0.7.0/rules_testing-v0.7.0.tar.gz",
    )
    maybe(
        http_archive,
        name = "with_cfg.bzl",
        sha256 = "d1d3049822d594e0057adbf6ad084242340eb37ec7cb8d43779710a9311ecd14",
        strip_prefix = "with_cfg.bzl-0.9.1",
        url = "https://github.com/fmeum/with_cfg.bzl/releases/download/v0.9.1/with_cfg.bzl-v0.9.1.tar.gz",
    )
