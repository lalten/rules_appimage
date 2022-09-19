"""Dependencies of rules_appimage."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

_SHAS = {
    "appimage_runtime_aarch64": "d2624ce8cc2c64ef76ba986166ad67f07110cdbf85112ace4f91611bc634c96a",
    "appimage_runtime_armhf": "c143d8981702b91cc693e5d31ddd91e8424fec5911fa2dda72082183b2523f47",
    "appimage_runtime_i686": "5cbfd3c7e78d9ebb16b9620b28affcaa172f2166f1ef5fe7ef878699507bcd7f",
    "appimage_runtime_x86_64": "4aa4ff1da357d4a46dea9bcf1ab15edfccb7b0fb36afdfe0688ce19495e6ed24",
    "mksquashfs_aarch64": "9cbe4cf6d6b83ac906cd4232192e532493285d2a499ebc31b6d7536957dcbf21",
    "mksquashfs_armhf": "36e95cc77948cb74b1496ddcda3540b7265d734a022854434693a2fcd3c5bd32",
    "mksquashfs_i686": "ff9f701d500979cee3c118d5f46e26e239ce015a37621b500188059e41194ca3",
    "mksquashfs_x86_64": "398f58d4217d4a942f1680ed8433ed2c9bb389782c81fe9cc4637872a1c66787",
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
                urls = ["https://github.com/probonopd/static-tools/releases/download/continuous/runtime-fuse2-{}".format(arch)],
            )

        name = "mksquashfs_" + arch
        if name not in excludes:
            http_file(
                name = name,
                executable = True,
                sha256 = _SHAS[name],
                urls = ["https://github.com/probonopd/static-tools/releases/download/continuous/mksquashfs-{}".format(arch)],
            )

    if "appimagetool.png" not in excludes:
        http_file(
            name = "appimagetool.png",
            sha256 = "0c23daaf7665216a8e8f9754c904ec18b2dfa376af2479601a571e504239fae6",
            urls = ["https://raw.githubusercontent.com/AppImage/AppImageKit/b51f685/resources/appimagetool.png"],
        )
