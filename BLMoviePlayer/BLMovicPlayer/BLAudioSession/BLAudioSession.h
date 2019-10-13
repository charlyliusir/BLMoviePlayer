//
//  BLAudioSession.h
//  BLMoviePlayer
//
//  Created by 刘朝龙 on 2019/10/13.
//  Copyright © 2019年 刘朝龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface BLAudioSession : NSObject

@property (nonatomic, readonly, strong) AVAudioSession *session;

@property (nonatomic, strong) NSString *category; // 分类
@property (nonatomic, assign) double preferredSampleRate;
@property (nonatomic, assign) double currentSampleRate;
@property (nonatomic, assign) NSTimeInterval preferredDurationBuffer;
@property (nonatomic, assign) BOOL action;

+ (instancetype)sharedInstance;

@end
