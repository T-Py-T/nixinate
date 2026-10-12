{ pkgs, inputs }:
{
  vmTestLocal = (import ./vmTest { inherit pkgs inputs; }).local;
  vmTestRemote = (import ./vmTest { inherit pkgs inputs; }).remote;
  vmTestLocalHermetic = (import ./vmTest { inherit pkgs inputs; }).localHermetic;
  vmTestRemoteHermetic = (import ./vmTest { inherit pkgs inputs; }).remoteHermetic;
}
