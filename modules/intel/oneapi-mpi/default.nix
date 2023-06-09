{ lib, pkg, cc, ... }:

assert cc == "intel" || cc == "gcc";

with lib;
let
  intelCompilers = [ "intel-oneapi-compilers" "intel-oneapi-classic" ];
  gccCompilers = [ "gcc" ];
in
{
  libName = "mpi";
  libPath = "lib/release";

  prerequisitesAny = if cc == "intel" then intelCompilers else gccCompilers;

  customPacName = "MPI";

  conflicts = [
    "openmpi"
    "intel-mpi"
  ];

  customScriptPath = "${pkg}/env/vars.sh";

  extraEnvVariables = builtins.toJSON ({
    I_MPI_ROOT = "${pkg}";
  } // attrsets.optionalAttrs (cc == "gcc") {
    I_MPI_CC = "gcc";
    I_MPI_CXX = "g++";
  });

  extraLua = if cc == "intel"  then ''
    if ( isloaded ("intel-oneapi-compilers") ) then
      setenv("I_MPI_CC", "icx")
      setenv("I_MPI_CXX", "icpx")
    else
      setenv("I_MPI_CC", "icc")
      setenv("I_MPI_CXX", "icpc")
    end
  '' else "";
}