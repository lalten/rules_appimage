# pycross_compat

One of rules_pycross' features is building sdists into wheels in build actions, rather than in repository rules.
Because of this, it also extracts Python wheels in build actions rather than repository rules, so the only thing added to the dependency graph is a single TreeArtifact containing the contents of the extracted wheel.
See [rules_pycross: wheel_library.bzl](https://github.com/jvolkman/rules_pycross/blob/531c8d21ff859e8b6df7f267eef066150723ec04/pycross/private/wheel_library.bzl#L8)

rules_appimage must ensure that the all of this TreeArtifact's contents are copied and not just symlinked to the bazel cache.

We use a container_structure_test to run a test in an isolated environment where the cache is not available.

Note that this directory is in .bazelignore when testing in Workspace mode in CI
