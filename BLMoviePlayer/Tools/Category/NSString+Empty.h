//
//  NSString+Empty.h
//  BLAudioPlayer
//
//  Created by Simon on 2019/7/26.
//  Copyright © 2019 Simon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Empty)

+ (BOOL)stringIsEmpty:(NSString *)str;
- (BOOL)isEmpty;

@end

NS_ASSUME_NONNULL_END
