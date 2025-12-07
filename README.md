# rules_appimage

[![CI status](https://img.shields.io/github/actions/workflow/status/lalten/rules_appimage/ci.yaml?branch=main)](https://github.com/lalten/rules_appimage/actions)
[![MIT License](https://img.shields.io/github/license/lalten/rules_appimage)](https://github.com/lalten/rules_appimage/blob/main/LICENSE)
[![Awesome](https://awesome.re/badge.svg)](https://awesomebazel.com/)

Create portable Linux applications by bundling a binary target and all its runfiles into a self-contained [AppImage](https://github.com/AppImage/AppImageKit) binary.

AppImages are a great match for Bazel because the runfiles structure and launcher stub (where applicable) can be packaged into an AppRun structure relatively easily.
No application source modifications are required.
No existing Bazel targets have to be modified.

The `appimage` rule has been used successfully with `py_binary`, `ruby_binary`, `sh_binary`, and `cc_binary`.
In fact, any _lang_\_binary should be compatible.

AppImages are executable ELF format files with a static runtime at the front and a compressed SquashFS image containing the application files at the back.
When run, the runtime will use FUSE to mount the SquashFS image and run the application from there.
Alternatively, the runtime can extract the files into a temporary directory and run the application from there.
There is no extra extraction or installation step.

See also [Alternatives](#alternatives) below.

## Getting Started

### Installation

See the [latest release notes](https://github.com/lalten/rules_appimage/releases/latest) for a snippet to add to your `MODULE.bazel` or `WORKSPACE`.

rules_appimage aims to be compatible and test with the last two [Bazel LTS releases](https://bazel.build/release) but is likely to work with older versions as well.

### Usage

See the [rule documentation](docs/defs.md).

There is an example workspace in [`examples/`](https://github.com/lalten/rules_appimage/blob/main/examples/README.md).

To package a binary target into an AppImage, add an `appimage` rule in a `BUILD` file and point it at the target.

```py
load("@rules_appimage//appimage:appimage.bzl", "appimage")

appimage(
    name = "program.appimage",
    binary = ":program",
)
```

There is also a `appimage_test` rule that takes the same arguments but runs the appimage as a Bazel test target.

## How to run the appimage artifact

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

### `$PWD` is a `Read-only file system`

When the AppImage is run, it will mount contained the SquashFS image via FUSE as read-only file system.

If this causes problems, you can:

- Write to `$BUILD_WORKING_DIRECTORY` instead, which is set by Bazel when running `bazel run`, and set by `rules_appimage` when running as pure AppImage.
- Set the `APPIMAGE_EXTRACT_AND_RUN` env var or pass the `--appimage-extract-and-run` CLI arg to extract the AppImage into a temporary directory and run it from there.

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

- Install [libfuse3](https://pkgs.org/search/?q=libfuse3): `sudo apt install libfuse3`
- Run the application with `--appimage-extract-and-run` as the first command-line argument.
- Set the `APPIMAGE_EXTRACT_AND_RUN` environment variable.

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

## Alternatives

There are a few other good ways to get you application and all its runfiles into a single portable executable.

- python_zip / par_binary / subpar: Only applicable to Python. Needs system Python to extract contained zip on startup, which can be slow for large apps. Bazel's builtin ijar zipper will segfault on very large (multiple GB) runfiles.
- [Kickoff Launcher](https://github.com/nimbus-build/kickoff):
  Very similar idea to appimages, but works also for Windows and macOS.
  Will always extract runfiles, no way to mount them like appimages do with squashfuse.
  No Bazel rules, but a CLI tool that could be used in a `genrule`.
  Check out @alloveras's talk at BazelCon 2023!
- <https://github.com/blaizard/rules_bundle>: Same goal, uses a custom runtime that self-extracts (i.e no self-mounting)

## Contributing

Issue reports and pull requests are welcome.

Please test your changes:

```sh
bazel test //...
```

And run the [linters/formatters](.github/workflows/ci.yaml):

```sh
pre-commit run --all-files
```
