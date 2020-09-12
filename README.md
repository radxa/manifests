## Env
```dockerfile
FROM ubuntu:xenial

RUN apt-get update -y && apt-get install -y openjdk-8-jdk python git-core gnupg flex bison gperf build-essential \
    zip curl liblz4-tool zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
    lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache \
    libgl1-mesa-dev libxml2-utils xsltproc unzip mtools u-boot-tools \
    htop iotop sysstat iftop pigz bc device-tree-compiler lunzip \
    dosfstools vim-common parted udev libssl-dev python3

RUN curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo > /usr/local/bin/repo && \
    chmod +x /usr/local/bin/repo && \
    which repo

ENV REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo/'
ENV PS1="\[\033[01;37m\]\u@build\[\033[00m\]:\[\033[01;32m\]\w\[\033[00m\]:$ "

RUN apt-get install -y python-pip && pip install pycrypto
RUN apt-get install -y lzop swig
```

## Download Source Code
```bash
$ repo init -u https://github.com/radxa/manifests.git -b rockchip-android-10 -m android-q-release.xml 
$ repo sync -d --no-tags -j4
```

## Build Code
ROCKPI 4A/B
```bash
cd ${source-dir}
./build-rockpi-4b.sh
```
Release dir: ${source-dir}/release/ROCKPI-4AB-`date +%F-%H-%M`

ROCKPI 4C
```bash
cd ${source-dir}
./build-rockpi-4c.sh
```
Release dir: ${source-dir}/release/ROCKPI-4C-`date +%F-%H-%M`


Please burn rockdev/update.img [GUIDE](https://wiki.radxa.com/Rockpi4/install/android-eMMC-rkupdate)