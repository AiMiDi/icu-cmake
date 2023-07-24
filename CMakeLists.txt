# © 2023 and later: Aimdi.
# License & terms of use: https://github.com/AiMiDi/icu-cmake

cmake_minimum_required (VERSION 3.10...3.21)

# ----- Start icu project ----- 

if (POLICY CMP0135)
  # policy CMP0135 will use OLD behavior for consistency
  cmake_policy(SET CMP0135 OLD)
endif()

if(NOT ICU_PATH)
	set(ICU_PATH "${CMAKE_CURRENT_SOURCE_DIR}/icu")
endif()

include(cmake/utils.cmake)

icu_extract_version()

project (icu-cmake VERSION ${ICU_VERSION} LANGUAGES CXX)
message(STATUS "Build icu: ${ICU_VERSION}")

# Check if icu is being used directly or via add_subdirectory, but allow overriding
if(NOT DEFINED ICU_MASTER_PROJECT)
    if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
        set(ICU_MASTER_PROJECT ON)
    else()
        set(ICU_MASTER_PROJECT OFF)
    endif()
endif()

# ----- Compiler config ----- 

set(CMAKE_CXX_STANDARD 17)

# Set the compiler to support utf8
if (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options(-finput-charset=UTF-8)
elseif (CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
  add_compile_options(/utf-8)
endif()

if(MSVC)
  string(APPEND CMAKE_CXX_FLAGS " /Zc:__cplusplus /MP")
endif()


# ----- Setting -----

option(ICU_BUILD_UC "Build icu::uc" ON)
option(ICU_BUILD_I18N "Build icu::i18n" ON)
option(ICU_BUILD_IO "Build icu::io" ON)
option(ICU_BUILD_SHARED "Build shared library" OFF)
option(ICU_BUILD_DEBUG_INFO "Open debug info" OFF)
option(ICU_INSTALL "Generate the install target" ${ICU_MASTER_PROJECT})


# ----- Install setting -----

option(ICU_NO_INSTALL "Using libicu without installation" OFF)

if(NOT CMAKE_INSTALL_BINDIR)
  set(CMAKE_INSTALL_BINDIR "${CMAKE_INSTALL_PREFIX}/bin")
endif()

if(NOT CMAKE_INSTALL_LIBDIR)
  set(CMAKE_INSTALL_LIBDIR "${CMAKE_INSTALL_PREFIX}/lib")
endif()

if(NOT CMAKE_INSTALL_INCLUDEDIR)
  set(CMAKE_INSTALL_INCLUDEDIR "${CMAKE_INSTALL_PREFIX}/include/icu")
endif()


# ----- Info -----

message(STATUS "ICU source path: ${ICU_PATH}")
message(STATUS "Is build icu::uc: ${ICU_BUILD_UC}")
message(STATUS "Is build icu::i18n: ${ICU_BUILD_I18N}")
message(STATUS "Is build icu::io: ${ICU_BUILD_IO}")
message(STATUS "Is build icu shared library: ${ICU_BUILD_SHARED}")
message(STATUS "Is open debug info: ${ICU_BUILD_DEBUG_INFO}")
message(STATUS "Is generate the install target: ${ICU_INSTALL}")


# ----- Find source file -----

set(STUBDATA_SRC "icu/icu4c/source/stubdata/stubdata.cpp")
if(ICU_BUILD_UC)
  append_prefix_to_file_list("${ICU_PATH}/icu4c/source/common/sources.txt" UC_SOURCE_FILE_LIST "${ICU_PATH}/icu4c/source/common/")
  if(ICU_BUILD_DEBUG_INFO)
    foreach(file ${UC_SOURCE_FILE_LIST})
      message("icu::uc source file: ${file}")
    endforeach()
  endif()
endif()
if(ICU_BUILD_I18N)
  append_prefix_to_file_list("${ICU_PATH}/icu4c/source/i18n/sources.txt" I18N_SOURCE_FILE_LIST "${ICU_PATH}/icu4c/source/i18n/")
  if(ICU_BUILD_DEBUG_INFO)
    foreach(file ${I18N_SOURCE_FILE_LIST})
      message("icu::i18n source file: ${file}")
    endforeach()
  endif()
endif()
if(ICU_BUILD_IO)
  append_prefix_to_file_list("${ICU_PATH}/icu4c/source/io/sources.txt" IO_SOURCE_FILE_LIST "${ICU_PATH}/icu4c/source/io/")
  if(ICU_BUILD_DEBUG_INFO)
    foreach(file ${IO_SOURCE_FILE_LIST})
      message("icu::io source file: ${file}")
    endforeach()
  endif()
endif()


# ----- Build -----

if (ICU_BUILD_SHARED)
  set(BUILD_SHARED_LIBS True)
endif()

add_library(icu INTERFACE)

# add library
if(ICU_BUILD_UC)
  add_library(uc ${UC_SOURCE_FILE_LIST} ${STUBDATA_SRC})
  add_library(icu::uc ALIAS uc)
  set_target_properties(
    uc 
    PROPERTIES  
    PREFIX "libicu_"
    VERSION ${ICU_VERSION} 
    SOVERSION ${ICU_VERSION_MAJOR}.${ICU_VERSION_MINOR}
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
    VERSION ${ICU_VERSION} 
    SOVERSION ${ICU_VERSION_MAJOR}.${ICU_VERSION_MINOR}
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
    VERSION ${ICU_VERSION} 
    SOVERSION ${ICU_VERSION_MAJOR}.${ICU_VERSION_MINOR}
    DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
  target_compile_definitions(io PRIVATE U_IO_IMPLEMENTATION)
endif()

# set target properties
if (NOT BUILD_SHARED_LIBS)
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

if(ICU_BUILD_UC)
  target_include_directories(uc PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/include")
  target_include_directories(uc PUBLIC "$<BUILD_INTERFACE:${ICU_PATH}/icu4c/source/common>"
                                       "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")
endif()
if(ICU_BUILD_I18N)
  target_include_directories(i18n PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/include")
  target_include_directories(i18n PUBLIC "$<BUILD_INTERFACE:${ICU_PATH}/icu4c/source/i18n>"
                                       "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")
endif()
if(ICU_BUILD_IO)
  target_include_directories(io PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/include")
  target_include_directories(io PUBLIC "$<BUILD_INTERFACE:${ICU_PATH}/icu4c/source/io>"
                                       "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")
endif()


# ----- Link -----

if(ICU_BUILD_I18N)
  add_dependencies(i18n uc)
  target_link_libraries(i18n uc)
endif()
if(ICU_BUILD_IO)
  add_dependencies(io uc i18n)
  target_link_libraries(io uc i18n)
endif()


# ----- Install -----

if(ICU_INSTALL)

  message(STATUS "Generating install")
  set(project_config_in "${CMAKE_CURRENT_LIST_DIR}/cmake/ICUConfig.cmake.in")
  set(project_config_out "${CMAKE_CURRENT_BINARY_DIR}/ICUConfig.cmake")
  set(version_config_file "${CMAKE_CURRENT_BINARY_DIR}/ICUConfigVersion.cmake")
  set(config_targets_file "ICUConfigTargets.cmake")
  set(export_dest_dir "${CMAKE_INSTALL_LIBDIR}/cmake/icu")

  # Install include files
  install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include/unicode" DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

  # Install target
  if(ICU_BUILD_UC)
    install(
      TARGETS uc
      EXPORT ICU
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
  endif()
  
  if(ICU_BUILD_I18N)
    install(
      TARGETS i18n
      EXPORT ICU
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
  endif()
  
  if(ICU_BUILD_IO)
    install(
      TARGETS io
      EXPORT ICU
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
  endif()
  
  #Export target
  export(EXPORT ICU NAMESPACE icu:: FILE "${config_targets_file}")

  #Install ICUTargets.cmake
  install(EXPORT ICU DESTINATION "${export_dest_dir}" NAMESPACE icu:: FILE "${config_targets_file}")
  
  #Install CMake config files
  include(CMakePackageConfigHelpers)

  configure_package_config_file("${project_config_in}" "${project_config_out}" INSTALL_DESTINATION "${config_targets_file}")
  write_basic_package_version_file("${version_config_file}" COMPATIBILITY SameMajorVersion)

  #Install ICU-config.cmake
  install(FILES "${project_config_out}" "${version_config_file}" DESTINATION "${export_dest_dir}")

endif()