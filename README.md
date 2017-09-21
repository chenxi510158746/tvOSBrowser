tvOS Browser
=============


使用专有API（UIWebView）的tvOS网页浏览器。 需要编辑XCode Availability.h文件中的以下行才能正确编译。

```
Availability.h 在AppleTV位于： Xcode > Contents > Developer > Platforms > AppleTVOS.platform > Developer > SDKs > AppleTVOS.sdk > usr > include
Availability.h 在AppleTV模拟器位于： Xcode > Contents > Developer > Platforms > AppleTVSimulator.platform > Developer > SDKs > AppleTVSimulator.sdk > usr > include
```
更换行 :
```
#define __TVOS_UNAVAILABLE                    __OS_AVAILABILITY(tvos,unavailable)
#define __TVOS_PROHIBITED                     __OS_AVAILABILITY(tvos,unavailable)
```
替换成 :
```
#define __TVOS_UNAVAILABLE_NOTQUITE                    __OS_AVAILABILITY(tvos,unavailable)
#define __TVOS_PROHIBITED_NOTQUITE                     __OS_AVAILABILITY(tvos,unavailable)
```

如何使用tvOSBrowser
=============

- 双击Apple TV遥控器触摸区域的中心，在光标和滚动模式之间切换；
- 单击触摸区域以选择；
- 单击菜单返回上一页；
- 单击播放/暂停按钮可让您输入网址（无模糊匹配或自动搜索）；
- 双击播放/暂停或菜单更多的选择。
