# Flutter环境切换工具

用于在 macOS 上快速切换鸿蒙 Flutter 与 iOS Flutter 开发环境。

## 核心能力

### macOS / Linux
- 自动创建目录：`~/flutter/harmony`、`~/flutter/ios`
- 自动检测并下载 Flutter 仓库（缺失时）
- 自动检测并创建 `PUB_CACHE` 目录
- 自动写入 `~/.flutter_env` 加载逻辑到 `~/.zshrc` 或 `~/.bash_profile`
- Shell 配置写入支持块级去重，避免重复追加

### Windows
- 自动创建目录：`%USERPROFILE%\flutter\harmony`、`%USERPROFILE%\flutter\ios`
- 自动检测并下载 Flutter 仓库（缺失时）
- 自动检测并创建 `PUB_CACHE` 目录
- 自动生成 `%USERPROFILE%\.flutter_env` 配置文件
- 自动通过 `setx` 命令将环境变量 `FLUTTER_ENV` 写入 Windows 注册表（HKCU\Environment），指向配置文件

  > **注意**：由于 Windows `setx` 命令的特性，环境变量设置后需要**重启命令行窗口**或**重启 IDE** 才能生效。脚本首次运行时会自动设置此环境变量，之后运行会跳过已存在的配置。

## 目录约定

### macOS / Linux
脚本固定使用以下目录（不存在会自动创建）：

- 鸿蒙 Flutter：`~/flutter/harmony/flutter_flutter`
- iOS Flutter：`~/flutter/ios/flutter`
- 鸿蒙 PUB_CACHE：`~/flutter/harmony/pub`
- iOS PUB_CACHE：`~/flutter/ios/pub`
- 环境配置文件：`~/.flutter_env`

### Windows
脚本固定使用以下目录（不存在会自动创建）。

> **说明**：`%USERPROFILE%` 是 Windows 系统的环境变量，对应用户主目录，通常为 `C:\Users\你的用户名`，例如 `C:\Users\张三`。

- 鸿蒙 Flutter：`%USERPROFILE%\flutter\harmony\flutter_flutter`
- iOS Flutter：`%USERPROFILE%\flutter\ios\flutter`
- 鸿蒙 PUB_CACHE：`%USERPROFILE%\flutter\harmony\pub`
- iOS PUB_CACHE：`%USERPROFILE%\flutter\ios\pub`
- 环境配置文件：`%USERPROFILE%\.flutter_env`

## 安装

### macOS / Linux

1. 复制脚本到本地（示例）：
   ```bash
   cp flutter_env_switch.sh ~/
   ```
2. 添加执行权限：
   ```bash
   chmod +x ~/flutter_env_switch.sh
   ```
3. 使用 `bash` 执行脚本：
   ```bash
   bash ~/flutter_env_switch.sh check
   ```

### Windows

1. 复制脚本到本地（示例）：
   ```cmd
   copy flutter_env_switch.bat %USERPROFILE%\
   ```
2. 在命令提示符或 PowerShell 中执行：
   ```cmd
   flutter_env_switch.bat check
   ```

> **注意**：Windows 版本脚本会自动设置系统环境变量 `FLUTTER_ENV`，指向配置文件 `%USERPROFILE%\.flutter_env`。

## 使用方法

### macOS / Linux

1. 切换到鸿蒙环境：
   ```bash
   bash ~/flutter_env_switch.sh harmony
   ```
2. 切换到 iOS 环境：
   ```bash
   bash ~/flutter_env_switch.sh ios
   ```
3. 查看当前环境：
   ```bash
   bash ~/flutter_env_switch.sh show
   ```
4. 执行环境检查与自动修复：
   ```bash
   bash ~/flutter_env_switch.sh check
   ```

### Windows

1. 切换到鸿蒙环境：
   ```cmd
   flutter_env_switch.bat harmony
   ```
2. 切换到 iOS 环境：
   ```cmd
   flutter_env_switch.bat ios
   ```
3. 查看当前环境：
   ```cmd
   flutter_env_switch.bat show
   ```
4. 执行环境检查与自动修复：
   ```cmd
   flutter_env_switch.bat check
   ```

## 环境变量说明

### 鸿蒙环境（`harmony`）

- `PUB_CACHE=$HOME/flutter/harmony/pub`
- `PUB_HOSTED_URL=https://pub-web.flutter-io.cn`
- `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`
- `FLUTTER_OHOS_STORAGE_BASE_URL=https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com`
- `FLUTTER_GIT_URL=https://gitcode.com/openharmony-tpc/flutter_flutter.git`
- `PATH` 追加：`$HOME/flutter/harmony/flutter_flutter/bin`

### iOS 环境（`ios`）

- `PUB_CACHE=$HOME/flutter/ios/pub`
- `PUB_HOSTED_URL=https://pub.dev`
- `FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com`
- `FLUTTER_GIT_URL=https://github.com/flutter/flutter.git`
- `PATH` 追加：`$HOME/flutter/ios/flutter/bin`

## 注意事项

1. 请确保系统已安装 `git`（脚本会使用 `git clone` 下载 Flutter 仓库）
2. 首次切换某个环境时，Flutter 可能会初始化下载工具链，耗时会更长
3. 环境配置保存在 `~/.flutter_env`（macOS/Linux）或 `%USERPROFILE%\.flutter_env`（Windows），切换后建议重新打开终端
4. Windows 用户切换后需要重启 IDE 以使新环境生效
5. 如遇异常，可先执行：
   - macOS/Linux:
     ```bash
     bash ~/flutter_env_switch.sh check
     ```
   - Windows:
     ```cmd
     flutter_env_switch.bat check
     ```

## License

本项目使用 `MIT License` 开源，详见仓库根目录下的 `LICENSE` 文件。

## FAQ

### 1. 为什么第一次切换环境很慢？

首次切换时，Flutter 可能会下载 Dart SDK 和工具缓存，这是正常现象。后续再切换通常会明显更快。

### 2. 为什么日志里会出现 `Downloading ...`？

这通常是 Flutter 首次初始化阶段输出的信息，不一定是错误。脚本会自动重试并尽量提取最终的 `Flutter` 版本行。

### 3. 下载中断后如何处理？

可以先执行：

```bash
bash ~/flutter_env_switch.sh check
```

如果仍失败，可清理缓存后重试：

```bash
rm -rf ~/flutter/harmony/flutter_flutter/bin/cache
rm -rf ~/flutter/ios/flutter/bin/cache

### 4. Windows 下环境变量没有生效？

确保在新的命令提示符窗口中运行命令，因为环境变量的修改只在新的命令行会话中生效。也可以手动检查系统环境变量：
- 按 `Win + R`，输入 `sysdm.cpl`
- 切换到「高级」选项卡，点击「环境变量」
- 确认 `FLUTTER_ENV` 变量已设置指向 `%USERPROFILE%\.flutter_env`
```