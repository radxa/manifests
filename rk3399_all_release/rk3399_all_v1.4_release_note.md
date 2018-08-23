
v1.4版本更新记录：
1. uboot新增next-dev分支，具体说明请参考RKDocs/rk3399/rk3399_android7.1_软件开发指南_v2.04_201800820.pdf 4.7节。
2. 修复网卡静态ip无法设置问题
3. lpddr4更新，修正某些颗粒问题以及增加一些颗粒支持。
4. rk3399：修改vdd_log电压为0.9v，降低功耗。
5. 修改fuse为sdcardfs，修正插入ntfs格式u盘时，视频播放器和文件管理器卡死问题。
6. 开发烧写工具更新到2.58，如果使用开发工具，请更新该版本。
7. 解决TC358749XGB hdmi in空指针崩溃问题。
8. 修正power hal代码导致的高温情况下开机卡死android界面问题。
9. 解决框架层的问题包括一个内存泄露问题以及修复一些应用bug。
10. 修改thermal关机温度和掉电温度。
11. 修正usb otg导致的待机无法唤醒问题。
12. 解决spi导致的内核崩溃问题。
13. 增加动态根据温度调节电压功能。
14. 新增双屏异触补丁，详情请见RKDocs/rk3399/patches/双屏异触Patch_V1.0-20170724.zip
15. 修正stresstest.apk以及Rk4kVideoPlayer.apk的一些bug。
