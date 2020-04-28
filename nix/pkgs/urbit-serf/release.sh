source $setup

cp -r $src ./src
chmod -R u+w ./src
cd src

for dep in $cross_inputs; do
   export CFLAGS="${CFLAGS-} -I$dep/include"
   export LDFLAGS="${LDFLAGS-} -L$dep/lib"
done

CC=$host-gcc                \
PKG_CONFIG=pkg-config-cross \
HOST=$host                  \
bash ./configure

make build/urbit-serf -j8

mkdir -p $out/bin
cp ./build/urbit-serf $out/bin/$exename-serf
