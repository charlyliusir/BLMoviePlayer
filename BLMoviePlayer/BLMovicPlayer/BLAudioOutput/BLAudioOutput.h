//
//  BLAudioOutput.h
//  BLMoviePlayer
//
//  Created by 刘朝龙 on 2019/10/13.
//  Copyright © 2019年 刘朝龙. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BLAudioOutputDelegate <NSObject>

- (void)readSample:(Byte *)samples;

@end

@interface BLAudioOutput : NSObject

- (instancetype)initWithSampleRate:(double)sampleRate
                          channels:(int)channels
                          delegate:(id <BLAudioOutputDelegate>)delegate;

@end
