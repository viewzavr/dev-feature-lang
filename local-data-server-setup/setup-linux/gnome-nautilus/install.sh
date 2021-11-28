#!/bin/bash -ex

echo installing nautilus context menu script

DIR=$( dirname "$(readlink -f "$0")" )
pushd "$DIR"
cp Vrungel ~/.local/share/nautilus/scripts/
popd

echo done
