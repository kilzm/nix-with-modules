{ stdenv, lib, oneapi, version, tbb }:

stdenv.mkDerivation rec {
  pname = "intel-oneapi-compilers";
  inherit version;

  phases = [ "installPhase" ];

  buildInputs = [ tbb ];

  propagatedBuildInputs = [ oneapi ];

  compdir = "${oneapi}/compiler/${version}";

  installPhase = ''
    mkdir -p $out/modulefiles
    for dir in documentation env lib licensing linux sys_check; do
      ln -s $compdir/$dir $out/$dir
    done
    cp -r $compdir/modulefiles $out
    ln -s ${tbb}/modulefiles/* $out/modulefiles

    modrc=$out/modulefiles/.modulerc.lua
    echo "-- autogenerated by nix-with-modules" >> $modrc
    for mod in $out/modulefiles/*; do
      echo -e "hide_modulefile(\"$mod\")" >> $modrc
    done
  '';

  meta = {
    description = "Intel OneAPI Thread Building Blocks";
    platforms = lib.platforms.linux;
    license = lib.licenses.unfree;
  };
}