set(SCMODELDOWNLOADER_DEPENDENCY_CACHE_DIR "${PROJECT_SOURCE_DIR}/thirdparty/cache" CACHE PATH "Downloaded dependency cache")
set(VC_LTL_Root "${SCMODELDOWNLOADER_DEPENDENCY_CACHE_DIR}/VC-LTL-5.3.1" CACHE PATH "VC-LTL binary package root")
set(SCMODELDOWNLOADER_DEPENDENCIES METAHOOK VGUI2EXTENSION UTILASSETSINTEGRITY UTILHTTPCLIENT SCOPEEXIT RAPIDJSON)
foreach(dependency IN LISTS SCMODELDOWNLOADER_DEPENDENCIES)
    set(${dependency}_SOURCE_PATH "$ENV{${dependency}_SOURCE_PATH}" CACHE PATH "${dependency} source tree; empty fetches the pinned commit")
endforeach()

# Every dependency is consumed as headers (MetaHook also supplies the SDK
# compilation units), so an external tree must provide the files used here.
function(scmodeldownloader_require_files name source)
    foreach(required IN LISTS ARGN)
        if(NOT EXISTS "${source}/${required}" OR IS_DIRECTORY "${source}/${required}")
            message(FATAL_ERROR "${name} is missing ${required}: ${source}")
        endif()
    endforeach()
endfunction()

# Populate pinned dependency sources without configuring or building their targets.
function(scmodeldownloader_fetch_source name url tag out_var)
    include(FetchContent)
    FetchContent_Populate(${name}
        GIT_REPOSITORY "${url}"
        GIT_TAG "${tag}"
        GIT_SUBMODULES ""
        GIT_SUBMODULES_RECURSE FALSE
        SOURCE_DIR "${CMAKE_BINARY_DIR}/_deps/${name}-src")
    string(TOLOWER "${name}" name_lower)
    set(${out_var} "${${name_lower}_SOURCE_DIR}" PARENT_SCOPE)
endfunction()

function(scmodeldownloader_prepare_dependencies)
    set(METAHOOK_url https://github.com/MetaHookSv/MetaHook)
    set(METAHOOK_tag ed94e2e6e692e27ae125afc6d8f530e03ecdc5c1)
    set(METAHOOK_files include/metahook.h include/HLSDK/common/interface.cpp
        include/Interface/IPlugins.h include/Interface/VGUI/IPanel2.h
        include/SourceSDK/filesystem.cpp include/SourceSDK/tier1/strtools.cpp
        include/SourceSDK/vstdlib/IKeyValuesSystem.h include/vgui_controls/Panel.cpp)
    set(VGUI2EXTENSION_url https://github.com/MetaHookSv/VGUI2Extension)
    set(VGUI2EXTENSION_tag 07933adf727f8a9a5443d4591d4c1be23b1b9edf)
    set(VGUI2EXTENSION_files include/Interface/IVGUI2Extension.h include/Interface/IDpiManager.h
        include/Interface/VGUI/IInput2.h include/Interface/VGUI/IScheme2.h include/Interface/VGUI/ISurface2.h)
    set(UTILASSETSINTEGRITY_url https://github.com/MetaHookSv/UtilAssetsIntegrity)
    set(UTILASSETSINTEGRITY_tag d823d360a86248c0b3ee88e211608fa20036b49b)
    set(UTILASSETSINTEGRITY_files include/Interface/IUtilAssetsIntegrity.h)
    # Both UtilHTTPClient implementations ship the same header; the plugin prefers libcurl at runtime.
    set(UTILHTTPCLIENT_url https://github.com/MetaHookSv/UtilHTTPClient_libcurl)
    set(UTILHTTPCLIENT_tag 10233abbd7a2cb77e4a6bd158b2bd07cc742966b)
    set(UTILHTTPCLIENT_files include/Interface/IUtilHTTPClient.h)
    set(SCOPEEXIT_url https://github.com/SergiusTheBest/ScopeExit)
    set(SCOPEEXIT_tag bd345da594a4675d04de663d93d00cb81b6678b2)
    set(SCOPEEXIT_files include/ScopeExit/ScopeExit.h)
    set(RAPIDJSON_url https://github.com/Tencent/rapidjson)
    set(RAPIDJSON_tag 6089180ecb704cb2b136777798fa1be303618975)
    set(RAPIDJSON_files include/rapidjson/document.h)

    # External trees are read-only inputs; validate explicit paths before downloading anything.
    foreach(dependency IN LISTS SCMODELDOWNLOADER_DEPENDENCIES)
        if(${dependency}_SOURCE_PATH)
            get_filename_component(${dependency}_SOURCE_PATH "${${dependency}_SOURCE_PATH}" ABSOLUTE BASE_DIR "${PROJECT_SOURCE_DIR}")
            scmodeldownloader_require_files(${dependency}_SOURCE_PATH "${${dependency}_SOURCE_PATH}" ${${dependency}_files})
        endif()
    endforeach()

    foreach(dependency IN LISTS SCMODELDOWNLOADER_DEPENDENCIES)
        if(NOT ${dependency}_SOURCE_PATH)
            string(TOLOWER "${dependency}" name)
            scmodeldownloader_fetch_source(scmodeldownloader_${name}
                "${${dependency}_url}" "${${dependency}_tag}" ${dependency}_SOURCE_PATH)
            scmodeldownloader_require_files(${dependency}_SOURCE_PATH "${${dependency}_SOURCE_PATH}" ${${dependency}_files})
        endif()
        set(${dependency}_SOURCE_PATH "${${dependency}_SOURCE_PATH}" PARENT_SCOPE)
        message(STATUS "${dependency}_SOURCE_PATH: ${${dependency}_SOURCE_PATH}")
    endforeach()

    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/VCLTL.cmake")
    scmodeldownloader_prepare_vcltl()
endfunction()
