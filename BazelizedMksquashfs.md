# How to use a bazelized mksquashfs instead of what's on the host.

It's nicer to use a bazel-built mksquashfs than hoping the host supplies one / using whatever version might be installed there.

Dropbox's dbx_build_tools repo provides a bazel-built squashfs-tools plus (some of) its build dependencies.
You can integrate it like this:

1. Add to WORKSPACE:
    ```py
    DBX_BUILD_TOOLS_VERSION = "c083ae0cdec5b2bd1fe929cad56d02b6770c4dd0"
    http_archive(
        name = "dbx_build_tools",
        sha256 = "2267c4c441b9cde94b8c94a9c1e2e2bd3c2c865c45f893224bfbbf9d5d0998a8",
        urls = ["https://github.com/dropbox/dbx_build_tools/archive/{}.tar.gz".format(DBX_BUILD_TOOLS_VERSION)],
        strip_prefix = "dbx_build_tools-" + DBX_BUILD_TOOLS_VERSION,
    )
    
    load("@dbx_build_tools//build_tools/bazel:external_workspace.bzl", "drte_deps")
    drte_deps()
    ```
2.  Use `"@com_github_plougher_squashfs_tools//:mksquashfs"` as the `mksquashfs` attr of all your `appimage` rules.
    Hint: You could create a custom wrapper macro like below.
    ```py
    load("//appimage:appimage.bzl", _appimage="appimage")

    def appimage(name, **kwargs):
        kwargs["mksquashfs"] = "@com_github_plougher_squashfs_tools//:mksquashfs"
        _appimage(name = name, **kwargs)
    ```
