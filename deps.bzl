"""Dependencies of rules_appimage."""

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
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
    maybe(
        http_archive,
        name = "libfuse",
        strip_prefix = "fuse-3.16.2",
        sha256 = "f797055d9296b275e981f5f62d4e32e089614fc253d1ef2985851025b8a0ce87",
        url = "https://github.com/libfuse/libfuse/releases/download/fuse-3.16.2/fuse-3.16.2.tar.gz",
        build_file = "@rules_appimage//third_party:libfuse.BUILD",
    )
    maybe(
        http_archive,
        name = "squashfuse",
        strip_prefix = "squashfuse-0.5.2",
        sha256 = "54e4baaa20796e86a214a1f62bab07c7c361fb7a598375576d585712691178f5",
        url = "https://github.com/vasi/squashfuse/releases/download/0.5.2/squashfuse-0.5.2.tar.gz",
        build_file = "@rules_appimage//third_party:squashfuse.BUILD",
    )
    maybe(
        git_repository,
        name = "appimage-type2-runtime",
        remote = "https://github.com/AppImage/type2-runtime",
        commit = "47b665594856b4e8928f8932adcf6d13061d8c30",
        build_file = "@rules_appimage//third_party:runtime.BUILD",
        patches = ["@rules_appimage//third_party:runtime-sqfs_usage.patch"],
    )

def _rules_appimage_workspace_deps():
    """Declare http_archive deps only needed in the WORKSPACE version of rules_appimage."""
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "bc283cdfcd526a52c3201279cda4bc298652efa898b10b4db0837dc51652756f",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
        ],
    )

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

    # rules python is needed to provide the bzlmod/workspace-agnostic bazel-runfiles pip requirement for mkappimage.
    # Don't forget to add the setup steps to the main WORKSPACE file! You can find them in the release notes as well.
    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "5bcfa3852444d084b1d3262714cec151b797648d4d444ea9895c7c7ed79cd715",
        strip_prefix = "rules_python-0.33.1",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.33.1/rules_python-0.33.1.tar.gz",
    )

def rules_appimage_development_deps():
    """Declare http_archive deps needed to run tests of rules_appimage."""
    maybe(
        http_archive,
        name = "rules_testing",
        sha256 = "02c62574631876a4e3b02a1820cb51167bb9cdcdea2381b2fa9d9b8b11c407c4",
        strip_prefix = "rules_testing-0.6.0",
        url = "https://github.com/bazelbuild/rules_testing/releases/download/v0.6.0/rules_testing-v0.6.0.tar.gz",
    )
    maybe(
        http_archive,
        name = "with_cfg.bzl",
        sha256 = "2361266489cf028061b8a1495d1b1e1a4786b8ea0006cf2a7359837c93fabc7a",
        strip_prefix = "with_cfg.bzl-0.2.3",
        url = "https://github.com/fmeum/with_cfg.bzl/releases/download/v0.2.3/with_cfg.bzl-v0.2.3.tar.gz",
    )
