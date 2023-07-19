# © 2023 and later: Aimdi.
# License & terms of use: https://github.com/AiMiDi/icu-cmake

cmake_minimum_required (VERSION 3.8)

project (icu-cmake VERSION 1.0.5)

if (POLICY CMP0135)
  # policy CMP0135 will use OLD behavior for consistency
  cmake_policy(SET CMP0135 OLD)
endif()

set(CMAKE_CXX_STANDARD 17)

# Set the compiler to support utf8
if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options(-finput-charset=UTF-8)
elseif (CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
  add_compile_options(/utf-8)
endif()

if(NOT ICU_PATH)
	set(ICU_PATH "${CMAKE_CURRENT_SOURCE_DIR}/icu")
endif()

# ----- Version -----

# Read the content of uvernum.h file
file(STRINGS "${ICU_PATH}/icu4c/source/common/unicode/uvernum.h" UVERNUM_H_CONTENT)

# Match U_ICU_VERSION_MAJOR_NUM macro
string(REGEX MATCH "U_ICU_VERSION_MAJOR_NUM ([0-9]+)" major_match ${UVERNUM_H_CONTENT})
if (major_match)
  set(LIBICU_VERSION_MAJOR ${CMAKE_MATCH_1})
endif()

# Match U_ICU_VERSION_MINOR_NUM macro
string(REGEX MATCH "U_ICU_VERSION_MINOR_NUM ([0-9]+)" minor_match ${UVERNUM_H_CONTENT})
if (minor_match)
  set(LIBICU_VERSION_MINOR ${CMAKE_MATCH_1})
endif()

# Match U_ICU_VERSION_PATCHLEVEL_NUM macro
string(REGEX MATCH "U_ICU_VERSION_PATCHLEVEL_NUM ([0-9]+)" patch_match ${UVERNUM_H_CONTENT})
if (patch_match)
  set(LIBICU_VERSION_PATCH ${CMAKE_MATCH_1})
endif()

set(LIBICU_VERSION ${LIBICU_VERSION_MAJOR}.${LIBICU_VERSION_MINOR}.${LIBICU_VERSION_PATCH})
message("icu version: ${LIBICU_VERSION}")

# ----- Setting -----

option(ICU_BUILD_UC "Build icu::uc" ON)
option(ICU_BUILD_I18N "Build icu::i18n" ON)
option(ICU_BUILD_IO "Build icu::io" ON)

option(ICU_STATIC "Build static lib" OFF)
option(ICU_BUILD_DEBUG "Open debug info" OFF)

# ----- Install setting -----

option(ICU_NO_INSTALL "Using libicu without installation" OFF)

if(NOT CMAKE_INSTALL_BINDIR)
  set(CMAKE_INSTALL_BINDIR ${CMAKE_INSTALL_PREFIX}/bin)
endif()

if(NOT CMAKE_INSTALL_LIBDIR)
  set(CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_PREFIX}/lib)
endif()

if(NOT CMAKE_INSTALL_INCLUDEDIR)
  set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_PREFIX}/include/icu)
endif()


# ----- Info -----

message("ICU source path: ${ICU_PATH}")
message("Is build icu::uc: ${ICU_BUILD_UC}")
message("Is build icu::i18n: ${ICU_BUILD_I18N}")
message("Is build icu::io: ${ICU_BUILD_IO}")
message("Is build icu static lib: ${ICU_STATIC}")
message("Is Open debug info: ${ICU_BUILD_DEBUG}")
message("Is using libicu without installation: ${ICU_NO_INSTALL}")


function(append_prefix_to_file_list FILE_LIST_TXT FILE_LIST FILE_PREFIX)
  # Read the contents of the input file to the file list
  file(STRINGS ${FILE_LIST_TXT} FILE_LIST_CONTENT)
  
  # Add a prefix to each file path
  list(TRANSFORM FILE_LIST_CONTENT PREPEND ${FILE_PREFIX})
  
  # Assign the list of processed files to external variables
  set(${FILE_LIST} ${FILE_LIST_CONTENT} PARENT_SCOPE)
endfunction()


# ----- Find source file -----

set(STUBDATA_SRC "icu/icu4c/source/stubdata/stubdata.cpp")
if(ICU_BUILD_UC)
  append_prefix_to_file_list("${ICU_PATH}/icu4c/source/common/sources.txt" UC_SOURCE_FILE_LIST "${ICU_PATH}/icu4c/source/common/")
  if(ICU_BUILD_DEBUG)
    foreach(file ${UC_SOURCE_FILE_LIST})
      message("icu::uc source file: ${file}")
    endforeach()
  endif()
