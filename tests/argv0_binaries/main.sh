#!/bin/sh

# Print which binary runs, where it runs relative to the AppDir, and its arguments.
echo "main ${PWD#"${APPDIR}"/} ${RUNFILES_DIR#"${APPDIR}"/} $*"
