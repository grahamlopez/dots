#!/bin/bash

# preamble {{{

# Script for installing neovim environment with all of the 3rd-party
# dependencies that come along with my current setup.
# It's assumed that wget and a C/C++ compiler are installed.

# exit on error
set -e

# }}}

##############################################################
# configuration information                                {{{
##############################################################

local_path=$HOME/local
local_path_deps=${local_path}/deps
local_path_apps=${local_path}/apps
local_modules=${local_path}/modulefiles

build_path=/dev/shm/

par_build=24

use_local_modules=false

system=unknown
if [[ $(hostname) =~ "rhea*" ]]; then
  system=rhea
elif [[ "$(uname)" = "Darwin" ]]; then
  system=macos
fi

#######################
# decide what to build

date_version=$(date +%Y.%m.%d)

python3_version=
pynvim_version=
lua_version=5.4.8
luarocks_version=3.12.1
ripgrep_version=14.1.1
fd_version=10.2.0
node_version=22.17.0   # from node.js
cargo_version= # from rust llvm
lazygit_version=
nerdfont_version=
neovim_version=0.11.2

# valid choices are possibly 'src', 'bin', or leave blank to disable
INSTALL_PYTHON3=
INSTALL_PYNVIM='bin'
INSTALL_LUA=
INSTALL_LUAROCKS=
INSTALL_RIPGREP='bin'
INSTALL_FD='bin'
INSTALL_NODE='bin'
INSTALL_CARGO=
INSTALL_LAZYGIT=
INSTALL_NERDFONT=
INSTALL_NEOVIM=

################################
# setup - create our directories

mkdir -p ${build_path}/src ${local_path}/deps ${local_path}/apps ${local_modules}

##############################################################
# }}}
##############################################################

##############################################################
####### Now Modules ######                                 {{{
##############################################################

if [[ $INSTALL_MODULES = 'true' ]]; then

  echo "****************************************************"
  echo "  installing environment modules-${modules_version} "
  echo "****************************************************"
  sleep 5

  cd ${build_path}/src

  # first TCL
  wget https://prdownloads.sourceforge.net/tcl/tcl${tcl_version}-src.tar.gz
  wget https://github.com/cea-hpc/modules/releases/download/v${modules_version}/modules-${modules_version}.tar.gz

  tar xvzf tcl${tcl_version}-src.tar.gz
  cd tcl${tcl_version}/unix

  ./configure --prefix=${local_path_apps}/tcl-${tcl_version}
  make -j${par_build}
  make install

  cd ../..

  tar xvzf modules-${modules_version}.tar.gz
  cd modules-${modules_version}
  CPPFLAGS="-DUSE_INTERP_ERRORLINE" LDFLAGS="-Wl,-rpath=${local_path_apps}/tcl-${tcl_version}/lib" ./configure \
    --prefix=${local_path_apps}/modules-${modules_version} \
    --with-tcl=${local_path_apps}/tcl-${tcl_version}/lib \
    --with-tclsh=${local_path_apps}/tcl-${tcl_version}/bin/tclsh${tcl_ver} \
    --with-tcl-ver=${tcl_ver} \
    --with-tclx-ver=${tcl_ver}
  make -j${par_build}
  make install

  cd ..
  rm -rf tcl${tcl_version} tcl${tcl_version}-src.tar.gz
  rm -rf modules-${modules_version} modules-${modules_version}.tar.gz

fi

############################################################
####### Setup modules for later use and bootstrapping ######
############################################################

if [[ ${use_local_modules} = 'true' ]]; then
  module_init=${local_path_apps}/modules-${modules_version}/init/bash
  #module_init=/usr/share/Modules/init/bash

  source ${module_init}

  module use ${local_modules}
fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now CMAKE ########                                 {{{
##############################################################

