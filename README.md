# zdelta 2.1+

This is a Git repository containing the source code of the official zdelta 2.1 release, and incorporating patches for bug fixes that have since been discovered. 

## What is zdelta?

From the [zdelta home page](http://cis.poly.edu/zdelta/):

>zdelta is a general purpose lossless delta compression library developed at Polytechnic University. It is implemented by modifying the zlib 1.1.3 compression library (the modifications are marked in all of the original zlib 1.1.3 files). With its version 2.0, however, the library has significantly deviated from zlib, though it still uses a lot of the zlib code and structure. The zdelta algorithm was designed by Nasir Memon, Torsten Suel, and Dimitre Trendafilov, and implemented by Dimitre Trendafilov. The work on the library was supported by a grant from Intel Corporation. Torsten Suel was also supported by NSF CAREER Award NSF CCR-0093400.

zdelta has been used in a number of programs, but is no longer under active development; the latest version, 2.1, dates from 2004. Since then a few bugs have been discovered and fixed, but there doesn't seem to be any central record of the bugs or the fixes, or any version-controlled repository to track. So I've created one.

## How to build it

_From the comments in the Makefile:_

To compile and test, type:

    make test

To compile the command line delta compressor, type:

    make zdc 

To compile the command line delta decompressor, type:

    make zdu 

For multiple reference file support compile with `REFNUM=N` option
where `N` is the desired number (1..4) of reference files. The default
value is 1.

NOTE: The number of reference files comes at a price! Based on
the selected number of reference files the compression may degrade, 
and/or the memory usage may be increase. Do NOT add support for more 
reference files than you need!!!

To suppress the zdelta header and checksum compile with `-DNO_ERROR_CHECK`

To install `/usr/local/lib/libzd.*`, `/usr/local/include/zdlib.h`, and
`/usr/local/include/zdconf.h` type:

    make install
To install in $HOME instead of /usr/local, use:

    make install prefix=$HOME


_--Jens Alfke, 26 October 2013_
