#!/bin/bash

###########################################################################
#  Change values here
#
SDKVERSION=$(xcrun -sdk iphoneos --show-sdk-version);
#
###########################################################################
#
# Don't change anything here
WORKING_DIR="$PWD";

ARCHS="i386 x86_64 armv7 armv7s arm64";
DEVELOPER_ROOT=$(xcode-select -print-path);
MBEDTLS_DIR="$PWD";
BUILD_TYPE="Release" ;
OTHER_CFLAGS="-fPIC" ;

# ======================= options =======================
while getopts "a:b:d:hi:r:s:-" OPTION; do
    case $OPTION in
        a)
            ARCHS="$OPTARG";
        ;;
        b)
            BUILD_TYPE="$OPTARG";
        ;;
        d)
            DEVELOPER_ROOT="$OPTARG";
        ;;
        h)
            echo "usage: $0 [options] -r SOURCE_DIR [-- [cmake options]]";
            echo "options:";
            echo "-a [archs]                    which arch need to built, multiple values must be split by space(default: $ARCHS)";
            echo "-b [build type]               build type(default: $BUILD_TYPE, available: Debug, Release, RelWithDebInfo, MinSizeRel)";
            echo "-d [developer root directory] developer root directory, we use xcode-select -print-path to find default value.(default: $DEVELOPER_ROOT)";
            echo "-h                            help message.";
            echo "-i [option]                   enable bitcode support(available: off, all, bitcode, marker)";
            echo "-s [sdk version]              sdk version, we use xcrun -sdk iphoneos --show-sdk-version to find default value.(default: $SDKVERSION)";
            echo "-r [source dir]               root directory of this library";
            exit 0;
        ;;
        i)
            if [ ! -z "$OPTARG" ]; then
                OTHER_CFLAGS="$OTHER_CFLAGS -fembed-bitcode=$OPTARG";
            else
                OTHER_CFLAGS="$OTHER_CFLAGS -fembed-bitcode";
            fi
        ;;
        r)
            MBEDTLS_DIR="$OPTARG";
        ;;
        s)
            SDKVERSION="$OPTARG";
        ;;
        -)
            break;
            break;
        ;;
        ?)  #当有不认识的选项的时候arg为?
            echo "unkonw argument detected";
            exit 1;
        ;;
    esac
done

shift $(($OPTIND-1));

echo "Ready to build for ios";
echo "WORKING_DIR=${WORKING_DIR}";
echo "ARCHS=${ARCHS}";
echo "DEVELOPER_ROOT=${DEVELOPER_ROOT}";
echo "SDKVERSION=${SDKVERSION}";
echo "make options=$@";

##########
if [ ! -e "$MBEDTLS_DIR/CMakeLists.txt" ]; then
    echo "$MBEDTLS_DIR/CMakeLists.txt not found";
    exit -2;
fi
MBEDTLS_DIR="$(cd "$MBEDTLS_DIR" && pwd)";

# mkdir -p "$WORKING_DIR/bin";
# mkdir -p "$WORKING_DIR/lib";

for ARCH in ${ARCHS}; do
    echo "================== Compling $ARCH ==================";
    if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
        PLATFORM="iPhoneSimulator"
    else
        PLATFORM="iPhoneOS"
    fi

    echo "Building mbedtls for ${PLATFORM} ${SDKVERSION} ${ARCH}"

    echo "Patching Makefile...";
    if [ -e "Makefile.bak" ]; then
        mv -f Makefile.bak Makefile;
    fi

    # sed -i.bak '4d' Makefile;
    echo "Please stand by..."

    export DEVROOT="${DEVELOPER_ROOT}/Platforms/${PLATFORM}.platform/Developer"
    export SDKROOT="${DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"
    export BUILD_TOOLS="${DEVELOPER_ROOT}"
    export GENERATED_DIR="${WORKING_DIR}/build/${PLATFORM}.${ARCH}"
    #export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
    #export CC=${BUILD_TOOLS}/usr/bin/gcc
    #export LD=${BUILD_TOOLS}/usr/bin/ld
    #export CPP=${BUILD_TOOLS}/usr/bin/cpp
    #export CXX=${BUILD_TOOLS}/usr/bin/g++
    #export AR=${DEVROOT}/usr/bin/ar
    #export AS=${DEVROOT}/usr/bin/as
    #export NM=${DEVROOT}/usr/bin/nm
    #export CXXCPP=${BUILD_TOOLS}/usr/bin/cpp
    #export RANLIB=${BUILD_TOOLS}/usr/bin/ranlib
    #export LDFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT}"
    #export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${SDKROOT} -I$MBEDTLS_DIR/include"

    if [ -e $GENERATED_DIR ]; then
        rm -rf $GENERATED_DIR;
    fi

    mkdir -p $GENERATED_DIR;
    cd $GENERATED_DIR;

    # add -DCMAKE_OSX_DEPLOYMENT_TARGET=7.1 to specify the min SDK version
    cmake "$MBEDTLS_DIR" -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_OSX_SYSROOT=$SDKROOT \
        -DCMAKE_SYSROOT=$SDKROOT -DCMAKE_GENERATED_DIR=$GENERATED_DIR\
        -DCMAKE_OSX_ARCHITECTURES=$ARCH -DCMAKE_ARCH=$ARCH -DCMAKE_PLATFORM=$PLATFORM \
        -DCMAKE_C_FLAGS="$OTHER_CFLAGS" \
        "$@";
    cmake --build . ;
done

# cd "$WORKING_DIR";
# echo "Linking and packaging library...";

#for LIB_NAME in "libmbedtls" "libmbedcrypto" "libmbedx509"; do
#    lipo -create $(find "$WORKING_DIR/build" -name $LIB_NAME.a) -output "$WORKING_DIR/build/$ARCH/lib/$LIB_NAME.a";
#done

#if [ -e "$WORKING_DIR/include" ] && [ "$WORKING_DIR" != "$MBEDTLS_DIR" ] ; then
#    rm -rf "$WORKING_DIR/include";
#fi
# cp -rf "$MBEDTLS_DIR/include" "$WORKING_DIR/include";

echo "Building done.";