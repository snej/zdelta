//
//  NSData+zdelta.m
//  zdelta
//
//  Created by Jens Alfke on 10/27/13.
//

#import "NSData+zdelta.h"
#import "zdlib.h"
#import "zdelta+blocks.h"

@implementation NSData (zdelta)

- (NSData*) zd_deltaTo: (NSData*)targetData {
    NSParameterAssert(targetData != nil);
    Bytef* delta = NULL;
    uLongf deltaSize = 0;
    // http://cis.poly.edu/zdelta/manual.shtml#compress1
    int status = zd_compress1(self.bytes, self.length,
                             targetData.bytes, targetData.length,
                             &delta, &deltaSize);
    if (status != ZD_OK)
        return nil;
    return [NSData dataWithBytesNoCopy: delta length: deltaSize];
}

- (NSData*) zd_applyDelta: (NSData*)delta {
    NSParameterAssert(delta != nil);
    Bytef* target = NULL;
    uLongf targetSize = 0;
    // http://cis.poly.edu/zdelta/manual.shtml#uncompress1
    int status = zd_uncompress1(self.bytes, self.length,
                                &target, &targetSize,
                                delta.bytes, delta.length);
    if (status != ZD_OK)
        return nil;
    return [NSData dataWithBytesNoCopy: target length: targetSize];
}


- (BOOL) zd_deltaTo: (NSData*)targetData
           onOutput: (ZDeltaOutputBlock)outputBlock
{
    NSParameterAssert(targetData != nil);
    NSParameterAssert(outputBlock != nil);
    int status = zd_compress_incr(self.bytes, self.length,
                                  targetData.bytes, targetData.length,
                                  ^int(const Bytef* delta_piece, uLongf piece_size) {
                                      return outputBlock(delta_piece, piece_size) ? ZD_OK
                                                                                  : ZD_STREAM_ERROR;
                                  });
    return (status == ZD_OK);
}

- (BOOL) zd_applyDelta: (NSData*)delta
              onOutput: (ZDeltaOutputBlock)outputBlock
{
    NSParameterAssert(delta != nil);
    NSParameterAssert(outputBlock != nil);
    int status = zd_uncompress_incr(self.bytes, self.length,
                                    ^int(const Bytef* target_piece, uLongf piece_size) {
                                        return outputBlock(target_piece, piece_size) ? ZD_OK
                                                                                : ZD_STREAM_ERROR;
                                    },
                                    delta.bytes, delta.length);
    return (status == ZD_OK);
}

+ (BOOL) zd_applyDelta: (NSData*)delta
                toFile: (NSURL*)sourceFileURL
         producingFile: (NSURL*)targetFileURL
                 error: (NSError**)outError
{
    BOOL success = NO;
    NSData* sourceData = [[NSData alloc] initWithContentsOfURL: sourceFileURL
                                                       options: NSDataReadingMappedIfSafe|NSDataReadingUncached
                                                         error: outError];
    if (!sourceData)
        return NO;
    NSOutputStream* output = [NSOutputStream outputStreamWithURL: targetFileURL append: NO];
    [output open];
    
    if (!output.streamError) {
        success = [sourceData zd_applyDelta: delta onOutput: ^BOOL(const void *bytes, size_t length) {
            NSInteger written = [output write: bytes maxLength: length];
            return (written == length);
        }];
    }

    if (output.streamError) {
        if (outError)
            *outError = output.streamError;
        [[NSFileManager defaultManager] removeItemAtURL: targetFileURL error: NULL];
        success = NO;
    } else if (!success && outError) {
        *outError = [NSError errorWithDomain: @"zdelta" code: -1 userInfo: nil];  //TODO
    }
    [output close];
    return success;
}

- (UInt32) zd_adlerChecksum {
    // http://cis.poly.edu/zdelta/manual.shtml#Checksum%20functions
    uLong adler = zd_adler32(0L, ZD_NULL, 0);
    return (UInt32)zd_adler32(adler, self.bytes, (uint)self.length);
}


@end
