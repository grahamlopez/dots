#!/bin/bash

# preamble {{{

# Script for installing a minimal, yet up-to-date development environment
# It's assumed that wget and a C/C++ compiler are installed.

# for a brand new ubuntu:18.04 lxc container:
# apt install gcc g++ make cmake autotools-dev automake
# apt install gcc g++ make m4 autoconf
# for neovim
# apt install unzip gettext
# for git
# apt install libssl-dev zlib1g-dev libcurl4-gnutls-dev libexpat1-dev gettext
# yum install zlib-devel openssl-devel libcurl-devel expat-devel gettext-devel perl-ExtUtils-MakeMaker
# for python3
# apt install zlib libffi-dev (for "No module named _ctypes") and libssl-dev (to use e.g. `pip3 install pynvim`)
# for llvm-head
# apt install python3-distutils
# for openblas
# apt install unzip
# for everything
# apt install gcc g++ make cmake autotools-dev automake pkg-config libtool-bin libssl-dev zlib1g-dev libcurl4-gnutls-dev libexpat1-dev gettext libffi-dev python3-distutils unzip

# MGL Notes
# tmux:
# need if "/usr/bin/ld: cannot find -lc" -> need to install glibc-static
# git:
# needs zlib-devel, openssl-devel, libcurl-devel, expat-devel, gettext-devel, perl-ExtUtils-MakeMaker
# (on ubuntu 18.04) apt install libssl-dev zlib1g-dev libcurl4-gnutls-dev libexpat1-dev gettext-devel
# needs asciidoc, makeinfo for documentation
# youcompleteme: on ubuntu 18.04: apt install python2.7-dev

# to fix and wishlist ideas
#
# Enhancements needed
# - move to neovim
# - convert to lmod
# - install llvm man pages
# - full gcc toolchain: ar etc. (https://en.wikipedia.org/wiki/GNU_toolchain)
# - take command line arguments to enable all/single (re)build
# - strip and other space optimizations (upx compression)
# - intel MKL, better instructions where to get, etc.
# - works on mac os
# - clean out fixmes
# - add rofi

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

build_path=/dev/shm

par_build=24

use_local_modules=false

system=unknown
if [[ $(hostname) =~ "rhea*" ]] ; then
  system=rhea
elif [[ "$(uname)" = "Darwin" ]] ; then
  system=macos
fi

#######################
# decide what to build

date_version=$(date +%Y.%m.%d)
tcl_version=8.6.11
tcl_ver=8.6
modules_version=4.7.1
cmake_version=3.20.5
bear_version=${date_version}
autotools_version=${date_version}
tmux_version=3.1b
git_version=${date_version}
neovim_version=0.11.2
neovim_version_nightly=${date_version}
python3_version=3.8.4
zsh_version=5.8
gcc_version=13.2.0
numactl_version=2.0.14
hwloc_version=2.4.0 # tbb_src 2021.2.0 can only use certain versions
tbb_version_src=2021.2.0
tbb_version=2021.2.0
llvm_release_version=18.1.3
llvm_head_version=${date_version}
openblas_version=0.3.15
openmpi_3_version=3.1.6
openmpi_4_version=4.1.6
openmpi_5_version=5.0.3

tmux_static=false # so far, only works on redhat/ubuntu -based systems
                  # but still builds a static executable on gentoo

BUILD_MODULES=false
BUILD_CMAKE=false
BUILD_BEAR=false
BUILD_AUTOTOOLS=false
BUILD_TMUX=false
BUILD_GIT=false
BUILD_PYTHON3=false
BUILD_NEOVIM=true
BUILD_NEOVIM_NIGHTLY=false
BUILD_VIM=false
BUILD_ZSH=false
BUILD_TBB=false
BUILD_TBB_SRC=false
BUILD_GCC=false
BUILD_RELEASE_LLVM=false
BUILD_HEAD_LLVM=false
BUILD_OPENBLAS=false
BUILD_OPENMPI_3=false
BUILD_OPENMPI_4=false
BUILD_OPENMPI_5=false

# deprecated
make_version=4.2.1
BUILD_MAKE=false
vim_version=${date_version}
BUILD_VIM_PLUGINS=false
python2_version=2.7.16
BUILD_PYTHON2=false
rtags_version=${date_version}
BUILD_RTAGS=false
mkl_version=2018.0.128
BUILD_MKL=false

################################
# setup - create our directories

mkdir -p ${build_path}/src ${local_path}/deps ${local_path}/apps ${local_modules}

##############################################################
# }}}
##############################################################



##############################################################
####### Now Modules ######                                 {{{
##############################################################

if [[ $BUILD_MODULES = 'true' ]] ; then

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

if [[ ${use_local_modules} = 'true' ]] ; then
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

