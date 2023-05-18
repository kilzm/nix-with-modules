{ stdenv, lib, oneapi, version }:

stdenv.mkDerivation rec {
  pname = "intel-oneapi-tbb";
  inherit version;

  phases = [ "installPhase" ];

  propagatedBuildInputs = [ oneapi ];

  tbbdir = "${oneapi}/tbb/${version}";

  installPhase = ''
    mkdir -p $out/modulefiles
    for dir in env  include  lib  licensing; do
      ln -s $tbbdir/$dir $out/$dir
    done

    ln -s $tbbdir/modulefiles/* $out/modulefiles
    
    modrc=$out/modulefiles/.modulerc.lua
    echo "-- autogenerated by nix-with-modules" >> $modrc
    for mod in $out/modulefiles/*; do
      echo -e "hide_modulefile(\"$mod\")" >> $modrc
    done
  '';

  meta = {
    description = "Intel OneAPI C/C++ and Fortran Compilers";
    platforms = lib.platforms.linux;
    license = lib.licenses.unfree;
  };
}