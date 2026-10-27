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

function(find_android_stl)
  find_library(
    android_stl
    ${ANDROID_STL}
    PATHS "${CMAKE_SYSROOT}/usr/lib"
    PATH_SUFFIXES "${CMAKE_LIBRARY_ARCHITECTURE}"
    NO_DEFAULT_PATH
    NO_CMAKE_FIND_ROOT_PATH
    REQUIRED
  )

  set(${result} ${android_stl})

  return(PROPAGATE ${result})
endfunction()

function(find_android_jar result)
  set(one_value_keywords
    PLATFORM
  )

  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "" "${one_value_keywords}" ""
  )

  if(NOT DEFINED ARGV_PLATFORM)
    set(ARGV_PLATFORM ${ANDROID_PLATFORM})
  endif()

  find_file(
    android_jar
    NAMES android.jar
    PATHS "${ANDROID_HOME}/platforms/${ARGV_PLATFORM}"
    NO_DEFAULT_PATH
    NO_CMAKE_FIND_ROOT_PATH
    REQUIRED
  )

  set(${result} ${android_jar})

  return(PROPAGATE ${result})
endfunction()

function(add_dex target)
  set(one_value_keywords
    OUTPUT_NAME
    OUTPUT_DIR
  )

  set(multi_value_keywords
    SOURCES
    INCLUDE_JARS
    PROGUARD_RULES
  )

  cmake_parse_arguments(
    PARSE_ARGV 1 ARGV "" "${one_value_keywords}" "${multi_value_keywords}"
  )

  # R8 applies the rules embedded in the JAR when shrinking an application that
  # depends on it, such as to keep the classes that only native code calls.
  set(resources)

  if(DEFINED ARGV_PROGUARD_RULES)
    set(resources RESOURCES NAMESPACE "META-INF/proguard" ${ARGV_PROGUARD_RULES})
  endif()

  if(NOT DEFINED ARGV_OUTPUT_NAME)
    set(ARGV_OUTPUT_NAME ${target})
  endif()

  if(NOT DEFINED ARGV_OUTPUT_DIR)
    set(ARGV_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
  endif()

  add_jar(
    ${target}
    OUTPUT_NAME ${ARGV_OUTPUT_NAME}
    OUTPUT_DIR ${ARGV_OUTPUT_DIR}
    SOURCES ${ARGV_SOURCES}
    INCLUDE_JARS ${ARGV_INCLUDE_JARS}
    ${resources}
  )

  find_d8(d8)

  set(dex_dir "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/${target}.dir/dex")

  set(dex "${ARGV_OUTPUT_DIR}/${ARGV_OUTPUT_NAME}.dex")

  set(args $<IF:$<CONFIG:Debug>,--debug,--release> --output "${dex_dir}")

  foreach(jar IN LISTS ARGV_INCLUDE_JARS)
    list(APPEND args --lib "${jar}")
  endforeach()

  list(APPEND args "$<TARGET_PROPERTY:${target},JAR_FILE>")

  add_custom_command(
    TARGET ${target}
    POST_BUILD
    BYPRODUCTS "${dex}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${dex_dir}"
    COMMAND "${d8}" ${args}
    COMMAND "${CMAKE_COMMAND}" -E copy "${dex_dir}/classes.dex" "${dex}"
  )

  set_target_properties(
    ${target}
    PROPERTIES
    DEX_FILE "${dex}"
  )
endfunction()
