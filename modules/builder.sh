source $stdenv/setup

shopt -s nullglob

modfile="$out/modules/$modName"
mkdir -p `dirname "$modfile"`

modPrependPath () {
  echo -e "prepend_path(\"$1\", \"$2\")" >> $modfile
}

modPrependPathIfExists () {
  if [[ -d "$2" && " $excludes " != *" $1 "* ]] ; then
      modPrependPath $1 $2
  fi
}

modSetEnv () {
  echo -e "setenv(\"$1\", \"$2\")" >> $modfile
}

addPaths () {
  modPrependPathIfExists "PATH" "$1/bin"
  modPrependPathIfExists "MANPATH" "$1/share/man"
  modPrependPathIfExists "PKG_CONFIG_PATH" "$1/lib/pkgconfig"
  modPrependPathIfExists "PKG_CONFIG_PATH" "$1/share/pkgconfig"
  modPrependPathIfExists "CMAKE_SYSTEM_PREFIX_PATH" "$1/lib/cmake"
  modPrependPathIfExists "PERL5LIB" "$1/lib/perl5/site_perl"

  libs=($1/lib/lib*.so)
  if [[ $addLDLibPath && -n $libs ]] ; then
    modPrependPath "LD_LIBRARY_PATH" "$1/lib"
  fi

  keys=$(jq -r 'keys[]' <<< "$extraPaths")
  for key in $keys ; do
    val=$(jq --arg key "$key" --raw-output '.[$key]' <<< "$extraPaths")
    modPrependPath "$key" "$val"
  done
}

addPkgVariables () {
  # PAC_BASE - base nix store path
  modSetEnv "${pacName}_BASE" "$BASE"
  # PAC_BIN - bin directory
  if [[ -d "$BINDIR" && " $excludes " != *" BIN "* ]] ; then
    modSetEnv "${pacName}_BIN" "$BINDIR"
  fi
  # PAC_LIBDIR - library directory
  if [[ -d "$LIBDIR" && " $excludes " != *" LIBDIR "* ]]; then
    modSetEnv "${pacName}_LIBDIR" "$LIBDIR"
  fi
  # PAC_LIB - setting for static linking
  if [[ -f "$LIBSTATIC" && " $excludes " != *" LIB "* ]] ; then
    modSetEnv "${pacName}_LIB" "$LIBSTATIC"
  fi
  # PAC_SHLIB - setting for dynamic linking
  if [[ -f "$LIBSHARED" && " $excludes " != *" LIB "* ]] ; then
    modSetEnv "${pacName}_SHLIB" "-L$LIBDIR -l$libName"
  fi
  # PAC_INC - include directory
  if [[ -d "$INCDIR" && " $excludes " != *" INC "* ]] ; then
    modSetEnv "${pacName}_INC" "-I$INCDIR"
  fi

  keys=$(jq -r 'keys[]' <<< "$extraPkgVariables")
  for key in $keys ; do
    val=$(jq --arg key "$key" --raw-output '.[$key]' <<< "$extraPkgVariables")
    modSetEnv "${pacName}_$key" "$val"
  done
}

cat > $modfile << EOF
-- $modName
-- autogenerated by nix-with-modules

local pkgName = myModuleName()
local version = myModuleVersion()

depends_on("nix-stdenv")
EOF

modSetEnv "NIXWM_ATTRNAME_${pkgNameUpper}" "${attrName}"
echo >> $modfile

if [[ -n "$customModfilePath" ]]; then
  moddir="$(dirname $customModfilePath)"
  modname="$(basename $customModfilePath)"
  modPrependPath "MODULEPATH" "$moddir"
  echo -e "load(\"$modname\")" >> $modfile
fi

if [[ -n "$customScriptPath" ]]; then
  echo -e "source_sh(\"bash\", \"$customScriptPath\")" >> $modfile
fi

if [[ -n "$dependencies" ]] ; then
  for module in $dependencies ; do
    echo -e "depends_on(\"$module\")" >> $modfile
  done
fi

if [[ -n "$conflicts" ]] ; then
  for module in $conflicts ; do
    echo -e "conflict(\"$module\")" >> $modfile
  done
fi

for i in "$buildInputs" ; do
  addPaths $i
done


echo >> $modfile

addPkgVariables

echo >> $modfile

keys=$(jq -r 'keys[]' <<< "$extraEnvVariables")
for key in $keys ; do
  val=$(jq --arg key "$key" --raw-output '.[$key]' <<< "$extraEnvVariables")
  modSetEnv "$key" "$val"
done
