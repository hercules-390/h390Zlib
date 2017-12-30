# test_bzip2.cmake - Run a single BZip2 test case

#[[   Copyright 2017 by Stephen Orso.

      Distributed under the Boost Software License, Version 1.0.
      See accompanying file BOOST_LICENSE_1_0.txt or copy at
      http://www.boost.org/LICENSE_1_0.txt)
]]

#[[ ###########   macro herc_setWindowsTarget   ###########

Function/Operation
- Performs a test of BZip2 on a single test case file.  Test steps
  include the following:
  - Compress the file and compare the compressed file to a reference
    compressed file.
  - Decompress the file using normal memory allocation and compare the
    decompressed file to the original file.
  - Decompress the file using limited memory allocation ("-ds")and
    compare the decompressed file to the original file.
- If a specific version of Windows is the target, the variables
  WINVER, _WIN32_WINNT, and NTDDI_VERSION are set to the hex values
  that correspond to the target.
- If an invalid target version is specified, the returned descriptive
  target version is set to ${Windows_version}_NotFound.

Input
- The following macros must be defined, generally using -D
  - SRC_DIR: source directory containing the test cases.
  - TEST_CASE: Name of the test case.  Used as the file name component
    of the uncompressed input file.
  - BZIP2_PATH: Path to the bzip2 executable.  Must be passed as a
    macro so that we get bzip2 from the build directory.
  - BZIP2_OPTION: BZip2 compression option(s).
- The test case name should not include an extension; an extension of
  .ref will be used for input.  .rb2 will be used for the compressed
  result, and .tst will be used for the decompressed version of the
  compressed result.


Output
- Error messages directed to standard output.  These messages are
  captured by CTEST and recorded in the test log.  The FATAL_ERROR
  keyword ends test script execution and generates a non-zero return
  code.
- Success messages directed to standard output.  These messages are
  captured by CTEST and recorded in the test log.
- A compressed version of the test case file, with extension .rb2, in
  the working directory.
- A decompressed version of the compressed test case file, with
  extension .tst, in the working directory.

Notes
- Sample invocation using add_test():
        add_test( NAME sample1.ref
                  COMMAND ${CMAKE_COMMAND}
                    -DBZIP2_PATH=$<TARGET_FILE:bzip2>
                    -DBZIP2_OPTION=-1
                    -DSRC_DIR=${CMAKE_CURRENT_SOURCE_DIR}/<testcase_dir>
                    -DTEST_CASE=sample1
                  -P ${CMAKE_CURRENT_SOURCE_DIR}/test_bzip2.cmake
            )

]]


get_filename_component( input_file ${SRC_DIR}/${TEST_CASE}.ref REALPATH )
get_filename_component( compr_file ${SRC_DIR}/${TEST_CASE}.rb2 REALPATH )
get_filename_component( decmp_file ${SRC_DIR}/${TEST_CASE}.tst REALPATH )
get_filename_component( refbz_file ${SRC_DIR}/${TEST_CASE}.bz2 REALPATH )

if( NOT EXISTS "${input_file}" )
    message( FATAL_ERROR "Input file not found: ${input_file}" )
endif( )


# ----------------------------------------------------------------------
# compress the input test case

execute_process( COMMAND ${BZIP2_PATH} ${BZIP2_OPTION}
        RESULT_VARIABLE comp_rc
        INPUT_FILE      ${input_file}
        OUTPUT_FILE     ${compr_file}
        )
if( comp_rc )
    message( FATAL_ERROR "Compression failed RC=${comp_rc} processing file ${}" )
endif( )

# Compare the compressed test case to the reference compressed file

execute_process(COMMAND ${CMAKE_COMMAND} -E compare_files
        ${compr_file}
        ${refbz_file}
        RESULT_VARIABLE comp_rc
        )
if( comp_rc )
    message( FATAL_ERROR "Compression mismatch processing file ${input_file}" )
else( )
    message( "Compression successful:         ${input_file}" )
endif( )


# ----------------------------------------------------------------------
# Decompress the compressed test case using normal memory

execute_process( COMMAND ${BZIP2_PATH} "-d"
        RESULT_VARIABLE decomp_rc
        INPUT_FILE      ${compr_file}
        OUTPUT_FILE     ${decmp_file}
        )
if( decomp_rc )
    message( FATAL_ERROR "decompression (-d) failed RC=${decomp_rc} processing file ${compr_file}" )
endif( )

# Compare the decompressed test case to the original input file

execute_process(COMMAND ${CMAKE_COMMAND} -E compare_files
        ${input_file}
        ${decmp_file}
        RESULT_VARIABLE decomp_rc
        )
if( decomp_rc )
    message( FATAL_ERROR "Decompression (-d) mismatch comparing file ${decmp_file}" )
else( )
    message( "Deompression (-d) successful:   ${input_file}" )
endif( )


# ----------------------------------------------------------------------
# Decompress the compressed test case using limited memory

execute_process( COMMAND ${BZIP2_PATH} "-ds"
        RESULT_VARIABLE decomp_rc
        INPUT_FILE      ${compr_file}
        OUTPUT_FILE     ${decmp_file}
        )
if( decomp_rc )
    message( FATAL_ERROR "Decompression (-ds) failed RC=${decomp_rc} processing file ${compr_file}" )
endif( )

# Compare the decompressed test case to the original input file

execute_process(COMMAND ${CMAKE_COMMAND} -E compare_files
        ${input_file}
        ${decmp_file}
        RESULT_VARIABLE decomp_rc
        )
if( decomp_rc )
    message( FATAL_ERROR "Decompression (-ds) mismatch comparing file ${decmp_file}" )
else( )
    message( "Decompression (-ds) successful: ${input_file}" )
endif( )

