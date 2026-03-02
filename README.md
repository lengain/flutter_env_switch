# Flutter环境切换工具

这个工具用于在Mac系统中快速切换不同Flutter开发环境（鸿蒙开发和iOS开发）的配置。

## 目录放置要求（重要）

脚本会按固定路径使用Flutter SDK和PUB缓存目录。如果目录位置不对，可能出现“Flutter SDK路径不存在”或缓存相关问题。

- 鸿蒙Flutter必须放在：`~/flutter/harmony/flutter_flutter`
- iOS Flutter必须放在：`~/flutter/ios/flutter`
- 鸿蒙PUB_CACHE目录建议放在：`~/flutter/harmony/pub`
- iOS PUB_CACHE目录建议放在：`~/flutter/ios/pub`

请先按以上路径准备好目录（不存在可手动创建），再执行安装和环境切换命令。

## 安装说明

1. 将`flutter_env_switch.sh`脚本复制到您的系统中，例如：
   ```bash
   cp flutter_env_switch.sh ~/bin/
   ```

2. 添加执行权限：
   ```bash
   chmod +x ~/bin/flutter_env_switch.sh
   ```

3. 在您的shell配置文件（~/.zshrc 或 ~/.bash_profile）中添加以下内容：
   ```bash
   # 加载Flutter环境配置
   if [ -f ~/.flutter_env ]; then
       source ~/.flutter_env
   fi
   ```

## 使用方法

1. 切换到鸿蒙开发环境：
   ```bash
   flutter_env_switch.sh harmony
   ```

2. 切换到iOS开发环境：
   ```bash
   flutter_env_switch.sh ios
   ```

3. 查看当前环境配置：
   ```bash
   flutter_env_switch.sh show
   ```

4. 检查环境配置：
   ```bash
   flutter_env_switch.sh check
   ```

## 环境说明

### 鸿蒙开发环境
- PUB_HOSTED_URL: https://pub.flutter-io.cn
- FLUTTER_STORAGE_BASE_URL: https://storage.flutter-io.cn
- Flutter路径: $HOME/flutter_harmony/bin

### iOS开发环境
- PUB_HOSTED_URL: https://pub.dev
- FLUTTER_STORAGE_BASE_URL: https://storage.googleapis.com
- Flutter路径: $HOME/flutter_ios/bin

## 功能特性

1. 自动检查Flutter SDK路径是否存在
2. 显示当前Flutter版本信息
3. 检查shell配置文件是否正确配置
4. 提供友好的错误提示
5. 支持环境配置持久化

## 注意事项

1. 请确保您的系统中已经安装了对应版本的Flutter SDK
2. 初始目录请按脚本约定放置：鸿蒙Flutter在`~/flutter/harmony/flutter_flutter`、鸿蒙PUB_CACHE在`~/flutter/harmony/pub`；iOS Flutter在`~/flutter/ios/flutter`、iOS PUB_CACHE在`~/flutter/ios/pub`
3. 切换环境后，需要重新打开终端或执行`source ~/.flutter_env`使配置生效
4. 环境配置会保存在`~/.flutter_env`文件中
5. 脚本必须使用bash运行
6. 如果遇到问题，可以使用`check`命令检查环境配置