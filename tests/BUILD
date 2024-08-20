load("@rules_appimage_py_deps//:requirements.bzl", "requirement")
load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_python//python:defs.bzl", "py_binary", "py_test")
load("//appimage:appimage.bzl", "appimage", "appimage_test")
load(":testrules.bzl", "declared_symlink", "runfiles_symlink", "transitioned_cc_binary")

sh_binary(
    name = "test_sh",
    srcs = ["test.sh"],
)

appimage_test(
    name = "appimage_test_sh",
    size = "small",
    args = ["--appimage-extract-and-run"],  # One way to run if no libfuse2 is available
    binary = ":test_sh",
    target_compatible_with = ["@platforms//os:linux"],
)

sh_binary(
    name = "test_mount-is-readonly",
    srcs = ["test_mount-is-readonly.sh"],
)

appimage_test(
    name = "test_mount-is-readonly.appimage",
    size = "small",
    binary = ":test_mount-is-readonly",
    tags = ["requires-fakeroot"],  # This helps tests failing with `fusermount3: mount failed: Operation not permitted`
    target_compatible_with = ["@platforms//os:linux"],
)

cc_binary(
    name = "test_cc",
    srcs = ["test.cc"],
    copts = ["-std=c++20"],
    env = {
        "MY_APPIMAGE_ENV": "original",
        "MY_BINARY_ENV": "not lost",
    },
)

appimage_test(
    name = "appimage_test_cc",
    size = "small",
    binary = ":test_cc",
    env = {"MY_APPIMAGE_ENV": "overwritten"},  # environment variables are propagated from the binary target env attr
    tags = ["requires-fakeroot"],
    target_compatible_with = ["@platforms//os:linux"],
)

sh_test(
    name = "appimage_test_cc_with_sh_test",
    size = "small",
    srcs = ["appimage_test_cc_with_sh_test.sh"],
    data = [":appimage_test_cc"],
)

py_binary(
    name = "test_py",
    srcs = ["test.py"],
    data = [
        "data.txt",
        "dir",  # this is a relative directory, not a target label
        ":dangling_symlink",
        ":dot_symlink",
        ":dotdot_symlink",
        ":external_bin.appimage",
        ":path/to/the/runfiles_symlink",
    ],
    env = {"MY_BINARY_ENV": "propagated only in Bazel 7+"},
    main = "test.py",
)

filegroup(
    name = "appimage_data_filegroup",
    srcs = ["appimage_data_filegroup.txt"],
)

genrule(
    name = "generated_data",
    outs = ["generated_data.txt"],
    cmd = "echo 'Generated data' > $@",
)

transitioned_cc_binary(
    name = "transitioned_binary",
    srcs = ["transitioned_binary_test.cc"],
    copts = ["-std=c++20"],
    data = [":generated_data"],
)

appimage(
    name = "appimage_test_with_transitioned_binary",
    binary = ":transitioned_binary",
    data = [
        ":generated_data",
    ],
    env = {"APPIMAGE_EXTRACT_AND_RUN": "1"},  # Another way to run if no libfuse2 is available
    target_compatible_with = ["@platforms//os:linux"],
)

appimage_test(
    name = "appimage_test_py",
    size = "small",
    binary = ":test_py",
    data = [
        "appimage_data_file.txt",
        ":appimage_data_filegroup",
    ],
    env = {"APPIMAGE_EXTRACT_AND_RUN": "1"},  # Another way to run if no libfuse2 is available
    target_compatible_with = ["@platforms//os:linux"],
)

appimage(
    name = "appimage_py",
    binary = ":test_py",
    build_args = [
        # Example: Compress the squashfs with zstd. mksquashfs defaults to gzip, see
        # https://github.com/lalten/rules_appimage/blob/0ba8e8b7f82e69c7aa6dfac62679bb3137ca4b02/third_party/squashfs-tools.BUILD#L10
        "-comp",
        "zstd",
    ],
    data = [
        "appimage_data_file.txt",
        ":appimage_data_filegroup",
    ],
)

py_test(
    name = "test_appimage",
    size = "small",
    srcs = ["test_appimage.py"],
    data = [":appimage_py"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [requirement("pytest")],
)

appimage(
    name = "external_bin.appimage",
    binary = "@rules_python//tools:wheelmaker",
)

sh_test(
    name = "runfiles_test_sh",
    size = "small",
    srcs = ["runfiles_test.sh"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

appimage_test(
    name = "runfiles_test_sh.appimage",
    size = "small",
    binary = ":runfiles_test_sh",
    env = {"RUNFILES_LIB_DEBUG": "1"},
    tags = ["requires-fakeroot"],
    target_compatible_with = ["@platforms//os:linux"],
)

declared_symlink(
    name = "dangling_symlink",
    target = "././.././idonotexist",
)

declared_symlink(
    name = "dot_symlink",
    target = ".",
)

declared_symlink(
    name = "dotdot_symlink",
    target = "..",
)

runfiles_symlink(
    name = "path/to/the/runfiles_symlink",
    target = ":data.txt",
)

py_test(
    name = "mkappdir_test",
    size = "small",
    srcs = ["mkappdir_test.py"],
    deps = [
        "//appimage/private:mkappdir",
        requirement("pytest"),
    ],
)
