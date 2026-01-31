"""Test that runfiles from external repos are correctly found through _repo_mapping.

See https://github.com/bazel-contrib/rules_python/blob/1.6.3/python/runfiles/runfiles.py#L134
"""

import os
from pathlib import Path

import pytest
from python.runfiles import runfiles


def test_dir_based() -> None:
    env = os.environ.copy()
    env.pop("RUNFILES_MANIFEST_FILE", None)
    assert "RUNFILES_DIR" in env, "RUNFILES_DIR should have been set in the AppRun"

    r = runfiles.Create(env)
    assert r is not None, "Failed to create runfiles object"

    repo_mapping = r.Rlocation("_repo_mapping")
    assert repo_mapping is not None, "repo_mapping not found"
    assert Path(repo_mapping).is_file(), f"_repo_mapping not found at {repo_mapping}"
    assert repo_mapping.endswith("test.runfiles/_repo_mapping"), f"_repo_mapping at unexpected path {repo_mapping}"

    file = r.Rlocation("appimage_runtime_aarch64/file/downloaded")
    assert file is not None, "runfile not found"
    assert Path(file).is_file(), f"runfile not found at {file}"


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__]))
