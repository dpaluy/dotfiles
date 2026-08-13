#!/usr/bin/env bash
#
# OMP Plugins
#

OMP_REFLECT_SOURCE="github:praneybehl/omp-reflect#6097b386bdc04fe91f9c334be159dbda730f6504"

if command -v omp &>/dev/null && ask_yes_no "Install or update OMP plugins?" "y"; then
    spin "Installing omp-reflect" omp plugin install --force "$OMP_REFLECT_SOURCE"
fi
