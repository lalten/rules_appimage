# LLVM-based cc toolchains restricted to musl libc target platforms.
#
# The containerized tests transition their binaries to @llvm//platforms:linux_*_musl so that the
# resulting binaries are self-contained and run in any Linux container, including when the build
# runs on macOS. We register these wrappers instead of @llvm//toolchain:all so that the hermetic
# LLVM toolchain is only loaded and used when a target is actually built for a musl platform;
# regular host builds keep using the default cc toolchain.

_EXECS = [
    ("linux", "x86_64"),
    ("linux", "aarch64"),
    ("macos", "x86_64"),
    ("macos", "aarch64"),
]

_TARGET_CPUS = [
    "x86_64",
    "aarch64",
]

[
    toolchain(
        name = "{}_{}_to_linux_{}_musl".format(exec_os, exec_cpu, target_cpu),
        exec_compatible_with = [
            "@platforms//os:" + exec_os,
            "@platforms//cpu:" + exec_cpu,
        ],
        target_compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:" + target_cpu,
            "@llvm//constraints/libc:musl",
        ],
        toolchain = "@llvm//toolchain:{}_{}_cc_toolchain".format(exec_os, exec_cpu),
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    )
    for (exec_os, exec_cpu) in _EXECS
    for target_cpu in _TARGET_CPUS
]
