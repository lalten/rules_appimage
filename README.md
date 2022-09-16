# rules_appimage
[![](https://img.shields.io/github/workflow/status/lalten/rules_appimage/CI)](https://github.com/lalten/rules_appimage/actions)
[![](https://img.shields.io/github/license/lalten/rules_appimage)](https://github.com/lalten/rules_appimage/blob/main/LICENSE)
[![Awesome](https://awesome.re/badge.svg)](https://awesomebazel.com/)

`rules_appimage` provides a [Bazel](https://bazel.build/) rule for packaging existing binary targets into [AppImage](https://github.com/AppImage/AppImageKit) packages.

AppImages are a great match for the Bazel build system because the runfiles structure and launcher stub (where applicable) can be packaged into an AppRun structure relatively easily.
There are no modifications to the packaged application's sources required, and even the existing Bazel target itself does not have to be modified.

The `appimage` rule has been used successfully with `py_binary`, `ruby_binary`, `sh_binary`, and `cc_binary`.
In fact, any *lang*_binary should be compatible.


## Getting Started

### Installation

Add this to your `WORKSPACE`:
```py
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

RULES_APPIMAGE_VER = "main"

http_archive(
    name = "rules_appimage",
    # sha = "",
    urls = ["https://github.com/lalten/rules_appimage/archive/{}.tar.gz".format(RULES_APPIMAGE_VER)],
    strip_prefix = "rules_appimage-{}".format(RULES_APPIMAGE_VER),
)

load("@rules_appimage//:deps.bzl", "rules_appimage_deps")

rules_appimage_deps()

load("@rules_appimage//:setup.bzl", "rules_appimage_setup")

rules_appimage_setup()
```

### Usage
To package a binary target into an AppImage, you add a `appimage` rule and point it at the target.
So in your `BUILD` files you do:
```py
load("@rules_appimage//appimage:appimage.bzl", "appimage")

appimage(
    name = "program.appimage",
    binary = ":program",
)
```

There is also a `appimage_test` rule that takes the same arguments but runs the appimage as a Bazel test target.

## How to use the appimage
### Via Bazel
You can `bazel run` AppImages directly:
```
❯ bazel run -- //tests:appimage_py                       
(...)
Hello, world!
```
```
❯ bazel run -- //tests:appimage_py --name TheAssassin       
(...)
Hello, TheAssassin!
```

### Directly
The resulting AppImage file is a portable standalone executable (which is kind of the point of the whole thing!)
```
❯ file bazel-bin/tests/appimage_py
bazel-bin/tests/appimage_py: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=9fdbc145689e0fb79cb7291203431012ae8e1911, stripped

❯ bazel-bin/tests/appimage_py --name GitHub    
Hello, GitHub!
```
```
❯ rsync bazel-bin/tests/appimage_py my-server:.     

❯ ssh my-server ./appimage_py
Hello, world!
```

### AppImage CLI args
There are certain [AppImage CLI args](https://github.com/AppImage/AppImageKit#command-line-arguments).
They'll still work. Try `--appimage-help`.
```
❯ bazel run -- //tests:appimage_py --appimage-version
(...)
Version: 8bbf694
```

## Troubleshooting

### Missing libfuse
rules_appimage builds `type-2 AppImages` via AppImageKit.
By default, the packaged application will try to load libfuse.so.2 on startup.
It does this to mount all the application files in a temporary directory, from which it will run.
If libfuse2 is not available, you'll get an error like this:
```
dlopen(): error loading libfuse.so.2

AppImages require FUSE to run. 
You might still be able to extract the contents of this AppImage 
if you run it with the --appimage-extract option. 
See https://github.com/AppImage/AppImageKit/wiki/FUSE 
for more information
```
In this case, you can:, which
 * Install [libfuse2](https://pkgs.org/search/?q=libfuse): ```sudo apt install libfuse2```
 * Run the application with `--appimage-extract-and-run` as the first command-line argument.
 * Set the `APPIMAGE_EXTRACT_AND_RUN` environment variable.

The latter two options will cause the appimage to extract the files instead of mounting them directly.
This may take slightly longer and consume more disk space.

### Missing runtime deps
The AppImage will only be as portable/hermetic/reproducible as the rest of your Bazel build is.

Example: Without a hermetic Python toolchain your target will use the system's Python interpreter.
If your program needs Python >=3.8 but you run the appimage on a host that uses Python 3.6 by default, you might get an error like this:
```
  File "/tmp/appimage_extracted_544993ad2a5919e445b618f1fe009e53/test_py.runfiles/rules_appimage/tests/test.py", line 10
    assert (s := DATA_DEP.stat().st_size) == 591, f"{DATA_DEP} has wrong size {s}"
              ^
SyntaxError: invalid syntax
```
Check https://thundergolfer.com/bazel/python/2021/06/25/a-basic-python-bazel-toolchain/ if you would like to know more.


### Something isn't right about my appimage, how can I debug?
An easy way to understand what is happening inside the appimage is to run the application with the `--appimage-extract` cli arg.
This will extract the bundled squashfs blob into a `squashfs-root` dir in the current working directory.

You can look at those files and see exactly what's going on.
In fact, you can even run `squashfs-root/AppRun` and it will run exactly the same as with the packaged appimage.
This can be very handy when rebuilding the Bazel target is not the best option but you need to modify a file inside.
