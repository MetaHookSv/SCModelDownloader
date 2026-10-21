# SCModelDownloader

[English](README.md)

SCModelDownloader 是 Sven Co-op 专用的 MetaHook 插件，自动从 [scmodels](https://wootguy.github.io/scmodels/)
数据库下载缺失的玩家模型，并在模型文件就绪后重新加载。

插件还会在 GameUI 中添加设置页和下载任务列表，并在本地玩家使用旧版模型时提示切换到最新版本。

## 安装

1. 安装 [MetaHookSv](https://github.com/MetaHookSv/MetaHook)。基于自动获取的 SDK 构建的插件
   要求 MetaHook API 115 或更新版本。
2. 安装运行时依赖：
   * [UtilHTTPClient_libcurl](https://github.com/MetaHookSv/UtilHTTPClient_libcurl/releases)（优先）
     或 [UtilHTTPClient_SteamAPI](https://github.com/MetaHookSv/UtilHTTPClient_SteamAPI/releases)，
     从 `metahook/dlls` 加载。
   * [UtilAssetsIntegrity](https://github.com/MetaHookSv/UtilAssetsIntegrity/releases)，
     从 `metahook/dlls` 加载；下载的文件在写入前会先经过完整性校验。
   * [VGUI2Extension](https://github.com/MetaHookSv/VGUI2Extension/releases)，需在 `plugins.lst`
     中启用。缺少它时不会注册设置页、任务列表和版本升级提示。
3. 从 [GitHub Releases](https://github.com/MetaHookSv/SCModelDownloader/releases) 下载
   `SCModelDownloader-windows-x86.7z`，或自行构建。
4. 将安装包的 `svencoop/` 内容合并到游戏的 `svencoop` 目录，保留
   `metahook/plugins/SCModelDownloader.dll`、`metahook/gamedata/scmodeldownloader/`
   和 `scmodeldownloader/`（UI 布局、本地化文本和内置模型数据库）。
5. 在 `metahook/configs/plugins.lst` 中单独添加一行 `SCModelDownloader.dll`，通过 MetaHook 启动游戏。

## 控制台参数与命令

| 名称 | 默认值 | 说明 |
| --- | --- | --- |
| `scmodel_autodownload` | `1` | 自动下载缺失的玩家模型。 |
| `scmodel_downloadlatest` | `1` | 模型存在多个版本时下载最新版本。 |
| `scmodel_cdn` | `0` | `0` 从 GitHub 下载，`1` 从 jsDelivr CDN 下载。 |
| `scmodel_max_retry` | `3` | 下载任务失败后的重试上限，`0` 表示不限次数。 |
| `scmodel_reload` | | 重新加载所有玩家模型。 |

## 构建

要求 Windows、包含 C++ 工具的 Visual Studio 2022、CMake 3.21 或更新版本、Git，
以及 Python 3.8 或更新版本。仅支持 MSVC x86。

```bat
scripts\build-SCModelDownloader-x86-Release.bat
scripts\build-SCModelDownloader-x86-Debug.bat
```

构建目录为 `build/x86/<Configuration>`，DLL、PDB、gamedata 和 UI 资源安装到
`install/x86/<Configuration>/svencoop`。脚本不会向本地游戏目录部署文件。

首次配置会获取所有源码依赖（MetaHook 跟踪最新 `main`），以及经过 SHA256 校验的 VC-LTL 5.3.1 二进制包；
后者缓存于 `thirdparty/cache`。依赖只以头文件形式使用（MetaHook SDK 另外提供编译单元），
不会配置或构建它们的工程。显式编译清单保留原工程的 13 个插件和 105 个 SDK 编译单元，
使用 C++20 和静态 CRT。插件不使用 Capstone，也不链接 `steam_api`。

| 变量 | 仓库 | 版本 |
| --- | --- | --- |
| `METAHOOK_SOURCE_PATH` | [MetaHookSv/MetaHook](https://github.com/MetaHookSv/MetaHook) | 最新 `main` |
| `VGUI2EXTENSION_SOURCE_PATH` | [MetaHookSv/VGUI2Extension](https://github.com/MetaHookSv/VGUI2Extension) | `07933ad` |
| `UTILASSETSINTEGRITY_SOURCE_PATH` | [MetaHookSv/UtilAssetsIntegrity](https://github.com/MetaHookSv/UtilAssetsIntegrity) | `d823d36` |
| `UTILHTTPCLIENT_SOURCE_PATH` | [MetaHookSv/UtilHTTPClient_libcurl](https://github.com/MetaHookSv/UtilHTTPClient_libcurl) | `10233ab` |
| `SCOPEEXIT_SOURCE_PATH` | [SergiusTheBest/ScopeExit](https://github.com/SergiusTheBest/ScopeExit) | `bd345da` |
| `RAPIDJSON_SOURCE_PATH` | [Tencent/rapidjson](https://github.com/Tencent/rapidjson) | `6089180` |

如需改用本地仓库，可在命令行传入仓库根目录；每个变量也支持同名环境变量。
显式路径会在任何下载之前完成校验。由于两个 UtilHTTPClient 仓库提供相同的
`include/Interface/IUtilHTTPClient.h`，`UTILHTTPCLIENT_SOURCE_PATH` 可以指向其中任意一个。

```bat
scripts\build-SCModelDownloader-x86-Release.bat -DMETAHOOK_SOURCE_PATH=D:\MetaHook -DVGUI2EXTENSION_SOURCE_PATH=D:\VGUI2Extension -DUTILASSETSINTEGRITY_SOURCE_PATH=D:\UtilAssetsIntegrity -DUTILHTTPCLIENT_SOURCE_PATH=D:\UtilHTTPClient_libcurl
```

接口仓库在 include 路径中排在 MetaHook SDK 之前，因此它们提供的 `IVGUI2Extension.h`、`IInput2.h`、
`IScheme2.h`、`ISurface2.h`、`IUtilHTTPClient.h` 和 `IUtilAssetsIntegrity.h` 优先于 SDK 中的同名副本。
构建脚本会透传其他 CMake 参数。

## gamedata

每次构建会同步并校验上游 catalog，只保留插件使用的 engine 符号：
`R_StudioDrawPlayer`、`studioapi_SetupPlayerModel`、`Host_IsSinglePlayerGame` 三个函数，
以及 `DM_PlayerState`、`cl_players_model` 两个全局变量。

manifest 声明了 `svencoop-10257` 和 `svencoop-8948` 两个引擎快照。不支持的引擎或缺失的必需符号
会在运行时报错，插件不提供特征扫描回退。

传入 `-DSCMODELDOWNLOADER_SYNC_GAMEDATA=OFF` 可跳过构建期间的 gamedata 下载，
安装时需要自行提供兼容的 catalog。校验已安装的 catalog：

```bat
python scripts\validate-gamedata.py install\x86\Release\svencoop\metahook\gamedata\scmodeldownloader --manifest scripts\manifests\scmodeldownloader.json
```

## F5 调试（可选）

先安装 MetaHook，并在游戏的 `plugins.lst` 中启用本插件，然后配置独立的 Visual Studio Win32 解决方案：

```powershell
cmake -S . -B build/launch -G "Visual Studio 17 2022" -A Win32 -DMETAHOOKSV_ENABLE_LAUNCH_GAME=ON
```

打开解决方案，选择 **LaunchGame** 后按 **F5**。**DeployGame** 编译本插件及依赖，暂存 Install，再复制插件 DLL、PDB 和资源，最后由原生调试器启动已有游戏 launcher。不会修改根目录启动器/运行库或插件列表。VS 应开启运行前构建，并将构建失败策略设为 **不启动**；重新部署前请退出游戏。普通构建不会部署。

`METAHOOKSV_GAME_DIRECTORY` 默认通过 Steam 自动查找，`METAHOOKSV_GAME_APPID` 默认为 `225840`。自定义 mod 使用 `METAHOOKSV_GAME_MOD`，附加参数使用 `METAHOOKSV_GAME_ARGUMENTS`；支持 Debug 和 Release。

共享模块依次从 `METAHOOKSV_LAUNCH_GAME_MODULE_DIR`、所在 MetaHookSv 聚合仓库或固定提交的源码包获取。缺少 Installer 源码时自动下载 GitHub `latest` 的自包含 CLI，无需安装 .NET；可用 `METAHOOKSV_INSTALLER_RELEASE` 固定 tag，或用 `METAHOOKSV_INSTALLER_CLI_EXECUTABLE` 指定离线 EXE。插件模式要求 v20261004c 或之后版本。`build/launch/launch-game/installer/<release>` 下的有效缓存直接复用，不自动升级；切换 tag 或清理该私有缓存后重新下载。首次下载若触发 GitHub API 限流，可通过环境变量 `GH_TOKEN`/`GITHUB_TOKEN` 提供凭据。功能默认 OFF，关闭时不新增下载。

## 许可证

使用 [MIT License](LICENSE)，各依赖保留其自身许可证。
