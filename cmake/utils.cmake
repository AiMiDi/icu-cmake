# © 2023 and later: Aimdi.
# License & terms of use: https://github.com/AiMiDi/icu-cmake


# Get icu version from icu4c/source/common/unicode/uvernum.h and put it in ICU_VERSION
function(icu_extract_version)
  # Read the content of uvernum.h file
  file(READ "${ICU_PATH}/icu4c/source/common/unicode/uvernum.h" file_contents)
  
  # Match U_ICU_VERSION_MAJOR_NUM macro
  string(REGEX MATCH "U_ICU_VERSION_MAJOR_NUM ([0-9]+)" _ "${file_contents}")
  if(NOT CMAKE_MATCH_COUNT EQUAL 1)
    message(FATAL_ERROR "Could not extract major version number from unicode/uvernum.h")
  endif()
  set(ver_major ${CMAKE_MATCH_1})

  # Match U_ICU_VERSION_MINOR_NUM macro
  string(REGEX MATCH "U_ICU_VERSION_MINOR_NUM ([0-9]+)" _ "${file_contents}")
  if(NOT CMAKE_MATCH_COUNT EQUAL 1)
    message(FATAL_ERROR "Could not extract minor version number from unicode/uvernum.h")
  endif()
  set(ver_minor ${CMAKE_MATCH_1})
  
  # Match U_ICU_VERSION_PATCHLEVEL_NUM macro
  string(REGEX MATCH "U_ICU_VERSION_PATCHLEVEL_NUM ([0-9]+)" _ "${file_contents}")
  if(NOT CMAKE_MATCH_COUNT EQUAL 1)
    message(FATAL_ERROR "Could not extract patch version number from unicode/uvernum.h")
  endif()
  set(ver_patch ${CMAKE_MATCH_1})

  set(ICU_VERSION_MAJOR ${ver_major} PARENT_SCOPE)
  set(ICU_VERSION_MINOR ${ver_minor} PARENT_SCOPE)
  set(ICU_VERSION_PATCH ${ver_patch} PARENT_SCOPE)
  set(ICU_VERSION "${ver_major}.${ver_minor}.${ver_patch}" PARENT_SCOPE)
endfunction()

# Get icu source file list from sources.txt and put it in file_list
function(append_prefix_to_file_list sources_txt file_list path_prefix)
  # Read the contents of the input file to the file list
  file(STRINGS ${sources_txt} file_list_content)
  
  # Add a prefix to each file path
  list(TRANSFORM file_list_content PREPEND ${path_prefix})
  
  # Assign the list of processed files to external variables
  set(${file_list} ${file_list_content} PARENT_SCOPE)
endfunction()