endif()
if(ICU_BUILD_I18N)
  append_prefix_to_file_list("${ICU_PATH}/icu4c/source/i18n/sources.txt" I18N_SOURCE_FILE_LIST "${ICU_PATH}/icu4c/source/i18n/")
  if(ICU_BUILD_DEBUG)
    foreach(file ${I18N_SOURCE_FILE_LIST})
      message("icu::i18n source file: ${file}")
    endforeach()
  endif()
endif()
if(ICU_BUILD_IO)
  append_prefix_to_file_list("${ICU_PATH}/icu4c/source/io/sources.txt" IO_SOURCE_FILE_LIST "${ICU_PATH}/icu4c/source/io/")
  if(ICU_BUILD_DEBUG)
    foreach(file ${IO_SOURCE_FILE_LIST})
      message("icu::io source file: ${file}")
    endforeach()
  endif()
endif()


# ----- Build -----

if (NOT ICU_STATIC)

endif()

# add library
if(ICU_BUILD_UC)
  add_library(uc ${UC_SOURCE_FILE_LIST} ${STUBDATA_SRC})
  add_library(icu::uc ALIAS uc)
  set_target_properties(
    uc 
    PROPERTIES  
    PREFIX "libicu_"
    VERSION ${PROJECT_VERSION} 
    SOVERSION ${PROJECT_VERSION}
    DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
  target_compile_definitions(uc PRIVATE U_COMMON_IMPLEMENTATION)
endif()
if(ICU_BUILD_I18N)
  add_library(i18n ${I18N_SOURCE_FILE_LIST})
  add_library(icu::i18n ALIAS i18n)
  set_target_properties(
    i18n 
    PROPERTIES  
    PREFIX "libicu_"
    VERSION ${PROJECT_VERSION} 
    SOVERSION ${PROJECT_VERSION}
    DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
  target_compile_definitions(i18n PRIVATE U_I18N_IMPLEMENTATION)
endif()
if(ICU_BUILD_IO)
  add_library(io ${IO_SOURCE_FILE_LIST})
  add_library(icu::io ALIAS io)
  set_target_properties(
    io 
    PROPERTIES 
    PREFIX "libicu_"
    VERSION ${PROJECT_VERSION} 
    SOVERSION ${PROJECT_VERSION}
    DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
  target_compile_definitions(io PRIVATE U_IO_IMPLEMENTATION)
endif()

# set target properties
if (ICU_STATIC)
  if(ICU_BUILD_UC)
    target_compile_definitions(uc PRIVATE U_STATIC_IMPLEMENTATION)
    set_target_properties(
      uc
      PROPERTIES
      INTERFACE_COMPILE_DEFINITIONS "U_STATIC_IMPLEMENTATION")
    if(MSVC)
      set_target_properties(
      	uc
      	PROPERTIES
      	DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}_static"
  		MINSIZEREL_POSTFIX "_static"
  		RELEASE_POSTFIX "_static"
  		RELWITHDEBINFO_POSTFIX "_static"
      )
    endif()
  endif()
  if(ICU_BUILD_I18N)
    target_compile_definitions(i18n PRIVATE U_STATIC_IMPLEMENTATION)
    set_target_properties(
      i18n
      PROPERTIES
      INTERFACE_COMPILE_DEFINITIONS "U_STATIC_IMPLEMENTATION")
    if(MSVC)
      set_target_properties(
      	i18n
      	PROPERTIES
          DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}_static"
  		MINSIZEREL_POSTFIX "_static"
  		RELEASE_POSTFIX "_static"
  		RELWITHDEBINFO_POSTFIX "_static"
      )
    endif()
  endif()
  if(ICU_BUILD_IO)
    target_compile_definitions(io PRIVATE U_STATIC_IMPLEMENTATION)
    set_target_properties(
      io
      PROPERTIES
      INTERFACE_COMPILE_DEFINITIONS "U_STATIC_IMPLEMENTATION")
    if(MSVC)
      set_target_properties(
      	io
      	PROPERTIES
      	DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}_static"
  		MINSIZEREL_POSTFIX "_static"
  		RELEASE_POSTFIX "_static"
  		RELWITHDEBINFO_POSTFIX "_static"
      )
    endif()
  endif()
