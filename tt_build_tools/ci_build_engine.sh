#!/usr/bin/env bash

# ninja
brew install ninja

# ant
brew install ant

# gclient
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

export PATH=`pwd`/depot_tools:$PATH

mkdir engine
(
cat <<EOF
solutions = [
  {
    "managed": False,
    "name": "src/flutter",
    "url": "git@code.byted.org:tech_client/flutter_engine.git",
    "custom_deps": {},
    "deps_file": "DEPS",
    "safesync_url": "",
  },
]
EOF
) > engine/.gclient

cd engine
if [ -d "src/" ];then
	cd src
    git checkout master
	git reset --hard head
	git clean -fd
	git pull
	cd ..
fi

if [ ! -d "src/flutter" ];then
    gclient sync
fi

cd src/flutter
git fetch
git reset --hard origin/$BRANCH
git clean -fd

gclient sync

cd tt_build_tools
if [ $MODE == 'fast' ]; then
    bash android_build_fast.sh $JCOUNT
else
    bash android_build.sh $JCOUNT
fi
bash iOS_build.sh $JCOUNT