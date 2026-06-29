#!/usr/bin/env bash
# Build the auth broker into one native binary. Needs machin + a C compiler.
set -e
cd "$(dirname "$0")"
machin encode framework/machweb.src framework/sso.src ui.src app.src > app.mfl
machin build app.mfl -o machin-auth
echo "built ./machin-auth — configure with env vars (see README), then run it."
