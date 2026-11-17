# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Helpers for collecting target runfiles.

The original source for some of the methods in this file are:
 * _app_layer_impl in https://github.com/bazelbuild/rules_docker/blob/master/lang/image.bzl
 * build_layer in https://github.com/bazelbuild/rules_docker/blob/master/container/layer.bzl
All docker toolchain and layer info provider references were removed and the methods adapted for use in this project.
"""

def _binary_name(ctx):
    """For //foo/bar/baz:blah this would translate to /app/foo/bar/baz/blah"""
    if ctx.attr.binary.label.package:
        return "/".join([ctx.attr.binary.label.package, ctx.attr.binary.label.name])
    return ctx.attr.binary.label.name

def _runfiles_dir(ctx):
    """For @foo//bar/baz:blah this would translate to /app/bar/baz/blah.runfiles"""
    return _binary_name(ctx) + ".runfiles"

def _reference_dir(ctx):
    """The directory relative to which all ".short_path" paths are relative.

    For @foo//bar/baz:blah this would translate to /app/bar/baz/blah.runfiles/foo

    If --enable_bzlmod is on, ctx.workspace_name is the fixed string _main.
    Otherwise, ctx.workspace_name is the workspace name as defined in the WORKSPACE file.
    """
    return "/".join([_runfiles_dir(ctx), ctx.workspace_name])

def _final_emptyfile_path(ctx, name):
    """The final location that this empty file needs to exist at for the foo_binary target to properly execute.

    Examples:
    With --legacy_external_runfiles (default in Bazel <8):
      tests/__init__.py -> tests/test_py.runfiles/_main/tests/__init__.py
      external/__init__.py -> tests/test_py.runfiles/__init__.py
      external/rules_python~/__init__.py -> tools/wheelmaker.runfiles/rules_python~/__init__.py
    With --nolegaxy_external_runfiles (default in Bazel 8+):
      tests/__init__.py -> tests/test_py.runfiles/_main/tests/__init__.py
      ../__init__.py -> tests/test_py.runfiles/__init__.py
      ../rules_python~/__init__.py -> tools/wheelmaker.runfiles/rules_python~/__init__.py
    """
    if name.startswith("external/"):
        relative_name = name[len("external/"):]
    elif name.startswith("../"):
        relative_name = name[len("../"):]
    else:
        # Names that don't start with external or ../ are relative to our own workspace.
        return _reference_dir(ctx) + "/" + name

    # References to workspace-external dependencies, which are identifiable
    # because their path begins with external/ or ../, are inconsistent with the
    # form of their File counterparts, whose ".short_form" is relative to
    #    .../foo.runfiles/workspace-name/  (aka _reference_dir(ctx))
    # whereas we see:
    #    external/foreign-workspace/...
    # so we "fix" the empty files' paths by removing "external/" and basing them
    # directly on the runfiles path.
    return _runfiles_dir(ctx) + "/" + relative_name

def _final_file_path(ctx, f):
    """The final location that this file needs to exist at for the foo_binary target to properly execute."""
    return "/".join([_reference_dir(ctx), f.short_path])

def _final_symlink_path(ctx, sl):
    """The final location that this symlink needs to exist at for the foo_binary target to properly execute."""
    return "/".join([_reference_dir(ctx), sl.path])

def _final_root_symlink_path(ctx, sl):
    """The final location that this root symlink needs to exist at for the foo_binary target to properly execute."""
    return "/".join([_runfiles_dir(ctx), sl.path])

def _default_runfiles(dep):
    return dep[DefaultInfo].default_runfiles.files

def _default_emptyfiles(dep):
    return dep[DefaultInfo].default_runfiles.empty_filenames

def _default_symlinks(dep):
    return dep[DefaultInfo].default_runfiles.symlinks

def _default_root_symlinks(dep):
    return dep[DefaultInfo].default_runfiles.root_symlinks

def get_merged_env(ctx):
    """Take the `binary` env and add the appimage target's env on top of it."""
    env = {}
    if RunEnvironmentInfo in ctx.attr.binary:
        env.update(ctx.attr.binary[RunEnvironmentInfo].environment)
    env.update(ctx.attr.env)
    return env

def get_workdir(ctx):
    return "/".join([_runfiles_dir(ctx), ctx.attr.binary.label.workspace_name or ctx.workspace_name])

def get_entrypoint(ctx):
    return _binary_name(ctx)

def _argv0_executable(name, target):
    executable = target[DefaultInfo].files_to_run.executable
    if not executable:
        fail("argv0_binaries[%r]: %s is not executable" % (name, target.label))
    return executable

def _validate_argv0_name(name):
    if not name or name in (".", "..") or "/" in name:
        fail("argv0_binaries: %r is not a valid file name, which is what $ARGV0 is matched against" % name)

def _rlocation_path(ctx, f):
    """The path of `f` relative to the runfiles root, as accepted by runfiles libraries' Rlocation()."""
    if f.short_path.startswith("../"):
        return f.short_path[len("../"):]
    return "/".join([ctx.workspace_name, f.short_path])

