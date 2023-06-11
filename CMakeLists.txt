cmake_minimum_required(VERSION 3.19)

#Required
set(CMAKE_CXX_STANDARD 20)

project(
 4fpm
 VERSION 0.0.0
 LANGUAGES C CXX
 DESCRIPTION "At least 4 frames per minute, or your money back guaranteed"
)

#Explicitly disallow in-source builds
if("${PROJECT_SOURCE_DIR}" STREQUAL "${PROJECT_BINARY_DIR}")
 message(
  FATAL_ERROR
  "Go back to autotools, you're drunk. In-source builds are not permitted."
 )
endif()

#Coalesce sources and create executable target
file(
 GLOB_RECURSE 4fpm_SOURCES
 "src/**.cpp"
)
add_executable(4fpm ${4fpm_SOURCES})
target_include_directories(4fpm PUBLIC include)

#Default compilation flags
target_compile_options(
 4fpm
  -ftemplate-backtrace-limit=0
  -Wno-zero-length-array
)

#Configuration flags
set(4fpm_PEDANTIC ON CACHE BOOL "Enable strict compilation flags")
set(4fpm_DEBUG OFF CACHE BOOL "Enable debug code")
set(4fpm_LINK_ARDUINO_CORE OFF CACHE BOOL "Use the Arduino core libs")

#Handle strict compilation flags
if(4fpm_PEDANTIC)
 target_compile_options(
  4fpm
   -Wall
   -Wextra
   -Werror
   -pedantic
 )
else()
 #Emit a warning if strict compilation flags are disabled for whatever reason
 message(
  WARNING
  "Pedantic compilation flags are disabled. I hope you know what you're doing"
 )
endif()

#Handle debug compilation flags
if(4fpm_DEBUG)
 target_compile_options(
  4fpm PUBLIC
   -D4FPM_DEBUG=1
   -O0
   -g
   -fno-inline
   -fno-inline-functions
   -fno-omit-frame-pointer
   -fno-lto
   -fstandalone-debug
 )
endif()

#TODO: Link the Arduino core lib, if specified
if(4fpm_LINK_ARDUINO_CORE)
 message(
  FATAL_ERROR
  "Linking against the Arduino core libraries is currently unimplemented"
 )
endif()
