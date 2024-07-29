# How to release a new rules_appimage version

1. Create a tag and push it

    ```sh
    git tag v1.12.1
    git push --tags
    ```

2. Download the automatic .tar.gz for the tag and rename it with a `rules_appimage-` prefix. Note the missing `v` prefix.

    ```sh
    wget https://github.com/lalten/rules_appimage/archive/refs/tags/v1.12.1.tar.gz
    mv v1.12.1.tar.gz rules_appimage-1.12.1.tar.gz
    ```

3. Create a release in the web UI: <https://github.com/lalten/rules_appimage/releases/new?tag=v1.12.1>
4. Upload the .tar.gz
5. "Generate release notes"
6. Get the sha256 sum of the .tar.gz

    ```sh
    sha256sum rules_appimage-v1.12.1.tar.gz
    ```

7. Add and update the hash and version numbers this block:

## `MODULE.bazel` setup

```Starlark
bazel_dep(name = "rules_appimage", version = "1.12.1")
```

## `WORKSPACE` setup

```Starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_appimage",
    sha256 = "c320857278bcb37ca21ad90e48b1289e58947ffac4976aab247d4e3b4c86509a",
    strip_prefix = "rules_appimage-1.12.1",
    url = "https://github.com/lalten/rules_appimage/releases/download/v1.12.1/rules_appimage-1.12.1.tar.gz",
    patch_cmds = ["rm -r tests"],
)

load("@rules_appimage//:deps.bzl", "rules_appimage_deps")

rules_appimage_deps()

register_toolchains("@rules_appimage//appimage:all")
