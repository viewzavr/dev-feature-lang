#!/bin/bash -x

git pull
git submodule update --init --recursive
git submodule update --recursive