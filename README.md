## Build environment setup

Recommend build host is Ubuntu 16.04 64bit, for other hosts, refer official Android documents [Establishing a Build Environment](https://source.android.com/setup/build/initializing).


```shell
$ mkdir -p ~/bin
$ wget 'https://storage.googleapis.com/git-repo-downloads/repo' -P ~/bin
$ chmod +x ~/bin/repo
```

Android's source code primarily consists of Java, C++, and XML files. To compile the source code, you'll need to install OpenJDK 8, GNU C and C++ compilers, XML parsing libraries, ImageMagick, and several other related packages.


```shell
$ sudo apt-get update
$ sudo apt-get install openjdk-8-jdk python python-pip git-core gnupg flex bison gperf build-essential zip curl liblz4-tool zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip mtools u-boot-tools htop iotop sysstat iftop pigz bc device-tree-compiler lunzip dosfstools vim-common parted udev
$ sudo pip install pycrypto
```

Configure the JAVA environment

```shell
$ export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
$ export PATH=$JAVA_HOME/bin:$PATH
$ export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar
```

## Download source code

```shell
$ mkdir rockpi4-android-p
$ cd rockpi4-android-p
```
Then run:

```shell
$ ~/bin/repo init -u https://github.com/radxa/manifests.git -b rockpi-box-9.0 -m rockpi-release.xml
$ repo sync -j$(nproc) -c
```
It might take quite a bit of time to fetch the entire AOSP source code(around 86G)!

In China:
Download Repo
```shell
$ curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo -o repo
$ export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo/'
```

## Build u-boot

```shell
$ cd u-boot
$ make distclean
$ make mrproper
$ ./make.sh rk3399
$ cd ..
```

The generated images are **rk3399_loader_v_xxx.bin** , **idbloader.img** and **uboot.img**

## Building kernel

```shell
$ cd kernel
$ make ARCH=arm64 rockchip_defconfig
$ make rk3399-rockpi-4b.img -j$(nproc)
$ cd ..
```

The generated images are **boot.img**:

- boot.img android p system as root boot.

## Building AOSP

```shell
$ source build/envsetup.sh
$ lunch rk3399-userdebug
# build Android TV
$ lunch rk3399_box-userdebug
$ make -j$(nproc)
```

It takes a long time, take a break and wait...

## Generate  images
```shell
$ ln -s RKTools/linux/Linux_Pack_Firmware/rockdev/ rockdev
$ ./mkimage.sh
```
The generated images under rockdev/Image are

	rockdev/Image/
	├── boot.img
	├── dtbo.img
	├── gpt.img
	├── idbloader.img
	├── kernel.img
	├── MiniLoaderAll.bin
	├── misc.img
	├── misc-recovery.img
	├── oem.img
	├── parameter.txt
	├── pcba_small_misc.img
	├── pcba_whole_misc.img
	├── recovery.img
	├── resource.img
	├── system.img
	├── trust.img
	├── uboot.img
	├── update.img
	├── vbmeta.img
	└── vendor.img


```bash
$ cd rockdev
$ ./android-gpt.sh
```
```
IMAGE_LENGTH:9018403
idbloader       64              16383           8.000000       MB
Warning: The resulting partition is not properly aligned for best performance.
uboot           16384           24575           4.000000       MB
trust           24576           32767           4.000000       MB
misc            32768           40959           4.000000       MB
resource        40960           73727           16.000000      MB
kernel          73728           139263          32.000000      MB
dtb             139264          147455          4.000000       MB
dtbo            147456          155647          4.000000       MB
vbmeta          155648          157695          1.000000       MB
boot            157696          223231          32.000000      MB
recovery        223232          354303          64.000000      MB
backup          354304          583679          112.000000     MB
security        583680          591871          4.000000       MB
cache           591872          1640447         512.000000     MB
system          1640448         6883327         2560.000000    MB
metadata        6883328         6916095         16.000000      MB
vendor          6916096         7964671         512.000000     MB
oem             7964672         9013247         512.000000     MB
frp             9013248         9014271         0.500000       MB
userdata        9014272         9014271         0.000000       MB
```
The images under rockdev/Image are `gpt.img`

    ├── boot.img
    ├── gpt.img
    ├── idbloader.img
    ├── kernel.img
    ├── ......
    └── uboot.img

Installation
you can use `tf card` or `emmc module`
```bash
$ sudo umount /dev/<Your device>*
# mac os maybe not supprot progress
$ sudo dd if=Image/gpt.img of=/dev/<Your device> bs=4M status=progress
$ sync
```
through rockusb
```bash
# on device u-boot
# mmc 0 is your emmc module
# mmc 1 is your tf card
$ rockusb 0 mmc 1

# on pc
$ rkdeveloptool wl 0 Image/gpt.img
```
[More](https://wiki.radxa.com/Rockpi4/install)

**There may be some performance loss when using tf card**