# Example Workspace using rules_appimage

This is a simple example workspace that uses rules_appimage to build an AppImage from a py_binary.

`BUILD` contains the definition of a `py_binary` target that is wrapped into an AppImage using the `appimage` rule.

`integration_test.sh` shows how the appimage is built and invoked.
