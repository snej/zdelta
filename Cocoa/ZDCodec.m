//
//  ZDCodec.m
//  zdelta
//
//  Created by Jens Alfke on 2/23/15.
//  Copyright (c) 2015 Jens Alfke. All rights reserved.
//

#import "ZDCodec.h"
#import "zdlib.h"
#import "zd_mem.h"


#define kBufferSize (100*1024)


@implementation ZDCodec
{
    zd_stream _strm;
    zd_mem_buffer _buf;
    BOOL _open;
    BOOL _compressing;
}

@synthesize status=_status;


- (instancetype)initWithSource: (NSData*)source
                   compressing: (BOOL)compressing
{
    self = [super init];
    if (self) {
        _strm.base[0]       = (Bytef*)source.bytes;
        _strm.base_avail[0] = source.length;
        _strm.refnum        = 1;
        if (zd_alloc(&_buf, kBufferSize) == 0) {
            return nil;
        }
        _strm.next_out  = _buf.buffer;
        _strm.avail_out = _buf.size;
        _strm.total_out = 0;
        _compressing = compressing;
        int rval = compressing ? zd_deflateInit(&_strm,ZD_DEFAULT_COMPRESSION)
                               : zd_inflateInit(&_strm);
        if (rval != ZD_OK)
            return nil;
        _open = YES;
        _status = ZD_OK;

        // The base data isn't needed anymore after initialization
        _strm.base[0] = NULL;
        _strm.base_avail[0] = 0;
    }
    return self;
}

- (void)dealloc {
    [self close];
}

- (BOOL) close {
    if (_open) {
        if (_compressing)
            _status = zd_deflateEnd(&_strm);
        else
            _status = zd_inflateEnd(&_strm);
        _open = NO;
    }
    zd_free(&_buf);
    return (_status >= ZD_OK);
}

- (BOOL) addBytes: (const void*)bytes length: (size_t)length
         onOutput: (void(^)(const void*,size_t))onOutput
{
    if (!_open)
        return NO;
    _strm.next_in  = (Bytef*) bytes;
    _strm.avail_in = length;
    do {
        int rval;
        if (_compressing)
            rval = zd_deflate(&_strm, (length > 0 ? Z_NO_FLUSH : ZD_FINISH));
        else
            rval = zd_inflate(&_strm, ZD_SYNC_FLUSH);
        if (rval == ZD_BUF_ERROR || rval == ZD_STREAM_END || length == 0) {
            // Output is full, so deliver it:
            onOutput(_buf.buffer, _buf.size - _strm.avail_out);
            _strm.next_out  = _buf.buffer;
            _strm.avail_out = _buf.size;
            if (rval == ZD_BUF_ERROR)
                rval = ZD_OK;
        }
        if (rval != ZD_OK) {
            _status = rval;
            [self close];
            return NO;
        }
    } while (_strm.avail_in > 0);
    return YES;
}


@end
