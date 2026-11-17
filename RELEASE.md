# How to release a new rules_appimage version

Create a tag and push it:

```sh
git tag v1.21.0
git push --tags
```

`.github/workflows/release.yaml` will kick off and do the rest:

1. Call `release_prep.sh` to build the release archive and stardoc, and create a **draft** GitHub Release with the archive + attestation bundles (uses [immutable releases](https://github.blog/changelog/2025-10-28-immutable-releases-are-now-generally-available/)).
1. Call `publish.yaml`, which generates the BCR entry, uploads its attestations to the draft release and pushes the entry to the BCR fork.
1. Publish the draft release. From here on the release is immutable.
1. Open the BCR pull request. This happens last because the BCR presubmit downloads the release archive, which is not publicly available while the release is a draft.

Go to <https://github.com/bazelbuild/bazel-central-registry/pulls/lalten> and find the generated PR to update the registry with the new version.
Review it, push changes if something looks wrong.
Click "Ready for review" to merge it (Authors can't approve their own PRs, so there is automation to merge on undrafting).

If a step fails before the release is published, fix the problem and re-run the failed jobs; the release is still a draft.
