#!/usr/bin/env bash
cd ..

jcount=$1
if [ ! $jcount ]
then
    jcount=4
fi

tosDir=$2
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

for mode in 'debug' 'profile' 'release'; do
    for platform in 'arm'; do
        for dynamic in 'normal'; do
            modeDir=android-$platform
            
            # arm不带后缀
            if [ $platform = 'arm' ]; then
                platformPostFix=''
            else
                platformPostFix=_${platform}
            fi

            ./flutter/tools/gn --android --runtime-mode=$mode --android-cpu=$platform
            androidDir=out/android_${mode}${platformPostFix}

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

            zip -rjq $cacheDir/$modeDir/artifacts.zip $androidDir/flutter.jar
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
zip -rjq $cacheDir/$modeDir/artifacts.zip $hostDir/flutter_tester $hostDir/gen/frontend_server.dart.snapshot \
out/android_release/flutter_shell_assets/icudtl.dat out/android_debug/gen/flutter/lib/snapshot/isolate_snapshot.bin \
out/android_debug/gen/flutter/lib/snapshot/vm_isolate_snapshot.bin $cacheDir/$modeDir/product_isolate_snapshot.bin \
$cacheDir/$modeDir/product_vm_isolate_snapshot.bin
node ./flutter/tt_build_tools/tosUpload.js $cacheDir/$modeDir/artifacts.zip flutter/framework/$tosDir/$modeDir/artifacts.zip
echo uploaded $cacheDir/$modeDir/artifacts.zip flutter/framework/$tosDir/$modeDir/artifacts.zip

rm -rf $cacheDir/pkg
mkdir $cacheDir/pkg
cp -rf $hostDir/gen/dart-pkg/sky_engine $cacheDir/pkg/sky_engine
rm -rf $cacheDir/pkg/sky_engine/packages
cd $cacheDir/pkg
zip -rq ../../../$cacheDir/pkg/sky_engine.zip sky_engine
cd ..
cd ..
cd ..
node ./flutter/tt_build_tools/tosUpload.js $cacheDir/pkg/sky_engine.zip flutter/framework/$tosDir/sky_engine.zip
echo uploaded $cacheDir/pkg/sky_engine.zip flutter/framework/$tosDir/sky_engine.zip
