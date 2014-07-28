#!/bin/bash

PKG_BASE="git gitk make tree vim"
PKG_BUILD="build-essential ccache colorgcc"
PKG_TOOLS="audacity meshlab gscan2pdf pdfmod"
#  libxss1     \


#if [ 1 -eq 0 ]; then
#  echo -e "\x1B[1;32mUpdating packages...\x1B[0m"
#  PPA_INSTALLED=`list-repositories | grep -o "ppa:\S*$"`
#  PPA_LIST=`cat packages/apt-ppa`
#
#  for ppa in $PPA_LIST; do
#    ppa=`echo $ppa | grep -o "[^']*"`
#    if [[ $PPA_INSTALLED != *$ppa* ]]; then
#      echo -e "Adding PPA: $ppa"
#      sudo apt-add-repository $ppa
#    else
#      echo -e "$ppa is already in the apt sources list."
#    fi
#  done
#fi


function upgrade_packages {
  echo -e "\x1B[1;32mRunning a dist-upgrade...\x1B[0m"
  sudo apt-get update
  sudo apt-get -y dist-upgrade
}

function install_packages {
  echo -e "\x1B[1;32mInstalling packages...\x1B[0m"
  sudo apt-get install -y $PKG_BASE
  sudo apt-get install -y $PKG_BUILD
  sudo apt-get install -y $PKG_TOOLS
}

function copy_config_files {
  echo -e "\x1B[1;32mCopying configuration files...\x1B[0m"
  for f in config/*; do
    dest="$HOME/.`basename $f`";
    echo -e "Copying $f to $dest"
    cp $f $dest;
  done
}


function install_when_changed {
  echo -e "\x1B[1;32mInstalling \"when-changed\"\x1B[0m"
  if [ -d ./when-changed ]; then
    echo -e "when-changed is already checked out, skipping"
  else
    git clone https://github.com/aleeper/when-changed.git
  fi
}

function install_google_translate {
  if [ -d ./google-translate-cli-master ]; then
    echo -e "google-translate-cli already exists, skipping"
  else
    wget https://github.com/soimort/google-translate-cli/archive/master.tar.gz
    tar -xvf master.tar.gz
    cd google-translate-cli-master/
    sudo make install
    cd ..
    rm master.tar.gz
  fi
}



echo -e "\x1B[32mRunning setup script.\x1B[0m"
upgrade_packages
install_packages
copy_config_files
install_when_changed
#install_google_translate
echo -e "\x1B[32mAll done.\x1B[0m"

exit 0;


ARGV0=$0 # First argument is shell command (as in C)
echo -e "Command: $ARGV0"

ARGC=$#  # Number of args, not counting $0
echo -e "Number of args: $ARGC"

while getopts dpf: flag
do
  case $flag in

    d)
      echo debugging on
      ;;
    f)
      file=$OPTARG
      echo filename is $file
      ;;
    p)
      echo -e "option p!"
      ;;
    ?)
      exit
      ;;
  esac
done
shift $(( OPTIND - 1 ))  # shift past the last flag or argument

echo parameters are $*

exit 0
