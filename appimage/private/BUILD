load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_python//python:defs.bzl", "py_binary")

py_binary(
    name = "mkappdir",
    srcs = ["mkappdir.py"],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "mkappimage",
    srcs = ["mkappimage.sh"],
    data = [
        ":mkappdir",
        "@squashfs-tools//:mksquashfs",
    ],
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

genrule(
    name = "dash_c",
    srcs = ["@ape//ape:bash"],
    outs = ["dash.c"],
    cmd = """
echo "const unsigned long dash_len = $$(stat -c %s $$(readlink -f $<));" > $@
echo 'const char dash[] = {' >> $@
cat $< | xxd -i >> $@
echo '};' >> $@
""",
)

cc_binary(
    name = "launch",
    srcs = [
        "dash.c",
        "launch.c",
    ],
    linkopts = ["-static"],
    local_defines = ["_GNU_SOURCE"],
    visibility = ["//visibility:public"],
)
