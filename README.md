# rules_appimage
![https://github.com/lalten/rules_appimage/actions](https://img.shields.io/github/workflow/status/lalten/rules_appimage/CI)
![LICENSE](https://img.shields.io/github/license/lalten/rules_appimage)

Bazel rules for creating AppImage packages

## Getting Started

Add this to your `WORKSPACE`:
```py
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

RULES_APPIMAGE_VER = "6b437b63643bf23ff819a80553628e5fd1f183d0"

http_archive(
    name = "rules_appimage",
    sha = "",
    urls = ["https://github.com/lalten/rules_appimage/archive/{}.tar.gz".format(RULES_APPIMAGE_VER)],
    strip_prefix = "rules_appimage-{}".format(RULES_APPIMAGE_VER),
)
```

To define AppImages in your `BUILD` files:
```py
load("@rules_appimage//appimage:appimage.bzl", "appimage")

appimage(
    name = "my_appimage",
    binary = ":the_executable_to_wrap",
)
```

## Usage examples
You can `bazel run` AppImages directly:
```
❯ bazel run -- //tests:appimage_py                       
INFO: Analyzed target //tests:appimage_py (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //tests:appimage_py up-to-date:
  bazel-bin/tests/appimage_py
INFO: Elapsed time: 0.351s, Critical Path: 0.24s
INFO: 4 processes: 3 internal, 1 linux-sandbox.
INFO: Build completed successfully, 4 total actions
INFO: Build completed successfully, 4 total actions
Hello, world!
```
```
❯ bazel run -- //tests:appimage_py --name User       
INFO: Analyzed target //tests:appimage_py (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //tests:appimage_py up-to-date:
  bazel-bin/tests/appimage_py
INFO: Elapsed time: 0.062s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Build completed successfully, 1 total action
Hello, User!
```

The [AppImage CLI args](https://github.com/AppImage/AppImageKit#command-line-arguments) continue to work
```
❯ bazel run -- //tests:appimage_py --appimage-version
INFO: Analyzed target //tests:appimage_py (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //tests:appimage_py up-to-date:
  bazel-bin/tests/appimage_py
INFO: Elapsed time: 0.088s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Build completed successfully, 1 total action
Version: 8bbf694
```

The resulting AppImage file is a portable standalone executable
```
❯ file bazel-out/k8-fastbuild/bin/tests/appimage_py
bazel-out/k8-fastbuild/bin/tests/appimage_py: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=9fdbc145689e0fb79cb7291203431012ae8e1911, stripped

❯ bazel-out/k8-fastbuild/bin/tests/appimage_py --name GitHub    
Hello, GitHub!
```
```
❯ rsync bazel-out/k8-fastbuild/bin/tests/appimage_py my-server:.     

❯ ssh my-server ./appimage_py
Hello, world!
```

## Troubleshooting

### Missing libfuse
rules_appimage builds type-2 AppImages, which use FUSE to run. If this dependency is not fulfilled, you'll get an error like this:
```
dlopen(): error loading libfuse.so.2

AppImages require FUSE to run. 
You might still be able to extract the contents of this AppImage 
if you run it with the --appimage-extract option. 
See https://github.com/AppImage/AppImageKit/wiki/FUSE 
for more information
```
You can either [install libfuse2](https://pkgs.org/search/?q=libfuse) or provide the `--appimage-extract-and-run` arg.

### Missing runtime deps
The AppImage will only be as portable as your Bazel build is. For example, if you run our test.py on a host that uses Python3.6 by default, you might get
```
  File "/tmp/appimage_extracted_544993ad2a5919e445b618f1fe009e53/test_py.runfiles/rules_appimage/tests/test.py", line 10
    assert (s := DATA_DEP.stat().st_size) == 591, f"{DATA_DEP} has wrong size {s}"
              ^
SyntaxError: invalid syntax
```
Which shows how important it is to have a hermetic build. Check https://thundergolfer.com/bazel/python/2021/06/25/a-basic-python-bazel-toolchain/ for some inspiration.
