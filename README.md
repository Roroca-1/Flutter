# 轻书架

轻书架官方 Flutter 客户端的功能拓展版本。目前面向 Android, Windows, Linux平台进行测试，iOS和macOS平台需要自行编译测试。


## 功能
支持在书架页显示系列而非单卷\
支持在书架页以标题，加入日期，更新日期排序\
支持漫画加入本地书架\
书架批量管理\
支持列表呈现方式\
自动签到\
自定义字体\
自定义字体颜色\
自定义应用主题\
缓存和加载速度优化


提交新功能：\
等你发issue呢

## 开发

```bash
flutter pub get
flutter run -d <device>
```

注入刷新令牌：

```bash
flutter run --dart-define=REFRESH_TOKEN=<refresh token>
```

## 赞助本站

<a href="https://www.ifdian.net/a/wuyu8512">赞助</a>本站可以帮助我购买更多的 Token，来使网站变得更好

<img src=".github/afdian.jpeg" height="300">

## 致谢

基于 https://github.com/celia-sh/Novella 的 Flutter 版本重新开发得来

感谢 https://github.com/Kanscape 提供的 UI 布局交互思路，如果你需要体验 iOS 上的原生组件，不妨试试上述第三方客户端