else()
  set(BUILD_SHARED_LIBS ON)
  if(MSVC)
  	set(DLL_VARIABLE "__declspec (dllimport)")
  endif()
  if(ICU_BUILD_UC)
    target_compile_definitions(uc PRIVATE BUILDING_DLL)
  endif()
  if(ICU_BUILD_I18N)
    target_compile_definitions(i18n PRIVATE BUILDING_DLL)
  endif()
  if(ICU_BUILD_IO)
    target_compile_definitions(io PRIVATE BUILDING_DLL)
  endif()
endif()  


# ----- Set include dir -----

if(ICU_BUILD_UC)
  # Search for .h files in the directory
  file(GLOB HEADER_FILES "${ICU_PATH}/icu4c/source/common/unicode/*.h")
   
  # Iterate over each .h file and copy to the installation directory
  foreach(header ${HEADER_FILES})
     
    # Copy file to CMAKE_CURRENT_BINARY_DIR
    file(COPY ${header} DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/include/unicode")
  endforeach()
endif()
if(ICU_BUILD_I18N)
  # Search for .h files in the directory
  file(GLOB HEADER_FILES "${ICU_PATH}/icu4c/source/i18n/unicode/*.h")
  
  # Iterate over each .h file and copy to the installation directory
  foreach(header ${HEADER_FILES})
    
    # Copy file to CMAKE_CURRENT_BINARY_DIR
    file(COPY ${header} DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/include/unicode")
  endforeach()
endif()
if(ICU_BUILD_IO)
  # Search for .h files in the directory
  file(GLOB HEADER_FILES "${ICU_PATH}/icu4c/source/io/unicode/*.h")
  
  # Iterate over each .h file and copy to the installation directory
  foreach(header ${HEADER_FILES})
  
    # Copy file to CMAKE_CURRENT_BINARY_DIR
    file(COPY ${header} DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/include/unicode")
  endforeach()
endif()

if(ICU_NO_INSTALL)
  set(ICU_INCLUDEDIR "${CMAKE_CURRENT_BINARY_DIR}/include" PARENT_SCOPE)
else()
  set(ICU_INCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}/icu")
  set_target_properties(uc PROPERTIES INTERFACE_INCLUDE_DIRECTORIES ${ICU_UC_INCLUDEDIR})
endif()


# ----- Link -----

if(ICU_BUILD_UC)
  target_include_directories(uc PRIVATE "${ICU_PATH}/icu4c/source/common")
endif()
if(ICU_BUILD_I18N)
  add_dependencies(i18n uc)

  target_include_directories(i18n PRIVATE "${ICU_PATH}/icu4c/source/common")
  target_include_directories(i18n PRIVATE "${ICU_PATH}/icu4c/source/i18n")

  target_link_libraries(i18n PRIVATE uc)
endif()
if(ICU_BUILD_IO)
  add_dependencies(io uc i18n)

  target_include_directories(io PRIVATE "${ICU_PATH}/icu4c/source/common")
  target_include_directories(io PRIVATE "${ICU_PATH}/icu4c/source/i18n")
  target_include_directories(io PRIVATE "${ICU_PATH}/icu4c/source/io")

  target_link_libraries(io PRIVATE uc PRIVATE i18n)
endif()


# ----- Install -----

# Determine whether to build modules based on conditions

# Installation target
if(ICU_BUILD_UC)
  install(
    TARGETS uc
    EXPORT ICUTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )
endif()

if(ICU_BUILD_I18N)
  install(
    TARGETS i18n
    EXPORT ICUTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )
endif()

if(ICU_BUILD_IO)
  install(
    TARGETS io
    EXPORT ICUTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )
endif()

# Installation header file
install(
  DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include/unicode"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

#Export target
export(
  EXPORT ICUTargets
  NAMESPACE icu::
  FILE "${CMAKE_CURRENT_BINARY_DIR}/ICUTargets.cmake"
)
#Install ICUTargets.cmake
install(
  EXPORT ICUTargets
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake"
  NAMESPACE icu::
  FILE "ICUTargets.cmake"
)

#Export ICU-config.cmake
include(CMakePackageConfigHelpers)
configure_package_config_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/ICU-config.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/ICU-config.cmake"
  INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake"
)
#Install ICU-config.cmake
install(
  FILES "${CMAKE_CURRENT_BINARY_DIR}/ICU-config.cmake"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake"
)
