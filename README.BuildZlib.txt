File README.BuildZlib.txt - Zlib build instructions for use with Hercules

This document Copyright © 2017 by Stephen R. Orso.  License at the bottom.

BUILDING the Zlib library for use by Hercules

    This repository builds a Zlib library for use by Hercules in a
    UNIX-like or Windows system (mac OS requires testing).  Hercules does
    not require anything but the library, and a CMake build script is
    included to generate the scripts needed to compile the library.
    A shared library (.so or .dll) is created; for Windows environments,
    a DLL import library is created as well.

    The original Zlib distribution, available from http://zlib.net, has
    an nmake-based build process that works with VS2015CE to build both
    32-bit and 64-bit versions of the libraries.   Two builds are needed
    to build the required libraries.


BUILDING the Zlib library using CMake

    If the Hercules build determines that the Zlib library included on
    target system is missing, does not have the development headers, or is
    at a lower version than the Zlib sources available in the
    Hercules-390 repository, Hercules will automatically build the Zlib
    library in the Hercules build directory; no additional steps are
    needed.

    If the target system has a Zlib library version the same as or higher
    than this version and the development headers and library are
    installed, the Hercules build will use that library, and again, no
    additional steps are required.

    If you wish to test an uplevel version of Zlib with Hercules, then
    use the following steps to build the Zlib library.  There is no
    need to "install" the library; Hercules can be pointed to the
    uplevel Zlib build directory.

    1.  If you are building on Windows, open a Visual Studio command
        prompt for the bit-ness of your system.  For example, on
        a 64-bit Windows 10 system with Visual Studio 2017 Community
        Edition installed, this would be "x64 Native Tools Command
        Prompt for VS 2017"

    2.  Clone this repository: git clone https://hercules-390/Zlib

    3.  Create the directory that will be the build directory you wish
        to populate with Zlib if needed.

    4.  Change to that build directory

    5.  Create the build scripts for the Zlib library by using the
        following CMake command:

            cmake <source-dir>

    6.  Build the Zlib library using the following CMake command:

            cmake --build .

        Include the option "--config Release" if building on Windows.

    7.  When building Hercules using CMake, use the command line option

            -DZlib_DIR=<build-dir>

        to point the Hercules build at your Zlib build directory.


BUILDING the Zlib library using the Zlib CMakeLists.txt (NOT RECOMMENDED)

   Zlib has a nearly complete CMake-based build process that generates
   dll and import libriaries.

   Build twice, once using a VS2015 x86 Native Tools command prompt, and
   once using a VS2015 x64 Native Tools command prompt.  You will need
   separate build directories for the 32-bit and 64-bit builds.

   1. Open a Visual Studio 2015 32-bit tools command prompt.  The Start
      Menu item is titled:

         VS2015 x86 Native Tools Command Prompt

   2. Issue the following command to start the CMake Windows GUI.

         cmake-gui

   3. Point cmake-gui at the source and build directories, then click
      Configure.  When asked to specify the generator for the project,
      select:

         "Visual Studio 14 2015"

      Do not specify "Visual Studio 14 2015 Win64".  You will do that
      when building the 64-bit libraries.  Leave "Use default native
      compilers" selected and Click Finish.

   4. Cmake-gui displaiys a list of options for building zlib.  Select
      BUILD_SHARED_LIBRARY, uncheck all of the other checkboxes, and
      click Configure again.  The options list changes from red to white.

   5. Click Generate.  When that completes, exit cmake-gui.

   6. Issue the following command to build the 32-bit dll and
      corresponding import library.  The Release directory will
      contain the created library and dll:

         cmake --build . -config release

   7. Copy the 32-bit files to the winbuild directory:

      <32-bit_build_dir>\release\zlib1.dll  --> winbuild\zlib
      <32-bit_build_dir>\release\zdll.lib   --> winbuild\zlib\lib
      <32-bit_build_dir>\zconf.h            --> winbuild\zlib\include
      <source_dir>\zlib.h                   --> winbuild\zlib\include

   8. Open a Visual Studio 2015 64-bit tools command prompt using the
      Windows Start menu.  On a 64-bit Windows machine, the start
      menu item is titled:

         VS2015 x64 Native Tools Command Prompt

      On a 32-bit machine, look for:

         VS2015 x86 x64 Cross Tools Command Prompt

   9. Issue the following command to start the CMake Windows GUI.

         cmake-gui

   10. Point cmake-gui at the source and build directories, then click
      Configure.  When asked to specify the generator for the project,
      select:

         "Visual Studio 14 2015 Win64"

      Leave "Use default native compilers" selected and Click Finish.

   11. Cmake-gui displaiys a list of options for building zlib.  Select
      BUILD_SHARED_LIBRARY, uncheck all of the other checkboxes, and
      click Configure again.  The options list changes from red to white.

   12. Click Generate.  When that completes, exit cmake-gui.

   13. Issue the following command to build the 64-bit dll and
      corresponding import library.  The Release directory will
      contain the created library and dll:

         cmake --build . -config release

   14. Copy the 64-bit files to the winbuild directory:

      <64-bit_build_dir>\release\zlib1.dll --> winbuild\zlib\x64
      <64-bit_build_dir>\release\zdll.lib  --> winbuild\zlib\x64\lib
      <64-bit_build_dir>\zconf.h           --> winbuild\zlib\x64\include
      <source_dir>\zlib.h                  --> winbuild\zlib\x64\include



This work is licensed under the Creative Commons Attribution- 
ShareAlike 4.0 International License. 

To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/ 
or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

