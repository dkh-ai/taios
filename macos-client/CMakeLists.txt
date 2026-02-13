cmake_minimum_required(VERSION 3.10)
project(TelegramMacOSClient)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Apple-specific settings
set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")
set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")

# Find required packages
find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)

# TDLib library path (from parent directory)
set(TDLIB_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/..")
set(TDLIB_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/../build")

# Include TDLib headers
include_directories(
    ${TDLIB_SOURCE_DIR}
    ${OPENSSL_INCLUDE_DIR}
    ${ZLIB_INCLUDE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Source files for TDLib bridge
set(TDLIB_BRIDGE_SOURCES
    TelegramClient/Bridge/TdBridge.cpp
)

set(TDLIB_BRIDGE_HEADERS
    TelegramClient/Bridge/TdBridge.h
)

# Create C++ library for TDLib bridge
add_library(TdBridge STATIC ${TDLIB_BRIDGE_SOURCES} ${TDLIB_BRIDGE_HEADERS})

# Link against TDLib and system libraries
target_link_libraries(TdBridge
    PRIVATE
        tdjson
        ${OPENSSL_LIBRARIES}
        ${ZLIB_LIBRARIES}
)

# Enable position-independent code for macOS
set_target_properties(TdBridge PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    FRAMEWORK FALSE
)

# Make library visible to Swift
set_target_properties(TdBridge PROPERTIES
    PUBLIC_HEADER "${TDLIB_BRIDGE_HEADERS}"
)

# Optional: Build as framework for easier Swift integration
add_library(TelegramClient FRAMEWORK STATIC)
target_link_libraries(TelegramClient PUBLIC TdBridge)

# Installation rules
install(TARGETS TdBridge
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    PUBLIC_HEADER DESTINATION include/TdBridge
)

# Enable testing
enable_testing()
add_subdirectory(Tests)
