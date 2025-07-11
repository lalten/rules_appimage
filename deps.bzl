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
        sha256 = "f1605ef720aa0b23939a49ef4491f6e734333ccc4bda4324d330da647e105328",
        strip_prefix = "squashfs-tools-4.7/squashfs-tools",
        url = "https://github.com/plougher/squashfs-tools/releases/download/4.7/squashfs-tools-4.7.tar.gz",
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
        sha256 = "9f9f3b300a9264e4c77999312ce663be5dee9a56e361a1f6fe7ec60e1beef9a3",
        strip_prefix = "rules_python-1.4.1",
        url = "https://github.com/bazelbuild/rules_python/releases/download/1.4.1/rules_python-1.4.1.tar.gz",
    )

def rules_appimage_development_deps():
    """Declare http_archive deps needed to run tests of rules_appimage."""

    # bazel_features is needed by with_cfg.bzl
    maybe(
        http_archive,
        name = "bazel_features",
        sha256 = "07bd2b18764cdee1e0d6ff42c9c0a6111ffcbd0c17f0de38e7f44f1519d1c0cd",
        strip_prefix = "bazel_features-1.32.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.32.0/bazel_features-v1.32.0.tar.gz",
    )

    # jq.bzl is needed by aspect_bazel_lib
    maybe(
        http_archive,
        name = "jq.bzl",
        sha256 = "7b63435aa19cc6a0cfd1a82fbdf2c7a2f0a94db1a79ff7a4469ffa94286261ab",
        strip_prefix = "jq.bzl-0.1.0",
        url = "https://github.com/bazel-contrib/jq.bzl/releases/download/v0.1.0/jq.bzl-v0.1.0.tar.gz",
    )

    # aspect_bazel_lib is needed by rules_pycross (which is not used by tests in WORKSPACE) and with_cfg.bzl
    maybe(
        http_archive,
        name = "aspect_bazel_lib",
        sha256 = "9a44f457810ce64ec36a244cc7c807607541ab88f2535e07e0bf2976ef4b73fe",
        strip_prefix = "bazel-lib-2.19.4",
        url = "https://github.com/bazel-contrib/bazel-lib/releases/download/v2.19.4/bazel-lib-v2.19.4.tar.gz",
    )
    maybe(
        http_archive,
        name = "rules_cc",
        sha256 = "d62624b45e0912713dcd3b8e30ba6ae55418ed6bf99e6d135cd61b8addae312b",
        strip_prefix = "rules_cc-0.1.2",
        url = "https://github.com/bazelbuild/rules_cc/releases/download/0.1.2/rules_cc-0.1.2.tar.gz",
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
        sha256 = "b15cc2e698a3c553d773ff4af35eb4b3ce2983c319163707dddd9e70faaa062d",
        strip_prefix = "rules_shell-0.5.0",
        url = "https://github.com/bazelbuild/rules_shell/releases/download/v0.5.0/rules_shell-v0.5.0.tar.gz",
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
