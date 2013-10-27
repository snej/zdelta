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
    NSData *_source, *_target;
}

- (void)setUp
{
    [super setUp];
    _source = [NSData dataWithContentsOfFile: @"../zdu.c"];
    XCTAssertNotNil(_source, @"Couldn't read zdu.c");
    _target = [NSData dataWithContentsOfFile: @"../_zdu.c"];
    XCTAssertNotNil(_target, @"Couldn't read _zdu.c");
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

@end
