"""Dependencies of rules_appimage."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

_SHAS = {
    "appimage_runtime_aarch64": "df1dcce6992a23cdf8728e88ed24f71b3c385f6384f3484ff66f45b9c97f00f2",
    "appimage_runtime_armhf": "dc6a546bd38a2df4cc6b14b0f2bcf925b0452e8a70d05b6027a631d60d26039b",
    "appimage_runtime_i686": "480017cfe6fa81785954c4ea39e4d06bc3b8fc287a55082ae781069c5d399116",
    "appimage_runtime_x86_64": "b86ac7572bb0b3ead120b09430a9dbeadde2f76ae54c1e30659cb54992d60ec1",
    "mksquashfs_aarch64": "9cbe4cf6d6b83ac906cd4232192e532493285d2a499ebc31b6d7536957dcbf21",
    "mksquashfs_armhf": "36e95cc77948cb74b1496ddcda3540b7265d734a022854434693a2fcd3c5bd32",
    "mksquashfs_i686": "55f8a7f915bf2b526148d7ed393787f683db59b69e0a4ec4e5d6345d999ee0e2",
    "mksquashfs_x86_64": "64a10d2f0dbd0c49753d10fef1afe615d4936794a942f40792f4fa3016199d6c",
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

    for arch in ("aarch64", "armhf", "i686", "x86_64"):
        name = "appimage_runtime_" + arch
        maybe(
            http_file,
            name = name,
            executable = True,
            sha256 = _SHAS[name],
            urls = ["https://github.com/lalten/type2-runtime/releases/download/build-2022-10-03-c5c7b07/runtime-{}".format(arch)],
        )

        name = "mksquashfs_" + arch
        maybe(
            http_file,
            name = name,
            executable = True,
            sha256 = _SHAS[name],
            urls = ["https://github.com/lalten/static-tools/releases/download/build-2022-10-02-970eff7/mksquashfs-{}".format(arch)],
        )

    maybe(
        http_file,
        name = "appimagetool.png",
        sha256 = "0c23daaf7665216a8e8f9754c904ec18b2dfa376af2479601a571e504239fae6",
        urls = ["https://raw.githubusercontent.com/AppImage/AppImageKit/b51f685/resources/appimagetool.png"],
    )
