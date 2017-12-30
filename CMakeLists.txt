# CMakeLists.txt - Build Zlib as needed for Hercules

#[[   Copyright 2017 by Stephen Orso.

      Distributed under the Boost Software License, Version 1.0.
      See accompanying file BOOST_LICENSE_1_0.txt or copy at
      http://www.boost.org/LICENSE_1_0.txt)
]]

#[[
This CMakeLists.txt for Zlib is based on the file CMakeLists.txt
that is provided with the upstream Zlib distribution.  The original
file is included in the pkg_src directory for reference.

The contents of pkg_src are Zlib 1.2.11, retrieved October 2017 from
https://zlib.net/

These are the differences from the win32/makefile.msc and CMakeLists.txt
included with the package:

- Normally, only the zlib library is built, as a shared library
  (libhercz.so or libz1.dll).  The static library is not built, as
  Hercules has no need of it.

- On Windows, a DLL import library is also built.

- On Windows, warning C4267 'var' : conversion from 'size_t' to 'type',
  possible loss of data is suppressed to eliminate noise messages when
  Hercules builds Zlib.

- If the option BUILD_TESTING is ON (-DBUILD_TESTING=ON), then the
  example and example64 executables are built and tests added for them.
  The executable is not included in the package installation.

- A WINTARGET option is added to allow generation for specific versions
  of the Windows API, with a range from WINXP364 to WIN10.

- The options to build assembly-language versions of selected routines
  are eliminated.  A single attempt to use these routines generated
  warnings that they were "use at your own risk," and a segment fault
  upon execution of the sample program.

- The entire unmodified Zlib distribution is stored in the pkg_src
  directory, and this script reflects that.  This should allow a
  complete replacement the pkg_src directory contents when an uplevel
  upstream Zlib distribution becomes available.

- On UNIX-like systems, the shared library is not versioned.  There is
  no need, as this build of the package is intended to be used with
  exactly one application, Hercules, and versioning issues are expected
  to be addressed as part of updating pkg-src with new upstream code.

The following describe the CMake-specific characteristics of this
script.

- The library installation target is exported to the zlib-targets
  sub-directory for inclusion by Hercules.

- The library target is also exported from the build tree to allow the
  Zlib library to be included by referencing the build directory.  If a
  Hercules builder elects to build this Zlib package, there is no need
  to install it; the build tree target can be imported.

- The two public headers are copied to the build tree so that the
  exported build tree target does not make any references to the source
  tree.

- For targets that support configurations (Windows and mac OS Xcode),
  only the Release and Debug configurations are supported.  The
  MinSizeRel and RelWithDebInfo configurations are removed if they are
  present in CMAKE_CONFIGURATION_TYPES.

- On Windows, for both Release and Debug configurations, linker .pdb
  files are created and included in the install of the library.

CMake 3.4 is the minimum version required to build Zlib because it is
the first version to include the boolean WINDOWS_EXPORT_ALL_SYMBOLS,
which creates the exports file (.def) needed to build DLLs from source
that lacks specific __declspec( dllexport ) declarations.

]]

# ----------------------------------------------------------------------
# Preamble: basic CMake setup, set configuration type(s), minimum CMake
# version required, and whether tests should be enabled.
# ----------------------------------------------------------------------

cmake_minimum_required( VERSION 3.4.0 )

project(zlib VERSION 1.2.11 LANGUAGES C )

include( herc_setWindowsTarget.cmake )

# In the Hercules repository for this package, source is one level down.
set( src_dir "pkg_src/"  )

option( BUILD_TESTING   "Build testing targets in addition to the library"  OFF )
option( DEBUG           "Build for debugging (no optimization etc)"         OFF )
## option( ASM686          "Enable building i686 assembly implementation"      OFF )
## option( AMD64           "Enable building amd64 assembly implementation"     OFF )

if( "${CMAKE_CONFIGURATION_TYPES}" STREQUAL "" )
# Generator in use creates build scripts for exactly one configuration.
# Determine whether this is a release or debug build.
    if( NOT DEBUG )
        set( CMAKE_BUILD_TYPE "Release" )
    else( )
        set( CMAKE_BUILD_TYPE "Debug" )
    endif( )
    message( STATUS "Single configuration generator; configuring for ${CMAKE_BUILD_TYPE}" )

else( )
# For generators that support multiple configurations with build-time
# configuration selection (Visual Studio or mac OS Xcode), CMake
# defaults to four configurations: Release, Debug, MinSizeRel, and
# RelWithDebInfo.  For now, only the first two are needed.  Remove the
# other two.
    list( REMOVE_ITEM CMAKE_CONFIGURATION_TYPES
                MinSizeRel
                RelWithDebInfo
                )
    message ( STATUS "Available configuration Types: ${CMAKE_CONFIGURATION_TYPES}"  )
