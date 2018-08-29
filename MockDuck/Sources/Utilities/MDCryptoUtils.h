//
//  MDCryptoUtils.h
//  MockDuck
//
//  Created by Sebastian Celis on 7/29/16.
//  Copyright © 2016 BuzzFeed, Inc. All rights reserved.
//

@import Foundation;

/**
 Some common crypto utilities that would be a PITA to write in Swift. Deal with it.
 */
@interface MDCryptoUtils : NSObject

/**
 Encode some data using SHA256.
 */
+ (nullable NSData *)encodeSHA256:(nonnull NSData *)data;

/**
 Generate an MD5 hash string for data.
 */
+ (nonnull NSString *)md5String:(nonnull NSData *)data;

@end
