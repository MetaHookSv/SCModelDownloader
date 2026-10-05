# AGENTS.md

This file provides guidance and important rules working with code in this repository.

## When coding / building plan

- Use a progressive disclosure approach for agent coding in this repository: start from high-level
  information in the Basic Memory knowledge base first, and only locate/read specific files or
  symbols when necessary, instead of expanding a large amount of context at once.

### Basic Memory knowledge base (project-scoped, `memory/`)

- Notes live in `memory/` (markdown with YAML frontmatter: `title`/`type`/`permalink`), tracked in git.
- Notes use the `scmodeldownloader/` permalink prefix to distinguish them from the source repository.

### High-level information in this repository (read corresponding notes first)

- Project overview, provenance, hook pipeline, download state machine and dependencies:
  `project_overview`

### When notes are insufficient: source entry points (query and read on demand)

- Build: `CMakeLists.txt`, `cmake/Sources.cmake` (explicit compile list: 13 plugin + 105 SDK units),
  `cmake/Dependencies.cmake` (dependency pins and source-path resolution), `cmake/VCLTL.cmake`,
  `scripts/build-SCModelDownloader-x86-{Debug,Release}.bat`
- Plugin sources: `src/`; lifecycle `src/plugins.cpp`, replaced client exports and model-change
  pipeline `src/exportfuncs.cpp`, gamedata symbols and hooks `src/privatehook.cpp`, query tasks and
  databases `src/SCModelDatabase.cpp`, UI `src/BaseUI.cpp` / `src/GameUI.cpp` and the dialog/page
  classes, dependency access `src/UtilHTTPClient.cpp` / `src/UtilAssetsIntegrity.cpp` /
  `src/VGUI2ExtensionImport.cpp`
- Asset layout, localization and the bundled database: `assets/svencoop/scmodeldownloader/`;
  download output goes to `models/player/<name>/` in the game directory, working data to
  `scmodeldownloader/`
- Public API / interface: `src/SCModelDatabase.h` declares `ISCModelDatabase` and the callback
  interfaces; MetaHook, VGUI2Extension, UtilHTTPClient and UtilAssetsIntegrity are consumed as
  headers and their interface copies precede the MetaHook SDK on the include path
- gamedata: `scripts/manifests/scmodeldownloader.json` (three function and two global symbols),
  `scripts/sync-gamedata.py`, `scripts/validate-gamedata.py`; the build-time sync prunes the upstream
  catalog into the nested `metahook/gamedata/scmodeldownloader/` directory, which the host launcher
  merges
- Docs: `README.md` / `README.zh-CN.md` (install, console variables, build and gamedata). There is no
  test suite in this repository
- External sources, all read-only inputs: `METAHOOK_SOURCE_PATH`, `VGUI2EXTENSION_SOURCE_PATH`,
  `UTILASSETSINTEGRITY_SOURCE_PATH`, `UTILHTTPCLIENT_SOURCE_PATH` (either UtilHTTPClient repository),
  `SCOPEEXIT_SOURCE_PATH`, `RAPIDJSON_SOURCE_PATH`; each also accepts an environment variable, and
  explicit paths are validated before anything is downloaded. VC-LTL 5.3.1 is fetched into
  `thirdparty/cache`
- Build output: `build/x86/<configuration>/`; install output: `install/x86/<configuration>/svencoop/`.
  Neither is tracked, and nothing is deployed to the game automatically

### Progressive disclosure key points

- Read notes first, then locate a single file/symbol; do not read the whole repository at once.
- Prefer correctly scoped Basic Memory MCP tools for knowledge retrieval; otherwise use the local
  notes before reading source.
- Prefer Context7 for external dependency/library usage (query on demand).

## Repository rules

- Preserve the MetaHook API, plugin exports, calling conventions and the player-model trigger
  semantics. Match the naming, indentation and comment style of the files you touch.
- Resolve engine symbols only through the host gamedata contract. Do not add scan, string or
  control-flow fallbacks for symbols gamedata provides, and keep the failure mode fatal and specific
  (`Failed to resolve "<symbol>"` with buildnum / CRC64 / status).
- Keep the caller hooks evaluable at the caller entry, exactly reproducing the engine predicate, and
  keep the "call the trampoline once, return its value unchanged" ordering. The query must continue to
  read the state the original caller just wrote.
- Keep the ABI `static_assert`s in `src/privatehook.h` (`0x20C` / `0x130` / `0x250`) unless the engine
  layout contract is re-verified; `cl_players_model` is a member address, not a pointer slot.
- When gamedata usage changes, update `scripts/manifests/scmodeldownloader.json` in the same change.
  Network endpoints, cvar names/defaults and local data paths are user-visible contracts: change them
  together with `README.md` / `README.zh-CN.md`.
- Do not modify external sources or third-party sources. MetaHook, VGUI2Extension, UtilHTTPClient,
  UtilAssetsIntegrity, RapidJSON and ScopeExit are read-only build inputs; only MetaHook's compilation
  units are compiled here.
- The plugin builds for MSVC x86 only. Keep the static CRT / VC-LTL, C++20 and warning-level settings
  in `CMakeLists.txt` in sync with the other standalone plugin repositories.
- Verification distinguishes build checks from a real game run: there is no test suite here, and the
  UI, the engine hooks and the downloader all need a live Sven Co-op session. Claims about in-game
  behavior must not be made without evidence. Documentation changes need content, path and format
  checks, not a plugin rebuild.
