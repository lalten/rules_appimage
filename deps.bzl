"""Dependencies of rules_appimage."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

RUNTIME_SHAS = {
    "aarch64": "df1dcce6992a23cdf8728e88ed24f71b3c385f6384f3484ff66f45b9c97f00f2",
    "armv7e-m": "dc6a546bd38a2df4cc6b14b0f2bcf925b0452e8a70d05b6027a631d60d26039b",
    "i386": "480017cfe6fa81785954c4ea39e4d06bc3b8fc287a55082ae781069c5d399116",
    "x86_64": "b86ac7572bb0b3ead120b09430a9dbeadde2f76ae54c1e30659cb54992d60ec1",
}

def rules_appimage_deps():
    """Download dependencies and set up rules_appimage."""
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "66ffd9315665bfaafc96b52278f57c7e2dd09f5ede279ea6d39b2be471e7e3aa",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.2/bazel-skylib-1.4.2.tar.gz",
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

    for arch in RUNTIME_SHAS.keys():
        maybe(
            http_file,
            name = "appimage_runtime_" + arch,
            executable = True,
            sha256 = RUNTIME_SHAS[arch],
            urls = ["https://github.com/lalten/type2-runtime/releases/download/build-2022-10-03-c5c7b07/runtime-{}".format(arch)],
        )

    maybe(
        http_file,
        name = "appimagetool.png",
        sha256 = "0c23daaf7665216a8e8f9754c904ec18b2dfa376af2479601a571e504239fae6",
        urls = ["https://raw.githubusercontent.com/AppImage/AppImageKit/b51f685/resources/appimagetool.png"],
    )

    # zstd is a dep of squashfs-tools
    maybe(
        http_archive,
        name = "zstd",
        build_file = "@rules_appimage//third_party:zstd.BUILD",
        sha256 = "9c4396cc829cfae319a6e2615202e82aad41372073482fce286fac78646d3ee4",
        strip_prefix = "zstd-1.5.5",
        url = "https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-1.5.5.tar.gz",
    )
