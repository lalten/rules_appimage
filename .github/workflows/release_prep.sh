#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Argument provided by reusable workflow caller, see
# https://github.com/bazel-contrib/.github/blob/d197a6427c5435ac22e56e33340dff912bc9334e/.github/workflows/release_ruleset.yaml#L72
TAG=$1
# The prefix is chosen to match what GitHub generates for source archives
# This guarantees that users can easily switch from a released artifact to a source archive
# with minimal differences in their code (e.g. strip_prefix remains the same)
prefix="rules_appimage-${TAG:1}"
archive="rules_appimage-$TAG.tar.gz"

# NB: configuration for 'git archive' is in /.gitattributes
git archive --format=tar --prefix="$prefix"/ "$TAG" | gzip >"$archive"
SHA="$(shasum -a 256 "$archive" | awk '{print $1}')"

# Add generated API docs to the release, see https://github.com/bazelbuild/bazel-central-registry/issues/5593
docs="$(mktemp -d)"
targets="$(mktemp)"
bazel --output_base="$docs" query --output=label --output_file="$targets" 'kind("starlark_doc_extract rule", //...)'
bazel --output_base="$docs" build --target_pattern_file="$targets"
tar --create --auto-compress \
    --directory "$(bazel --output_base="$docs" info bazel-bin)" \
    --file "$GITHUB_WORKSPACE/${archive%.tar.gz}.docs.tar.gz" .

cat <<EOF
## Using Bzlmod (recommended)

Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_appimage", version = "${TAG:1}")
\`\`\`

## Using WORKSPACE (deprecated)

Paste this snippet into your \`WORKSPACE.bazel\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_appimage",
    sha256 = "${SHA}",
    strip_prefix = "${prefix}",
    url = "https://github.com/lalten/rules_appimage/releases/download/${TAG}/${archive}",
)

load("@rules_appimage//:deps.bzl", "rules_appimage_deps")

rules_appimage_deps()

register_toolchains("@rules_appimage//appimage:all")
\`\`\`
EOF
