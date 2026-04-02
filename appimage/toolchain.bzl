"""Toolchain for the AppImage runtime."""

def _appimage_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        appimage_runtime = ctx.file.appimage_runtime,
    )]

appimage_toolchain = rule(
    implementation = _appimage_toolchain_impl,
    attrs = {
        "appimage_runtime": attr.label(allow_single_file = True),
    },
    doc = """Declare an AppImage toolchain wrapping a platform-specific AppImage runtime binary.

A separate toolchain target should be registered for each supported CPU architecture, constrained to the matching platform, so that the `appimage()` rule automatically selects the correct runtime for the target platform.
""",
)
