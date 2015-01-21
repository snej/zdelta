//
//  zdelta_Tests.m
//  zdelta Tests
//
//  Created by Jens Alfke on 10/27/13.
//  Copyright (c) 2013 zdelta. All rights reserved.
//

#import "NSData+zdelta.h"
#import "zdlib.h"
#import <XCTest/XCTest.h>

static NSData* randomData(size_t length) {
    NSMutableData* data = [NSMutableData dataWithLength: length];
    SecRandomCopyBytes(kSecRandomDefault, data.length, data.mutableBytes);
    return data;
}

@interface zdelta_Tests : XCTestCase
@end

@implementation zdelta_Tests
{
    NSString* _sourcePath, *_targetPath;
    NSData *_source, *_target;
}

- (void)setUp
{
    [super setUp];
    _sourcePath = [[NSBundle bundleForClass: [self class]] pathForResource: @"README" ofType: @""];
    XCTAssertNotNil(_sourcePath, @"Couldn't read README");
    _source = [NSData dataWithContentsOfFile: _sourcePath];
    _targetPath = [[NSBundle bundleForClass: [self class]] pathForResource: @"README" ofType: @"md"];
    XCTAssertNotNil(_targetPath, @"Couldn't read README.md");
    _target = [NSData dataWithContentsOfFile: _targetPath];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testDelta
{
    NSLog(@"zdelta version %s", zdlibVersion());
    NSLog(@"Source length = %u bytes", (unsigned)_source.length);
    NSLog(@"Target length = %u bytes", (unsigned)_target.length);

    NSData *delta = [_source zd_deltaTo: _source];
    XCTAssertNotNil(delta, @"zd_deltaTo: failed");
    NSLog(@"Null delta length = %u bytes", (unsigned)delta.length);

    delta = [_source zd_deltaTo: _target];
    XCTAssertNotNil(delta, @"zd_deltaTo: failed");
    NSLog(@"Delta length = %u bytes", (unsigned)delta.length);

    NSData* target2 = [_source zd_applyDelta: delta];
    XCTAssertNotNil(delta, @"zd_applyDelta: failed");
    XCTAssertEqualObjects(target2, _target, @"Applying delta gave wrong result");
}

- (void)testLargeDelta
{
    NSData* source = randomData(200000);
    NSData* target = randomData(200000);

    NSData *delta = [source zd_deltaTo: source];
    XCTAssertNotNil(delta, @"zd_deltaTo: failed");
    NSLog(@"Null delta length = %u bytes", (unsigned)delta.length);

    delta = [source zd_deltaTo: target];
    XCTAssertNotNil(delta, @"zd_deltaTo: failed");
    NSLog(@"Delta length = %u bytes", (unsigned)delta.length);

    NSData* target2 = [source zd_applyDelta: delta];
    XCTAssertNotNil(delta, @"zd_applyDelta: failed");
    XCTAssertEqualObjects(target2, target, @"Applying delta gave wrong result");
}

- (void) testIncrementalDelta {
    NSMutableData* delta = [NSMutableData data];
    BOOL ok = [_source zd_deltaTo: _target onOutput: ^BOOL(const void *deltaBytes, size_t deltaLength) {
        NSLog(@"... got %u bytes at %p", (unsigned)deltaLength, deltaBytes);
        [delta appendBytes: deltaBytes length: deltaLength];
        return YES;
    }];
    XCTAssert(ok, @"zd_deltaTo:onOutput: failed");
    NSLog(@"Delta length = %u bytes", (unsigned)delta.length);
    XCTAssertEqualObjects(delta, [_source zd_deltaTo: _target], @"Got wrong delta");
}

- (void) testLargeIncrementalDelta {
    NSData* source = randomData(200000);
    NSData* target = randomData(200000);
    NSMutableData* delta = [NSMutableData data];
    BOOL ok = [source zd_deltaTo: target onOutput: ^BOOL(const void *deltaBytes, size_t deltaLength) {
        NSLog(@"... got %u bytes at %p", (unsigned)deltaLength, deltaBytes);
        [delta appendBytes: deltaBytes length: deltaLength];
        return YES;
    }];
    XCTAssert(ok, @"zd_deltaTo:onOutput: failed");
    NSLog(@"Delta length = %u bytes", (unsigned)delta.length);
    XCTAssertEqualObjects(delta, [source zd_deltaTo: target], @"Got wrong delta");

    NSMutableData* target2 = [NSMutableData data];
    ok = [source zd_applyDelta: delta onOutput: ^BOOL(const void *targetBytes, size_t targetLength) {
        NSLog(@"... got %u bytes at %p", (unsigned)targetLength, targetBytes);
        [target2 appendBytes: targetBytes length: targetLength];
        return YES;
    }];
    XCTAssertEqualObjects(target2, target, @"Applying delta gave wrong incremental result");
}

- (void) testFileBasedDelta {
    NSData* delta = [_source zd_deltaTo: _target];
    NSError* error;
    BOOL ok = [NSData zd_applyDelta: delta
                             toFile: [NSURL fileURLWithPath: _sourcePath]
                      producingFile: [NSURL fileURLWithPath: @"/tmp/zdelta_tmp"]
                              error: &error];
    XCTAssert(ok);
    NSData* result = [NSData dataWithContentsOfFile: @"/tmp/zdelta_tmp"];
    XCTAssertEqualObjects(result, _target, @"Wrong target file contents");
}

- (void) testAdler {
    UInt32 sourceChecksum = _source.zd_adlerChecksum;
    UInt32 targetChecksum = _target.zd_adlerChecksum;
    NSLog(@"Source checksum = %08X", sourceChecksum);
    NSLog(@"Target checksum = %08X", targetChecksum);
    XCTAssertNotEqual(sourceChecksum, targetChecksum, @"Checksums shouldn't match");
    // (I guess theoretically there is a tiny chance they could match...)
}

@end
