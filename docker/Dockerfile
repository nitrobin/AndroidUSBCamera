# Reproducible build environment for AndroidUSBCamera.
#
# Pinned to linux/amd64 on purpose: the Android SDK command-line tools,
# build-tools, CMake and NDK are published as x86_64 Linux binaries only,
# so an arm64 image cannot run them. On Apple Silicon this runs emulated.
ARG BUILD_PLATFORM=linux/amd64
FROM --platform=$BUILD_PLATFORM eclipse-temurin:11-jdk-jammy

# Gradle 6.7.1 / AGP 4.2.2 need JDK 11. sdkmanager itself needs JDK 17,
# so a second JDK is installed just to drive it.
# make and file are what ndk-build shells out to; without them libuvc's
# hand-rolled ndkBuild task fails with "GNUMAKE" / "file: command not found".
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl unzip rsync git openjdk-17-jdk-headless \
        make file \
    && rm -rf /var/lib/apt/lists/*

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT

ARG CMDLINE_TOOLS_VERSION=11076708
RUN mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools" \
    && curl -fsSL -o /tmp/tools.zip \
       "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip" \
    && unzip -q /tmp/tools.zip -d /tmp/cmdline \
    && mv /tmp/cmdline/cmdline-tools "$ANDROID_SDK_ROOT/cmdline-tools/latest" \
    && rm -rf /tmp/tools.zip /tmp/cmdline

# platform 31: required by appcompat 1.4.1 (compileSdk).
# platform 29: targetSdk.
# cmake 3.10.2: version requested by libnative/build.gradle.
# ndk 21.4.7075529: default NDK for AGP 4.2.2.
# JAVA_HOME is exported for the whole layer on purpose: a "VAR=x cmd | other"
# prefix would only reach the left-hand side of the pipe, not sdkmanager.
# The image's own JAVA_HOME (JDK 11, what Gradle needs) is untouched.
RUN export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    && yes | "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --licenses > /dev/null \
    && "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --install \
        "platform-tools" \
        "platforms;android-29" \
        "platforms;android-31" \
        "build-tools;30.0.2" \
        "cmake;3.10.2.4988404" \
        "ndk;21.4.7075529" > /dev/null

# libuvc/build.gradle drives ndk-build by hand and looks for NDK_HOME (not
# ANDROID_NDK_HOME) before falling back to ndk.dir. Without this the build
# dies with "command 'null/ndk-build'".
ENV NDK_HOME=$ANDROID_SDK_ROOT/ndk/21.4.7075529

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD [":app:assembleDebug"]
