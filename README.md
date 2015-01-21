# zdelta 2.1+

This is a Git repository containing the source code of the official zdelta 2.1 release, and incorporating patches for bug fixes that have since been discovered. It also adds platform-specific wrapper APIs, for convenience; so far I've added one for Objective-C (supporting iOS and Mac OS X), but I'm open to submissions.

## What is zdelta?

Zdelta is a _delta-compression_ engine. Given two data blobs, a source and a target, it computes the differences between them and encodes that into an output blob called a _delta_. The delta isn't human-readable (and it should be treated as opaque by client programs), but the great thing about it is that it's usually much, much smaller than the target.

What's great about that? Because you can perform the inverse operation, applying the delta to the source, to reconstitute the target. That means that, if you already have the source, then having the (small) delta is equivalent to having the (large) target. This has uses such as:

* If two computers have the same source file, and it's then edited on one of them, the computer that did the editing can create a delta and send that to the other computer, which can apply it to its copy of the source, saving a lot of network bandwidth.
* If a program wants to keep archival copies of older versions of data (for undo purposes or for backup) it can store each old version as a _reverse delta_ from the next newer version. Older versions can then be reconstituted by applying one or more of these reverse deltas in sequence to the current version. (This is in fact how all serious version control systems, from CVS to Git, store files in their repositories.)

## History of zdelta

From the [zdelta home page](http://cis.poly.edu/zdelta/):

>zdelta is a general purpose lossless delta compression library developed at Polytechnic University. It is implemented by modifying the zlib 1.1.3 compression library (the modifications are marked in all of the original zlib 1.1.3 files). With its version 2.0, however, the library has significantly deviated from zlib, though it still uses a lot of the zlib code and structure. The zdelta algorithm was designed by Nasir Memon, Torsten Suel, and Dimitre Trendafilov, and implemented by Dimitre Trendafilov. The work on the library was supported by a grant from Intel Corporation. Torsten Suel was also supported by NSF CAREER Award NSF CCR-0093400.

zdelta has been used in a number of programs, but is no longer under active development; the latest version, 2.1, dates from 2004. Since then a few bugs have been discovered and fixed, but there doesn't seem to be any central record of the bugs or the fixes, or any version-controlled repository to track. So I've created one.

## How to build it

### Cross-platform

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

### Mac OS and iOS

There is an Xcode project in the `Cocoa` subdirectory. Its `xdelta` target produces a static library for 64-bit Mac OS that includes the core xdelta as well as some Objective-C wrappers (a category on NSData.) There is also an `xdelta-iOS` target for building an iOS static library.
