"""Dependencies of rules_appimage."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

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
    excludes = native.existing_rules().keys()

    if "bazel_skylib" not in excludes:
        http_archive(
            name = "bazel_skylib",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
                "https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
            ],
            sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
        )

    if "rules_python" not in excludes:
        http_archive(
            name = "rules_python",
            url = "https://github.com/bazelbuild/rules_python/releases/download/0.5.0/rules_python-0.5.0.tar.gz",
            sha256 = "cd6730ed53a002c56ce4e2f396ba3b3be262fd7cb68339f0377a45e8227fe332",
        )

    for arch in ("aarch64", "armhf", "i686", "x86_64"):
        name = "appimage_runtime_" + arch
        if name not in excludes:
            http_file(
                name = name,
                executable = True,
                sha256 = _SHAS[name],
                urls = ["https://github.com/lalten/type2-runtime/releases/download/build-2022-10-03-c5c7b07/runtime-{}".format(arch)],
            )

        name = "mksquashfs_" + arch
        if name not in excludes:
            http_file(
                name = name,
                executable = True,
                sha256 = _SHAS[name],
                urls = ["https://github.com/lalten/static-tools/releases/download/build-2022-10-02-970eff7/mksquashfs-{}".format(arch)],
            )

    if "appimagetool.png" not in excludes:
        http_file(
            name = "appimagetool.png",
            sha256 = "0c23daaf7665216a8e8f9754c904ec18b2dfa376af2479601a571e504239fae6",
            urls = ["https://raw.githubusercontent.com/AppImage/AppImageKit/b51f685/resources/appimagetool.png"],
        )
