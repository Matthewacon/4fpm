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

#[[
 TODO:
  - Add check for supported compilers, either clang or avr-gcc
  - Add clang cross-compilation support
]]

#Coalesce sources and create executable target
file(
 GLOB_RECURSE 4fpm_SOURCES
 "src/**.cpp"
)
add_executable("${PROJECT_NAME}" ${4fpm_SOURCES})
target_include_directories("${PROJECT_NAME}" PUBLIC include)

#Arduino board configuration, taken from `boards.txt`. Override as needed
set(AVR_HOME /usr/share/arduino/hardware/archlinux-arduino)
set(ARDUINO_BOARD AVR_NANO)
set(ARDUINO_CORE arduino)
set(ARDUINO_VARIANT eightanaloginputs)
set(ARDUINO_CPU atmega328p)
set(ARDUINO_CPU_FREQUENCY 16000000L)
set(ARDUINO_UPLOAD_MAXIMUM_SIZE 30720)
set(ARDUINO_UPLOAD_MAXIMUM_DATA_SIZE 2048)
set(ARDUINO_UPLOAD_SPEED 57600)
set(ARDUINO_BOOTLOADER_UNLOCK_BITS 0x3F)
set(ARDUINO_BOOTLOADER_LOCK_BITS 0x0F)
set(ARDUINO_BOOTLOADER_LOW_FUSES 0xFF)
set(ARDUINO_BOOTLOADER_HIGH_FUSES 0xDA)
set(ARDUINO_BOOTLOADER_EXTENDED_FUSES 0xFD)
set(ARDUINO_BOOTLOADER_FILE atmega/ATmegaBOOT_168_atmega328.hex)

#Default compilation flags
target_compile_options(
 "${PROJECT_NAME}" PUBLIC
  -fno-exceptions
  -ftemplate-backtrace-limit=0
  -Wno-zero-length-array
)

#Configuration flags
set(4fpm_PEDANTIC ON CACHE BOOL "Enable strict compilation flags")
set(4fpm_DEBUG OFF CACHE BOOL "Enable debug code")
set(4fpm_LINK_ARDUINO_CORE OFF CACHE BOOL "Use the Arduino core library")
set(4fpm_LINK_AVR_LIBC OFF CACHE BOOL "Use the avr-libc library")
set(4fpm_TESTS OFF CACHE BOOL "Build tests and add test target")

#Handle strict compilation flags
if(4fpm_PEDANTIC)
 target_compile_options(
  "${PROJECT_NAME}" PUBLIC
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

#Handle debug/non-debug compilation flags
if(4fpm_DEBUG)
 #Debug compiler flags
 target_compile_options(
  "${PROJECT_NAME}" PUBLIC
   -D4FPM_DEBUG=1
   -O0
   -g
   -fno-inline
   -fno-inline-functions
   -fno-omit-frame-pointer
   -fno-lto
   -fstandalone-debug
 )
else()
 #Non-debug compiler flags
 target_compile_options(
  "${PROJECT_NAME}" PUBLIC
   -Os
   -fno-threadsafe-statics
   -fno-devirtualize
   -flto
   -fno-fat-lto-objects
 )
endif()

#Build and link against the Arduino core lib, if specified
if(4fpm_LINK_ARDUINO_CORE)
 #Arduino core required flags
 list(
  APPEND ARDUINO_CORE_COMPILER_FLAGS
   -mmcu=${ARDUINO_CPU}
   -DF_CPU=${ARDUINO_CPU_FREQUENCY}
   -DARDUINO=1819
   -DARDUINO_${ARDUINO_BOARD}
   -DARDUINO_ARCH_AVR
   -DARDUINO_BOARD="\"${ARDUINO_BOARD}\""
   -DARDUINO_VARIANT="\"${ARDUINO_VARIANT}\""
   -D__PROG_TYPES_COMPAT__
   -ffunction-sections
   -fdata-sections
 )

 #[[
  Collect Arduino core sources, configure compilation and add core library
  target
 ]]
 set(ARDUINO_CORE_SOURCE_DIR "${AVR_HOME}/avr/cores/arduino")
 file(
  GLOB_RECURSE arduino_core_SOURCES
  "${ARDUINO_CORE_SOURCE_DIR}/**.cpp"
  "${ARDUINO_CORE_SOURCE_DIR}/**.c"
 )
 add_library(
  arduino_core STATIC
  ${arduino_core_SOURCES}
 )
 target_include_directories(
  arduino_core PUBLIC
  "${ARDUINO_CORE_SOURCE_DIR}"
 )

 #Add the board-specific variant headers to the core include path
 set(ARDUINO_VARIANT_HEADER_DIR "${AVR_HOME}/avr/variants/${ARDUINO_VARIANT}")
 target_include_directories(
  arduino_core PUBLIC
  "${ARDUINO_VARIANT_HEADER_DIR}"
 )

 #[[
  NOTE: The Arduino core lib does not enforce nearly as strict compilation
  flags as us, so it gets its own independnt compilation flags
 ]]
 target_compile_options(
  arduino_core PUBLIC
   ${ARDUINO_CORE_COMPILER_FLAGS}
   -fpermissive
   -Wno-error=narrowing
   -Wno-volatile
   -Wno-deprecated-functions
   -fno-exceptions
   -fno-threadsafe-statics
   -fno-devirtualize
   -flto
   -fno-fat-lto-objects
   -Os
 )

 #[[
  Add arduino core headers to include path and link main executable against
  core lib

  NOTE: We also add the Arduino core compiler flags, so included core headers
  are correctly configured
 ]]
 target_include_directories(
  "${PROJECT_NAME}" PUBLIC
  "${ARDUINO_CORE_SOURCE_DIR}"
 )
 target_link_libraries("${PROJECT_NAME}" arduino_core)
 target_compile_options(
  "${PROJECT_NAME}" PUBLIC
  ${ARDUINO_CORE_COMPILER_FLAGS}
 )
