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
        sha256 = "91c49f9a1ed972ad00688a38222119e2baf49ba74cf5fda05729a79d7d59d335",
        strip_prefix = "squashfs-tools-4.7.4/squashfs-tools",
        url = "https://github.com/plougher/squashfs-tools/releases/download/4.7.4/squashfs-tools-4.7.4.tar.gz",
    )

    # zlib is a dep of squashfs-tools
    maybe(
        http_archive,
        name = "zlib",
        build_file = "@rules_appimage//third_party:zlib.BUILD",
        sha256 = "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23",
        strip_prefix = "zlib-1.3.1",
        url = "https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz",
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
        sha256 = "f609f341d6e9090b981b3f45324d05a819fd7a5a56434f849c761971ce2c47da",
        strip_prefix = "rules_python-1.7.0",
        url = "https://github.com/bazelbuild/rules_python/releases/download/1.7.0/rules_python-1.7.0.tar.gz",
    )

def rules_appimage_development_deps():
    """Declare http_archive deps needed to run tests of rules_appimage."""

    # bazel_features is needed by with_cfg.bzl
    maybe(
        http_archive,
        name = "bazel_features",
        sha256 = "adc8ddf121917f197f75c5245dfa8d7b1619f10a1002e25062b093b7957f2798",
        strip_prefix = "bazel_features-1.37.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.37.0/bazel_features-v1.37.0.tar.gz",
    )

    # jq.bzl is needed by aspect_bazel_lib
    maybe(
        http_archive,
        name = "jq.bzl",
        sha256 = "21617eb71fb775a748ef5639131ab943ef39946bd2a4ce96ea60b03f985db0c5",
        strip_prefix = "jq.bzl-0.4.0",
        url = "https://github.com/bazel-contrib/jq.bzl/releases/download/v0.4.0/jq.bzl-v0.4.0.tar.gz",
    )

    # aspect_bazel_lib is needed by rules_pycross (which is not used by tests in WORKSPACE) and with_cfg.bzl
    maybe(
        http_archive,
        name = "aspect_bazel_lib",
        sha256 = "94e192033ca8027f26de71c9000a67ef9c73695c2b88e2c559045170917ead0c",
        strip_prefix = "bazel-lib-2.22.5",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.22.5/bazel-lib-v2.22.5.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_cc",
        sha256 = "472ddca8cec1e64ad78e4f0cabbec55936a3baddbe7bef072764ca91504bd523",
        strip_prefix = "rules_cc-0.2.13",
        url = "https://github.com/bazelbuild/rules_cc/releases/download/0.2.13/rules_cc-0.2.13.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_oci",
        sha256 = "5994ec0e8df92c319ef5da5e1f9b514628ceb8fc5824b4234f2fe635abb8cc2e",
        strip_prefix = "rules_oci-2.2.6",
        url = "https://github.com/bazel-contrib/rules_oci/releases/download/v2.2.6/rules_oci-v2.2.6.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_shell",
        sha256 = "e6b87c89bd0b27039e3af2c5da01147452f240f75d505f5b6880874f31036307",
        strip_prefix = "rules_shell-0.6.1",
        url = "https://github.com/bazelbuild/rules_shell/releases/download/v0.6.1/rules_shell-v0.6.1.tar.gz",
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
        sha256 = "c8eb6b436415ad283ccc72291542b597934b95f227211837005f2928eb542e6c",
        strip_prefix = "with_cfg.bzl-0.10.3",
        url = "https://github.com/fmeum/with_cfg.bzl/releases/download/v0.10.3/with_cfg.bzl-v0.10.3.tar.gz",
    )
    maybe(
        http_archive,
        name = "container_structure_test",
        sha256 = "c91a76f7b4949775941f8308ee7676285555ae4756ec1ec990c609c975a55f93",
        strip_prefix = "container-structure-test-1.19.3",
        url = "https://github.com/GoogleContainerTools/container-structure-test/archive/refs/tags/v1.19.3.tar.gz",
    )
