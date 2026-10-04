cmake_minimum_required(VERSION 3.21)
cmake_policy(SET CMP0091 NEW)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
project(SCModelDownloader LANGUAGES CXX)

if(NOT WIN32 OR NOT MSVC OR NOT CMAKE_SIZEOF_VOID_P EQUAL 4)
    message(FATAL_ERROR "SCModelDownloader requires Windows MSVC x86. Configure with -A Win32.")
endif()
get_property(multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(multi_config)
    set(CMAKE_CONFIGURATION_TYPES "Debug;Release" CACHE STRING "Supported configurations" FORCE)
elseif(NOT CMAKE_BUILD_TYPE MATCHES "^(Debug|Release)$")
    message(FATAL_ERROR "Select Debug or Release.")
endif()

include(cmake/Dependencies.cmake)
scmodeldownloader_prepare_dependencies()
include("${VC_LTL_Root}/VC-LTL helper for cmake.cmake")

# Include directories and definitions follow SCModelDownloader.vcxproj. The
# interface repositories come before the MetaHook SDK so their headers win over
# the SDK's older copies of IInput2.h / IUtilHTTPClient.h / IUtilAssetsIntegrity.h.
add_library(scmodeldownloader_settings INTERFACE)
target_compile_features(scmodeldownloader_settings INTERFACE cxx_std_20)
target_include_directories(scmodeldownloader_settings INTERFACE
    src
    "${VGUI2EXTENSION_SOURCE_PATH}/include/Interface"
    "${VGUI2EXTENSION_SOURCE_PATH}/include/Interface/VGUI"
    "${UTILASSETSINTEGRITY_SOURCE_PATH}/include/Interface"
    "${UTILHTTPCLIENT_SOURCE_PATH}/include/Interface"
    "${METAHOOK_SOURCE_PATH}/include"
    "${METAHOOK_SOURCE_PATH}/include/Interface"
    "${METAHOOK_SOURCE_PATH}/include/Interface/VGUI"
    "${METAHOOK_SOURCE_PATH}/include/HLSDK/cl_dll"
    "${METAHOOK_SOURCE_PATH}/include/HLSDK/common"
    "${METAHOOK_SOURCE_PATH}/include/HLSDK/engine"
    "${METAHOOK_SOURCE_PATH}/include/HLSDK/pm_shared"
    "${METAHOOK_SOURCE_PATH}/include/HLSDK/public"
    "${METAHOOK_SOURCE_PATH}/include/VGUI"
    "${METAHOOK_SOURCE_PATH}/include/vgui_controls"
    "${METAHOOK_SOURCE_PATH}/include/SourceSDK"
    "${METAHOOK_SOURCE_PATH}/include/SourceSDK/tier1"
    "${METAHOOK_SOURCE_PATH}/include/SourceSDK/tier3"
    "${METAHOOK_SOURCE_PATH}/include/SourceSDK/vstdlib"
    "${RAPIDJSON_SOURCE_PATH}/include"
    "${SCOPEEXIT_SOURCE_PATH}/include"
)
target_compile_definitions(scmodeldownloader_settings INTERFACE
    WIN32 _WINDOWS _USRDLL _MBCS
    VGUI_USE_SURFACE2 VGUI_USE_SCHEME2 VGUI_USE_INPUT2
    NO_MALLOC_OVERRIDE NO_TIER0_MINIDUMP NO_VCR
    $<$<CONFIG:Debug>:_DEBUG>
    $<$<CONFIG:Release>:NDEBUG>)
target_compile_options(scmodeldownloader_settings INTERFACE /permissive
    $<$<CONFIG:Debug>:/W0>
    $<$<CONFIG:Release>:/W3>
    /wd4311 /wd4312 /wd4819 /wd4996)

include(cmake/Sources.cmake)
add_library(SCModelDownloader SHARED ${SCMODELDOWNLOADER_SOURCES})
target_link_libraries(SCModelDownloader PRIVATE scmodeldownloader_settings)
target_compile_options(SCModelDownloader PRIVATE /MP /Zi)
target_link_options(SCModelDownloader PRIVATE /DEBUG /SUBSYSTEM:WINDOWS
    $<$<CONFIG:Debug>:/INCREMENTAL>
    $<$<CONFIG:Release>:/INCREMENTAL:NO>
    $<$<CONFIG:Release>:/OPT:REF>
    $<$<CONFIG:Release>:/OPT:ICF>)
set_target_properties(SCModelDownloader PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE)

install(TARGETS SCModelDownloader RUNTIME DESTINATION svencoop/metahook/plugins)
install(FILES "$<TARGET_PDB_FILE:SCModelDownloader>" DESTINATION svencoop/metahook/plugins)
# UI layouts, localization and the bundled model database (svencoop/scmodeldownloader).
install(DIRECTORY assets/ DESTINATION .)

option(SCMODELDOWNLOADER_SYNC_GAMEDATA "Download and prune SCModelDownloader's gamedata catalog before building" ON)
set(SCMODELDOWNLOADER_GAMEDATA_DIR "${PROJECT_BINARY_DIR}/assets/svencoop/metahook/gamedata/scmodeldownloader" CACHE PATH "SCModelDownloader gamedata catalog directory")
if(SCMODELDOWNLOADER_SYNC_GAMEDATA)
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    add_custom_target(SCModelDownloaderGameData
        COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/scripts/sync-gamedata.py"
            --manifest "${CMAKE_CURRENT_SOURCE_DIR}/scripts/manifests/scmodeldownloader.json"
            --target-dir "${SCMODELDOWNLOADER_GAMEDATA_DIR}" --temp-root "${PROJECT_BINARY_DIR}/gamedata-sync"
        COMMENT "Synchronizing and validating SCModelDownloader gamedata"
        VERBATIM)
    add_custom_target(SCModelDownloaderGameDataValidate
        COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/scripts/validate-gamedata.py"
            "${SCMODELDOWNLOADER_GAMEDATA_DIR}" --manifest "${CMAKE_CURRENT_SOURCE_DIR}/scripts/manifests/scmodeldownloader.json"
        COMMENT "Validating SCModelDownloader gamedata against the manifest"
        VERBATIM)
    add_dependencies(SCModelDownloaderGameDataValidate SCModelDownloaderGameData)
    add_dependencies(SCModelDownloader SCModelDownloaderGameDataValidate)
endif()
install(DIRECTORY "${SCMODELDOWNLOADER_GAMEDATA_DIR}/" DESTINATION svencoop/metahook/gamedata/scmodeldownloader OPTIONAL)

# The aggregate solution owns its single LaunchGame target.
if(CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
    option(METAHOOKSV_ENABLE_LAUNCH_GAME "Add the Visual Studio build/deploy/debug target" OFF)
    if(METAHOOKSV_ENABLE_LAUNCH_GAME)
        include(cmake/LaunchGame.cmake)
        metahooksv_add_launch_game()
    endif()
endif()
