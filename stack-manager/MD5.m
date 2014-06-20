//
//  MD5.h
//  stack-manager
//
//  Created by Leonardo Murillo on 6/20/14.
//  Copyright (c) 2014 High Fidelity. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "MD5.h"

@implementation NSData(MD5)

- (NSString *)MD5
{
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, self.length, md5Buffer);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x",md5Buffer[i]];
    }
    return output;
}

@end