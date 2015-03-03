//
//  ZDCodec.m
//  zdelta
//
//  Created by Jens Alfke on 2/23/15.
//  Copyright (c) 2015 Jens Alfke. All rights reserved.
//

#import "ZDCodec.h"
#import "zdlib.h"


#define kBufferSize (8*1024)


@implementation ZDCodec
{
    NSData* _source;
    zd_stream _strm;
    BOOL _open;
    BOOL _compressing;
    uint8_t _buffer[kBufferSize];
}

@synthesize status=_status;


- (instancetype)initWithSource: (NSData*)source
                   compressing: (BOOL)compressing
{
    self = [super init];
    if (self) {
        _source = source;
        _strm.base[0]       = (Bytef*)_source.bytes;
        _strm.base_avail[0] = _source.length;
        _strm.refnum        = 1;
        _strm.next_out  = _buffer;
        _strm.avail_out = (uInt)kBufferSize;
        _strm.total_out = 0;
        _compressing = compressing;
        int rval = compressing ? zd_deflateInit(&_strm,ZD_DEFAULT_COMPRESSION)
                               : zd_inflateInit(&_strm);
        if (rval != ZD_OK)
            return nil;
        _open = YES;
        _status = ZD_OK;
    }
    return self;
}

- (void) dealloc {
    [self close];
}

- (BOOL) close {
    if (_open) {
        int status;
        if (_compressing)
            status = zd_deflateEnd(&_strm);
        else
            status = zd_inflateEnd(&_strm);
        if (_status < ZD_OK && _status >= ZD_OK)
            _status = status;
        _open = NO;
    }
    return (_status >= ZD_OK);
}

- (BOOL) addBytes: (const void*)bytes length: (size_t)length
         onOutput: (void(^)(const void*,size_t))onOutput
{
    if (!_open) {
        if (length == 0)
            return YES;
        if (_status >= 0)
            _status = ZDStatusReadPastEOF;
        return NO;
    }
    _strm.next_in  = (Bytef*) bytes;
    _strm.avail_in = (uInt)length;
    do {
        int rval;
        if (_compressing)
            rval = zd_deflate(&_strm, (length > 0 ? Z_NO_FLUSH : ZD_FINISH));
        else
            rval = zd_inflate(&_strm, ZD_SYNC_FLUSH);
        if (rval == ZD_BUF_ERROR || rval == ZD_STREAM_END || length == 0) {
            // Output is full, so deliver it:
            onOutput(_buffer, kBufferSize - _strm.avail_out);
            _strm.next_out  = _buffer;
            _strm.avail_out = (uInt)kBufferSize;
            if (rval == ZD_BUF_ERROR)
                rval = ZD_OK;
        }
        if (rval != ZD_OK) {
            _status = rval;
            [self close];
            return rval == ZD_STREAM_END;
        }
    } while (_strm.avail_in > 0 || length == 0);
    return YES;
}


@end
