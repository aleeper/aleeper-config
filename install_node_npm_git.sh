# this way is best if you want to stay up to date
# or submit patches to node or npm

PREFIX=$HOME/webdev/local
mkdir -p ${PREFIX}
echo "Installing to $PREFIX"

echo "export PATH=${PREFIX}/bin:$PATH" >> ~/.bashrc
. ~/.bashrc

# could also fork, and then clone your own fork instead of the official one

git clone git://github.com/aleeper-forks/node.git
cd node
./configure --prefix=$PREFIX
make -j4
make install
cd ..

echo -e "\e[1;32mChecking that node is on the path... \e[0m"
node -v

exit
git clone git://github.com/aleeper-forks/npm.git
cd npm
./configure --prefix=$PREFIX
make -j4
make install # or `make link` for bleeding edge

