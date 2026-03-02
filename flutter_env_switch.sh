#!/bin/bash

# 检查是否以bash运行
if [ -z "$BASH_VERSION" ]; then
    echo "错误：请使用bash运行此脚本"
    exit 1
fi

# 路径与仓库配置
FLUTTER_ROOT="$HOME/flutter"
HARMONY_PATH="$FLUTTER_ROOT/harmony/flutter_flutter"
IOS_PATH="$FLUTTER_ROOT/ios/flutter"
HARMONY_PUB_CACHE="$FLUTTER_ROOT/harmony/pub"
IOS_PUB_CACHE="$FLUTTER_ROOT/ios/pub"
HARMONY_GIT_URL="https://gitcode.com/openharmony-tpc/flutter_flutter.git"
IOS_GIT_URL="https://github.com/flutter/flutter.git"

# 失败后的操作指引
print_troubleshooting_guide() {
    echo "操作建议："
    echo "1. 检查网络是否可访问以下仓库与资源地址"
    echo "   - $HARMONY_GIT_URL"
    echo "   - $IOS_GIT_URL"
    echo "   - https://storage.googleapis.com"
    echo "2. 重新执行命令：bash $0 check"
    echo "3. 若首次下载被中断，可删除不完整缓存后重试："
    echo "   - rm -rf $HARMONY_PATH/bin/cache"
    echo "   - rm -rf $IOS_PATH/bin/cache"
}

# 通用重试执行器
run_with_retry() {
    local max_retries="$1"
    shift
    local attempt=1
    local exit_code=1

    while [ "$attempt" -le "$max_retries" ]; do
        "$@"
        exit_code=$?
        if [ "$exit_code" -eq 0 ]; then
            return 0
        fi

        echo "第${attempt}/${max_retries}次执行失败，退出码：$exit_code"
        if [ "$attempt" -lt "$max_retries" ]; then
            echo "2秒后重试..."
            sleep 2
        fi
        attempt=$((attempt + 1))
    done

    return "$exit_code"
}

# 检查命令是否可用
ensure_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "错误：未找到命令 '$cmd'，请先安装后再执行脚本"
        return 1
    fi
}

# 自动创建目录并安装Flutter（如果缺失）
ensure_flutter_installation() {
    ensure_command git || return 1

    mkdir -p "$FLUTTER_ROOT/harmony" "$FLUTTER_ROOT/ios"

    install_flutter_if_missing "鸿蒙" "$HARMONY_PATH" "$HARMONY_GIT_URL" || return 1
    install_flutter_if_missing "iOS" "$IOS_PATH" "$IOS_GIT_URL" || return 1
    ensure_pub_cache_dirs || return 1
}

# 如果Flutter不存在则自动克隆
install_flutter_if_missing() {
    local env_label="$1"
    local flutter_path="$2"
    local git_url="$3"
    local parent_dir
    parent_dir="$(dirname "$flutter_path")"

    if [ -f "$flutter_path/bin/flutter" ]; then
        echo "$env_label Flutter路径：$flutter_path"
        return 0
    fi

    if [ -d "$flutter_path" ] && [ -n "$(ls -A "$flutter_path" 2>/dev/null)" ] && [ ! -d "$flutter_path/.git" ]; then
        echo "错误：$env_label Flutter路径存在但不是可识别的Git仓库：$flutter_path"
        echo "请清理该目录后重试，或手动放置正确的Flutter SDK"
        return 1
    fi

    echo "检测到$env_label Flutter缺失，开始下载：$git_url"
    mkdir -p "$parent_dir"
    if [ -d "$flutter_path/.git" ]; then
        echo "$env_label Flutter路径（Git仓库）：$flutter_path，跳过克隆"
    else
        run_with_retry 3 git clone "$git_url" "$flutter_path" || {
            echo "错误：下载$env_label Flutter失败（已重试3次）"
            print_troubleshooting_guide
            return 1
        }
    fi

    if [ ! -f "$flutter_path/bin/flutter" ]; then
        echo "错误：$env_label Flutter安装不完整，未找到可执行文件：$flutter_path/bin/flutter"
        return 1
    fi

    echo "$env_label Flutter准备完成：$flutter_path"
}

