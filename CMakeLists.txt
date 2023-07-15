# © 2023 and later: Aimdi.
# License & terms of use: https://github.com/AiMiDi/icu-cmake

cmake_minimum_required (VERSION 3.8)

project (icu-cmake VERSION 1.0.2)

if (POLICY CMP0135)
    # policy CMP0135 will use OLD behavior for consistency
    cmake_policy(SET CMP0135 OLD)
endif()

# Set the compiler to support utf8
if (CMAKE_CXX_COMPILER_ID MATCHES "AppleClang")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Xclang -finput-charset -Xclang UTF-8")
elseif (CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -finput-charset=UTF-8")
elseif (CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
  add_compile_options(/utf-8)
endif()

# ----- Setting -----

option(ICU_BUILD_UC "Build icu::uc" ON)
option(ICU_BUILD_I18N "Build icu::i18n" ON)
option(ICU_BUILD_IO "Build icu::io" ON)

option(ICU_STATIC "Build static lib" OFF)

if(NOT ICU_PATH)
	set(ICU_PATH icu)
endif()

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
	foreach(file ${UC_SOURCE_FILE_LIST})
		message("icu::uc source file: ${file}")
	endforeach()
endif()
if(ICU_BUILD_I18N)
	append_prefix_to_file_list("${ICU_PATH}/icu4c/source/i18n/sources.txt" I18N_SOURCE_FILE_LIST "${ICU_PATH}/icu4c/source/i18n/")
	foreach(file ${I18N_SOURCE_FILE_LIST})
		message("icu::i18n source file: ${file}")
	endforeach()
endif()
if(ICU_BUILD_IO)
	append_prefix_to_file_list("${ICU_PATH}/icu4c/source/io/sources.txt" IO_SOURCE_FILE_LIST "${ICU_PATH}/icu4c/source/io/")
	foreach(file ${IO_SOURCE_FILE_LIST})
		message("icu::io source file: ${file}")
	endforeach()
endif()


# ----- Build -----

if (ICU_STATIC)
	if(ICU_BUILD_UC)
		add_library(uc STATIC ${UC_SOURCE_FILE_LIST} ${STUBDATA_SRC})
		add_library(icu::uc ALIAS uc)
		set_target_properties(
		   uc 
		   PROPERTIES 
		   VERSION ${PROJECT_VERSION} 
		   SOVERSION ${PROJECT_VERSION}
		   INTERFACE_COMPILE_DEFINITIONS "U_STATIC_IMPLEMENTATION" 
		   DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
		target_compile_definitions(uc PRIVATE U_STATIC_IMPLEMENTATION)
	endif()
	if(ICU_BUILD_I18N)
		add_library(i18n STATIC ${I18N_SOURCE_FILE_LIST})
		add_library(icu::i18n ALIAS i18n)
		set_target_properties(
		   i18n 
		   PROPERTIES 
		   VERSION ${PROJECT_VERSION} 
		   SOVERSION ${PROJECT_VERSION}
		   INTERFACE_COMPILE_DEFINITIONS "U_STATIC_IMPLEMENTATION" 
		   DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
		target_compile_definitions(i18n PRIVATE U_STATIC_IMPLEMENTATION)
	endif()
	if(ICU_BUILD_IO)
		add_library(io STATIC ${IO_SOURCE_FILE_LIST})
		add_library(icu::io ALIAS io)
		set_target_properties(
		   io 
		   PROPERTIES 
		   VERSION ${PROJECT_VERSION} 
		   SOVERSION ${PROJECT_VERSION}
		   INTERFACE_COMPILE_DEFINITIONS "U_STATIC_IMPLEMENTATION" 
		   DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
		target_compile_definitions(io PRIVATE U_STATIC_IMPLEMENTATION)
		add_dependencies(io uc)
	endif()
else()
	if(ICU_BUILD_UC)
		add_library(uc SHARED ${UC_SOURCE_FILE_LIST} ${STUBDATA_SRC})
		add_library(icu::uc ALIAS uc)
		set_target_properties(
		   uc 
		   PROPERTIES 
		   VERSION ${PROJECT_VERSION} 
		   SOVERSION ${PROJECT_VERSION} 
		   DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
	endif()
	if(ICU_BUILD_I18N)
		add_library(i18n SHARED ${I18N_SOURCE_FILE_LIST})
		add_library(icu::i18n ALIAS i18n)
		set_target_properties(
		   i18n 
		   PROPERTIES 
		   VERSION ${PROJECT_VERSION} 
		   SOVERSION ${PROJECT_VERSION} 
		   DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
	endif()
	if(ICU_BUILD_IO)
		add_library(io SHARED ${IO_SOURCE_FILE_LIST})
		add_library(icu::io ALIAS io)
		set_target_properties(
		   io 
		   PROPERTIES 
		   VERSION ${PROJECT_VERSION} 
		   SOVERSION ${PROJECT_VERSION} 
		   DEBUG_POSTFIX "${CMAKE_DEBUG_POSTFIX}")
	endif()
endif()  

if(ICU_BUILD_UC)
	target_compile_definitions(uc PRIVATE U_COMMON_IMPLEMENTATION)
	target_include_directories(uc PRIVATE "${ICU_PATH}/icu4c/source/common")
endif()
if(ICU_BUILD_I18N)
	target_compile_definitions(i18n PRIVATE U_I18N_IMPLEMENTATION)
	target_include_directories(i18n PRIVATE "${ICU_PATH}/icu4c/source/i18n")
	target_include_directories(i18n PRIVATE "${ICU_PATH}/icu4c/source/common")
	add_dependencies(i18n uc)
	target_link_libraries(i18n uc)
endif()
if(ICU_BUILD_IO)
	target_compile_definitions(io PRIVATE U_IO_IMPLEMENTATION)
	target_include_directories(io PRIVATE "${ICU_PATH}/icu4c/source/io")
	target_include_directories(io PRIVATE "${ICU_PATH}/icu4c/source/common")
	target_include_directories(io PRIVATE "${ICU_PATH}/icu4c/source/i18n")
	add_dependencies(io uc i18n)
	target_link_libraries(io uc i18n)
endif()



# ----- Install -----

if(NOT CMAKE_INSTALL_BINDIR)
  set(CMAKE_INSTALL_BINDIR ${CMAKE_INSTALL_PREFIX}/bin)
endif()

if(NOT CMAKE_INSTALL_LIBDIR)
  set(CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_PREFIX}/lib)
endif()

if(NOT CMAKE_INSTALL_INCLUDEDIR)
  set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_PREFIX}/include)
endif()

# Determine whether to build modules based on conditions
# Set the properties of the target, etc
if(ICU_BUILD_UC)
  # Installation header file
  # Search for .h files in the directory
  file(GLOB HEADER_FILES "${ICU_PATH}/icu4c/source/common/unicode/*.h")
  
  # Iterate over each .h file and copy to the installation directory
  foreach(header ${HEADER_FILES})
    
    # Install the file to the specified target path
    install(
      FILES ${header}
      DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/unicode"
    )
  endforeach()

 # Installation target
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
  # Installation header file
  # Search for .h files in the directory
  file(GLOB HEADER_FILES "${ICU_PATH}/icu4c/source/i18n/unicode/*.h")
  
  # Iterate over each .h file and copy to the installation directory
  foreach(header ${HEADER_FILES})
    
    # Install the file to the specified target path
    install(
      FILES ${header}
      DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/unicode"
    )
  endforeach()

  # Installation target
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
  # Installation header file
  # Search for .h files in the directory
  file(GLOB HEADER_FILES "${ICU_PATH}/icu4c/source/io/unicode/*.h")
  
  # Iterate over each .h file and copy to the installation directory
  foreach(header ${HEADER_FILES})
    
    # Install the file to the specified target path
    install(
      FILES ${header}
      DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/unicode"
    )
  endforeach()

  # Installation target
  install(
    TARGETS io
    EXPORT ICUTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )
endif()

include(CMakePackageConfigHelpers)

#Export target
export(
  EXPORT ICUTargets
  NAMESPACE icu::
  FILE "${CMAKE_CURRENT_BINARY_DIR}/ICUTargets.cmake"
)
#Install ICUTargets.cmake
install(
    FILES "${CMAKE_CURRENT_BINARY_DIR}/ICUTargets.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake"
)

#Export ICU-config.cmake
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
