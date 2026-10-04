# SCModelDownloader

[中文文档](README.zh-CN.md)

SCModelDownloader is a MetaHook plugin for Sven Co-op that downloads missing player models
from the [scmodels](https://wootguy.github.io/scmodels/) database automatically and reloads
them once the model files are ready.

It also adds a settings page and a download task list to the GameUI, and offers to switch
the local player to the latest version of an outdated model.

## Install

1. Install [MetaHookSv](https://github.com/MetaHookSv/MetaHook). A build from the pinned SDK
   requires MetaHook API 115 or newer.
2. Install the runtime dependencies:
   * [UtilHTTPClient_libcurl](https://github.com/MetaHookSv/UtilHTTPClient_libcurl/releases)
     (preferred) or [UtilHTTPClient_SteamAPI](https://github.com/MetaHookSv/UtilHTTPClient_SteamAPI/releases),
     loaded from `metahook/dlls`.
   * [UtilAssetsIntegrity](https://github.com/MetaHookSv/UtilAssetsIntegrity/releases),
     loaded from `metahook/dlls`; downloaded files are validated before they are written.
   * [VGUI2Extension](https://github.com/MetaHookSv/VGUI2Extension/releases), enabled in
     `plugins.lst`. Without it the settings page, task list and upgrade prompt are not registered.
3. Download `SCModelDownloader-windows-x86.7z` from
   [GitHub Releases](https://github.com/MetaHookSv/SCModelDownloader/releases), or build it locally.
4. Merge the package's `svencoop/` contents into your game's `svencoop` directory. Keep
   `metahook/plugins/SCModelDownloader.dll`, `metahook/gamedata/scmodeldownloader/` and
   `scmodeldownloader/` (UI layouts, localization and the bundled model database).
5. Add `SCModelDownloader.dll` on its own line in `metahook/configs/plugins.lst`, then launch through MetaHook.

## Console variables and commands

| Name | Default | Description |
| --- | --- | --- |
| `scmodel_autodownload` | `1` | Download missing player models automatically. |
| `scmodel_downloadlatest` | `1` | Download the latest version when a model has several versions. |
| `scmodel_cdn` | `0` | `0` downloads from GitHub, `1` from the jsDelivr CDN. |
| `scmodel_max_retry` | `3` | Retry limit for a failed download task; `0` retries without limit. |
| `scmodel_reload` | | Reload every player model. |

## Build

Requirements: Windows, Visual Studio 2022 with C++ tools, CMake 3.21 or newer,
Git, and Python 3.8 or newer. The plugin builds for MSVC x86 only.

```bat
scripts\build-SCModelDownloader-x86-Release.bat
scripts\build-SCModelDownloader-x86-Debug.bat
```

The scripts configure under `build/x86/<Configuration>` and install the DLL, PDB,
gamedata and UI assets under `install/x86/<Configuration>/svencoop`.
They do not deploy files into a local game installation.

The first configure fetches every source dependency at a pinned commit and a
SHA256-verified VC-LTL 5.3.1 binary package in `thirdparty/cache`. Dependencies are
consumed as headers (the MetaHook SDK also supplies its compilation units); none of their
projects are configured or built. The explicit source list preserves the original 13 plugin
and 105 SDK compilation units, with C++20 and a static CRT. The plugin neither uses Capstone
nor links `steam_api`.

| Variable | Repository | Pinned commit |
| --- | --- | --- |
| `METAHOOK_SOURCE_PATH` | [MetaHookSv/MetaHook](https://github.com/MetaHookSv/MetaHook) | `ed94e2e` |
| `VGUI2EXTENSION_SOURCE_PATH` | [MetaHookSv/VGUI2Extension](https://github.com/MetaHookSv/VGUI2Extension) | `07933ad` |
| `UTILASSETSINTEGRITY_SOURCE_PATH` | [MetaHookSv/UtilAssetsIntegrity](https://github.com/MetaHookSv/UtilAssetsIntegrity) | `d823d36` |
| `UTILHTTPCLIENT_SOURCE_PATH` | [MetaHookSv/UtilHTTPClient_libcurl](https://github.com/MetaHookSv/UtilHTTPClient_libcurl) | `10233ab` |
| `SCOPEEXIT_SOURCE_PATH` | [SergiusTheBest/ScopeExit](https://github.com/SergiusTheBest/ScopeExit) | `bd345da` |
| `RAPIDJSON_SOURCE_PATH` | [Tencent/rapidjson](https://github.com/Tencent/rapidjson) | `6089180` |

To use local repositories instead, pass their roots on the command line; each variable also
accepts an environment variable of the same name. Explicit paths are validated before anything
is downloaded. `UTILHTTPCLIENT_SOURCE_PATH` accepts either UtilHTTPClient repository, since
both ship the same `include/Interface/IUtilHTTPClient.h`.

```bat
scripts\build-SCModelDownloader-x86-Release.bat -DMETAHOOK_SOURCE_PATH=D:\MetaHook -DVGUI2EXTENSION_SOURCE_PATH=D:\VGUI2Extension -DUTILASSETSINTEGRITY_SOURCE_PATH=D:\UtilAssetsIntegrity -DUTILHTTPCLIENT_SOURCE_PATH=D:\UtilHTTPClient_libcurl
```

The interface repositories precede the MetaHook SDK on the include path, so their
`IVGUI2Extension.h`, `IInput2.h`, `IScheme2.h`, `ISurface2.h`, `IUtilHTTPClient.h` and
`IUtilAssetsIntegrity.h` take precedence over any copies in the SDK. Build scripts forward
additional CMake arguments.

## gamedata

Each build synchronizes and validates an upstream catalog, pruned to the engine
symbols consumed by SCModelDownloader: the `R_StudioDrawPlayer`, `studioapi_SetupPlayerModel`
and `Host_IsSinglePlayerGame` functions and the `DM_PlayerState` and `cl_players_model` globals.

The manifest declares the `svencoop-10257` and `svencoop-8948` engine snapshots. An unknown
engine or a missing required symbol causes a diagnostic error at runtime; the plugin has no
signature-scan fallback.

Use `-DSCMODELDOWNLOADER_SYNC_GAMEDATA=OFF` to skip downloading gamedata during a build;
provide a compatible catalog yourself when installing. To validate the installed catalog:

```bat
python scripts\validate-gamedata.py install\x86\Release\svencoop\metahook\gamedata\scmodeldownloader --manifest scripts\manifests\scmodeldownloader.json
```

## F5 debugging (optional)

Install MetaHook and enable this plugin in the game's `plugins.lst` first. Configure a standalone Visual Studio Win32 solution:

```powershell
cmake -S . -B build/launch -G "Visual Studio 17 2022" -A Win32 -DMETAHOOKSV_ENABLE_LAUNCH_GAME=ON
```

Open the solution, select **LaunchGame** and press **F5**. **DeployGame** builds this plugin and its dependencies, stages Install, and copies plugin DLLs/PDBs/resources before the native debugger starts the existing game launcher. Root launchers/runtime files and plugin lists remain unchanged. Set VS to build before running and **Do not launch** on build errors; stop the game before redeploying. Ordinary builds do not deploy.

`METAHOOKSV_GAME_DIRECTORY` defaults to Steam discovery; `METAHOOKSV_GAME_APPID` defaults to `225840`. Set `METAHOOKSV_GAME_MOD` for a custom mod and `METAHOOKSV_GAME_ARGUMENTS` for extra arguments. Debug and Release are supported.

The shared module uses `METAHOOKSV_LAUNCH_GAME_MODULE_DIR`, the surrounding MetaHookSv checkout, or a pinned source archive. Without Installer sources, it downloads the self-contained CLI from GitHub `latest` (no .NET required); `METAHOOKSV_INSTALLER_RELEASE` selects a fixed tag, and `METAHOOKSV_INSTALLER_CLI_EXECUTABLE` supplies an offline EXE. Plugin mode requires v20261004c or later. Valid caches under `build/launch/launch-game/installer/<release>` are reused without update checks; select another tag or clear that private cache to upgrade. `GH_TOKEN`/`GITHUB_TOKEN` may be supplied through the environment if GitHub API rate limits prevent the first download. The feature defaults OFF and performs no extra downloads when disabled.

## License

Licensed under the [MIT License](LICENSE); each dependency retains its own license.
