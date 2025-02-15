#!/bin/bash
# Download apkeep
get_artifact_download_url () {
    # Usage: get_download_url <repo_name> <artifact_name> <file_type>
    local api_url="https://api.github.com/repos/$1/releases/latest"
    local result=$(curl $api_url | jq ".assets[] | select(.name | contains(\"$2\") and contains(\"$3\") and (contains(\".sig\") | not)) | .browser_download_url")
    echo ${result:1:-1}
}

# Artifacts associative array aka dictionary
declare -A artifacts

artifacts["apkeep"]="EFForg/apkeep apkeep-x86_64-unknown-linux-gnu"
artifacts["apktool.jar"]="iBotPeaches/Apktool apktool .jar"

# Fetch all the dependencies
for artifact in "${!artifacts[@]}"; do
    if [ ! -f $artifact ]; then
        echo "Downloading $artifact"
        curl -L -o $artifact $(get_artifact_download_url ${artifacts[$artifact]})
    fi
done

chmod +x apkeep

# Download Azur Lane
if [ ! -f "com.bilibili.AzurLane.apk" ]; then
    echo "Get Azur Lane apk"

    # eg: wget "your download link" -O "your packge name.apk" -q
    #if you want to patch .xapk, change the suffix here to wget "your download link" -O "your packge name.xapk" -q
    wget https://downali.wandoujia.com/wm/9/25/blhx_uc_2024_08_22_17_25_01_11597433_111709f2614a.apk?nrd=0&fname=%E7%A2%A7%E8%93%9D%E8%88%AA%E7%BA%BF&productid=2011&packageid=701136864&pkg=com.bilibili.blhx.uc&vcode=8210&yingid=wdj_web&minSDK=21&size=1429258654&pos=wdj_web%2Fdetail_normal_dl%2F0&shortMd5=358909ab66a0c2c13df42cf1bebe155b&appid=7605326&apprd=7605326&crc32=2133299074&iconUrl=http%3A%2F%2Fandroid-artworks.25pp.com%2Ffs08%2F2024%2F08%2F27%2F2%2F109_88e0f17dd9e92b5a17d7636218cfcb67_con.png&did=e3074a40fc0e5df2299fdd35ed05747d&md5=8b0289d1b95e7e69c7e494f53d264015 -O com.bilibili.AzurLane.apk -q
    echo "apk downloaded !"
    
    # if you can only download .xapk file uncomment 2 lines below. (delete the '#')
    #unzip -o com.YoStarJP.AzurLane.xapk -d AzurLane
    #cp AzurLane/com.YoStarJP.AzurLane.apk .
fi

# Download Perseus
if [ ! -d "Perseus" ]; then
    echo "Downloading Perseus"
    git clone https://github.com/IceEst/Azurlane_libSkin
fi

echo "Decompile Azur Lane apk"
java -jar apktool.jar -q -f d com.bilibili.AzurLane.apk

echo "Copy Perseus libs"
cp -r Azurlane_libSkin/. com.bilibili.AzurLane/lib/

echo "Patching Azur Lane with Perseus"
oncreate=$(grep -n -m 1 'onCreate' com.bilibili.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali | sed  's/[0-9]*\:\(.*\)/\1/')
sed -ir "s#\($oncreate\)#.method private static native init(Landroid/content/Context;)V\n.end method\n\n\1#" com.bilibili.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali
sed -ir "s#\($oncreate\)#\1\n    const-string v0, \"JMBQ\"\n\n\    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V\n\n    invoke-static {p0}, Lcom/unity3d/player/UnityPlayerActivity;->init(Landroid/content/Context;)V\n#" com.bilibili.AzurLane/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali

echo "Build Patched Azur Lane apk"
java -jar apktool.jar -q -f b com.bilibili.AzurLane -o build/com.bilibili.AzurLane.patched.apk

echo "Set Github Release version"
echo "PERSEUS_VERSION=$(echo JMBQ)" >> $GITHUB_ENV
