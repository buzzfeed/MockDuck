//
//  MDCryptoUtils.h
//  MockDuck
//
//  Created by Sebastian Celis on 7/29/16.
//  Copyright © 2016 BuzzFeed, Inc. All rights reserved.
//

@import Foundation;

/// Some common crypto utilities that are diffiult to write in Swift. We should be able to migrate
/// this code to swift once Xcode 10 is released and CommonCryto is accessible from Swift.
@interface MDCryptoUtils : NSObject

/// Generate an MD5 hash string given some data.
+ (nonnull NSString *)md5String:(nonnull NSData *)data;

@end
