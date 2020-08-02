FROM buildpack-deps:stretch-curl
MAINTAINER Noah B Johnson <noah@noahbjohnson.net> (https://github.com/noahbjohnson)

# Configure the Go environment, since it's not going to change
ENV PATH   /usr/local/go/bin:$PATH
ENV GOPATH /go

# Inject the remote file fetcher and checksum verifier
ADD assets/fetch.sh /fetch.sh
ENV FETCH /fetch.sh
RUN chmod +x $FETCH

# Install deps
RUN set -x; echo "Starting image build for Debian Stretch" \
 && dpkg --add-architecture arm64                      \
 && dpkg --add-architecture armel                      \
 && dpkg --add-architecture armhf                      \
 && dpkg --add-architecture i386                       \
 && dpkg --add-architecture mips                       \
 && dpkg --add-architecture mipsel                     \
 && dpkg --add-architecture powerpc                    \
 && dpkg --add-architecture ppc64el                    \
 && apt-get update                                     \
 && apt-get install -y -q                              \
        libc6                                          \
        libc6-dev                                      \
#        gcc-multilib                                   \
#        g++-multilib                                   \
        gcc-6-arm-linux-gnueabi                        \
        g++-6-arm-linux-gnueabi                        \
        libc6-dev-armel-cross                          \
        gcc-6-arm-linux-gnueabihf                      \
        g++-6-arm-linux-gnueabihf                      \
        libc6-dev-armhf-cross                          \
        gcc-6-aarch64-linux-gnu                        \
        g++-6-aarch64-linux-gnu                        \
        libc6-dev-arm64-cross                          \
        gcc-6-mips-linux-gnu                           \
        g++-6-mips-linux-gnu                           \
        libc6-dev-mips-cross                           \
        gcc-6-mipsel-linux-gnu                         \
        g++-6-mipsel-linux-gnu                         \
        libc6-dev-mipsel-cross                         \
        gcc-6-mips64-linux-gnuabi64                    \
        g++-6-mips64-linux-gnuabi64                    \
        libc6-dev-mips64-cross                         \
        gcc-6-mips64el-linux-gnuabi64                  \
        g++-6-mips64el-linux-gnuabi64                  \
        libc6-dev-mips64el-cross                       \
        gcc-6-multilib                                 \
        g++-6-multilib                                 \
        gcc-mingw-w64                                  \
        g++-mingw-w64


RUN apt-get install -y -q                              \
        autoconf                                       \
        automake                                       \
        autotools-dev                                  \
        bc                                             \
        binfmt-support                                 \
        binutils-multiarch                             \
        binutils-multiarch-dev                         \
        build-essential                                \
        clang                                          \
        crossbuild-essential-arm64                     \
        crossbuild-essential-armel                     \
        crossbuild-essential-armhf                     \
        crossbuild-essential-mipsel                    \
        crossbuild-essential-ppc64el                   \
        curl                                           \
        devscripts                                     \
        gdb                                            \
        git-core                                       \
        libtool                                        \
        llvm                                           \
        mercurial                                      \
        multistrap                                     \
        patch                                          \
        software-properties-common                     \
        subversion                                     \
        wget                                           \
        xz-utils                                       \
        cmake                                          \
        qemu-user-static                               \
        libxml2-dev                                    \
        lzma-dev                                       \
        openssl                                        \
        libssl-dev                                     \
        libwebkit2gtk-4.0-37                           \
        gtk+3.0                                        \
        openjdk-8-jdk                                  \
        swig                                           \
 && apt-get clean

# Fix any stock package issues
RUN ln -s /usr/include/asm-generic /usr/include/asm

# Install Windows cross-tools
RUN apt-get install -y mingw-w64 \
 && apt-get clean

# Configure the container for Android cross compilation
ENV ANDROID_NDK         android-ndk-r13b
ENV ANDROID_NDK_PATH    http://dl.google.com/android/repository/$ANDROID_NDK-linux-x86_64.zip
ENV ANDROID_NDK_ROOT    /usr/local/$ANDROID_NDK
ENV ANDROID_NDK_LIBC    $ANDROID_NDK_ROOT/sources/cxx-stl/gnu-libstdc++/4.9
ENV ANDROID_PLATFORM    21
ENV ANDROID_CHAIN_ARM   arm-linux-androideabi-4.9
ENV ANDROID_CHAIN_ARM64 aarch64-linux-android-4.9
ENV ANDROID_CHAIN_AMD64 x86_64-4.9
ENV ANDROID_CHAIN_386   x86-4.9

RUN \
  $FETCH $ANDROID_NDK_PATH 0600157c4ddf50ec15b8a037cfc474143f718fd0 && \
  unzip `basename $ANDROID_NDK_PATH` \
    "$ANDROID_NDK/build/*"                                           \
    "$ANDROID_NDK/sources/cxx-stl/gnu-libstdc++/4.9/include/*"       \
    "$ANDROID_NDK/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi*/*" \
    "$ANDROID_NDK/sources/cxx-stl/gnu-libstdc++/4.9/libs/arm64*/*"   \
    "$ANDROID_NDK/sources/cxx-stl/gnu-libstdc++/4.9/libs/x86_64/*"   \
    "$ANDROID_NDK/sources/cxx-stl/gnu-libstdc++/4.9/libs/x86/*"      \
    "$ANDROID_NDK/prebuilt/linux-x86_64/*"                           \
    "$ANDROID_NDK/platforms/*/arch-arm/*"                            \
    "$ANDROID_NDK/platforms/*/arch-arm64/*"                          \
    "$ANDROID_NDK/platforms/*/arch-x86_64/*"                         \
    "$ANDROID_NDK/platforms/*/arch-x86/*"                            \
    "$ANDROID_NDK/toolchains/llvm/*"                                 \
    "$ANDROID_NDK/toolchains/$ANDROID_CHAIN_ARM/*"                   \
    "$ANDROID_NDK/toolchains/$ANDROID_CHAIN_ARM64/*"                 \
    "$ANDROID_NDK/toolchains/$ANDROID_CHAIN_386/*"                   \
    "$ANDROID_NDK/toolchains/$ANDROID_CHAIN_AMD64/*" -d /usr/local > /dev/null && \
  rm -f `basename $ANDROID_NDK_PATH`

ENV PATH /usr/$ANDROID_CHAIN_ARM/bin:$PATH
ENV PATH /usr/$ANDROID_CHAIN_ARM64/bin:$PATH
ENV PATH /usr/$ANDROID_CHAIN_AMD64/bin:$PATH

# setup Android SDK tooling too
ENV ANDROID_SDK_PATH https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
ENV ANDROID_HOME /usr/local/android-sdk

RUN \
    $FETCH $ANDROID_SDK_PATH 92ffee5a1d98d856634e8b71132e8a95d96c83a63fde1099be3d86df3106def9 && \
    unzip `basename $ANDROID_SDK_PATH` \
        -d $ANDROID_HOME > /dev/null && \
    rm -f `basename $ANDROID_SDK_PATH` && \
    echo "Y" | $ANDROID_HOME/tools/bin/sdkmanager "platforms;android-21" "platforms;android-16"

# Install OSx cross-tools

#Build arguments
ARG osxcross_repo="tpoechtrager/osxcross"
ARG osxcross_revision="542acc2ef6c21aeb3f109c03748b1015a71fed63"
ARG darwin_sdk_version="10.10"
ARG darwin_osx_version_min="10.6"
ARG darwin_version="14"
ARG darwin_sdk_url="https://www.dropbox.com/s/yfbesd249w10lpc/MacOSX${darwin_sdk_version}.sdk.tar.xz"

# ENV available in docker image
ENV OSXCROSS_REPO="${osxcross_repo}"                   \
    OSXCROSS_REVISION="${osxcross_revision}"           \
    DARWIN_SDK_VERSION="${darwin_sdk_version}"         \
    DARWIN_VERSION="${darwin_version}"                 \
    DARWIN_OSX_VERSION_MIN="${darwin_osx_version_min}" \
    DARWIN_SDK_URL="${darwin_sdk_url}"

RUN mkdir -p "/tmp/osxcross"                                                                                   \
 && cd "/tmp/osxcross"                                                                                         \
 && curl -sLo osxcross.tar.gz "https://codeload.github.com/${OSXCROSS_REPO}/tar.gz/${OSXCROSS_REVISION}"  \
 && tar --strip=1 -xzf osxcross.tar.gz                                                                         \
 && rm -f osxcross.tar.gz                                                                                      \
 && curl -sLo tarballs/MacOSX${DARWIN_SDK_VERSION}.sdk.tar.xz                                                  \
             "${DARWIN_SDK_URL}"                \
 && yes "" | SDK_VERSION="${DARWIN_SDK_VERSION}" OSX_VERSION_MIN="${DARWIN_OSX_VERSION_MIN}" ./build.sh                               \
 && mv target /usr/osxcross                                                                                    \
 && mv tools /usr/osxcross/                                                                                    \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/omp                                                    \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/osxcross-macports                                      \
 && ln -sf ../tools/osxcross-macports /usr/osxcross/bin/osxcross-mp                                            \
 && rm -rf /tmp/osxcross                                                                                       \
 && rm -rf "/usr/osxcross/SDK/MacOSX${DARWIN_SDK_VERSION}.sdk/usr/share/man"


# Create symlinks for triples and set default CROSS_TRIPLE
ENV LINUX_TRIPLES=arm-linux-gnueabi,arm-linux-gnueabihf,aarch64-linux-gnu,mipsel-linux-gnu,powerpc64le-linux-gnu                  \
    DARWIN_TRIPLES=x86_64h-apple-darwin${DARWIN_VERSION},x86_64-apple-darwin${DARWIN_VERSION},i386-apple-darwin${DARWIN_VERSION}  \
    WINDOWS_TRIPLES=i686-w64-mingw32,x86_64-w64-mingw32                                                                           \
    CROSS_TRIPLE=x86_64-linux-gnu
COPY ./assets/osxcross-wrapper /usr/bin/osxcross-wrapper
RUN mkdir -p /usr/x86_64-linux-gnu;                                                               \
    for triple in $(echo ${LINUX_TRIPLES} | tr "," " "); do                                       \
      for bin in /usr/bin/$triple-*; do                                                           \
        if [ ! -f /usr/$triple/bin/$(basename $bin | sed "s/$triple-//") ]; then                  \
          ln -s $bin /usr/$triple/bin/$(basename $bin | sed "s/$triple-//");                      \
        fi;                                                                                       \
      done;                                                                                       \
      for bin in /usr/bin/$triple-*; do                                                           \
        if [ ! -f /usr/$triple/bin/cc ]; then                                                     \
          ln -s gcc /usr/$triple/bin/cc;                                                          \
        fi;                                                                                       \
      done;                                                                                       \
    done &&                                                                                       \
    for triple in $(echo ${DARWIN_TRIPLES} | tr "," " "); do                                      \
      mkdir -p /usr/$triple/bin;                                                                  \
      for bin in /usr/osxcross/bin/$triple-*; do                                                  \
        ln /usr/bin/osxcross-wrapper /usr/$triple/bin/$(basename $bin | sed "s/$triple-//");      \
      done &&                                                                                     \
      rm -f /usr/$triple/bin/clang*;                                                              \
      ln -s cc /usr/$triple/bin/gcc;                                                              \
      ln -s /usr/osxcross/SDK/MacOSX${DARWIN_SDK_VERSION}.sdk/usr /usr/x86_64-linux-gnu/$triple;  \
    done;                                                                                         \
    for triple in $(echo ${WINDOWS_TRIPLES} | tr "," " "); do                                     \
      mkdir -p /usr/$triple/bin;                                                                  \
      for bin in /etc/alternatives/$triple-* /usr/bin/$triple-*; do                               \
        if [ ! -f /usr/$triple/bin/$(basename $bin | sed "s/$triple-//") ]; then                  \
          ln -s $bin /usr/$triple/bin/$(basename $bin | sed "s/$triple-//");                      \
        fi;                                                                                       \
      done;                                                                                       \
      ln -s gcc /usr/$triple/bin/cc;                                                              \
      ln -s /usr/$triple /usr/x86_64-linux-gnu/$triple;                                           \
    done
# we need to use default clang binary to avoid a bug in osxcross that recursively call himself
# with more and more parameters

ENV LD_LIBRARY_PATH /usr/osxcross/lib:$LD_LIBRARY_PATH

# Inject the new Go root distribution downloader and bootstrapper
ADD assets/bootstrap_pure.sh /bootstrap_pure.sh
ENV BOOTSTRAP_PURE /bootstrap_pure.sh
RUN chmod +x $BOOTSTRAP_PURE

ENV GO_VERSION 11406

ENV ROOT_DIST https://golang.org/dl/go1.14.6.linux-amd64.tar.gz

RUN wget -q $ROOT_DIST && \
    tar -C /usr/local -xzf "go1.14.6.linux-amd64.tar.gz" && \
    rm -f "go1.14.6.linux-amd64.tar.gz"

ENV GOROOT /usr/local/go

RUN $BOOTSTRAP_PURE

# Image metadata
# crossbuild is original entrypoint
# TODO: create CLI handler go script to support both
ENTRYPOINT ["/usr/bin/crossbuild"]
#ENTRYPOINT ["/usr/bin/gobuild"]
CMD ["/bin/bash"]
WORKDIR /workdir
COPY assets/gobuild /usr/bin/gobuild
COPY assets/crossbuild /usr/bin/crossbuild