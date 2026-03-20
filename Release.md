# How to release a new rules_appimage version

Create a tag and push it:

```sh
git tag v1.20.0
git push --tags
```

`.github/workflows/release.yaml` will kick off, which calls `release_prep.sh` to build the release archive and stardoc, then creates a GitHub Release with the archive + attestation bundles.
After that, it calls `publish.yaml` to publish to BCR.

Go to <https://github.com/bazelbuild/bazel-central-registry/pulls/lalten> and find the generated PR to update the registry with the new version.
Review it, push changes if something looks wrong.
Click "Ready for review" to merge it (Authors can't approve their own PRs, so there is automation to merge on undrafting).
