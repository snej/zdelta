//
//  zdelta+blocks.h
//  zdelta
//
//  Created by Jens Alfke on 10/27/13.
//

#ifndef zdelta_zdelta_blocks_h
#define zdelta_zdelta_blocks_h

#include "zdlib.h"

/* zdelta convenience API for use with Clang or other C compilers that support blocks. */

/*  Callback that gives chunks of output to the caller.
    A return value other than ZD_OK will stop the compress/uncompress operation and return the
    same error value from the function. */
typedef int (^zd_writer_block)(const Bytef* piece, uLongf size);

int ZEXPORT zd_compress_incr(const Bytef *ref, uLong rsize,
                             const Bytef *tar, uLong tsize,
                             zd_writer_block delta_writer);

int ZEXPORT zd_uncompress_incr(const Bytef *ref, uLong rsize,
                               zd_writer_block target_writer,
                               const Bytef *delta, uLong dsize);

#endif
