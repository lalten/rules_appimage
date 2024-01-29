"""rules_appimage bzlmod extensions."""

load("//:deps.bzl", "rules_appimage_common_deps")

def _appimage_ext_dependencies_impl(_):
    rules_appimage_common_deps()

appimage_ext_dependencies = module_extension(implementation = _appimage_ext_dependencies_impl)