# 自动检查并创建PUB缓存目录
ensure_pub_cache_dirs() {
    if [ ! -d "$HARMONY_PUB_CACHE" ]; then
        mkdir -p "$HARMONY_PUB_CACHE" || {
            echo "错误：创建鸿蒙PUB_CACHE目录失败：$HARMONY_PUB_CACHE"
            return 1
        }
        echo "已创建鸿蒙PUB_CACHE目录：$HARMONY_PUB_CACHE"
    fi

    if [ ! -d "$IOS_PUB_CACHE" ]; then
        mkdir -p "$IOS_PUB_CACHE" || {
            echo "错误：创建iOS PUB_CACHE目录失败：$IOS_PUB_CACHE"
            return 1
        }
        echo "已创建iOS PUB_CACHE目录：$IOS_PUB_CACHE"
    fi
}

# 自动将环境配置加载加入shell配置文件
ensure_shell_env_loader() {
    local config_file=""
    local config_name=""
    local source_regex='^[[:space:]]*(source|\.)[[:space:]]+~/.flutter_env([[:space:]]|$)'
    local block_start="# >>> flutter_env_switch auto-load >>>"
    local block_end="# <<< flutter_env_switch auto-load <<<"
    local legacy_block_comment="# Flutter env switch auto-load"

    if [[ "$SHELL" == *"zsh"* ]]; then
        config_file="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        config_file="$HOME/.bash_profile"
    elif [ -f "$HOME/.zshrc" ]; then
        config_file="$HOME/.zshrc"
    else
        config_file="$HOME/.bash_profile"
    fi
    config_name="$(basename "$config_file")"

    touch "$config_file"

    # 块级去重：新标记块存在则不重复追加
    if grep -Fq "$block_start" "$config_file"; then
        echo "Shell配置文件：$config_name"
        echo "Shell配置路径：$config_file"
        echo "Shell配置状态：已存在自动加载块"
        return 0
    fi

    # 兼容旧版本：若历史块或手写source已存在，也不再追加
    if grep -Fq "$legacy_block_comment" "$config_file" || grep -Eq "$source_regex" "$config_file"; then
        echo "Shell配置文件：$config_name"
        echo "Shell配置路径：$config_file"
        echo "Shell配置状态：已存在flutter_env加载配置"
        return 0
    fi

    cat >> "$config_file" << 'EOF'

# >>> flutter_env_switch auto-load >>>
if [ -f ~/.flutter_env ]; then
    source ~/.flutter_env
fi
# <<< flutter_env_switch auto-load <<<
EOF

    echo "Shell配置文件：$config_name"
    echo "已自动写入环境加载配置到：$config_file"
}

# 检查Flutter SDK路径是否存在
check_flutter_path() {
    local env=$1
    local flutter_path=""
    
    case $env in
        "harmony")
            flutter_path="$HARMONY_PATH"
            ;;
        "ios")
            flutter_path="$IOS_PATH"
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
    
    # 显示Flutter版本（兼容首次初始化下载场景）
    if command -v flutter &> /dev/null; then
        local try=1
        local max_try=3
        local version_output=""
        local version_line=""
        local last_exit_code=1

        while [ "$try" -le "$max_try" ]; do
            version_output="$(flutter --version 2>&1)"
            last_exit_code=$?
            if [ "$last_exit_code" -eq 0 ]; then
                version_line="$(printf "%s\n" "$version_output" | sed -n '/^Flutter /p' | sed -n '1p')"
                if [ -n "$version_line" ]; then
                    echo "Flutter版本: $version_line"
                    return 0
                fi
                echo "提示：Flutter首次初始化中，正在等待版本信息（${try}/${max_try}）..."
            else
                echo "第${try}/${max_try}次获取Flutter版本失败，退出码：$last_exit_code"
            fi

            if [ "$try" -lt "$max_try" ]; then
                sleep 2
            fi
            try=$((try + 1))
        done

        echo "错误：获取Flutter版本失败（已重试${max_try}次）"
        print_troubleshooting_guide
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

    # 自动准备Flutter目录与安装
    ensure_flutter_installation || return 1

    # 检查Flutter SDK路径
    check_flutter_path "$env" || return 1

    # 创建或更新环境配置文件
    cat > ~/.flutter_env << EOF
# Flutter环境配置
# 最后更新时间: $(date)
$config
EOF

    # 自动确保shell配置会加载环境文件
    ensure_shell_env_loader || return 1

    # 应用新的环境配置
    source ~/.flutter_env
    
    echo "已切换到 $env 环境"
    show_current_env
}

# 检查shell配置文件
check_shell_config() {
    ensure_flutter_installation || return 1
    ensure_shell_env_loader || return 1
    echo "检查完成：目录与shell环境加载配置均已就绪"
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