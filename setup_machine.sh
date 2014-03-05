echo -e "\e[1;32mInstalling packages...\e[0m"

sudo apt-get update

sudo apt-get install \
audacity    \
ccache      \
colorgcc    \
git         \
meshlab     \
tree        \
vim         \

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
