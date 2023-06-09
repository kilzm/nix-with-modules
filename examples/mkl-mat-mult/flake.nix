{
  description = "Autogenerated by lmod2flake";

  inputs.lmix.url = github:kilzm/lmix;

  outputs = { self, lmix }:
    let
      system = "x86_64-linux";
      pkgs = lmix.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell.override { stdenv = pkgs.lmix-pkgs.intel21Stdenv; } rec {
        buildInputs = with pkgs; [
          mkl
        ];
        nativeBuildInputs = with pkgs; [
          lmix-pkgs.intel-oneapi-ifort_2021_9_0
        ];
        MKL_BASE="${pkgs.mkl}";
      };
    };

  nixConfig = {
    bash-prompt-prefix = ''[0;36m\[(nix develop)[0m '';
  };
}