if [[ $INSTALL_CMAKE = 'true' ]]; then

  echo "*************************************"
  echo "  installing cmake-${cmake_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  wget https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}-Linux-x86_64.tar.gz
  tar xvzf cmake-${cmake_version}-Linux-x86_64.tar.gz

  # watch out; sometimes they change the capitalization of e.g. 'linux'
  mv cmake-${cmake_version}-linux-x86_64 ${local_path_apps}/cmake-${cmake_version}
  ln -s ${local_path_apps}/cmake-${cmake_version}/bin/cmake ${local_path_apps}/cmake-${cmake_version}/bin/cmake3

  rm ${build_path}/src/cmake-${cmake_version}-Linux-x86_64.tar.gz

  mkdir -p ${local_modules}/cmake
  echo "#%Module 1.0" >${local_modules}/cmake/${cmake_version}
  echo "prepend-path  PATH      ${local_path_apps}/cmake-${cmake_version}/bin" >>${local_modules}/cmake/${cmake_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/cmake-${cmake_version}/man" >>${local_modules}/cmake/${cmake_version}

fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now python3 ######                                 {{{
##############################################################

if [[ $INSTALL_PYTHON3 = 'true' ]]; then

  echo "*************************************"
  echo "  installing python-${python3_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  wget https://www.python.org/ftp/python/${python3_version}/Python-${python3_version}.tar.xz
  tar xvJf Python-${python3_version}.tar.xz
  cd Python-${python3_version}

  ./configure --prefix=${local_path_apps}/python-${python3_version}
  make -j${par_build}
  make install
  cd ../
  rm -rf Python-${python3_version} Python-${python3_version}.tar.xz

  mkdir -p ${local_modules}/python
  echo "#%Module 1.0" >${local_modules}/python/${python3_version}
  echo "prepend-path  PATH      ${local_path_apps}/python-${python3_version}/bin" >>${local_modules}/python/${python3_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/python-${python3_version}/share/man" >>${local_modules}/python/${python3_version}

fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now pynvim ######                                  {{{
##############################################################

if [[ $INSTALL_PYNVIM = 'bin' ]]; then

  echo "*************************************"
  echo "  installing pynvim in a venv        "
  echo "*************************************"
  sleep 5

  if [ ! -d "${local_path_deps}/neovim-venv" ]; then
    python3 -m venv ${local_path_deps}/neovim-venv
    ${local_path_deps}/neovim-venv/bin/pip install pynvim
  else
    echo "python env already installed. skipping."
  fi

fi

if [[ $INSTALL_PYNVIM = 'src' ]]; then
  echo "*************************************"
  echo "  installing pynvim from source      "
  echo "*************************************"
  sleep 5

  echo "This is building a full python3 enviornment, then installing the pynvim module"
  echo "This is not yet implemented. Use the 'bin' installation option or implement this in build_nvim_env.sh"
  exit 1
fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now lua ######                                     {{{
##############################################################

if [[ $INSTALL_LUA = 'src' ]]; then

  echo "*************************************"
  echo "  installing Lua from src            "
  echo "*************************************"
  sleep 5

  echo ##
  echo ## !!!! WARNING: this is untested, as I wasn't using lua directly at the time
  echo ##
  if [ ! -d "${local_path_deps}/lua-${lua_version}" ]; then
    cd ${build_path}/src
    wget "https://www.lua.org/ftp/lua-${lua_version}.tar.gz"
    tar xvf "lua-${lua_version}.tar.gz"
    cd "lua-${lua_version}"

    # Adjust the Makefile for your OS. For Linux:
    make linux MYCFLAGS="-fPIC" INSTALL_TOP="${local_path_deps}/lua-${lua_version}"
    make install INSTALL_TOP="${local_path_deps}/lua-${lua_version}"
  else
    echo "lua already installed. skipping."
  fi

fi

if [[ $INSTALL_LUA = 'bin' ]]; then
  echo "*************************************"
  echo "  installing Lua from binary         "
  echo "*************************************"
  sleep 5

  echo "This is not yet implemented. Use the 'src' installation option or implement this in build_nvim_env.sh"
  exit 1
fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now luarocks ######                                {{{
##############################################################

if [[ $INSTALL_LUAROCKS = 'bin' ]]; then

  echo "*************************************"
  echo "  installing luarocks                "
  echo "*************************************"
  sleep 5

  echo "This is not yet implemented."
  exit 1
fi

if [[ $INSTALL_LUAROCKS = 'src' ]]; then
  echo "*************************************"
  echo "  installing luarocks from src       "
  echo "*************************************"
  sleep 5

  echo "This is not yet implemented. Use the 'bin' installation option or implement this in build_nvim_env.sh"
  exit 1
fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now ripgrep ######                                 {{{
##############################################################

if [[ $INSTALL_RIPGREP = 'bin' ]]; then

  echo "*************************************"
  echo "  installing ripgrep                 "
  echo "*************************************"
  sleep 5

  if [ ! -d "${local_path_deps}/ripgrep-${ripgrep_version}" ]; then
    cd ${build_path}/src
    wget https://github.com/BurntSushi/ripgrep/releases/download/${ripgrep_version}/ripgrep-14.1.1-i686-unknown-linux-gnu.tar.gz
    tar xvzf ripgrep-${ripgrep_version}-i686-unknown-linux-gnu.tar.gz
    mv ripgrep-${ripgrep_version}-i686-unknown-linux-gnu ${local_path_deps}/ripgrep-${ripgrep_version}
    ln -sf ${local_path_deps}/ripgrep-${ripgrep_version}/rg ${local_path}/bin/rg
  else
    echo "ripgrep-${ripgrep_version} already installed. skipping."
  fi

fi

if [[ $INSTALL_RIPGREP = 'src' ]]; then
  echo "*************************************"
  echo "  installing ripgrep from src        "
  echo "*************************************"
  sleep 5

  echo "This is not yet implemented. Use the 'bin' installation option or implement this in build_nvim_env.sh"
  exit 1
fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now fd      ######                                 {{{
##############################################################

if [[ $INSTALL_FD = 'bin' ]]; then

  echo "*************************************"
  echo "  installing fd                      "
  echo "*************************************"
  sleep 5

  if [ ! -d "${local_path_deps}/fd-${fd_version}" ]; then
    cd ${build_path}/src
    wget https://github.com/sharkdp/fd/releases/download/v${fd_version}/fd-v${fd_version}-x86_64-unknown-linux-gnu.tar.gz
    tar xvzf fd-v${fd_version}-x86_64-unknown-linux-gnu.tar.gz
    mv fd-v${fd_version}-x86_64-unknown-linux-gnu ${local_path_deps}/fd-${fd_version}
    ln -sf ${local_path_deps}/fd-${fd_version}/fd ${local_path}/bin/fd
  else
    echo "fd-${fd_version} already installed. skipping."
  fi

fi

if [[ $INSTALL_RIPGREP = 'src' ]]; then
  echo "*************************************"
  echo "  installing fd from src             "
  echo "*************************************"
  sleep 5

  echo "This is not yet implemented. Use the 'bin' installation option or implement this in build_nvim_env.sh"
  exit 1
fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now npm (via node) ######                          {{{
##############################################################

if [[ $INSTALL_NODE = 'bin' ]]; then

  echo "*************************************"
  echo "  installing npm (via node)          "
  echo "*************************************"
  sleep 5

  if [ ! -d "${local_path_deps}/node-${node_version}" ]; then
    cd ${build_path}/src
    wget https://nodejs.org/dist/v${node_version}/node-v${node_version}-linux-x64.tar.xz
    tar xvJf node-v${node_version}-linux-x64.tar.xz
    mv node-v${node_version}-linux-x64 ${local_path_deps}/node-${node_version}
    ln -sf ${local_path_deps}/node-${node_version}/bin/npm ${local_path}/bin/npm
    ln -sf ${local_path_deps}/node-${node_version}/bin/node ${local_path}/bin/node
    ln -sf ${local_path_deps}/node-${node_version}/bin/corepack ${local_path}/bin/corepack
    ln -sf ${local_path_deps}/node-${node_version}/bin/npx ${local_path}/bin/npx
  else
    echo "node-${node_version} already installed. skipping."
  fi

fi

if [[ $INSTALL_RIPGREP = 'src' ]]; then
  echo "*************************************"
  echo "  installing npm from src            "
  echo "*************************************"
  sleep 5

  echo "This is not yet implemented. Use the 'bin' installation option or implement this in build_nvim_env.sh"
  exit 1
fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now nerdfont       ######                          {{{
##############################################################

if [[ $INSTALL_NODE = 'bin' ]]; then

  echo "*************************************"
  echo "  installing npm (via node)          "
  echo "*************************************"
  sleep 5

  if [ ! -d "${local_path_deps}/node-${node_version}" ]; then
    cd ${build_path}/src
    wget https://nodejs.org/dist/v${node_version}/node-v${node_version}-linux-x64.tar.xz
    tar xvJf node-v${node_version}-linux-x64.tar.xz
    mv node-v${node_version}-linux-x64 ${local_path_deps}/node-${node_version}
    ln -sf ${local_path_deps}/node-${node_version}/bin/npm ${local_path}/bin/npm
    ln -sf ${local_path_deps}/node-${node_version}/bin/node ${local_path}/bin/node
    ln -sf ${local_path_deps}/node-${node_version}/bin/corepack ${local_path}/bin/corepack
    ln -sf ${local_path_deps}/node-${node_version}/bin/npx ${local_path}/bin/npx
  else
    echo "node-${node_version} already installed. skipping."
  fi

fi

if [[ $INSTALL_RIPGREP = 'src' ]]; then
  echo "*************************************"
  echo "  installing npm from src            "
  echo "*************************************"
  sleep 5

  echo "This is not yet implemented. Use the 'bin' installation option or implement this in build_nvim_env.sh"
  exit 1
fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now neovim #######                                 {{{
##############################################################

if [[ $INSTALL_NEOVIM = 'true' ]]; then

  echo "*************************************"
  echo "  installing neovim-${neovim_version} "
  echo "*************************************"
  sleep 5

  if [[ ${use_local_modules} = 'true' ]]; then
    module purge
    module load cmake autotools
  fi

  cd ${build_path}/src

  wget https://github.com/neovim/neovim/archive/v${neovim_version}.tar.gz
  tar xvzf v${neovim_version}.tar.gz

  cd neovim-${neovim_version}
  make -j${par_build} CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${local_path_apps}/neovim-${neovim_version} -DCMAKE_BUILD_TYPE=RelWithDebInfo"

  make install
  cd ../
  rm -rf neovim-${neovim_version}
  rm -f v${neovim_version}.tar.gz

  mkdir -p ${local_modules}/nvim
  echo "#%Module 1.0" >${local_modules}/nvim/${neovim_version}
  echo "prepend-path  PATH      ${local_path_apps}/neovim-${neovim_version}/bin" >>${local_modules}/nvim/${neovim_version}
  echo "prepend-path  MANPATH ${local_path_apps}/neovim-${neovim_version}/share/man" >>${local_modules}/nvim/${neovim_version}

fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now neovim (nightly) #########                     {{{
##############################################################

if [[ $INSTALL_NEOVIM_NIGHTLY = 'true' ]]; then

  echo "*************************************"
  echo "  installing neovim-nightly "
  echo "*************************************"
  sleep 5

  if [[ ${use_local_modules} = 'true' ]]; then
    module purge
    module load cmake autotools
  fi

  cd ${build_path}/src

  wget https://github.com/neovim/neovim/archive/nightly.tar.gz
  tar xvzf nightly.tar.gz

  cd neovim-nightly
  make -j${par_build} CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=${local_path_apps}/neovim-${neovim_version_nightly} -DCMAKE_BUILD_TYPE=RelWithDebInfo"

  make install
  cd ../
  rm -rf neovim-nightly
  rm -f nightly.tar.gz

  mkdir -p ${local_modules}/nvim
  echo "#%Module 1.0" >${local_modules}/nvim/${neovim_version_nightly}
  echo "prepend-path  PATH ${local_path_apps}/neovim-${neovim_version_nightly}/bin" >>${local_modules}/nvim/${neovim_version_nightly}
  echo "prepend-path  MANPATH ${local_path_apps}/neovim-${neovim_version_nightly}/share/man" >>${local_modules}/nvim/${neovim_version_nightly}

fi

##############################################################
# }}}
##############################################################
