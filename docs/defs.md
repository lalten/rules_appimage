<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="appimage"></a>

## appimage

<pre>
load("@rules_appimage//appimage:defs.bzl", "appimage")

appimage(<a href="#appimage-name">name</a>, <a href="#appimage-data">data</a>, <a href="#appimage-argv0_binaries">argv0_binaries</a>, <a href="#appimage-binary">binary</a>, <a href="#appimage-build_args">build_args</a>, <a href="#appimage-env">env</a>)
</pre>

Package your binary into an AppImage.

Inspect intermediate build artifacts with `--output_groups=appimage_debug`

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="appimage-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="appimage-data"></a>data |  Any additional data that will be made available inside the appimage   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="appimage-argv0_binaries"></a>argv0_binaries |  Additional executables to run instead of `binary`, keyed by the name the appimage is invoked as, e.g. `{"my_tool": "//path/to:my_tool"}`.<br><br>The AppImage runtime exports the path the appimage was invoked with as `$ARGV0`. If its basename matches one of the keys, the corresponding executable is run instead of `binary`. This makes it possible to ship several programs in one appimage and select among them with symlinks, e.g. `ln -s my.appimage my_tool`.<br><br>The runfiles of these executables are merged into the runfiles tree of `binary`, so the working directory and `RUNFILES_DIR` are the same whichever executable runs. The environment is that of `binary` combined with `env`; the environment of the executables listed here is not applied.   | Dictionary: String -> Label | optional |  `{}`  |
| <a id="appimage-binary"></a>binary |  The executable that is packaged and run inside the appimage, e.g. `//path/to:my_binary`   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="appimage-build_args"></a>build_args |  Extra arguments passed to `mksquashfs` when building the appimage, e.g. `['-comp', 'xz']`   | List of strings | optional |  `[]`  |
| <a id="appimage-env"></a>env |  Runtime environment variables. See https://bazel.build/reference/be/common-definitions#common-attributes-tests   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `{}`  |


<a id="appimage_test"></a>

## appimage_test

<pre>
load("@rules_appimage//appimage:defs.bzl", "appimage_test")

appimage_test(<a href="#appimage_test-name">name</a>, <a href="#appimage_test-data">data</a>, <a href="#appimage_test-argv0_binaries">argv0_binaries</a>, <a href="#appimage_test-binary">binary</a>, <a href="#appimage_test-build_args">build_args</a>, <a href="#appimage_test-env">env</a>)
</pre>

Package your test target into an AppImage.

Inspect intermediate build artifacts with `--output_groups=appimage_debug`

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="appimage_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="appimage_test-data"></a>data |  Any additional data that will be made available inside the appimage   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="appimage_test-argv0_binaries"></a>argv0_binaries |  Additional executables to run instead of `binary`, keyed by the name the appimage is invoked as, e.g. `{"my_tool": "//path/to:my_tool"}`.<br><br>The AppImage runtime exports the path the appimage was invoked with as `$ARGV0`. If its basename matches one of the keys, the corresponding executable is run instead of `binary`. This makes it possible to ship several programs in one appimage and select among them with symlinks, e.g. `ln -s my.appimage my_tool`.<br><br>The runfiles of these executables are merged into the runfiles tree of `binary`, so the working directory and `RUNFILES_DIR` are the same whichever executable runs. The environment is that of `binary` combined with `env`; the environment of the executables listed here is not applied.   | Dictionary: String -> Label | optional |  `{}`  |
| <a id="appimage_test-binary"></a>binary |  The executable that is packaged and run inside the appimage, e.g. `//path/to:my_binary`   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="appimage_test-build_args"></a>build_args |  Extra arguments passed to `mksquashfs` when building the appimage, e.g. `['-comp', 'xz']`   | List of strings | optional |  `[]`  |
| <a id="appimage_test-env"></a>env |  Runtime environment variables. See https://bazel.build/reference/be/common-definitions#common-attributes-tests   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `{}`  |


<a id="appimage_toolchain"></a>

## appimage_toolchain

<pre>
load("@rules_appimage//appimage:defs.bzl", "appimage_toolchain")

appimage_toolchain(<a href="#appimage_toolchain-name">name</a>, <a href="#appimage_toolchain-appimage_runtime">appimage_runtime</a>)
</pre>

Declare an AppImage toolchain wrapping a platform-specific AppImage runtime binary.

A separate toolchain target should be registered for each supported CPU architecture, constrained to the matching platform, so that the `appimage()` rule automatically selects the correct runtime for the target platform.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="appimage_toolchain-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="appimage_toolchain-appimage_runtime"></a>appimage_runtime |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |


