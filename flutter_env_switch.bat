@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
:: Flutter 环境切换脚本 (Windows)
:: ============================================

set "FLUTTER_ROOT=%USERPROFILE%\flutter"
set "HARMONY_PATH=%FLUTTER_ROOT%\harmony\flutter_flutter"
set "IOS_PATH=%FLUTTER_ROOT%\ios\flutter"
set "HARMONY_PUB_CACHE=%FLUTTER_ROOT%\harmony\pub"
set "IOS_PUB_CACHE=%FLUTTER_ROOT%\ios\pub"
set "HARMONY_GIT_URL=https://gitcode.com/openharmony-tpc/flutter_flutter.git"
set "IOS_GIT_URL=https://github.com/flutter/flutter.git"
set "ENV_FILE=%USERPROFILE%\.flutter_env"

:: ============================================
:: 通用函数
:: ============================================

:print_troubleshooting_guide
echo.
echo 操作建议：
echo 1. 检查网络是否可访问以下仓库与资源地址
echo    - %HARMONY_GIT_URL%
echo    - %IOS_GIT_URL%
echo    - https://storage.googleapis.com
echo 2. 重新执行命令：flutter_env_switch.bat check
echo 3. 若首次下载被中断，可删除不完整缓存后重试：
echo    - rmdir /s /q "%HARMONY_PATH%\bin\cache"
echo    - rmdir /s /q "%IOS_PATH%\bin\cache"
goto :eof

:ensure_command
where %1 >nul 2>&1
if errorlevel 1 (
    echo 错误：未找到命令 '%1'，请先安装后再执行脚本
    return /b 1
)
return /b 0

:: ============================================
:: 自动创建目录并安装Flutter（如果缺失）
:: ============================================

:ensure_flutter_installation
call :ensure_command git
if errorlevel 1 return /b 1

if not exist "%FLUTTER_ROOT%\harmony" mkdir "%FLUTTER_ROOT%\harmony"
if not exist "%FLUTTER_ROOT%\ios" mkdir "%FLUTTER_ROOT%\ios"

call :install_flutter_if_missing "鸿蒙" "%HARMONY_PATH%" "%HARMONY_GIT_URL%"
if errorlevel 1 return /b 1

call :install_flutter_if_missing "iOS" "%IOS_PATH%" "%IOS_GIT_URL%"
if errorlevel 1 return /b 1

call :ensure_pub_cache_dirs
return /b %errorlevel%

:: ============================================
:: 如果Flutter不存在则自动克隆
:: ============================================

:install_flutter_if_missing
set "env_label=%~1"
set "flutter_path=%~2"
set "git_url=%~3"

if exist "%flutter_path%\bin\flutter.bat" (
    echo %env_label% Flutter路径：%flutter_path%
    return /b 0
)

if exist "%flutter_path%" (
    dir /b "%flutter_path%" 2>nul | findstr /v "^$" >nul
    if not errorlevel 1 (
        if not exist "%flutter_path%\.git" (
            echo 错误：%env_label% Flutter路径存在但不是可识别的Git仓库：%flutter_path%
            echo 请清理该目录后重试，或手动放置正确的Flutter SDK
            return /b 1
        )
    )
)

echo 检测到%env_label% Flutter缺失，开始下载：%git_url%
if exist "%flutter_path%\.git" (
    echo %env_label% Flutter路径（Git仓库）：%flutter_path%，跳过克隆
) else (
    call :run_git_clone "%git_url%" "%flutter_path%"
    if errorlevel 1 (
        echo 错误：下载%env_label% Flutter失败
        call :print_troubleshooting_guide
        return /b 1
    )
)

if not exist "%flutter_path%\bin\flutter.bat" (
    echo 错误：%env_label% Flutter安装不完整，未找到可执行文件：%flutter_path%\bin\flutter.bat
    return /b 1
)

echo %env_label% Flutter准备完成：%flutter_path%
return /b 0

:: ============================================
:: Git克隆（带重试）
:: ============================================

:run_git_clone
set "git_url=%~1"
set "flutter_path=%~2"
set "attempt=1"
set "max_retries=3"

:retry_loop
git clone "%git_url%" "%flutter_path%" 2>nul
if not errorlevel 1 return /b 0

echo 第%attempt%/%max_retries%次执行失败，退出码：%errorlevel%
if !attempt! LSS %max_retries% (
    echo 2秒后重试...
    timeout /t 2 /nobreak >nul
    set /a attempt+=1
    goto :retry_loop
)

return /b 1

:: ============================================
:: 自动检查并创建PUB缓存目录
:: ============================================

:ensure_pub_cache_dirs
if not exist "%HARMONY_PUB_CACHE%" (
    mkdir "%HARMONY_PUB_CACHE%" 2>nul
    if errorlevel 1 (
        echo 错误：创建鸿蒙PUB_CACHE目录失败：%HARMONY_PUB_CACHE%
        return /b 1
    )
    echo 已创建鸿蒙PUB_CACHE目录：%HARMONY_PUB_CACHE%
)

if not exist "%IOS_PUB_CACHE%" (
    mkdir "%IOS_PUB_CACHE%" 2>nul
    if errorlevel 1 (
        echo 错误：创建iOS PUB_CACHE目录失败：%IOS_PUB_CACHE%
        return /b 1
    )
    echo 已创建iOS PUB_CACHE目录：%IOS_PUB_CACHE%
)

return /b 0

:: ============================================
:: 自动将环境配置加载加入系统环境变量
:: ============================================

:ensure_windows_env_loader
set "env_var_name=FLUTTER_ENV"
set "env_var_value=%ENV_FILE: =\0%"

:: 检查系统环境变量是否已配置
reg query "HKCU\Environment" /v %env_var_name% >nul 2>&1
if not errorlevel 1 (
    echo 系统环境变量已配置
    return /b 0
)

:: 写入系统环境变量
setx %env_var_name% "%ENV_FILE%" >nul 2>&1
if errorlevel 1 (
    echo 警告：设置系统环境变量失败，请手动设置
    echo   变量名：%env_var_name%
    echo   变量值：%ENV_FILE%
) else (
    echo 已自动设置系统环境变量：%env_var_name%
)
return /b 0

:: ============================================
:: 检查Flutter SDK路径是否存在
:: ============================================

:check_flutter_path
set "env=%~1"
set "flutter_path="

if "%env%"=="harmony" set "flutter_path=%HARMONY_PATH%"
if "%env%"=="ios" set "flutter_path=%IOS_PATH%"

if not defined flutter_path (
    echo 错误：未知的环境 '%env%'
    echo 可用的环境: harmony, ios
    return /b 1
)

if not exist "%flutter_path%" (
    echo 错误：Flutter SDK路径不存在: %flutter_path%
    echo 请确保已安装Flutter SDK并放置在正确位置
    return /b 1
)

if not exist "%flutter_path%\bin\flutter.bat" (
    echo 错误：Flutter可执行文件不存在: %flutter_path%\bin\flutter.bat
    return /b 1
)

return /b 0

:: ============================================
:: 获取环境配置
:: ============================================

:get_env_config
set "env=%~1"

if "%env%"=="harmony" (
    echo set PUB_CACHE=%HARMONY_PUB_CACHE%
    echo set PUB_HOSTED_URL=https://pub-web.flutter-io.cn
    echo set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
    echo set FLUTTER_OHOS_STORAGE_BASE_URL=https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com
    echo set FLUTTER_GIT_URL=https://gitcode.com/openharmony-tpc/flutter_flutter.git
    echo set PATH=%HARMONY_PATH%\bin;%%PATH%%
    return /b 0
)

if "%env%"=="ios" (
    echo set PUB_CACHE=%IOS_PUB_CACHE%
    echo set PUB_HOSTED_URL=https://pub.dev
    echo set FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
    echo set FLUTTER_GIT_URL=https://github.com/flutter/flutter.git
    echo set PATH=%IOS_PATH%\bin;%%PATH%%
    return /b 0
)

return /b 1

:: ============================================
:: 写入环境配置文件
:: ============================================

:write_env_config
set "env=%~1"

(
    echo @echo off
    echo REM Flutter环境配置
    echo REM 最后更新时间: %date% %time%
) > "%ENV_FILE%"

call :get_env_config "%env%" >> "%ENV_FILE%"
return /b %errorlevel%

:: ============================================
:: 显示当前环境
:: ============================================

:show_current_env
echo.
echo ====== 当前环境配置 ======
echo PUB_HOSTED_URL: %PUB_HOSTED_URL%
echo FLUTTER_STORAGE_BASE_URL: %FLUTTER_STORAGE_BASE_URL%
echo PUB_CACHE: %PUB_CACHE%

where flutter >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%i in ('where flutter 2^>nul') do (
        if not defined first_flutter_path (
            echo Flutter路径: %%i
            set "first_flutter_path=1"
        )
    )
    echo.
    echo Flutter版本:
    call flutter --version 2>nul | findstr /B "Flutter"
) else (
    echo Flutter路径: 未找到
    echo.
    echo 提示：请在新的命令提示符窗口中运行以加载新环境
)
goto :eof

:: ============================================
:: 切换环境
:: ============================================

:switch_env
set "env=%~1"

if not "%env%"=="harmony" if not "%env%"=="ios" (
    echo 错误：未知的环境 '%env%'
    echo 可用的环境: harmony, ios
    return /b 1
)

:: 获取环境配置
call :get_env_config "%env%" >nul
if errorlevel 1 (
    echo 错误：未知的环境 '%env%'
    echo 可用的环境: harmony, ios
    return /b 1
)

:: 自动准备Flutter目录与安装
call :ensure_flutter_installation
if errorlevel 1 return /b 1

:: 检查Flutter SDK路径
call :check_flutter_path "%env%"
if errorlevel 1 return /b 1

:: 创建或更新环境配置文件
call :write_env_config "%env%"
if errorlevel 1 (
    echo 错误：写入环境配置文件失败
    return /b 1
)

:: 自动确保Windows环境变量会加载环境文件
call :ensure_windows_env_loader

:: 应用新的环境配置（当前会话）
call "%ENV_FILE%"

echo.
echo ========================================
echo 已切换到 %env% 环境
echo ========================================

:: 显示当前环境
call :show_current_env

:: 终止 Dart 进程
echo.
echo 为了使IDE使用新的环境，请重启IDE

return /b 0

:: ============================================
:: 检查环境配置
:: ============================================

:check_env
call :ensure_flutter_installation
if errorlevel 1 return /b 1

call :ensure_windows_env_loader
echo.
echo 检查完成：目录与环境变量配置均已就绪
return /b 0

:: ============================================
:: 主程序
:: ============================================

if "%~1"=="" goto :usage
if "%~1"=="harmony" goto :do_harmony
if "%~1"=="ios" goto :do_ios
if "%~1"=="show" goto :do_show
if "%~1"=="check" goto :do_check
goto :usage

:do_harmony
call :switch_env "harmony"
goto :end

:do_ios
call :switch_env "ios"
goto :end

:do_show
call :show_current_env
goto :end

:do_check
call :check_env
goto :end

:usage
echo.
echo 用法: flutter_env_switch.bat {harmony^|ios^|show^|check}
echo   harmony: 切换到鸿蒙开发环境
echo   ios: 切换到iOS开发环境
echo   show: 显示当前环境配置
echo   check: 检查环境配置
echo.
echo 示例：
echo   flutter_env_switch.bat harmony
echo   flutter_env_switch.bat ios
echo   flutter_env_switch.bat show
echo   flutter_env_switch.bat check

:end
endlocal