if [[ $BUILD_CMAKE = 'true' ]] ; then

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
  echo "#%Module 1.0" > ${local_modules}/cmake/${cmake_version}
  echo "prepend-path  PATH      ${local_path_apps}/cmake-${cmake_version}/bin" >> ${local_modules}/cmake/${cmake_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/cmake-${cmake_version}/man" >> ${local_modules}/cmake/${cmake_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now BEAR    ######                                 {{{
##############################################################

if [[ $BUILD_BEAR = 'true' ]] ; then

  echo "*************************************"
  echo "  installing bear-${bear_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  git clone --depth 1 http://github.com/rizsotto/Bear

  mkdir Bear/build
  cd Bear/build

  cmake -DCMAKE_INSTALL_PREFIX=${local_path_apps}/bear-${bear_version} ..
  make all
  make install

  cd ../..
  rm -rf Bear

  mkdir -p ${local_modules}/bear
  echo "#%Module 1.0" > ${local_modules}/bear/${bear_version}
  echo "prepend-path  PATH      ${local_path_apps}/bear-${bear_version}/bin" >> ${local_modules}/bear/${bear_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/bear-${bear_version}/man" >> ${local_modules}/bear/${bear_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now autotools ######                               {{{
##############################################################

if [[ $BUILD_AUTOTOOLS = 'true' ]] ; then

  echo "*********************************************"
  echo "  installing autotools-${autotools_version} "
  echo "*********************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz
  wget https://ftp.gnu.org/gnu/automake/automake-1.16.3.tar.gz
  wget http://ftpmirror.gnu.org/libtool/libtool-2.4.6.tar.gz
  wget https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz

  # autoconf

  cd ${build_path}/src
  tar xvzf autoconf-*
  cd autoconf-2.71
  ./configure --prefix=${local_path_apps}/autotools-${autotools_version}
  make -j${par_build}
  make install
  cd ..
  rm -rf autoconf-*

  # automake

  cd ${build_path}/src
  tar xvzf automake-*
  cd automake-1.16.3
  ./configure --prefix=${local_path_apps}/autotools-${autotools_version}
  make -j${par_build}
  make install
  cd ..
  rm -rf automake-*

  # libtool

  cd ${build_path}/src
  tar xvzf libtool-*
  cd libtool-2.4.6
  ./configure --prefix=${local_path_apps}/autotools-${autotools_version}
  make -j${par_build}
  make install
  cd ..
  rm -rf libtool-*

  # pkg-config

  cd ${build_path}/src
  tar xvzf pkg-config-*
  cd pkg-config-0.29.2
  #./configure --prefix=${local_path}
  ./configure --prefix=${local_path_apps}/autotools-${autotools_version} --with-internal-glib
  make -j${par_build}
  make install
  cd ..
  rm -rf pkg-config-*

  mkdir -p ${local_modules}/autotools
  echo "#%Module 1.0" > ${local_modules}/autotools/${autotools_version}
  echo "prepend-path  PATH      ${local_path_apps}/autotools-${autotools_version}/bin" >> ${local_modules}/autotools/${autotools_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/autotools-${autotools_version}/share/man" >> ${local_modules}/autotools/${autotools_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now tmux  ########                                 {{{
##############################################################

if [[ $BUILD_TMUX = 'true' ]] ; then

  echo "*************************************"
  echo "  installing tmux-${tmux_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  ## libevent #
  wget https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz
  tar xvzf libevent-*

  cd libevent-2.1.8-stable

  if [[ ${system} = 'macos' ]] ; then
    CFLAGS=-I/usr/local/opt/openssl/include \
    LDFLAGS=-L/usr/local/opt/openssl/lib \
      ./configure --prefix=${local_path_deps} --disable-shared
      make -j${par_build}
  else
    ./configure --prefix=${local_path_deps} --disable-shared
    make install
  fi

  cd ..
  rm -rf libevent-*

  ## ncurses #
  if [[ ${system} != 'macos' ]] ; then
    wget http://invisible-mirror.net/archives/ncurses/current/ncurses.tar.gz
    tar xvzf ncurses.tar.gz
    cd ncurses-*
    CPPFLAGS="-fPIC" ./configure --prefix=${local_path_deps} --enable-pc-files --with-pkg-config-libdir=${local_path_deps}/deps/lib/pkgconfig
    CPPFLAGS="-fPIC" make -j${par_build}
    make install
    cd ..
    rm -rf ncurses*
  fi

  ### tmux #
  wget https://github.com/tmux/tmux/releases/download/${tmux_version}/tmux-${tmux_version}.tar.gz

  tar xvzf tmux-${tmux_version}.tar.gz

  cd tmux-${tmux_version}

  if [[ ${system} = 'macos' ]] ; then # NO static linking with Apple
                                      # https://stackoverflow.com/questions/5259249/creating-static-mac-os-x-c-build
                                      # (and also compat.h problems if linking # against ncurses)

    LDFLAGS="-L${local_path_deps}/lib" \
    CPPFLAGS="-I${local_path_deps}/include" \
    LIBS="-lresolv" \
    PKG_CONFIG_PATH=${local_path_deps}/lib/pkgconfig \
    ./configure --prefix=${local_path_apps}/tmux-${tmux_version}

    LDFLAGS="-L${local_path_deps}/lib" \
    CPPFLAGS="-I${local_path_deps}/include" \
    LIBS="-lresolv" \
    PKG_CONFIG_PATH=${local_path_deps}/lib/pkgconfig \
    make -j${par_build}

  else # in linux, static build should be possible (and preferable)

    TERM_LINK="-L${local_path_deps}/lib -Wl,-rpath=${local_path_deps}/lib -L${local_path_deps}/include/ncurses -Wl,-rpath=${local_path_deps}/include/ncurses -L${local_path_deps}/include -Wl,-rpath=${local_path_deps}/include -levent -lncurses -static -static-libgcc"
    TERM_FLAGS="-I${local_path_deps}/include -I${local_path_deps}/include/ncurses"

    if [[ ${tmux_static} = 'true' ]] ; then
      LIBTINFO_CFLAGS=$TERM_FLAGS \
      LIBTINFO_LIBS=$TERM_LINK \
      LIBNCURSES_CFLAGS=$TERM_FLAGS \
      LIBNCURSES_LIBS=$TERM_LINK \
      CFLAGS=$TERM_FLAGS \
      LDFLAGS=$TERM_LINK \
      ./configure --enable-static --prefix=${local_path_apps}/tmux-${tmux_version}
    else # still builds a static executable on gentoo
      LIBTINFO_CFLAGS=$TERM_FLAGS \
      LIBTINFO_LIBS=$TERM_LINK \
      LIBNCURSES_CFLAGS=$TERM_FLAGS \
      LIBNCURSES_LIBS=$TERM_LINK \
      CFLAGS=$TERM_FLAGS \
      LDFLAGS=$TERM_LINK \
      ./configure --prefix=${local_path_apps}/tmux-${tmux_version}
    fi

    LIBTINFO_CFLAGS=$TERM_FLAGS \
    LIBTINFO_LIBS=$TERM_LINK \
    LIBNCURSES_CFLAGS=$TERM_FLAGS \
    LIBNCURSES_LIBS=$TERM_LINK \
    CFLAGS=$TERM_FLAGS \
    LDFLAGS=$TERM_LINK \
    make -j${par_build}
  fi

  mkdir -p ${local_path_apps}/tmux-${tmux_version}/bin
  mkdir -p ${local_path_apps}/tmux-${tmux_version}/man/man1
  cp tmux ${local_path_apps}/tmux-${tmux_version}/bin
  cp tmux.1 ${local_path_apps}/tmux-${tmux_version}/man/man1

  cd ..
  rm -rf tmux-*

  mkdir -p ${local_modules}/tmux
  echo "#%Module 1.0" > ${local_modules}/tmux/${tmux_version}
  echo "prepend-path  PATH      ${local_path_apps}/tmux-${tmux_version}/bin" >> ${local_modules}/tmux/${tmux_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/tmux-${tmux_version}/man/man1" >> ${local_modules}/tmux/${tmux_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now git at head #######                            {{{
##############################################################

if [[ $BUILD_GIT = 'true' ]] ; then

  echo "*************************************"
  echo "  installing git-${git_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  git clone --depth 1 https://github.com/gitster/git-manpages
  git clone --depth 1 http://github.com/git/git
  cd git

  # if can't find libintl.h --> brew unlink gettext && brew link gettext --force
  if [[ ${system} = 'macos' ]] ; then # disables localization / only get english
    make configure
    ./configure
    make -j${par_build} prefix=${local_path_apps}/git-${git_version} all
  else
    make -j${par_build} prefix=${local_path_apps}/git-${git_version} all
  fi

  make prefix=${local_path_apps}/git-${git_version} install
  mkdir -p ${local_path_apps}/git-${git_version}/man

  cd ..
  mv git-manpages/man1 git-manpages/man5 git-manpages/man7 ${local_path_apps}/git-${git_version}/man

  rm -rf git git-manpages

  mkdir -p ${local_modules}/git
  echo "#%Module 1.0" > ${local_modules}/git/${git_version}
  echo "prepend-path  PATH      ${local_path_apps}/git-${git_version}/bin" >> ${local_modules}/git/${git_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/git-${git_version}/man" >> ${local_modules}/git/${git_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now python3 ######                                 {{{
##############################################################

if [[ $BUILD_PYTHON3 = 'true' ]] ; then

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
  echo "#%Module 1.0" > ${local_modules}/python/${python3_version}
  echo "prepend-path  PATH      ${local_path_apps}/python-${python3_version}/bin" >> ${local_modules}/python/${python3_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/python-${python3_version}/share/man" >> ${local_modules}/python/${python3_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now neovim #######                                 {{{
##############################################################

if [[ $BUILD_NEOVIM = 'true' ]] ; then

  echo "*************************************"
  echo "  installing neovim-${neovim_version} "
  echo "*************************************"
  sleep 5

  if [[ ${use_local_modules} = 'true' ]] ; then
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
  echo "#%Module 1.0" > ${local_modules}/nvim/${neovim_version}
  echo "prepend-path  PATH      ${local_path_apps}/neovim-${neovim_version}/bin" >> ${local_modules}/nvim/${neovim_version}
  echo "prepend-path  MANPATH ${local_path_apps}/neovim-${neovim_version}/share/man" >> ${local_modules}/nvim/${neovim_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now neovim (nightly) #########                     {{{
##############################################################

if [[ $BUILD_NEOVIM_NIGHTLY = 'true' ]] ; then

  echo "*************************************"
  echo "  installing neovim-nightly "
  echo "*************************************"
  sleep 5

  if [[ ${use_local_modules} = 'true' ]] ; then
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
  echo "#%Module 1.0" > ${local_modules}/nvim/${neovim_version_nightly}
  echo "prepend-path  PATH ${local_path_apps}/neovim-${neovim_version_nightly}/bin" >> ${local_modules}/nvim/${neovim_version_nightly}
  echo "prepend-path  MANPATH ${local_path_apps}/neovim-${neovim_version_nightly}/share/man" >> ${local_modules}/nvim/${neovim_version_nightly}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now vim head ########                              {{{
##############################################################

if [[ $BUILD_VIM = 'true' ]] ; then

  echo "*************************************"
  echo "  installing vim-${vim_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  git clone --depth 1 https://github.com/vim/vim.git
  cd vim/src

  # note that it's tough to get simultaneous python2/3 support - bailing for now
  # https://goo.gl/ntKua8
  # https://gist.github.com/odiumediae/3b22d09b62e9acb7788baf6fdbb77cf8
  # https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source

  LDFLAGS="-L${local_path_deps}/lib -L${local_path_deps}/lib64" \
  ./configure --prefix=${local_path_apps}/vim-${vim_version} \
              --enable-cscope \
              --without-x \
              --enable-gui=no \
              --with-tlib=ncurses \
              --enable-pythoninterp \
              --enable-python3interp \
              --with-features=huge

  make -j${par_build}
  make install
  cd ../..
  rm -rf vim

  mkdir -p ${local_modules}/vim
  echo "#%Module 1.0" > ${local_modules}/vim/${vim_version}
  echo "prepend-path  PATH      ${local_path_apps}/vim-${vim_version}/bin" >> ${local_modules}/vim/${vim_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/vim-${vim_version}/share/man" >> ${local_modules}/vim/${vim_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now zsh ##########                                 {{{
##############################################################

if [[ $BUILD_ZSH = 'true' ]] ; then

  echo "*************************************"
  echo "  installing zsh-${zsh_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  wget http://downloads.sourceforge.net/project/zsh/zsh/${zsh_version}/zsh-${zsh_version}.tar.xz
  tar xvJf zsh-${zsh_version}.tar.xz
  cd zsh-${zsh_version}

  CFLAGS="-I${local_path_deps}/include -I${local_path_deps}/include/ncurses" \
  LDFLAGS="-L${local_path_deps}/lib -L${local_path_deps}/include/ncurses -L${local_path_deps}/include -levent" \
  ./configure --prefix=${local_path_apps}/zsh-${zsh_version}

  CPPFLAGS="-I${local_path_deps}/include -I${local_path_deps}/include/ncurses -fPIC" \
  LDFLAGS="-L${local_path_deps}/include -L${local_path_deps}/include/ncurses -L${local_path_deps}/lib -levent" \
  make -j${par_build}

  make install

  cd ..
  rm -rf zsh-${zsh_version} zsh-${zsh_version}.tar.gz

  mkdir -p ${local_modules}/zsh
  echo "#%Module 1.0" > ${local_modules}/zsh/${zsh_version}
  echo "prepend-path  PATH      ${local_path_apps}/zsh-${zsh_version}/bin" >> ${local_modules}/zsh/${zsh_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/zsh-${zsh_version}/share/man" >> ${local_modules}/zsh/${zsh_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now gcc ##########                                 {{{
##############################################################

if [[ $BUILD_GCC = 'true' ]] ; then

  echo "*************************************"
  echo "  installing gcc-${gcc_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  #wget http://www.netgull.com/gcc/releases/gcc-${gcc_version}/gcc-${gcc_version}.tar.gz
  #wget http://bigsearcher.com/mirrors/gcc/releases/gcc-${gcc_version}/gcc-${gcc_version}.tar.gz
  #wget http://mirrors.concertpass.com/gcc/releases/gcc-${gcc_version}/gcc-${gcc_version}.tar.gz
  #tar xvzf gcc-${gcc_version}.tar.gz

  #cd gcc-${gcc_version}
  
  git clone --depth 1 --branch releases/gcc-${gcc_version} git://gcc.gnu.org/git/gcc.git
  
  cd gcc
  ./contrib/download_prerequisites

  mkdir ../build
  cd ../build

  if [[ ${system} = 'macos' ]] ; then
    module load autotools
    ../gcc-${gcc_version}/configure \
      --prefix=${local_path_apps}/gcc-${gcc_version} \
      --enable-languages=c,c++,fortran \
      --enable-checking=release
  else
    ../gcc/configure \
      --prefix=${local_path_apps}/gcc-${gcc_version} \
      --enable-languages=c,c++,fortran \
      --enable-checking=release \
      --disable-multilib
  fi

  make -j${par_build}
  make install

  cd gmp # fixes 'gmp.h' not found message
  make install

  cd ../../
  rm -rf build gcc

  mkdir -p ${local_modules}/gcc
  echo "#%Module 1.0" > ${local_modules}/gcc/${gcc_version}
  echo "conflict  cuda" >> ${local_modules}/gcc/${gcc_version}
  echo "prepend-path  PATH              ${local_path_apps}/gcc-${gcc_version}/bin" >> ${local_modules}/gcc/${gcc_version}
  echo "prepend-path  LD_LIBRARY_PATH   ${local_path_apps}/gcc-${gcc_version}/lib64" >> ${local_modules}/gcc/${gcc_version}
  echo "prepend-path  MANPATH           ${local_path_apps}/gcc-${gcc_version}/share/man" >> ${local_modules}/gcc/${gcc_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now tbb ##########                                 {{{
##############################################################

if [[ $BUILD_TBB = 'true' ]] ; then

  echo "*************************************"
  echo "  installing tbb-${tbb_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  # tbb linux binaries
  wget https://github.com/oneapi-src/oneTBB/releases/download/v${tbb_version}/oneapi-tbb-${tbb_version}-lin.tgz
  tar xvzf oneapi-tbb-${tbb_version}-lin.tgz
  mv oneapi-tbb-${tbb_version} ${local_path_deps}

  mkdir -p ${local_modules}/tbb
  echo "#%Module 1.0" > ${local_modules}/tbb/${tbb_version}
  echo "prepend-path  LD_LIBRARY_PATH ${local_path_deps}/oneapi-tbb-${tbb_version}/lib" >> ${local_modules}/tbb/${tbb_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now tbb_src ##########                             {{{
##############################################################

if [[ $BUILD_TBB_SRC = 'true' ]] ; then

  echo "*************************************"
  echo "  installing tbb-src-${tbb_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  # first libnuma
  wget https://github.com/numactl/numactl/archive/refs/tags/v${numactl_version}.tar.gz
  tar xvzf v${numactl_version}.tar.gz
  cd numactl-${numactl_version}
  ./autogen.sh
  ./configure --prefix=${local_path_deps}/numactl-${hwloc_version}
  make -j${par_build}
  make install

  # then hwloc
  wget https://github.com/open-mpi/hwloc/archive/refs/tags/hwloc-${hwloc_version}.tar.gz
  tar xvzf hwloc-${hwloc_version}.tar.gz
  cd hwloc-hwloc-${hwloc_version}
  ./autogen.sh
  ./configure --prefix=${local_deps}/hwloc-${hwloc_version} HWLOC_NUMA_CFLAGS=-I${local_path_deps}/numactl-${numactl_version}/include HWLOC_NUMA_LIBS=-L${local_path_deps}/numactl-2.0.14/lib ./configure --prefix=${local_path_deps}/hwloc-2.5.0
  make -j${par_build}
  make install

  # now tbb from source
  wget https://github.com/oneapi-src/oneTBB/archive/refs/tags/v${tbb_src_version}.tar.gz
  tar xvzf v${tbb_src_version}.tar.gz
  mkdir oneTBB-${tbb_src_version}/build
  cd oneTBB-${tbb_src_version}/build
  cmake ..  -DCMAKE_HWLOC_2_4_LIBRARY_PATH=${local_path_deps}/hwloc-${hwloc_version}/lib -DCMAKE_HWLOC_2_4_INCLUDE_PATH=${local_path_deps}/hwloc-${hwloc_version}/include

  mkdir -p ${local_modules}/tbb-src
  echo "#%Module 1.0" > ${local_modules}/tbb/${tbb_src_version}
  echo "prepend-path  LD_LIBRARY_PATH ${local_path_deps}/oneapi-tbb-${tbb_src_version}/lib" >> ${local_modules}/tbb-src/${tbb_src_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now LLVM  ########                                 {{{
##############################################################

if [[ $BUILD_RELEASE_LLVM  = 'true' ]] ; then

  echo "*************************************"
  echo "  installing llvm-${llvm_release_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  # contain our mess
  mkdir -p llvm-build-${llvm_release_version}/tarballs
  cd llvm-build-${llvm_release_version}/tarballs

  wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_release_version}/llvm-${llvm_release_version}.src.tar.xz
  wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_release_version}/clang-${llvm_release_version}.src.tar.xz
  wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_release_version}/clang-tools-extra-${llvm_release_version}.src.tar.xz
  wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_release_version}/openmp-${llvm_release_version}.src.tar.xz
  wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_release_version}/compiler-rt-${llvm_release_version}.src.tar.xz
  wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_release_version}/libcxx-${llvm_release_version}.src.tar.xz
  wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_release_version}/libcxxabi-${llvm_release_version}.src.tar.xz
  wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_release_version}/lld-${llvm_release_version}.src.tar.xz

  cd ..

  tar xvf tarballs/llvm-${llvm_release_version}.src.tar.xz
  tar xvf tarballs/clang-${llvm_release_version}.src.tar.xz
  tar xvf tarballs/clang-tools-extra-${llvm_release_version}.src.tar.xz
  tar xvf tarballs/openmp-${llvm_release_version}.src.tar.xz
  tar xvf tarballs/compiler-rt-${llvm_release_version}.src.tar.xz
  tar xvf tarballs/libcxx-${llvm_release_version}.src.tar.xz
  tar xvf tarballs/libcxxabi-${llvm_release_version}.src.tar.xz
  tar xvf tarballs/lld-${llvm_release_version}.src.tar.xz

  mv clang-${llvm_release_version}.src llvm-${llvm_release_version}.src/tools/clang
  mv clang-tools-extra-${llvm_release_version}.src llvm-${llvm_release_version}.src/tools/clang/tools/extra
  mv openmp-${llvm_release_version}.src llvm-${llvm_release_version}.src/projects/openmp
  mv compiler-rt-${llvm_release_version}.src llvm-${llvm_release_version}.src/projects/compiler-rt
  mv libcxx-${llvm_release_version}.src llvm-${llvm_release_version}.src/projects/libcxx
  mv libcxxabi-${llvm_release_version}.src llvm-${llvm_release_version}.src/projects/libcxxabi
  mv lld-${llvm_release_version}.src llvm-${llvm_release_version}.src/tools/lld

  # watch out for these
  # wget http://releases.llvm.org/${llvm_release_version}/test-suite-${llvm_release_version}.src.tar.xz
  # wget http://releases.llvm.org/${llvm_release_version}/lldb-${llvm_release_version}.src.tar.xz
  # git clone http://llvm.org/git/polly.git polly
  # tar xvf tarballs/test-suite-${llvm_release_version}.src.tar.xz
  # tar xvf tarballs/lldb-${llvm_release_version}.src.tar.xz
  # mv test-suite-${llvm_release_version}.src llvm-${llvm_release_version}.src/projects/test-suite
  # mv lldb-${llvm_release_version}.src llvm-${llvm_release_version}.src/tools/lldb
  # mv polly llvm-${llvm_release_version}.src/tools/polly

  mkdir -p build
  cd build

  # module load cmake
  # module list

  cmake -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_CXX_COMPILER=g++ \
        -DCMAKE_INSTALL_PREFIX=${local_path_apps}/llvm-${llvm_release_version} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCOMPILER_RT_INCLUDE_TESTS=OFF \
        -DLLVM_ENABLE_ASSERTIONS=OFF \
        -G "Unix Makefiles" \
        ../llvm-${llvm_release_version}.src

  make -j${par_build}
  #make -j${par_build} check-all
  # on 20 Jan 2018 on gentoo using system gcc64, this recipe resulted in
  # ********************
  # Testing Time: 606.51s
  # ********************
  # Failing Tests (1):
  #     LLVM :: tools/llvm-symbolizer/print_context.c
  #
  #   Expected Passes    : 38480
  #   Expected Failures  : 182
  #   Unsupported Tests  : 1566
  #   Unexpected Failures: 1


  make install

  cd ${build_path}/src
  #rm -rf llvm-build-${llvm_release_version}
  mv llvm-build-${llvm_release_version} $HOME

  mkdir -p ${local_modules}/llvm
  echo "#%Module 1.0" > ${local_modules}/llvm/${llvm_release_version}
  echo "prepend-path  PATH		${local_path_apps}/llvm-${llvm_release_version}/bin" >> ${local_modules}/llvm/${llvm_release_version}
  echo "prepend-path  MANPATH           ${local_path_apps}/llvm-${llvm_release_version}/share/man" >> ${local_modules}/llvm/${llvm_release_version}
  echo "prepend-path  LD_LIBRARY_PATH	${local_path_apps}/llvm-${llvm_release_version}/lib64" >> ${local_modules}/llvm/${llvm_release_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now LLVM at head #######                           {{{
##############################################################

if [[ $BUILD_HEAD_LLVM  = 'true' ]] ; then

  echo "*************************************"
  echo "  installing llvm-${llvm_head_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  mkdir -p llvm-build-${llvm_head_version}
  cd llvm-build-${llvm_head_version}

  git clone --depth 1 https://llvm.org/git/llvm.git
  cd llvm/tools
  git clone --depth 1 https://llvm.org/git/clang.git
  git clone --depth 1 https://llvm.org/git/lld.git
  cd clang/tools
  git clone --depth 1 https://llvm.org/git/clang-tools-extra.git extra
  cd ../../../projects
  git clone --depth 1 https://llvm.org/git/libcxx.git
  git clone --depth 1 https://llvm.org/git/libcxxabi.git
  git clone --depth 1 https://llvm.org/git/compiler-rt.git
  git clone --depth 1 https://llvm.org/git/openmp.git

  cd ../..

  # module load cmake
  # module list

  mkdir -p build
  cd build

  cmake -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_CXX_COMPILER=g++ \
        -DCMAKE_INSTALL_PREFIX=${local_path_apps}/llvm-${llvm_head_version} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCOMPILER_RT_INCLUDE_TESTS=OFF \
        -DLLVM_ENABLE_ASSERTIONS=OFF \
        -G "Unix Makefiles" \
        ../llvm

  make -j${par_build}
  # make -j${par_build} check-all
  # on 19 Jan 2018 on ubuntu 17.10 using system gcc72, this recipe resulted in
  # ********************
  # Testing Time: 539.47s
  # ********************
  # Failing Tests (1):
  #     libc++ :: std/utilities/meta/meta.unary/meta.unary.prop/has_unique_object_representations.pass.cpp
  #
  #   Expected Passes    : 42178
  #   Expected Failures  : 183
  #   Unsupported Tests  : 1257
  #   Unexpected Failures: 1
  #
  # on 16 Mar 2018 on gentoo using system gcc64, this recipe resulted in
  # ********************
  # Testing Time: 777.04s
  # ********************
  # Failing Tests (27):
  #
  # building from head produces variable results, day-to-day

  make install

  cd ${build_path}/src
  #rm -rf llvm-build-${llvm_head_version}
  mv llvm-build-${llvm_head_version} $HOME

  mkdir -p ${local_modules}/llvm
  echo "#%Module 1.0" > ${local_modules}/llvm/${llvm_head_version}
  echo "prepend-path  PATH		${local_path_apps}/llvm-${llvm_head_version}/bin" >> ${local_modules}/llvm/${llvm_head_version}
  echo "prepend-path  MANPATH           ${local_path_apps}/llvm-${llvm_head_version}/share/man" >> ${local_modules}/llvm/${llvm_head_version}
  echo "prepend-path  LD_LIBRARY_PATH	${local_path_apps}/llvm-${llvm_head_version}/lib64" >> ${local_modules}/llvm/${llvm_head_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now openblas ########                              {{{
##############################################################

if [[ $BUILD_OPENBLAS = 'true' ]] ; then

  echo "*************************************"
  echo "  installing openblas-${openblas_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  wget https://github.com/xianyi/OpenBLAS/releases/download/v${openblas_version}/OpenBLAS-${openblas_version}.tar.gz
  tar xvzf OpenBLAS-${openblas_version}.tar.gz
  cd OpenBLAS-${openblas_version}

  make

  make PREFIX=${local_path_apps}/openblas-${openblas_version} install

  cd ..
  rm -rf OpenBLAS-${openblas_version}.tar.gz OpenBLAS-${openblas_version}

  mkdir -p ${local_modules}/openblas
  echo "#%Module 1.0" > ${local_modules}/openblas/${openblas_version}
  echo "prepend-path  LD_LIBRARY_PATH   ${local_path_apps}/openblas-${openblas_version}/lib" >> ${local_modules}/openblas/${openblas_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now openmpi 3 #######                              {{{
##############################################################

if [[ $BUILD_OPENMPI_3 = 'true' ]] ; then

  echo "*************************************"
  echo "  installing openmpi-${openmpi_3_version}"
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  source ${HOME}/local/apps/modules-${modules_version}/init/bash
  module use ${HOME}/local/modulefiles
  module load gcc/${gcc_version}

  wget https://www.open-mpi.org/software/ompi/v3.1/downloads/openmpi-${openmpi_3_version}.tar.bz2
  tar xvjf openmpi-${openmpi_3_version}.tar.bz2
  cd openmpi-${openmpi_3_version}

  ./configure --prefix=${local_path_apps}/openmpi-${openmpi_3_version}
  make -j${par_build} all
  make install

  cd ..
  rm -rf openmpi-${openmpi_3_version} openmpi-${openmpi_3_version}.tar.bz2

  mkdir -p ${local_modules}/openmpi
  echo "#%Module 1.0" > ${local_modules}/openmpi/${openmpi_3_version}
  echo "prepend-path  PATH              ${local_path_apps}/openmpi-${openmpi_3_version}/bin" >> ${local_modules}/openmpi/${openmpi_3_version}
  echo "prepend-path  LD_LIBRARY_PATH   ${local_path_apps}/openmpi-${openmpi_3_version}/lib" >> ${local_modules}/openmpi/${openmpi_3_version}
  echo "prepend-path  MANPATH           ${local_path_apps}/openmpi-${openmpi_3_version}/man" >> ${local_modules}/openmpi/${openmpi_3_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now openmpi 4 #######                              {{{
##############################################################

if [[ $BUILD_OPENMPI_4 = 'true' ]] ; then

  echo "*************************************"
  echo "  installing openmpi-${openmpi_4_version}"
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  source ${HOME}/local/apps/modules-${modules_version}/init/bash
  module use ${HOME}/local/modulefiles
  module load gcc/${gcc_version}

  wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-${openmpi_4_version}.tar.bz2
  tar xvjf openmpi-${openmpi_4_version}.tar.bz2
  cd openmpi-${openmpi_4_version}

  ./configure CC=gcc CXX=g++ --prefix=${local_path_apps}/openmpi-${openmpi_4_version}
  make -j${par_build} all
  make install

  cd ..
  rm -rf openmpi-${openmpi_4_version} openmpi-${openmpi_4_version}.tar.bz2

  mkdir -p ${local_modules}/openmpi
  echo "#%Module 1.0" > ${local_modules}/openmpi/${openmpi_4_version}
  echo "prepend-path  PATH              ${local_path_apps}/openmpi-${openmpi_4_version}/bin" >> ${local_modules}/openmpi/${openmpi_4_version}
  echo "prepend-path  LD_LIBRARY_PATH   ${local_path_apps}/openmpi-${openmpi_4_version}/lib" >> ${local_modules}/openmpi/${openmpi_4_version}
  echo "prepend-path  MANPATH           ${local_path_apps}/openmpi-${openmpi_4_version}/man" >> ${local_modules}/openmpi/${openmpi_4_version}

fi

##############################################################
# }}}
##############################################################



##############################################################
####### Now openmpi 5 #######                              {{{
##############################################################

if [[ $BUILD_OPENMPI_5 = 'true' ]] ; then

  echo "*************************************"
  echo "  installing openmpi-${openmpi_5_version}"
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  source ${HOME}/local/apps/modules-${modules_version}/init/bash
  module use ${HOME}/local/modulefiles
  module load gcc/${gcc_version}

  wget https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-${openmpi_5_version}.tar.bz2
  tar xvjf openmpi-${openmpi_5_version}.tar.bz2
  cd openmpi-${openmpi_5_version}

  ./configure CC=gcc CXX=g++ --prefix=${local_path_apps}/openmpi-${openmpi_5_version}
  make -j${par_build} all
  make install

  cd ..
  rm -rf openmpi-${openmpi_5_version} openmpi-${openmpi_5_version}.tar.bz2

  mkdir -p ${local_modules}/openmpi
  echo "#%Module 1.0" > ${local_modules}/openmpi/${openmpi_5_version}
  echo "prepend-path  PATH              ${local_path_apps}/openmpi-${openmpi_5_version}/bin" >> ${local_modules}/openmpi/${openmpi_5_version}
  echo "prepend-path  LD_LIBRARY_PATH   ${local_path_apps}/openmpi-${openmpi_5_version}/lib" >> ${local_modules}/openmpi/${openmpi_5_version}
  echo "prepend-path  MANPATH           ${local_path_apps}/openmpi-${openmpi_5_version}/man" >> ${local_modules}/openmpi/${openmpi_5_version}
fi

##############################################################
# }}}
##############################################################



##############################################################
#################     deprecated                ########## {{{
##############################################################

##############################################################
####### Now make    ######                                 {{{
##############################################################

if [[ $BUILD_MAKE = 'true' ]] ; then

  echo "*************************************"
  echo "  installing gnu make-${make_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  wget https://ftp.gnu.org/gnu/make/make-${make_version}.tar.bz2
  tar xvjf make-${make_version}.tar.bz2
  cd make-${make_version}

  ./configure --prefix=${local_path_apps}/make-${make_version}
  make -j${par_build}
  make install

  cd ..
  rm -rf make-${make_version} make-${make_version}.tar.bz2


  mkdir -p ${local_modules}/make
  echo "#%Module 1.0" >> ${local_modules}/make/${make_version}
  echo "prepend-path  PATH      ${local_path_apps}/make-${make_version}/bin" >> ${local_modules}/make/${make_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/make-${make_version}/share/man" >> ${local_modules}/make/${make_version}

fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now Intel MKL #########                            {{{
##############################################################

if [[ $BUILD_MKL = 'true' ]] ; then

  # --------------------------------------------------------------------------------
  # The install directory path was changed to
  # /home/bgl/local/apps/mkl-2018.0.128
  # because at least one software product component was detected as having already
  # been installed on the system.
  # --------------------------------------------------------------------------------
  # Please select at least one component before you continue.
  # --------------------------------------------------------------------------------
  #
  # if this message comes up, rm -rf ~/intel/intel_sdp_products.db and ~/intel/.pset

  echo "*************************************"
  echo "  installing MKL-${mkl_version} "
  echo "*************************************"
  sleep 5
  # module purge

  mkl_tarball_path=~/.mgl_configs/tarballs
  mkl_package=l_mkl_${mkl_version}

  cd ${build_path}/src

  tar xvzf ${mkl_tarball_path}/${mkl_package}.tgz
  cd ${mkl_package}

  cp silent.cfg _bak_silent.cfg

  echo "# Patterns used to check silent configuration file" > silent.cfg
  echo "#" >> silent.cfg
  echo "# anythingpat - any string" >> silent.cfg
  echo "# filepat     - the file location pattern (/file/location/to/license.lic)" >> silent.cfg
  echo "# lspat       - the license server address pattern (0123@hostname)" >> silent.cfg
  echo "# snpat       - the serial number pattern (ABCD-01234567)" >> silent.cfg
  echo "" >> silent.cfg
  echo "# Accept EULA, valid values are: {accept, decline}" >> silent.cfg
  echo "ACCEPT_EULA=accept" >> silent.cfg
  echo "" >> silent.cfg
  echo "# Optional error behavior, valid values are: {yes, no}" >> silent.cfg
  echo "CONTINUE_WITH_OPTIONAL_ERROR=yes" >> silent.cfg
  echo "" >> silent.cfg
  echo "# Install location, valid values are: {/opt/intel, filepat}" >> silent.cfg
  echo "PSET_INSTALL_DIR=${local_path_apps}/mkl-${mkl_version}" >> silent.cfg
  echo "" >> silent.cfg
  echo "# Continue with overwrite of existing installation directory, valid values are: {yes, no}" >> silent.cfg
  echo "CONTINUE_WITH_INSTALLDIR_OVERWRITE=yes" >> silent.cfg
  echo "" >> silent.cfg
  echo "# List of components to install, valid values are: {ALL, DEFAULTS, anythingpat}" >> silent.cfg
  echo "COMPONENTS=DEFAULTS" >> silent.cfg
  echo "" >> silent.cfg
  echo "# Installation mode, valid values are: {install, repair, uninstall}" >> silent.cfg
  echo "PSET_MODE=install" >> silent.cfg
  echo "" >> silent.cfg
  echo "# Directory for non-RPM database, valid values are: {filepat}" >> silent.cfg
  echo "#NONRPM_DB_DIR=filepat" >> silent.cfg
  echo "" >> silent.cfg
  echo "# Path to the cluster description file, valid values are: {filepat}" >> silent.cfg
  echo "#CLUSTER_INSTALL_MACHINES_FILE=filepat" >> silent.cfg
  echo "" >> silent.cfg
  echo "# Perform validation of digital signatures of RPM files, valid values are: {yes, no}" >> silent.cfg
  echo "SIGNING_ENABLED=yes" >> silent.cfg
  echo "" >> silent.cfg
  echo "# Select target architecture of your applications, valid values are: {IA32, INTEL64, ALL}" >> silent.cfg
  echo "ARCH_SELECTED=ALL" >> silent.cfg

  ./install.sh -s silent.cfg

  cd ..
  rm -rf l_mkl_${mkl_version}

  mkdir -p ${local_modules}/mkl
  echo "#%Module 1.0" > ${local_modules}/mkl/${mkl_version}
  echo "setenv        MKLROOT           ${local_path_apps}/mkl-${mkl_version}/compilers_and_libraries_${mkl_version}/linux/mkl" >> ${local_modules}/mkl/${mkl_version}
  echo "prepend-path  LD_LIBRARY_PATH   ${local_path_apps}/mkl-${mkl_version}/compilers_and_libraries_${mkl_version}/linux/tbb/lib/intel64_lin/gcc4.7:${local_path_apps}/mkl-${mkl_version}/compilers_and_libraries_${mkl_version}/linux/compiler/lib/intel64_lin:${local_path_apps}/mkl-${mkl_version}/compilers_and_libraries_${mkl_version}/linux/mkl/lib/intel64_lin" >> ${local_modules}/mkl/${mkl_version}
  echo "prepend-path  LIBRARY_PATH      ${local_path_apps}/mkl-${mkl_version}/compilers_and_libraries_${mkl_version}/linux/tbb/lib/intel64_lin/gcc4.7:${local_path_apps}/mkl-${mkl_version}/compilers_and_libraries_${mkl_version}/linux/compiler/lib/intel64_lin:${local_path_apps}/mkl-${mkl_version}/compilers_and_libraries_${mkl_version}/linux/mkl/lib/intel64_lin" >> ${local_modules}/mkl/${mkl_version}
  echo "setenv        NLSPATH           ${local_path_apps}/mkl-${mkl_version}/compilers_and_libraries_${mkl_version}/linux/mkl/lib/intel64_lin/locale/%l_%t/%N" >> ${local_modules}/mkl/${mkl_version}
  echo "setenv        CPATH             ${local_path_apps}/mkl-${mkl_version}/compilers_and_libraries_${mkl_version}/linux/mkl/include" >> ${local_modules}/mkl/${mkl_version}

fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now python2 ######                                 {{{
##############################################################
if [[ $BUILD_PYTHON2 = 'true' ]] ; then

  echo "*************************************"
  echo "  installing python-${python2_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  wget https://www.python.org/ftp/python/${python2_version}/Python-${python2_version}.tar.xz
  tar xvJf Python-${python2_version}.tar.xz
  cd Python-${python2_version}

  ./configure --prefix=${local_path_apps}/python-${python2_version}
  make -j${par_build}
  make install

  cd ../
  rm -rf Python-${python2_version} Python-${python2_version}.tar.xz

  mkdir -p ${local_modules}/python
  echo "#%Module 1.0" > ${local_modules}/python/${python2_version}
  echo "prepend-path  PATH      ${local_path_apps}/python-${python2_version}/bin" >> ${local_modules}/python/${python2_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/python-${python2_version}/share/man" >> ${local_modules}/python/${python2_version}

fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now the vim plugins ######                         {{{
##############################################################
if [[ $BUILD_VIM_PLUGINS = 'true' ]] ; then

  echo "*************************************"
  echo "  installing vim plugins  "
  echo "*************************************"
  sleep 5
  # module purge

  # prepare the plugins dir (backup if necessary)
  if [[ -e ${HOME}/.vim/pack/dist/start ]] ; then
    mv ${HOME}/.vim/pack/dist/start ${HOME}/vim_plugins_backup_${date_version}
  fi

  mkdir -p ${HOME}/.vim/pack/dist/start
  cd ${HOME}/.vim/pack/dist/start

  # get the plugins
  for pluginurl in ${VIM_PLUGIN_LIST}
  do
    git clone --recursive --depth 1 http://github.com/${pluginurl}
    plugin=$(basename ${pluginurl})
    cd ${plugin}
    vim -c "helptags doc/" -c q
    cd ..
  done

  for bob in $(find . -name .git) ; do rm -rf ${bob} ; done

  # set up youcompleteme
  # libclang=${local_path_apps}/llvm-${llvm_release_version}/lib/libclang.so
  libclang=/usr/lib/llvm-6.0/lib/libclang.so.1
  if [[ -e ${libclang} ]] ; then
    cd youcompleteme
    mkdir ycm_build && cd ycm_build
    cmake -G "Unix Makefiles" -DEXTERNAL_LIBCLANG_PATH=${libclang} ../third_party/ycmd/cpp
    cmake --build . --target ycm_core
  else
    echo "point me to libclang.so"
  fi

fi

##############################################################
# }}}
##############################################################

##############################################################
####### Now rtags   ######                                 {{{
##############################################################

if [[ $BUILD_RTAGS = 'true' ]] ; then

  echo "*************************************"
  echo "  installing rtags-${rtags_version} "
  echo "*************************************"
  sleep 5
  # module purge

  cd ${build_path}/src

  git clone --depth 1 --recursive https://github.com/Andersbakken/rtags.git

  module load cmake
  module load llvm # disable to build against system llvm 6.0.0 on ubuntu 17.10

  mkdir -p build
  cd build

  cmake -DCMAKE_C_COMPILER=gcc \
        -DLIBCLANG_LLVM_CONFIG_EXECUTABLE=llvm-config \
        -DLIBCLANG_CXXFLAGS="$(llvm-config --cxxflags) -fexceptions" \
        -DLIBCLANG_LIBDIR="$(llvm-config --libdir)" \
        -DCMAKE_INSTALL_PREFIX=${local_path_apps}/rtags-${rtags_version} \
        ../rtags
  # let rtags build its own llvm/clang
  # cmake -DCMAKE_C_COMPILER=gcc \
  #       -DCMAKE_INSTALL_PREFIX=${local_path_apps}/rtags-${rtags_version} \
  #       -DRTAGS_BUILD_CLANG=1 \
  #       ../rtags

  make -j${par_build}
  make install

  # enable gcc wrapper
  ln -s ${local_path_apps}/rtags-${rtags_version}/bin/gcc-rtags-wrapper.sh ${local_path_apps}/rtags-${rtags_version}/bin/gcc
  ln -s ${local_path_apps}/rtags-${rtags_version}/bin/gcc-rtags-wrapper.sh ${local_path_apps}/rtags-${rtags_version}/bin/g++

  cd ..
  rm -rf build rtags

  mkdir -p ${local_modules}/rtags
  echo "#%Module 1.0" > ${local_modules}/rtags/${rtags_version}
  echo "prepend-path  PATH      ${local_path_apps}/rtags-${rtags_version}/bin" >> ${local_modules}/rtags/${rtags_version}
  echo "prepend-path  MANPATH   ${local_path_apps}/rtags-${rtags_version}/share/man" >> ${local_modules}/rtags/${rtags_version}

fi

##############################################################
# }}}
##############################################################

##############################################################
# }}}
##############################################################
