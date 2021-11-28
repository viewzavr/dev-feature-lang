#!/bin/bash -e

DIR=$( dirname "$(readlink -f "$0")" )
pushd "$DIR"
gnome-nautilus/install.sh
popd
