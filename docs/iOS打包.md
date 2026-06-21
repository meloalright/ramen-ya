# iOS 打包说明

## 关键前提(无法回避)
- **iOS 的 `.ipa` 只能在 macOS + Xcode 上编译**——这是苹果的硬性限制,Linux/Windows 都不行。
- Godot 的 iOS 导出**需要一个 Apple Team ID**(10 位,来自 Apple 开发者账号),即使只是导出工程也要填。
- 想**装到真机 / 上架 App Store**,还需要 **Apple 开发者账号**(个人 $99/年;免费 Apple ID 只能签 7 天、装自己的设备)。

## 项目已经做好的部分(iOS-ready)
- ✅ 横屏锁定(`window/handheld/orientation="landscape"`)
- ✅ 触屏:鼠标点击/拖拽逻辑会自动响应触摸(`emulate_touch_from_mouse`)
- ✅ App 图标:`assets/icon/icon_1024.png`(1024×1024 不透明,符合 App Store 要求)
- ✅ iOS 导出预设:`export_presets.cfg` 里的 `[preset.1] iOS`(横屏、图标已配)
- ✅ 渲染用 GL Compatibility(iOS 走 OpenGL ES,轻量)

## App Store Connect 信息(已登记)
- **Team ID(Seed ID)**:`9TGD35M5GT` —— 已填入导出预设
- **Bundle ID**:`meloalright.ramen-ya`(名称 RAMEN-YA,ID `6HS4YW98L8`)—— 已注册,已填入导出预设
- **App 记录**:✅ 已创建,**App ID `6782641107`**,主语言 `zh-Hant`
- **待办**:商店显示名当前是 `meloalright.ramen-ya`,建议在 App Store Connect → 你的 App → **App 信息(App Information)→ 名称** 改成「拉麵屋」。

## 下一步:把构建传到这个 App
1. 在 Mac/CI 上导出 iOS 工程并打出 **已签名** 的 `.ipa`(签名要用上面的 Team ID `9TGD35M5GT` + 你的发布证书/描述文件)。
2. 上传到 TestFlight:`xcrun altool` 或 **Transporter** App,目标就是 App ID `6782641107` / Bundle ID `meloalright.ramen-ya`。
3. 在 App Store Connect 的 TestFlight 里就能看到构建,可内测;补齐元数据/截图后可提交审核上架。

## 三种出包方式

### A. 你自己有 Mac(最简单)
1. 在 Mac 上装 Godot 4.3 + iOS 导出模板。
2. 打开本工程,菜单 **Project → Export**,选 iOS 预设,填上 Team ID。
3. 点 **Export Project** → 生成一个 Xcode 工程。
4. 用 Xcode 打开,选你的签名团队,**Run** 到真机 / 模拟器,或 **Archive** 出 `.ipa`。

### B. 没有 Mac → 用 GitHub Actions(macOS runner)
已提供工作流 `.github/workflows/ios.yml`(手动触发,Actions → Build iOS → Run workflow):
- 在仓库 **Settings → Secrets and variables → Actions → Variables** 加一个 `IOS_TEAM_ID`(你的 Team ID)。
- 默认产出**未签名**的 `ramenya-unsigned.ipa`(能验证编译通过,但**装不进真机**,需要再签名)。
- 注:macOS 的 CI 分钟数按更高费率计费,所以设成了手动触发。

### C. 只是想试玩 → 还是得 Mac 上的 iOS 模拟器
未签名 build 可以在 Xcode 的 iOS Simulator 里跑,无需开发者账号。

## 我需要你提供的
- **Apple Team ID**(10 位,如 `A1B2C3D4E5`)—— 有了它我就能把预设填好。
- 告诉我你**有没有 Mac / 开发者账号**,我据此决定走 A 还是 B,以及要不要把 CI 改成「带签名、直接出可安装 ipa」。
