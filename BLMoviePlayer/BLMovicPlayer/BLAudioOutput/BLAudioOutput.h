//
//  BLAudioOutput.h
//  BLMoviePlayer
//
//  Created by 刘朝龙 on 2019/10/13.
//  Copyright © 2019年 刘朝龙. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BLAudioOutputDelegate <NSObject>

- (void)readSamples:(short *)samples withNumberFrame:(UInt32)numberFrame channels:(UInt32)channels;

@end

@interface BLAudioOutput : NSObject

- (instancetype)initWithSampleRate:(double)sampleRate
                          channels:(int)channels
                          delegate:(id <BLAudioOutputDelegate>)delegate;

- (void)play;
- (void)stop;

@end
