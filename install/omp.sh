#!/usr/bin/env bash
#
# OMP Plugins
#

OMP_REFLECT_SOURCE="github:praneybehl/omp-reflect#6097b386bdc04fe91f9c334be159dbda730f6504"

# OMP and its plugins are opt-in. Merely having omp installed must not install
# plugins during an unrelated dotfiles update.
install_omp="${install_omp:-false}"
if $install_omp && command -v omp &>/dev/null; then
    spin "Installing omp-reflect" omp plugin install --force "$OMP_REFLECT_SOURCE"
fi
