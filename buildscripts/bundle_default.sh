# --------------------------------------------------

if [ ! -f "deps" ]; then
  sudo rm -r deps
fi
if [ ! -f "prefix" ]; then
  sudo rm -r prefix
fi

./download.sh
./patch.sh

# --------------------------------------------------

if [ ! -f "scripts/ffmpeg" ]; then
  rm scripts/ffmpeg.sh
fi
cp flavors/default.sh scripts/ffmpeg.sh

# --------------------------------------------------

./build.sh

zip -r debug-symbols-default.zip prefix/*/lib

. ./include/depinfo.sh
./sdk/android-sdk-linux/ndk/$v_ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-all prefix/arm64-v8a/usr/local/lib/libmpv.so
./sdk/android-sdk-linux/ndk/$v_ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-all prefix/armeabi-v7a/usr/local/lib/libmpv.so
./sdk/android-sdk-linux/ndk/$v_ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-all prefix/x86/usr/local/lib/libmpv.so
./sdk/android-sdk-linux/ndk/$v_ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-all prefix/x86_64/usr/local/lib/libmpv.so

# --------------------------------------------------

cd deps/media-kit-android-helper

sudo chmod +x gradlew
./gradlew assembleRelease

unzip -o app/build/outputs/apk/release/app-release.apk -d app/build/outputs/apk/release

archs=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")
pairs=("aarch64-linux-android" "arm-linux-androideabi" "i686-linux-android" "x86_64-linux-android")

for i in "${!archs[@]}"; do
    arch=${archs[$i]}
    pair=${pairs[$i]}
    cp ../../prefix/${arch}/usr/local/lib/{libsrt.so,libmbedcrypto.so,libmbedtls.so,libmbedx509.so,libmpv.so} app/build/outputs/apk/release/lib/${arch}
    cp ../../sdk/android-sdk-linux/ndk/$v_ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${pair}/libc++_shared.so app/build/outputs/apk/release/lib/${arch}
done

cd app/build/outputs/apk/release

zip -r default-arm64-v8a.jar      lib/arm64-v8a/*.so
zip -r default-armeabi-v7a.jar    lib/armeabi-v7a/*.so
zip -r default-x86.jar            lib/x86/*.so
zip -r default-x86_64.jar         lib/x86_64/*.so

md5sum *.jar

cd ../../../../../../..

mkdir -p artifacts/default
cp deps/media-kit-android-helper/app/build/outputs/apk/release/default-*.jar artifacts/default/
