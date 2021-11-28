#!/bin/bash -ex

echo installing nautilus context menu script

DIR=$( dirname "$(readlink -f "$0")" )
pushd "$DIR"
cp vrungel ~/.local/share/nautilus/scripts/
popd

echo done
