echo -e "\e[1;32mUpdating packages...\e[0m"

PPA_INSTALLED=`list-repositories | grep -o "ppa:\S*$"`

PPA_LIST=`cat packages/apt-ppa`

for ppa in $PPA_LIST; do
  ppa=`echo $ppa | grep -o "[^']*"`
  if [[ $PPA_INSTALLED != *$ppa* ]]; then
    echo "Adding PPA: $ppa"
    sudo apt-add-repository $ppa
  else
    echo "$ppa is already in the apt sources list."
  fi
done


sudo apt-get update

echo -e "\e[1;32mRunning a dist-upgrade...\e[0m"
sudo apt-get dist-upgrade

echo -e "\e[1;32mInstalling custom packages...\e[0m"
sudo apt-get install \
audacity    \
ccache      \
colorgcc    \
git         \
gscan2pdf   \
libxss1     \
meshlab     \
tree        \
vim         \
pdfmod      \


echo -e "\e[1;32mCopying configuration files...\e[0m"
for f in config/*; do
  dest="../.`basename $f`";
  echo "Copying $f to $dest"
  cp $f $dest;
done

echo -e "\e[1;32mCloning repositories...\e[0m"

if [ -d ./when-changed ]; then
  echo "when-changed is already checked out, skipping"
else
  git clone https://github.com/aleeper/when-changed.git
fi

if [ -d ./google-translate-cli-master ]; then
  echo "google-translate-cli already exists, skipping"
else
  wget https://github.com/soimort/google-translate-cli/archive/master.tar.gz
  tar -xvf master.tar.gz
  cd google-translate-cli-master/
  sudo make install
  cd ..
fi

