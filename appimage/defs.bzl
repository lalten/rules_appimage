load("//appimage:appimage.bzl", _appimage = "appimage", _appimage_test = "appimage_test")
load("//appimage:toolchain.bzl", _appimage_toolchain = "appimage_toolchain")

appimage = _appimage
appimage_test = _appimage_test

appimage_toolchain = _appimage_toolchain
