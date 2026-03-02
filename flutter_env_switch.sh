#!/bin/bash

# 检查是否以bash运行
if [ -z "$BASH_VERSION" ]; then
    echo "错误：请使用bash运行此脚本"
    exit 1
fi

# 检查Flutter SDK路径是否存在
check_flutter_path() {
    local env=$1
    local flutter_path=""
    
    case $env in
        "harmony")
            flutter_path="$HOME/flutter/harmony/flutter_flutter"
            ;;
        "ios")
            flutter_path="$HOME/flutter/ios/flutter"
            ;;
    esac
    
    if [ ! -d "$flutter_path" ]; then
        echo "错误：Flutter SDK路径不存在: $flutter_path"
        echo "请确保已安装Flutter SDK并放置在正确位置"
        return 1
    fi
    
    if [ ! -f "$flutter_path/bin/flutter" ]; then
        echo "错误：Flutter可执行文件不存在: $flutter_path/bin/flutter"
        return 1
    fi
}

# 获取环境配置
get_env_config() {
    local env=$1
    
    case $env in
        "harmony")
            cat << 'EOF'
export PUB_CACHE=$HOME/flutter/harmony/pub
export PUB_HOSTED_URL=https://pub-web.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export FLUTTER_OHOS_STORAGE_BASE_URL=https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com
export FLUTTER_GIT_URL=https://gitcode.com/openharmony-tpc/flutter_flutter.git
export PATH=$HOME/flutter/harmony/flutter_flutter/bin:$PATH
EOF
            ;;
        "ios")
            cat << 'EOF'
export PUB_CACHE=$HOME/flutter/ios/pub
export PUB_HOSTED_URL=https://pub.dev
export FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
export FLUTTER_GIT_URL=https://github.com/flutter/flutter.git
export PATH=$HOME/flutter/ios/flutter/bin:$PATH
EOF
            ;;
        *)
            return 1
            ;;
    esac
}

# 显示当前环境
show_current_env() {
    echo "当前环境配置："
    echo "PUB_HOSTED_URL: $PUB_HOSTED_URL"
    echo "FLUTTER_STORAGE_BASE_URL: $FLUTTER_STORAGE_BASE_URL"
    echo "Flutter路径: $(which flutter 2>/dev/null || echo '未找到')"
    
    # 显示Flutter版本
    if command -v flutter &> /dev/null; then
        echo "Flutter版本: $(flutter --version | head -n 1)"
    fi
}

# 切换环境
switch_env() {
    local env=$1
    local config=""
    
    # 获取环境配置
    config=$(get_env_config "$env")
    if [ $? -ne 0 ]; then
        echo "错误：未知的环境 '$env'"
        echo "可用的环境: harmony, ios"
        return 1
    fi

    # 检查Flutter SDK路径
    check_flutter_path "$env" || return 1

    # 创建或更新环境配置文件
    cat > ~/.flutter_env << EOF
# Flutter环境配置
# 最后更新时间: $(date)
$config
EOF

    # 应用新的环境配置
    source ~/.flutter_env
    
    echo "已切换到 $env 环境"
    show_current_env
}

# 检查shell配置文件
check_shell_config() {
    local config_file=""
    if [ -f "$HOME/.zshrc" ]; then
        config_file="$HOME/.zshrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        config_file="$HOME/.bash_profile"
    fi

    if [ -n "$config_file" ]; then
        if ! grep -q "source ~/.flutter_env" "$config_file"; then
            echo "警告：未在 $config_file 中找到环境配置加载命令"
            echo "请添加以下内容到 $config_file："
            echo "if [ -f ~/.flutter_env ]; then"
            echo "    source ~/.flutter_env"
            echo "fi"
        fi
    else
        echo "警告：未找到shell配置文件（.zshrc 或 .bash_profile）"
    fi
}

# 主程序
case "$1" in
    "harmony")
        switch_env "harmony"
        ;;
    "ios")
        switch_env "ios"
        ;;
    "show")
        show_current_env
        ;;
    "check")
        check_shell_config
        ;;
    *)
        echo "用法: $0 {harmony|ios|show|check}"
        echo "  harmony: 切换到鸿蒙开发环境"
        echo "  ios: 切换到iOS开发环境"
        echo "  show: 显示当前环境配置"
        echo "  check: 检查环境配置"
        exit 1
        ;;
esac 