#!/bin/bash
id
df -h
free -h
cat /proc/cpuinfo

echo "update submodules"
git submodule update --init --recursive --remote || { echo "submodule update failed"; exit 1; }

if [ -d "immortalwrt" ]; then
    echo "repo dir exists"
    cd immortalwrt
    git pull || { echo "git pull failed"; exit 1; }
    git reset --hard HEAD
    git clean -fd
else
    echo "repo dir not exists"
    git clone -b openwrt-24.10 --single-branch --filter=blob:none "https://github.com/immortalwrt/immortalwrt" || { echo "git clone failed"; exit 1; }
    cd immortalwrt
fi

echo "add feeds"
cat feeds.conf.default > feeds.conf
echo "" >> feeds.conf
echo "src-git qmodem https://github.com/FUjr/QModem.git;main" >> feeds.conf
echo "src-git istore https://github.com/linkease/istore;main" >> feeds.conf
echo "update files"
rm -rf files
cp -r ../files .

# WLAN Compatibility Fix
mkdir -p ./files/lib/wifi/
cp package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc ./files/lib/wifi/mac80211.uc
sed -i 's/const bands_order = \[ "6G", "5G", "2G" \];/const bands_order = [ "2G", "5G", "6G" ];/' ./files/lib/wifi/mac80211.uc
echo "diff lib/wifi/mac80211.uc with builder repo:"
diff ../files/lib/wifi/mac80211.uc ./files/lib/wifi/mac80211.uc
echo "diff lib/wifi/mac80211.uc with immortalwrt repo:"
diff package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc ./files/lib/wifi/mac80211.uc

echo "update feeds"
./scripts/feeds update -a || { echo "update feeds failed"; exit 1; }
echo "install feeds"
./scripts/feeds install -a || { echo "install feeds failed"; exit 1; }
./scripts/feeds install -a -f -p qmodem || { echo "install qmodem feeds failed"; exit 1; }

if [ -L "package/zz-packages" ]; then
    echo "package/zz-packages is already a symlink"
else
    if [ -d "package/zz-packages" ]; then
        echo "package/zz-packages directory exists, removing it"
        rm -rf package/zz-packages
    fi
    ln -s ../../zz-packages package/zz-packages
    echo "Created symlink package/zz-packages -> ../../zz-packages"
fi
