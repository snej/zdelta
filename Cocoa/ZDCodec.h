//
//  ZDCodec.h
//  zdelta
//
//  Created by Jens Alfke on 2/23/15.
//  Copyright (c) 2015 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum : int {
    ZDStatusOK = 0,
    ZDStatusEOF = 1,    // decompressor reached EOF; not an error
    ZDStatusErrno = -1,
    ZDStatusStreamError = -2,
    ZDStatusDataError = -3,
    ZDStatusMemError = -4,
    ZDStatusBufError = -5,
    ZDStatusVersionError = -6
} ZDStatus;


/** Incremental, stream-like ZDelta compressor/decompressor. */
@interface ZDCodec : NSObject

/** Initializes a codec instance.
    @param source  The source data of the delta.
    @param compressing  YES if this operation will create a delta; in this case, the target version
            data should be passed to -addBytes. 
            Or NO if applying a data; in this case the delta data should be passed to -addBytes.
    @return  The initialized instance. */
- (instancetype)initWithSource: (NSData*)source
                   compressing: (BOOL)compressing;

/** Adds data to the codec -- target data if compressing, delta data if decompressing.
    This may generate output data, which will be passed to the onOutput block. 
    A single call to this method might not invoke the output block at all, or on the other
    hand it might invoke it multple times.

    When compressing, you must tell the codec the input is complete by calling it one more time
    with a length of zero. This will trigger it to output the remaining buffered data.

    The return value is YES if the codec is still ready for more input, NO if it's not.
    In the latter case, it's either reached EOF or an error; check the .status property. */
- (BOOL) addBytes: (const void*)bytes
           length: (size_t)length
         onOutput: (void(^)(const void*,size_t))onOutput;

/** The codec's current status. */
@property (readonly) ZDStatus status;

@end
