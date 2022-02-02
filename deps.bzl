"""Dependencies of rules_appimage."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

APPIMAGETOOL_RELEASES = {
    "aarch64": "334e77beb67fc1e71856c29d5f3f324ca77b0fde7a840fdd14bd3b88c25c341f",
    "armhf": "36bb718f32002357375d77b082c264baba2a2dcf44ed1a27d51dbb528fbb60f6",
    "i686": "104978205c888cb2ad42d1799e03d4621cb9a6027cfb375d069b394a82ff15d1",
    "x86_64": "df3baf5ca5facbecfc2f3fa6713c29ab9cefa8fd8c1eac5d283b79cab33e4acb",
}

def rules_appimage_deps():
    """Download dependencies and set up rules_appimage."""
    excludes = native.existing_rules().keys()

    if "bazel_skylib" not in excludes:
        http_archive(
            name = "bazel_skylib",
            urls = [
                "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
                "https://github.com/bazelbuild/bazel-skylib/releases/download/1.1.1/bazel-skylib-1.1.1.tar.gz",
            ],
            sha256 = "c6966ec828da198c5d9adbaa94c05e3a1c7f21bd012a0b29ba8ddbccb2c93b0d",
        )

    if "rules_python" not in excludes:
        http_archive(
            name = "rules_python",
            url = "https://github.com/bazelbuild/rules_python/releases/download/0.5.0/rules_python-0.5.0.tar.gz",
            sha256 = "cd6730ed53a002c56ce4e2f396ba3b3be262fd7cb68339f0377a45e8227fe332",
        )

    for arch, sha in APPIMAGETOOL_RELEASES.items():
        name = "appimagetool_release_" + arch
        if name not in excludes:
            http_file(
                name = name,
                sha256 = sha,
                urls = ["https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-{}.AppImage".format(arch)],
            )

    if "AppImageKit" not in excludes:
        http_archive(
            name = "AppImageKit",
            sha256 = "51b837c78dd99ecc1cf3dd283f4a98a1be665b01457da0edc1ff736d12974b1a",
            urls = ["https://github.com/AppImage/AppImageKit/archive/refs/tags/13.tar.gz"],
            build_file_content = 'exports_files(glob(["**"]))',
            strip_prefix = "AppImageKit-13",
        )
