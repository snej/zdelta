//
//  NSData+zdelta.h
//  zdelta
//
//  Created by Jens Alfke on 10/27/13.
//

#import <Foundation/Foundation.h>

/** Output block for writing delta or target data. Return NO to stop the process. */
typedef BOOL (^ZDeltaOutputBlock)(const void* bytes, size_t length);


@interface NSData (zdelta)

/** Generates a data blob (the "delta") that encapsulates the changes from the source data (the
    receiver) to the target data.
    Subsequently, applying the delta to an NSData equal to self will result in an NSData equal to
    the target data.
    The delta will ordinarily be significantly smaller than the targetData (that's the purpose of
    delta encoding) but in the worst case may be slightly larger. */
- (NSData*) zd_deltaTo: (NSData*)targetData;

/** Incremental delta generator. As the delta data is produced, the `onOutput` block is called
    with the bytes, which the caller is responsible for concatenating. */
- (BOOL) zd_deltaTo: (NSData*)targetData
           onOutput: (ZDeltaOutputBlock)outputBlock;


/** Applies a delta to source data (self), returning the target data. */
- (NSData*) zd_applyDelta: (NSData*)delta;

/** Incremental delta applicator. As the target data is produced, the `onOutput` block is called
    with the bytes, which the caller is responsible for concatenating. */
- (BOOL) zd_applyDelta: (NSData*)delta
              onOutput: (ZDeltaOutputBlock)outputBlock;

/** File-based delta applicator. Applies in-memory delta to a source file producing a target file.
    This memory-maps the source file and streams the target file, so it's useable even with very
    large files as long as there's enough free address space to map the source.
    If the target file already exists, it will be overwritten.
    If the operation fails, the target file will be deleted. */
+ (BOOL) zd_applyDelta: (NSData*)delta
                toFile: (NSURL*)sourceFileURL
         producingFile: (NSURL*)targetFileURL
                 error: (NSError**)outError;

/** Computes the 32-bit Adler checksum of the data. According to the zlib documentation,
    "An Adler-32 checksum is almost as reliable as a CRC32 but can be computed much faster."
    It's also much faster (and much smaller) than a SHA digest; but it's not safe against deliberate
    collision attacks, so it should never be used for security or cryptographc purposes.
    It's useful to send a checksum of the source along with a delta, so the recipient can verify
    that the source they have is the same as the one you generated the delta from; otherwise the
    target they create will be garbage. */
@property (readonly) UInt32 zd_adlerChecksum;

@end
