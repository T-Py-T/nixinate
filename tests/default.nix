{ pkgs, makeTest, inputs, self }:
let
  vmTests = import ./vmTest { inherit pkgs makeTest inputs; };
  evalTests = import ./eval.nix { inherit pkgs self; };
  scriptTests = import ./scripts.nix { inherit pkgs self; };
in
vmTests
// evalTests
// scriptTests
