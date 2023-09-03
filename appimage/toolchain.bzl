""" Toolchain for the AppImage runtime """

def _appimage_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        appimage_runtime = ctx.file.appimage_runtime,
    )]

appimage_toolchain = rule(
    implementation = _appimage_toolchain_impl,
    attrs = {
        "appimage_runtime": attr.label(allow_single_file = True),
    },
)
