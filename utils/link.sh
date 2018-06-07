#!/bin/bash

cd "$(dirname "$0")/.."

[[ ! -d embeds ]] && mkdir -p embeds
[[ ! -L embeds/oUF ]] && ln -s ../oUF embeds/oUF
[[ ! -L embeds/oUF_MovableFrames ]] && ln -s ../oUF_MovableFrames embeds/oUF_MovableFrames
[[ ! -L embeds/oUF_Experience ]] && ln -s ../oUF_Experience embeds/oUF_Experience
