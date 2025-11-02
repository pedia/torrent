# export CXXFLAGS="-I/usr/local/Homebrew/include -I/usr/local/Homebrew/opt/openssl@3/include"
# export LDFLAGS="-L/usr/local/Homebrew/lib -L/usr/local/Homebrew/opt/openssl@3/lib"
export CXXFLAGS="-I/usr/local/Homebrew/include"
export LDFLAGS="-L/usr/local/Homebrew/lib"
# rm ~/user-config.jam

# echo "using darwin ;" >>~/user-config.jam

# b2 crypto=built-in cxxstd=14 boost-link=static i2p=on fpic=on link=static release
cd bindings/c2
b2 crypto=built-in cxxstd=14 boost-link=static i2p=on fpic=on link=static release
