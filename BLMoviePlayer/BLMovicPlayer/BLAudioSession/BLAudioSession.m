//
//  BLAudioSession.m
//  BLMoviePlayer
//
//  Created by 刘朝龙 on 2019/10/13.
//  Copyright © 2019年 刘朝龙. All rights reserved.
//

#import "BLAudioSession.h"
#import <AVFoundation/AVFoundation.h>

@implementation BLAudioSession

- (instancetype)init {
    if (self = [super init]) {
        _session = [[AVAudioSession alloc] init];
        _preferredSampleRate = 44100.0f;
    }
    return self;
}

+ (instancetype)sharedInstance {
    static BLAudioSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        session = [[BLAudioSession alloc] init];
    });
    return session;
}

- (void)setPreferredDurationBuffer:(NSTimeInterval)preferredDurationBuffer {
    _preferredDurationBuffer = preferredDurationBuffer;
    
    NSError *error;
    if (![_session setPreferredIOBufferDuration:preferredDurationBuffer error:&error]) {
        NSLog(@"Error when set io buffer duration : %@", error.localizedDescription);
    }
}

- (void)setCategory:(NSString *)category {
    _category = category;
    
    NSError *error;
    if (![_session setCategory:category error:&error]) {
        NSLog(@"Error when set category : %@", error.localizedDescription);
    }
}

- (void)setAction:(BOOL)action {
    _action = action;
    
    NSError *error;
    if (![_session setPreferredSampleRate:_preferredSampleRate error:&error]) {
        NSLog(@"Error when set sample rate : %@", error.localizedDescription);
    }
    
    if (![_session setActive:_action error:&error]) {
        NSLog(@"Error when set action : %@", error.localizedDescription);
    }
    
    _currentSampleRate = _session.sampleRate;
}

@end
