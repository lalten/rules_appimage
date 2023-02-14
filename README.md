# rules_appimage

[![CI status](https://img.shields.io/github/workflow/status/lalten/rules_appimage/CI)](https://github.com/lalten/rules_appimage/actions)
[![MIT License](https://img.shields.io/github/license/lalten/rules_appimage)](https://github.com/lalten/rules_appimage/blob/main/LICENSE)
[![Awesome](https://awesome.re/badge.svg)](https://awesomebazel.com/)

`rules_appimage` provides a [Bazel](https://bazel.build/) rule for packaging existing binary targets into [AppImage](https://github.com/AppImage/AppImageKit) packages.

AppImages are a great match for Bazel because the runfiles structure and launcher stub (where applicable) can be packaged into an AppRun structure relatively easily.
No application source modifications are required.
No existing Bazel targets have to be modified.

The `appimage` rule has been used successfully with `py_binary`, `ruby_binary`, `sh_binary`, and `cc_binary`.
In fact, any *lang*_binary should be compatible.

## Getting Started

### Installation

Add this to your `WORKSPACE`:

```py
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

RULES_APPIMAGE_VER = "1.0.0"

http_archive(
    name = "rules_appimage",
    sha256 = "3a8abc9093eb920f045de1d623bf10f8950c3cf7fb9e13ef35c5d06f634ccb37",
    strip_prefix = "rules_appimage-{}".format(RULES_APPIMAGE_VER),
    urls = ["https://github.com/lalten/rules_appimage/archive/refs/tags/v{}.tar.gz".format(RULES_APPIMAGE_VER)],
)

load("@rules_appimage//:deps.bzl", "rules_appimage_deps")

rules_appimage_deps()
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

```sh
❯ bazel run -- //tests:appimage_py
(...)
Hello, world!
```

```sh
❯ bazel run -- //tests:appimage_py --name TheAssassin
(...)
Hello, TheAssassin!
```

### Directly

The resulting AppImage file is a portable standalone executable (which is kind of the point of the whole thing!)

```sh
❯ file bazel-bin/tests/appimage_py
bazel-bin/tests/appimage_py: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, stripped

❯ bazel-bin/tests/appimage_py --name GitHub
Hello, GitHub!
```

```sh
❯ rsync bazel-bin/tests/appimage_py my-server:. && ssh my-server ./appimage_py
Hello, world!
```

### AppImage CLI args

There are certain [AppImage CLI args](https://github.com/AppImage/AppImageKit#command-line-arguments).
They'll still work. Try `--appimage-help`.

```sh
❯ bazel run -- //tests:appimage_py --appimage-version
(...)
AppImage runtime version: https://github.com/lalten/type2-runtime/releases/tag/build-2022-10-03-c5c7b07
```

## Troubleshooting

### Missing `fusermount`

rules_appimage builds `type-2 AppImages` using a statically-linked appimage runtime.
The only runtime dependency is either `fusermount` (from fuse2) or `fusermount3` (from fuse3).
If neither is not available, you'll get an error like this:

```sh
fuse: failed to exec fusermount3: No such file or directory

Cannot mount AppImage, please check your FUSE setup.
You might still be able to extract the contents of this AppImage
if you run it with the --appimage-extract option.
See https://github.com/AppImage/AppImageKit/wiki/FUSE
for more information
open dir error: No such file or directory
```

In this case, you can:

* Install [libfuse3](https://pkgs.org/search/?q=libfuse3): ```sudo apt install libfuse3```
* Run the application with `--appimage-extract-and-run` as the first command-line argument.
* Set the `APPIMAGE_EXTRACT_AND_RUN` environment variable.

The latter two options will cause the appimage to extract the files instead of mounting them directly.
This may take slightly longer and consume more disk space.

### Missing runtime deps

The AppImage will only be as portable/hermetic/reproducible as the rest of your Bazel build is.

Example: Without a hermetic Python toolchain your target will use the system's Python interpreter.
If your program needs Python >=3.8 but you run the appimage on a host that uses Python 3.6 by default, you might get an error like this:

```sh
  File "/tmp/appimage_extracted_544993ad2a5919e445b618f1fe009e53/test_py.runfiles/rules_appimage/tests/test.py", line 10
    assert (s := DATA_DEP.stat().st_size) == 591, f"{DATA_DEP} has wrong size {s}"
              ^
SyntaxError: invalid syntax
```

Check <https://thundergolfer.com/bazel/python/2021/06/25/a-basic-python-bazel-toolchain/> if you would like to know more.

### Something isn't right about my appimage, how can I debug?

An easy way to understand what is happening inside the appimage is to run the application with the `--appimage-extract` cli arg.
This will extract the bundled squashfs blob into a `squashfs-root` dir in the current working directory.

You can look at those files and see exactly what's going on.
In fact, you can even run `squashfs-root/AppRun` and it will run exactly the same as with the packaged appimage.
This can be very handy when rebuilding the Bazel target is not the best option but you need to modify a file inside.

## Contributing

Issue reports and pull requests are welcome.

Please test your changes:

```sh
bazel test //...
```

And run the [linters](.github/workflows/ci.yaml):

```sh
buildifier -lint=fix -warnings all -r .
markdownlint .
yamllint --strict .
pylint .
pycodestyle .
flake8 .
black .
mypy --install-types .
isort .
vulture .
pydocstyle .
```