endif( )

set(INSTALL_BIN_DIR "${CMAKE_INSTALL_PREFIX}/bin" CACHE PATH "Installation directory for executables")
set(INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib" CACHE PATH "Installation directory for libraries")
set(INSTALL_INC_DIR "${CMAKE_INSTALL_PREFIX}/include" CACHE PATH "Installation directory for headers")
set(INSTALL_MAN_DIR "${CMAKE_INSTALL_PREFIX}/share/man" CACHE PATH "Installation directory for manual pages")
set(INSTALL_PKGCONFIG_DIR "${CMAKE_INSTALL_PREFIX}/share/pkgconfig" CACHE PATH "Installation directory for pkgconfig (.pc) files")

include(CheckTypeSize)
include(CheckFunctionExists)
include(CheckIncludeFile)


# ----------------------------------------------------------------------
# Probe the target system.  Create the package configuration file and
# the zconf.h configuration header.  Also set compiler flags for
# macros that should be defined.

# Most preprocessor macros needed for Zlib are passed on the command
# line rather than in a config.h file.  The one possible configuration
# file would be zconf.h, and that is used as a public header, not as a
# package configuration header.
# ----------------------------------------------------------------------

check_include_file(sys/types.h HAVE_SYS_TYPES_H)
check_include_file(stdint.h    HAVE_STDINT_H)
check_include_file(stddef.h    HAVE_STDDEF_H)

#
# Check to see if we have large file support
#
set(CMAKE_REQUIRED_DEFINITIONS -D_LARGEFILE64_SOURCE=1)
check_type_size(off64_t OFF64_T)
if(HAVE_OFF64_T)
   add_definitions(-D_LARGEFILE64_SOURCE=1)
endif()
set(CMAKE_REQUIRED_DEFINITIONS "" )

#
# Check for fseeko
#
check_function_exists(fseeko HAVE_FSEEKO)
if(NOT HAVE_FSEEKO)
    add_definitions(-DNO_FSEEKO)
endif()

#
# Check for unistd.h
#
check_include_file(unistd.h Z_HAVE_UNISTD_H)

# Configure the package configuration and zconf.h files.

set(ZLIB_PC ${CMAKE_CURRENT_BINARY_DIR}/zlib.pc)
configure_file( ${CMAKE_CURRENT_SOURCE_DIR}/${src_dir}zlib.pc.cmakein
		${ZLIB_PC} @ONLY)
configure_file(	${CMAKE_CURRENT_SOURCE_DIR}/${src_dir}zconf.h.cmakein
		${CMAKE_CURRENT_BINARY_DIR}/include/zconf.h @ONLY)

include_directories( BEFORE ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${src_dir})

# When building for Windows, ensure that the correct Windows API version
# is used.  The default is the API version of the host system.  While we
# are here, ensure the debug library gets a different name and a exports
# file is created for later creation of the import library.

if( WIN32 )
    add_definitions( -DWIN32 )
    herc_setWindowsTarget( "${WINTARGET}" Windows_version )
    if( WINVER )
        add_definitions( -DWINVER=${WINVER}
                         -D_WIN32_WINNT=${_WIN32_WINNT}
                         -DNTDDI_VERSION=${NTDDI_VERSION}  )
    endif( )
    set( CMAKE_DEBUG_POSTFIX "d" )      # provide unique names for debug libs
endif( )   # if( WIN32 )

if( MSVC )
    set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /MP" )
endif(  )

# CMake pre-defined MSVC Release and Debug compiler flags are fine.
# CMake gcc flags need work; as provided, gcc provides "-O3 -DNDEBUG"
# for Release and "-g" for Debug.  We will avoid for the moment target
# architecture-specific optimizations.
# CMake clang flags are the same as those for gcc.  This script treats
# clang as identical to gcc.  For the moment we assume that this works
# for AppleClang as well.

if( ( ${CMAKE_C_COMPILER_ID} STREQUAL "GNU" )
        OR ( ${CMAKE_C_COMPILER_ID} STREQUAL "Clang" )
        OR ( ${CMAKE_C_COMPILER_ID} STREQUAL "AppleClang" ) )
    set( CMAKE_C_FLAGS_RELEASE "-Wall -Winline -O2 -g -DNDEBUG" )
    set( CMAKE_C_FLAGS_DEBUG   "-g3 -gdb3 -O0 -DDEBUG" )
elseif( MSVC )
    add_definitions( -D_CRT_SECURE_NO_DEPRECATE )
    add_definitions( -D_CRT_NONSTDC_NO_DEPRECATE )
    # Suppress warning C4267 'var' : conversion from 'size_t' to 'type',
    # possible loss of data
    set( CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /GL /Zi /wd4267 /MP" )
    set( CMAKE_C_FLAGS_DEBUG   "${CMAKE_C_FLAGS_DEBUG} /D DEBUG /D _DEBUG" )
    # Allow link-time code generation for Release builds (required and
    # implied for obj's compiled with /GL).  Ensure .pdb files are
    # created for release builds.
    set( CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG" )
    set( CMAKE_EXE_LINKER_FLAGS_RELEASE    "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /LTCG" )
    set( CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /LTCG" )
endif( )

get_property( __defns DIRECTORY PROPERTY COMPILE_DEFINITIONS )
message( STATUS "Compile definitions:   \"${__defns}\"" )
message( STATUS "C flags (Release) are: \"${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_RELEASE}\"" )
message( STATUS "C flags (Debug) are:   \"${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_DEBUG}\"" )


# ----------------------------------------------------------------------
# Source code definitions.
# ----------------------------------------------------------------------

set(ZLIB_PUBLIC_HDRS
    ${CMAKE_CURRENT_BINARY_DIR}/include/zconf.h
    ${src_dir}zlib.h
    )

# Copy the zlib.h public header to the build tree so that an export of
# build tree targets does not make any references to the source tree.
# The other public header, zconf.h, was generated directly to the
# include/ directory by configure_file().

file( COPY ${src_dir}zlib.h DESTINATION ${PROJECT_BINARY_DIR}/include )

set(ZLIB_PRIVATE_HDRS
    ${src_dir}crc32.h
    ${src_dir}deflate.h
    ${src_dir}gzguts.h
    ${src_dir}inffast.h
    ${src_dir}inffixed.h
    ${src_dir}inflate.h
    ${src_dir}inftrees.h
    ${src_dir}trees.h
    ${src_dir}zutil.h
    )

set(ZLIB_SRCS
    ${src_dir}adler32.c
    ${src_dir}compress.c
    ${src_dir}crc32.c
    ${src_dir}deflate.c
    ${src_dir}gzclose.c
    ${src_dir}gzlib.c
    ${src_dir}gzread.c
    ${src_dir}gzwrite.c
    ${src_dir}inflate.c
    ${src_dir}infback.c
    ${src_dir}inftrees.c
    ${src_dir}inffast.c
    ${src_dir}trees.c
    ${src_dir}uncompr.c
    ${src_dir}zutil.c
    )

set(ZLIB_DLL_SRCS
    ${src_dir}win32/zlib1.rc # If present will override custom build rule below.
    )


# Note: when the AMD64 assembler routine was included in a build on
# Debian 9, the assembler code issued a warning that it was "at your own
# risk," which was appropriate, because the example test promptly
# segment faulted.  So we will not support it.
##  # ----------------------------------------------------------------------
##  # If specified through options, enable assembly versions of selected
##  # routines.  Hercules does not by default enable assembly code, but
##  # it can be enabled in a separately-built external package.  And who
##  # knows, after some validation it might be enabled generally.  Clang
##  # support for these routines is another question.
##  # ----------------------------------------------------------------------
##
##  if(CMAKE_COMPILER_IS_GNUCC)
##      if(ASM686)
##          set(ZLIB_ASMS ${src_dir}contrib/asm686/match.S)
##      elseif (AMD64)
##          set(ZLIB_ASMS ${src_dir}contrib/amd64/amd64-match.S)
##      endif ()
##
##  	if(ZLIB_ASMS)
##  		add_definitions(-DASMV)
##  		set_source_files_properties(${ZLIB_ASMS} PROPERTIES LANGUAGE C COMPILE_FLAGS -DNO_UNDERLINE)
##  	endif()
##  endif()
##
##  if(MSVC)
##      if(ASM686)
##  		ENABLE_LANGUAGE(ASM_MASM)
##          set(ZLIB_ASMS
##  			contrib/masmx86/inffas32.asm
##  			contrib/masmx86/match686.asm
##  		)
##      elseif (AMD64)
##  		ENABLE_LANGUAGE(ASM_MASM)
##          set(ZLIB_ASMS
##  			contrib/masmx64/gvmat64.asm
##  			contrib/masmx64/inffasx64.asm
##  		)
##      endif()
##
##  	if(ZLIB_ASMS)
##  		add_definitions(-DASMV -DASMINF)
##  	endif()
##  endif()


# ----------------------------------------------------------------------
# Create target(s).  Only one is always created: zlib.  A target for the
#                    examples is created only if BUILD_TESTING is ON.
# ----------------------------------------------------------------------

# parse the full version number from zlib.h and include in ZLIB_FULL_VERSION
file(READ ${CMAKE_CURRENT_SOURCE_DIR}/${src_dir}zlib.h
            _zlib_h_contents
            REGEX "^#define[ \t]+ZLIB_VERSION[ \t]+\"[^\"]*\"$"
            )
string(REGEX REPLACE ".*#define[ \t]+ZLIB_VERSION[ \t]+\"([-0-9A-Za-z.]+)\".*"
    "\\1" ZLIB_FULL_VERSION ${_zlib_h_contents})


add_library(zlib SHARED ${ZLIB_SRCS} ${ZLIB_ASMS} ${ZLIB_DLL_SRCS} ${ZLIB_PUBLIC_HDRS} ${ZLIB_PRIVATE_HDRS})
# add_library(zlibstatic STATIC ${ZLIB_SRCS} ${ZLIB_ASMS} ${ZLIB_PUBLIC_HDRS} ${ZLIB_PRIVATE_HDRS})
set_target_properties(zlib PROPERTIES DEFINE_SYMBOL ZLIB_DLL)

if(UNIX)
   # On UNIX-like platforms the library is called libhercz.so
   set_target_properties(zlib PROPERTIES OUTPUT_NAME hercz)
#   if(NOT APPLE)
#     set_target_properties(zlib PROPERTIES LINK_FLAGS "-Wl,--version-script,\"${CMAKE_CURRENT_SOURCE_DIR}/${src_dir}zlib.map\"")
#   endif()
elseif( WIN32 )
    # On Windows, the shared library is named herczlib1.dll
    set_target_properties(zlib PROPERTIES OUTPUT_NAME herczlib1 )
endif()

# Define the location of the public headers that need to be part of the
# exported targets (build tree and install) for this target.  The
# generator expression $<BUILD_INTERFACE:...> has the expected value at
# build time and is the null string at install time, and vice versa for
# $<INSTALL_INTERFACE:..>.  Without target_include_directories(), the
# public header directory will never  appear in the exported targets.

target_include_directories( zlib PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
            $<INSTALL_INTERFACE:include> )


install(TARGETS zlib
        EXPORT  zlib            # Include target in export of
                                # ..install targets
        RUNTIME DESTINATION "${INSTALL_BIN_DIR}"
        ARCHIVE DESTINATION "${INSTALL_LIB_DIR}"
        LIBRARY DESTINATION "${INSTALL_LIB_DIR}"
        )

install(FILES ${ZLIB_PUBLIC_HDRS} DESTINATION "${INSTALL_INC_DIR}")

# Any .pdb debugging file generated by the MSVC linker is installed.
# The MSVC linker creates .pdb files when /DEBUG is specified as a
# line option.

if( MSVC )
    install( FILES ${PROJECT_BINARY_DIR}/Release/herczlib1.pdb
            DESTINATION bin
            CONFIGURATIONS Release )
    install( FILES ${PROJECT_BINARY_DIR}/Debug/herczlib1d.pdb
            DESTINATION bin
            CONFIGURATIONS Debug )
endif( )


# ----------------------------------------------------------------------
# Test cases: if testing is enabled, we build the example binaries
# ----------------------------------------------------------------------

if( BUILD_TESTING )
    enable_testing()
    add_executable(example ${src_dir}test/example.c)
    target_link_libraries(example zlib)
    add_test(example example)

    if(HAVE_OFF64_T)
        add_executable(example64 ${src_dir}test/example.c)
        target_link_libraries(example64 zlib)
        set_target_properties(example64 PROPERTIES COMPILE_FLAGS "-D_FILE_OFFSET_BITS=64")
        add_test(example64 example64)
    endif()
endif( )



# ----------------------------------------------------------------------
# Export the targets for later import by a downstream consumer of the
# Zlib library.  Use of imported targets means the consumer of the Zlib
# does not need to understand the directory structure of the Zlib build
# tree or install tree.
# ----------------------------------------------------------------------

# Create the export of the installation target.  This export can be
# imported by the CMake build for Hercules.

install( EXPORT zlib DESTINATION zlib-targets  )

# Create an export target of the build tree.  This allows the build tree
# to be used as an import target without requiring an install.  The build
# tree target import script is stored in the same relative location in
# the build tree as the installation target import script would be in
# install tree.  This lets Hercules include the import script without
# needing to know if it is from a build tree or an install tree.

export( EXPORT zlib FILE zlib-targets/zlib.cmake   )

return( )


# ----------------------------------------------------------------------
# Create target(s).  One is always created: Zlib.  A target for the
#                    examples is created only if BUILD_TESTING is ON.
# ----------------------------------------------------------------------

include_directories( ${PROJECT_SOURCE_DIR}/${src_dir}  )

# Add a target for the shared library libbz2.so or libbz2.dll.  If
# building on Windows, CMake will create the import library libbz2.lib.
# The CMake import target scripts will include the import library
# if building on a Windows host.

add_library(ZLib SHARED ${ZLIB_HEADERS} ${ZLIB_SOURCES} )
set_target_properties( BZlib2 PROPERTIES
        WINDOWS_EXPORT_ALL_SYMBOLS TRUE )

# Define the location of the public headers that need to be part of the
# exported targets (build tree and install) for this target.  The
# generator expression $<BUILD_INTERFACE:...> has the expected value at
# build time and is the null string at install time, and vice versa for
# $<INSTALL_INTERFACE:..>.  Without target_include_directories(), the
# public header directory will never  appear in the exported targets.

target_include_directories( BZlib2 PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
            $<INSTALL_INTERFACE:include> )

# If building testing targets, add the bzip2 executable and create
# the three tests.  The bzip2 target is never installed, but is instead
# used to run tests on the libbz2 library.

# If building on Windows, include setargv.obj from the Windows runtime
# for file name wildcarding.  While not really a link flag, including
# "setargv.obj" as a flag achieves the desired result.

if( BUILD_TESTING )
    add_executable( bzip2 ${BZIP2_SOURCES} )
    target_link_libraries( bzip2 BZlib2 )
    if( WIN32 )
        SET_TARGET_PROPERTIES(bzip2 PROPERTIES LINK_FLAGS "setargv.obj")
    endif( )
##  bzip2recover is not required for testing.  But one never knows what
##  the future holds.
#   add_executable( bzip2recover ${BZIP2RECOVER_SOURCES} )
#   target_link_libraries( bzip2recover BZlib2 )

    enable_testing( )

    add_test( NAME sample1.ref
          COMMAND ${CMAKE_COMMAND}
            -DBZIP2_PATH=$<TARGET_FILE:bzip2>
            -DBZIP2_OPTION=-1
            -DSRC_DIR=${CMAKE_CURRENT_SOURCE_DIR}/${src_dir}
            -DTEST_CASE=sample1
          -P ${CMAKE_CURRENT_SOURCE_DIR}/test_bzip2.cmake
    )

    add_test( NAME sample2.ref
          COMMAND ${CMAKE_COMMAND}
            -DBZIP2_PATH=$<TARGET_FILE:bzip2>
            -DBZIP2_OPTION=-2
            -DSRC_DIR=${CMAKE_CURRENT_SOURCE_DIR}/${src_dir}
            -DTEST_CASE=sample2
          -P ${CMAKE_CURRENT_SOURCE_DIR}/test_bzip2.cmake
    )

    add_test( NAME sample3.ref
          COMMAND ${CMAKE_COMMAND}
            -DBZIP2_PATH=$<TARGET_FILE:bzip2>
            -DBZIP2_OPTION=-3
            -DSRC_DIR=${CMAKE_CURRENT_SOURCE_DIR}/${src_dir}
            -DTEST_CASE=sample3
          -P ${CMAKE_CURRENT_SOURCE_DIR}/test_bzip2.cmake
    )

endif( )


# ----------------------------------------------------------------------
# Install the target, public headers, and if on Windows, the .pdb files
# ----------------------------------------------------------------------

# Install the target.  Include the target in the export of the install
# target.  For Windows, the shared DLL will be installed to the bin
# directory and the DLL import library will end up in lib.

install( TARGETS BZlib2
            EXPORT  BZlib2             # Include target in export of
                                       # ..install targets
            RUNTIME DESTINATION bin    # Used for Windows DLLs
            LIBRARY DESTINATION lib    # Used for static libraries or
                                       # ..UNIX-like shared libraries
            ARCHIVE DESTINATION lib )  # ARCHIVE used for the DLL import
                                       # ..library.
install( FILES ${BZLIB_PUBLIC_HEADERS} DESTINATION include )
install( FILES ${src_dir}LICENSE DESTINATION . )




# end CMakeLists.txt
