//
//  NSString+Empty.m
//  BLAudioPlayer
//
//  Created by Simon on 2019/7/26.
//  Copyright © 2019 Simon. All rights reserved.
//

#import "NSString+Empty.h"

@implementation NSString (Empty)

+ (BOOL)stringIsEmpty:(NSString *)str
{
    if (str &&
        !([str isEqualToString:@""] ||
          [str isEqualToString:@" "] ||
          [str isEqualToString:@"\r\n"] ||
          [str isEqualToString:@"\n"])) {
            return NO;
        }
    return YES;
}

- (BOOL)isEmpty
{
    if (!([self isEqualToString:@""] ||
          [self isEqualToString:@" "] ||
          [self isEqualToString:@"\r\n"] ||
          [self isEqualToString:@"\n"])) {
        return NO;
    }
    return YES;
}

@end
