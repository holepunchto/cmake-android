include_guard()

find_package(cmake-java REQUIRED PATHS node_modules/cmake-java)

function(find_d8 result)
  find_program(
    d8
    NAMES d8
    PATHS "${ANDROID_HOME}/build-tools/*"
    NO_DEFAULT_PATH
    REQUIRED
  )

  set(${result} ${d8})

  return(PROPAGATE ${result})
endfunction()

function(find_android_jar result)
  find_file(
    android_jar
    NAMES android.jar
    PATHS "${ANDROID_HOME}/platforms/${ANDROID_PLATFORM}"
    NO_DEFAULT_PATH
    NO_CMAKE_FIND_ROOT_PATH
    REQUIRED
  )

  set(${result} ${android_jar})

  return(PROPAGATE ${result})
endfunction()

function(add_dex target)
  set(one_value_keywords
    OUTPUT_DIR
  )

  set(multi_value_keywords
    SOURCES
    INCLUDE_JARS
  )

  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "" "${one_value_keywords}" "${multi_value_keywords}"
  )

  if(NOT DEFINED ARGV_OUTPUT_DIR)
    set(ARGV_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
  endif()

  add_jar(
    ${target}
    OUTPUT_NAME classes
    OUTPUT_DIR ${ARGV_OUTPUT_DIR}
    SOURCES ${ARGV_SOURCES}
    INCLUDE_JARS ${ARGV_INCLUDES_JARS}
  )

  find_d8(d8)

  set(args $<IF:$<CONFIG:Debug>,--debug,--release> --output ${CMAKE_BINARY_DIR})

  foreach(jar IN LISTS ARGV_INCLUDE_JARS)
    list(APPEND args --lib "${jar}")
  endforeach()

  list(APPEND args "${CMAKE_BINARY_DIR}/classes.jar")

  add_custom_command(
    TARGET ${target}
    POST_BUILD
    BYPRODUCTS "${CMAKE_BINARY_DIR}/classes.dex"
    COMMAND "${d8}" ${args}
  )

  set_target_properties(
    ${target}
    PROPERTIES
    DEX_FILE "${CMAKE_BINARY_DIR}/classes.dex"
  )
endfunction()
