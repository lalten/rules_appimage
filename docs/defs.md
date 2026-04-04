<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="appimage"></a>

## appimage

<pre>
load("@rules_appimage//appimage:defs.bzl", "appimage")

appimage(<a href="#appimage-name">name</a>, <a href="#appimage-data">data</a>, <a href="#appimage-binary">binary</a>, <a href="#appimage-build_args">build_args</a>, <a href="#appimage-env">env</a>)
</pre>

Package your binary into an AppImage.

Inspect intermediate build artifacts with `--output_groups=appimage_debug

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="appimage-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="appimage-data"></a>data |  Any additional data that will be made available inside the appimage   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="appimage-binary"></a>binary |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="appimage-build_args"></a>build_args |  -   | List of strings | optional |  `[]`  |
| <a id="appimage-env"></a>env |  Runtime environment variables. See https://bazel.build/reference/be/common-definitions#common-attributes-tests   | <a href="https://bazel.build/rules/lib/core/dict">Dictionary: String -> String</a> | optional |  `{}`  |


<a id="appimage_test"></a>

## appimage_test

<pre>
load("@rules_appimage//appimage:defs.bzl", "appimage_test")

appimage_test(<a href="#appimage_test-name">name</a>, <a href="#appimage_test-data">data</a>, <a href="#appimage_test-binary">binary</a>, <a href="#appimage_test-build_args">build_args</a>, <a href="#appimage_test-env">env</a>)
</pre>

Package your test target into an AppImage.

Inspect intermediate build artifacts with `--output_groups=appimage_debug

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="appimage_test-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="appimage_test-data"></a>data |  Any additional data that will be made available inside the appimage   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="appimage_test-binary"></a>binary |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | optional |  `None`  |
| <a id="appimage_test-build_args"></a>build_args |  -   | List of strings | optional |  `[]`  |
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


