#!/usr/bin/env bash

nix-build -E '(with import <nixpkgs> {};
 pkgs.callPackage ./test.nix { mkZixDerivation = ((import ./default.nix pkgs).mkZixDerivation); })
' --show-trace;