endif()

#[[
 TODO: Configure 4fpm to link against avr-libc

 NOTE: avr-libc is prebuilt, we only have headers, object files and archives
]]
if(4fpm_LINK_AVR_LIBC)
 message(
  FATAL_ERROR
  "Linking against avr-libc is currently unimplemented!"
 )
endif()

#TODO: Build tests and add test target
if(4fpm_TESTS)
 message(
  FATAL_ERROR
  "Tests are currently unimplemented!"
 )
endif()

#Add avr-objcopy targets to produce final ROM
set(OBJCOPY_EEP_OUTPUT "${PROJECT_BINARY_DIR}/${PROJECT_NAME}.eep")
add_custom_command(
 OUTPUT "${OBJCOPY_EEP_OUTPUT}"
 COMMAND /usr/bin/avr-objcopy
  -j .eeprom
  --set-section-flags=.eeprom='alloc,load'
  --no-change-warnings
  --change-section-lma .eeprom=0
  -O ihex
  "${PROJECT_BINARY_DIR}/${PROJECT_NAME}"
  "${OBJCOPY_EEP_OUTPUT}"
 DEPENDS "${PROJECT_NAME}"
)

set(OBJCOPY_BIN_OUTPUT "${PROJECT_BINARY_DIR}/${PROJECT_NAME}.bin")
add_custom_command(
 OUTPUT "${OBJCOPY_BIN_OUTPUT}"
 COMMAND /usr/bin/avr-objcopy
  -O binary
  "${PROJECT_BINARY_DIR}/${PROJECT_NAME}"
  "${OBJCOPY_BIN_OUTPUT}"
 DEPENDS "${PROJECT_NAME}"
)

set(OBJCOPY_HEX_OUTPUT "${PROJECT_BINARY_DIR}/${PROJECT_NAME}.hex")
add_custom_command(
 OUTPUT "${OBJCOPY_HEX_OUTPUT}"
 COMMAND /usr/bin/avr-objcopy
  -O ihex
  -R .eeprom
  "${PROJECT_BINARY_DIR}/${PROJECT_NAME}"
  "${OBJCOPY_HEX_OUTPUT}"
 DEPENDS "${PROJECT_NAME}"
)

add_custom_target(
 avr-size ALL
 COMMAND /usr/bin/avr-size
  --mcu="${ARDUINO_CPU}"
  -C
  --format=avr
  "${PROJECT_BINARY_DIR}/${PROJECT_NAME}"
 DEPENDS
  "${OBJCOPY_EEP_OUTPUT}"
  "${OBJCOPY_BIN_OUTPUT}"
  "${OBJCOPY_HEX_OUTPUT}"
  "${PROJECT_NAME}"
)

#Custom target to produce all artifacts required for avrdude uploads
add_custom_target(
 rom
 DEPENDS
  "${OBJCOPY_EEP_OUTPUT}"
  "${OBJCOPY_BIN_OUTPUT}"
  "${OBJCOPY_HEX_OUTPUT}"
  avr-size
)

#Add avrdude upload target
add_custom_target(
 upload
 COMMAND /usr/bin/avrdude
  -q
  -V
  -p "${ARDUINO_CPU}"
  -D
  -c arduino
  -b ${ARDUINO_UPLOAD_SPEED}
  -P "$$ARDUINO_SERIAL_PORT"
  -U "flash:w:${OBJCOPY_HEX_OUTPUT}:i"
 USES_TERMINAL
 DEPENDS rom
)
