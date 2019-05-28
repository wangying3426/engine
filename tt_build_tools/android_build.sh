#!/usr/bin/env bash
cd ..

jcount=$1
if [ ! $jcount ]
then
    jcount=4
fi

isFast=$2

if [ $isFast = 'fast' ]; then
    platforms=('arm')
    dynamics=('normal')
else
    platforms=('arm' 'x64' 'x86' 'arm64')
    dynamics=('normal' 'dynamic')
fi

tosDir=$3
if [ ! $tosDir ]
then 
	tosDir=$(git rev-parse HEAD)
fi

if [ ! $tosDir ]
then 
	tosDir='default'
fi

cd ..

cacheDir=out/tt_android_cache
rm -rf $cacheDir
mkdir $cacheDir

hostDir=out/host_debug
./flutter/tools/gn
ninja -C $hostDir -j $jcount

# flutter_patched_sdk.zip
rm -f $cacheDir/flutter_patched_sdk.zip
cd $hostDir
zip -rq ../../$cacheDir/flutter_patched_sdk.zip flutter_patched_sdk
cd ..
cd ..
node ./flutter/tt_build_tools/tosUpload.js $cacheDir/flutter_patched_sdk.zip flutter/framework/$tosDir/flutter_patched_sdk.zip
echo uploaded flutter/framework/$tosDir/flutter_patched_sdk.zip

hostDir=out/host_release
./flutter/tools/gn --runtime-mode=release
ninja -C $hostDir -j $jcount

# flutter_patched_sdk.zip
rm -f $cacheDir/flutter_patched_sdk_product.zip
rm -rf $cacheDir/flutter_patched_sdk_product
cp -r $hostDir/flutter_patched_sdk $cacheDir/flutter_patched_sdk_product
cd $cacheDir
zip -rq flutter_patched_sdk_product.zip flutter_patched_sdk_product
cd ..
cd ..
node ./flutter/tt_build_tools/tosUpload.js $cacheDir/flutter_patched_sdk_product.zip flutter/framework/$tosDir/flutter_patched_sdk_product.zip
echo uploaded flutter/framework/$tosDir/flutter_patched_sdk_product.zip

for mode in 'debug' 'profile' 'release'; do
    for platform in ${platforms[@]}; do
        # x64和x86只打debug
        if [ $mode != 'debug' ]; then
            if [ $platform = 'x64' -o $platform = 'x86' ]; then
                continue
            fi
        fi
        for dynamic in ${dynamics[@]}; do
            modeDir=android-$platform
            
            # arm不带后缀
            if [ $platform = 'arm' ]; then
                platformPostFix=''
            else
                platformPostFix=_${platform}
            fi

            # dynamic只打非debug
            if [ $dynamic = 'dynamic' ]; then
                if [ $mode = 'debug' ]; then
                    continue
                fi
                ./flutter/tools/gn --android --runtime-mode=$mode --android-cpu=$platform --dynamic
                androidDir=out/android_dynamic_${mode}${platformPostFix}
                modeDir=$modeDir-dynamic
            else
                ./flutter/tools/gn --android --runtime-mode=$mode --android-cpu=$platform
                androidDir=out/android_${mode}${platformPostFix}
            fi

            ninja -C $androidDir -j $jcount

            if [ $mode != 'debug' ]; then
                modeDir=$modeDir-$mode
            fi

            rm -f $cacheDir/$modeDir
            mkdir $cacheDir/$modeDir

            # 非debug还要带上gen_snapshot
            if [ $mode != 'debug' ]; then
                if [ -f "$androidDir/clang_x86/gen_snapshot" ];then
                    zip -rjq $cacheDir/$modeDir/darwin-x64.zip $androidDir/clang_x86/gen_snapshot
                else
                    zip -rjq $cacheDir/$modeDir/darwin-x64.zip $androidDir/clang_x64/gen_snapshot
                fi
                node ./flutter/tt_build_tools/tosUpload.js $cacheDir/$modeDir/darwin-x64.zip flutter/framework/$tosDir/$modeDir/darwin-x64.zip
                echo uploaded flutter/framework/$tosDir/$modeDir/darwin-x64.zip
            fi

            # x86和x64要带上libflutter.so
            if [ $platform = 'x64' -o $platform = 'x86' ]; then
                zip -rjq $cacheDir/$modeDir/artifacts.zip $androidDir/flutter.jar $androidDir/lib.stripped/libflutter.so
            else
                zip -rjq $cacheDir/$modeDir/artifacts.zip $androidDir/flutter.jar
            fi
            node ./flutter/tt_build_tools/tosUpload.js $cacheDir/$modeDir/artifacts.zip flutter/framework/$tosDir/$modeDir/artifacts.zip
            echo uploaded $cacheDir/$modeDir/artifacts.zip flutter/framework/$tosDir/$modeDir/artifacts.zip
        done
    done
done

# darwin-x64.zip
modeDir=darwin-x64
rm -rf $cacheDir/$modeDir
mkdir $cacheDir/$modeDir
cp out/android_release/gen/flutter/lib/snapshot/isolate_snapshot.bin $cacheDir/$modeDir/product_isolate_snapshot.bin
cp out/android_release/gen/flutter/lib/snapshot/vm_isolate_snapshot.bin $cacheDir/$modeDir/product_vm_isolate_snapshot.bin
zip -rjq $cacheDir/$modeDir/artifacts.zip out/host_debug/flutter_tester out/host_debug/gen/frontend_server.dart.snapshot \
out/android_release/flutter_shell_assets/icudtl.dat out/android_debug/gen/flutter/lib/snapshot/isolate_snapshot.bin \
out/android_debug/gen/flutter/lib/snapshot/vm_isolate_snapshot.bin $cacheDir/$modeDir/product_isolate_snapshot.bin \
$cacheDir/$modeDir/product_vm_isolate_snapshot.bin
node ./flutter/tt_build_tools/tosUpload.js $cacheDir/$modeDir/artifacts.zip flutter/framework/$tosDir/$modeDir/artifacts.zip
echo uploaded $cacheDir/$modeDir/artifacts.zip flutter/framework/$tosDir/$modeDir/artifacts.zip

rm -rf $cacheDir/pkg
mkdir $cacheDir/pkg
cp -rf out/host_release/gen/dart-pkg/sky_engine $cacheDir/pkg/sky_engine
rm -rf $cacheDir/pkg/sky_engine/packages
cd $cacheDir/pkg
zip -rq ../../../$cacheDir/pkg/sky_engine.zip sky_engine
cd ..
cd ..
cd ..
node ./flutter/tt_build_tools/tosUpload.js $cacheDir/pkg/sky_engine.zip flutter/framework/$tosDir/sky_engine.zip
echo uploaded $cacheDir/pkg/sky_engine.zip flutter/framework/$tosDir/sky_engine.zip
