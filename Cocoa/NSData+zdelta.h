//
//  NSData+zdelta.h
//  zdelta
//
//  Created by Jens Alfke on 10/27/13.
//

#import <Foundation/Foundation.h>

/** Output block for writing delta or target data. Return NO to stop the process. */
typedef BOOL (^ZDOutputBlock)(const void* bytes, size_t length);


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
           onOutput: (ZDOutputBlock)outputBlock;


/** Applies a delta to source data (self), returning the target data. */
- (NSData*) zd_applyDelta: (NSData*)delta;

/** Incremental delta applicator. As the target data is produced, the `onOutput` block is called
    with the bytes, which the caller is responsible for concatenating. */
- (BOOL) zd_applyDelta: (NSData*)delta
              onOutput: (ZDOutputBlock)outputBlock;

@end
