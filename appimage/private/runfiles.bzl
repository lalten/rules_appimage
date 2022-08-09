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
    """
    return "/".join([_runfiles_dir(ctx), ctx.workspace_name])

def _external_dir(ctx):
    """The special "external" directory which is an alternate way of accessing other repositories.

    For @foo//bar/baz:blah this would translate to /app/bar/baz/blah.runfiles/foo/external
    """
    return "/".join([_reference_dir(ctx), "external"])

def _final_emptyfile_path(ctx, name):
    """The final location that this file needs to exist for the foo_binary target to properly execute."""
    if not name.startswith("external/"):
        # Names that don't start with external are relative to our own workspace.
        return _reference_dir(ctx) + "/" + name

    # References to workspace-external dependencies, which are identifiable
    # because their path begins with external/, are inconsistent with the
    # form of their File counterparts, whose ".short_form" is relative to
    #    .../foo.runfiles/workspace-name/  (aka _reference_dir(ctx))
    # whereas we see:
    #    external/foreign-workspace/...
    # so we "fix" the empty files' paths by removing "external/" and basing them
    # directly on the runfiles path.

    return "/".join([_runfiles_dir(ctx), name[len("external/"):]])

def _final_file_path(ctx, f):
    """The final location that this file needs to exist for the foo_binary target to properly execute."""
    return "/".join([_reference_dir(ctx), f.short_path])

def _layer_emptyfile_path(ctx, name):
    if not name.startswith("external/"):
        # Names that don't start with external are relative to our own workspace.
        return "/".join([ctx.workspace_name, name])

    # References to workspace-external dependencies, which are identifiable
    # because their path begins with external/, are inconsistent with the
    # form of their File counterparts, whose ".short_form" is relative to
    #    .../foo.runfiles/workspace-name/  (aka _reference_dir(ctx))
    # whereas we see:
    #    external/foreign-workspace/...
    # so we "fix" the empty files' paths by removing "external/" and basing them
    # directly on the runfiles path.

    return "/".join([name[len("external/"):]])

def _layer_file_path(ctx, f):
    """The foo_binary independent location in which we store a particular dependency's file such that it can be shared."""
    return "/".join([ctx.workspace_name, f.short_path])

def _default_runfiles(dep):
    return dep[DefaultInfo].default_runfiles.files

def _default_emptyfiles(dep):
    return dep[DefaultInfo].default_runfiles.empty_filenames

def _default_symlinks(dep):
    return dep[DefaultInfo].default_runfiles.symlinks

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
    runfiles_list = _default_runfiles(ctx.attr.binary).to_list()
    file_map = {_final_file_path(ctx, f): f for f in runfiles_list}

    emptyfiles_list = _default_emptyfiles(ctx.attr.binary).to_list()
    empty_files = [_final_emptyfile_path(ctx, f) for f in emptyfiles_list]

    symlinks = {}
    symlinks.update({
        (_reference_dir(ctx) + "/" + s.path): _layer_file_path(ctx, s.target_file)
        for s in _default_symlinks(ctx.attr.binary).to_list()
    })
    symlinks.update({
        _final_file_path(ctx, f): _layer_file_path(ctx, f)
        for f in runfiles_list
        if _final_file_path(ctx, f) not in file_map
    })
    symlinks.update({
        _final_emptyfile_path(ctx, f): _layer_emptyfile_path(ctx, f)
        for f in emptyfiles_list
        if _final_emptyfile_path(ctx, f) not in empty_files
    })
    entrypoint = _binary_name(ctx)
    symlinks.update({
        # Create a symlink from the entrypoint to where it will actually be put under runfiles.
        entrypoint: _final_file_path(ctx, ctx.executable.binary),
        # Create a directory symlink from <workspace>/external to the runfiles root, since they may be accessed via either path.
        _external_dir(ctx): _runfiles_dir(ctx),
    })

    manifest = struct(
        files = [struct(src = f.path, dst = path) for (path, f) in file_map.items()],
        symlinks = [struct(linkname = k, target = symlinks[k]) for k in symlinks],
        empty_files = empty_files,
    )
    workdir = "/".join([_runfiles_dir(ctx), ctx.attr.binary.label.workspace_name or ctx.workspace_name])
    return struct(
        files = runfiles_list,
        manifest = manifest,
        workdir = workdir,
        entrypoint = entrypoint,
    )
