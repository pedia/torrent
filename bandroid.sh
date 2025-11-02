
# export ANDROID_NDK_ROOT=/Users/mord/Applications/AndroidNDK13750724.app/Contents/NDK
# ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch arm64 --api 21 --stl libc++ --install-dir android-toolchain



export ANDROID_TOOLCHAIN=${PWD}/android-toolchain
export ANDROID_NDK_ROOT=${PWD}/android-toolchain
export PATH=${ANDROID_TOOLCHAIN}/bin:${PATH}
export CC=clang
# TODO: aarch64-linux-android-ar miss?
# TODO: aarch64-linux-android-ranlib miss?
# export AR=llvm-ar

# export OPENSSL_VERSION=3.5.4
# export OPENSSL_OPTS="no-deprecated no-shared no-makedepend -fvisibility=hidden -O3"
# # wget -nv -O openssl.tar.gz https://github.com/openssl/openssl/releases/download/openssl-3.5.4/openssl-3.5.4.tar.gz
# # tar xzf openssl.tar.gz
# cd openssl-${OPENSSL_VERSION}
# # NOTE.ANDROID
# # ./Configure linux-armv4 ${OPENSSL_OPTS} -march=armv7-a -mfpu=neon -fPIC --prefix=${PWD}/../openssl
# ./Configure android-arm64 ${OPENSSL_OPTS} -D__ANDROID_API__=21 -mfpu=neon -fPIC --prefix=${PWD}/../openssl-arm64
# make 
# make install_sw 
# cd ..


export BOOST_ROOT=${HOME}/res/boost_1_81_0
export OPENSSL_ROOT=${PWD}/openssl-arm64

echo "boost-build ${BOOST_ROOT}/tools/build/src ;" > boost-build.jam

rm ~/user-config.jam

echo "using darwin : arm64 : ${ANDROID_TOOLCHAIN}/bin/aarch64-linux-android-clang++
# <cxxflags>-fPIC
# <cxxflags>-march=arm64
# <cxxflags>-mfpu=neon ;" >>~/user-config.jam;

export CXXFLAGS=-DOPENSSL_API_COMPAT=10000

cd bindings/c2
${BOOST_ROOT}/b2 cxxstd=14 target-os=android \
    crypto=openssl openssl-include=${OPENSSL_ROOT}/include openssl-lib=${OPENSSL_ROOT}/lib \
    boost-link=static i2p=on fpic=on link=static runtime-link=static release torrentc

# libc++_shared.so: runtime-link=static
# 

# ${BOOST_ROOT}/b2 cxxstd=14 warnings-as-errors=off target-os=android link=static \
#     crypto=openssl openssl-include=${OPENSSL_ROOT}/include openssl-lib=${OPENSSL_ROOT}/lib
