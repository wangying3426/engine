cd ..

tosDir=$1
if [ ! $tosDir ]
then 
	tosDir=$(git rev-parse HEAD)
fi

if [ ! $tosDir ]
then 
	tosDir='default'
fi

cd ..

for mode in 'debug' 'profile' 'release'
	do
		hostDir=out/host_${mode}
		iOSArm64Dir=out/ios_${mode}
		iOSArmV7Dir=out/ios_${mode}_arm
		iOSSimDir=out/ios_debug_sim
		cacheDir=out/tt_ios_${mode}

		rm -rf $cacheDir
		mkdir $cacheDir

		./flutter/tools/gn --runtime-mode=$mode
		ninja -C $hostDir

		./flutter/tools/gn --ios --runtime-mode=$mode
		ninja -C $iOSArm64Dir

		./flutter/tools/gn --ios --runtime-mode=$mode --ios-cpu=arm
		ninja -C $iOSArmV7Dir

		./flutter/tools/gn --ios --runtime-mode=debug --simulator
		ninja -C $iOSSimDir

		lipo -create $iOSArm64Dir/Flutter.framework/Flutter $iOSArmV7Dir/Flutter.framework/Flutter $iOSSimDir/Flutter.framework/Flutter -output $cacheDir/Flutter

		if [ "$mode" == "release" ]
		then
			xcrun strip -x -S $cacheDir/Flutter
		fi

		cp -r $iOSArm64Dir/Flutter.framework $cacheDir/Flutter.framework
		mv $cacheDir/Flutter $cacheDir/Flutter.framework/Flutter

		lipo -create $iOSArm64Dir/clang_x64/gen_snapshot $iOSArmV7Dir/clang_x86/gen_snapshot -output $cacheDir/gen_snapshot

		cp $iOSArm64Dir/Flutter.podspec $cacheDir/Flutter.podspec
		cp flutter/lib/snapshot/snapshot.dart $cacheDir/snapshot.dart

		cd $cacheDir

		cd Flutter.framework
		zip -rq Flutter.framework.zip Flutter Headers icudtl.dat Info.plist Modules
		cd ..
		mv Flutter.framework/Flutter.framework.zip Flutter.framework.zip
		rm -rf Flutter.framework
		zip -rq artifacts.zip Flutter.framework.zip gen_snapshot Flutter.podspec snapshot.dart
		rm -rf Flutter.framework.zip
		rm -rf gen_snapshot
		rm -rf Flutter.podspec
		rm -rf snapshot.dart

		cd ..
		cd ..

		modeDir=ios
		if [ "$mode" == "profile" ]
		then
			modeDir=ios-profile
		elif [ "$mode" == "release" ]
		then
			modeDir=ios-release
		else
			modeDir=ios
		fi

		node ./flutter/tt_build_tools/tosUpload.js $cacheDir/artifacts.zip flutter/framework/$tosDir/$modeDir/artifacts.zip
	done