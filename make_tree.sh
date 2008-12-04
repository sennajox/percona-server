pushd $1
hg init && hg add && hg ci -m "initial" && hg qinit
popd
cp -r * $1/.hg/patches