def get_argv0_entrypoints(ctx):
    """Map each `argv0_binaries` name to its executable's path relative to the runfiles root.

    Args:
        ctx: Bazel runtime context

    Returns:
        List of (name, rlocation path) tuples, sorted by name.
    """
    entrypoints = []
    for name, target in sorted(ctx.attr.argv0_binaries.items()):
        _validate_argv0_name(name)
        if name == ctx.label.name:
            fail("argv0_binaries: %r is the name of the appimage itself, so `binary` would never run" % name)
        entrypoints.append((name, _rlocation_path(ctx, _argv0_executable(name, target))))
    return entrypoints

def _merge_repo_mappings(ctx, repo_mapping):
    """Union of the repo mappings of `binary` and all `argv0_binaries`.

    A repo mapping manifest only lists the repositories that contribute runfiles to its own executable, but the merged
    runfiles tree is shared by all executables and has a single `_repo_mapping`.
    """
    others = [t[DefaultInfo].files_to_run.repo_mapping_manifest for t in ctx.attr.argv0_binaries.values()]
    others = depset([m for m in others if m and m != repo_mapping]).to_list()
    if not others:
        return repo_mapping

    merged = ctx.actions.declare_file(ctx.attr.name + ".merged_repo_mapping")
    ctx.actions.run_shell(
        mnemonic = "MergeRepoMapping",
        inputs = [repo_mapping] + others,
        outputs = [merged],
        arguments = [merged.path, repo_mapping.path] + [m.path for m in others],
        command = 'out="$1"; shift; LC_ALL=C sort -u "$@" >"$out"',
    )
    return merged

def collect_runfiles_info(ctx):
    """Collect application files and runfiles.

    Args:
        ctx: Bazel runtime context

    Attrs:
        binary: Target of application whose files to collect
        _directory: Target base directory ("AppDir")

    Returns:
        struct with infos about files needed by app.
    """

    # All executables share the runfiles tree of `binary`, and `data` is made available in it too.
    deps = [ctx.attr.binary] + ctx.attr.data + ctx.attr.argv0_binaries.values()
    argv0_executables = [_argv0_executable(name, t) for name, t in ctx.attr.argv0_binaries.items()]

    # Collect everything that needs to be in the appimage and deduplicate using depset.
    runfiles_list = depset(ctx.files.data + argv0_executables, transitive = [_default_runfiles(d) for d in deps]).to_list()
    file_map = {f.path: _final_file_path(ctx, f) for f in runfiles_list if not f.is_directory}
    repo_mapping = ctx.attr.binary[DefaultInfo].files_to_run.repo_mapping_manifest
    merged_repo_mapping = _merge_repo_mappings(ctx, repo_mapping)

    # Add the repo_mapping but not the runfiles_manifest. We generate our own MANIFEST file.
    file_map.update({merged_repo_mapping.path: repo_mapping.short_path})

    tree_artifacts_map = {f.path: _final_file_path(ctx, f) for f in runfiles_list if f.is_directory}

    # Handle empty_filenames. This is used for some __init__.py files.
    emptyfiles_list = depset(transitive = [_default_emptyfiles(d) for d in deps]).to_list()
    empty_files = [_final_emptyfile_path(ctx, f) for f in emptyfiles_list]

    # Handle symlinks. See https://bazel.build/extending/rules#runfiles_symlinks
    symlinks_list = depset(transitive = [_default_symlinks(d) for d in deps]).to_list()
    symlinks = {_final_symlink_path(ctx, sl): _final_file_path(ctx, sl.target_file) for sl in symlinks_list}

    root_symlinks_list = depset(transitive = [_default_root_symlinks(d) for d in deps]).to_list()
    symlinks.update({_final_root_symlink_path(ctx, sl): _final_file_path(ctx, sl.target_file) for sl in root_symlinks_list})

    # Root symlink target files may not be in default_runfiles.files, must ensure they're in the file map.
    root_symlink_files = [sl.target_file for sl in root_symlinks_list]
    for rslf in root_symlink_files:
        file_map.setdefault(rslf.path, _final_file_path(ctx, rslf))

    symlinks.update({
        # Create a symlink from the entrypoint to where it will actually be put under runfiles.
        get_entrypoint(ctx): _final_file_path(ctx, ctx.executable.binary),
        # Create the --legacy_external_runfiles symlink from <workspace>/external to the runfiles root
        # For @foo//bar/baz:blah this would translate to /app/bar/baz/blah.runfiles/foo/external
        # This is needed until --nolegacy_external_runfiles is not supported anymore
        _reference_dir(ctx) + "/external": _runfiles_dir(ctx),
        # Symlink the _repo_mapping so that runfiles libraries can find it
        _runfiles_dir(ctx) + "/_repo_mapping": repo_mapping.short_path,
    })

    runfiles_manifest = ctx.attr.binary[DefaultInfo].files_to_run.runfiles_manifest
    manifest = struct(
        empty_files = empty_files,
        files = [struct(src = src, dst = dst) for src, dst in file_map.items()],
        files_to_run = {
            "repo_mapping_basename": repo_mapping.basename,
            "runfiles_manifest_short_path": runfiles_manifest.short_path,
        },
        symlinks = [struct(linkname = linkname, target = target) for linkname, target in symlinks.items()],
        tree_artifacts = [struct(src = src, dst = dst) for src, dst in tree_artifacts_map.items()],
    )
    return struct(
        files = runfiles_list + root_symlink_files + [merged_repo_mapping, runfiles_manifest],
        manifest = manifest,
    )
