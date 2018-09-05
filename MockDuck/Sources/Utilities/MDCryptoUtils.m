//
//  MDCryptoUtils.m
//  MockDuck
//
//  Created by Sebastian Celis on 7/29/16.
//  Copyright © 2016 BuzzFeed, Inc. All rights reserved.
//

#import <CommonCrypto/CommonCrypto.h>
#import "MDCryptoUtils.h"

@implementation MDCryptoUtils

+ (NSString *)md5String:(NSData *)data {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end
