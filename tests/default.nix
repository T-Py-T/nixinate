{ pkgs, makeTest, inputs, self }:
let
  vmTests = import ./vmTest { inherit pkgs makeTest inputs; };
  evalTests = import ./eval.nix { inherit pkgs self; lib = pkgs.lib; };
  scriptTests = import ./scripts.nix { inherit pkgs self; lib = pkgs.lib; };
in
vmTests
// evalTests
// scriptTests
