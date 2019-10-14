//
//  BLAudioOutput.m
//  BLMoviePlayer
//
//  Created by 刘朝龙 on 2019/10/13.
//  Copyright © 2019年 刘朝龙. All rights reserved.
//

#import "BLAudioOutput.h"
#import "BLAudioSession.h"
#import <AudioUnit/AudioUnit.h>

#define BL_IO_ELEMENT_OUTPUT    0
#define BL_IO_ELEMENT_INPUT     1
#define BL_IO_OUTPUT_BUS        0
#define BL_IO_INPUT_BUS         1

#define BL_CVT_ELEMENT          0
#define BL_CVT_OUTPUT_BUS       0
#define BL_CVT_INPUT_BUS        1

@interface BLAudioOutput () {
    AUGraph ioGraph;
    
    AUNode ioNode;
    AUNode cvtNode;
    
    AudioUnit ioUnit;
    AudioUnit cvtUnit;
    
    short *sampleBuffer;
    
}

@property (nonatomic, assign) int sampleRate;
@property (nonatomic, assign) int channels;
@property (nonatomic, weak) id <BLAudioOutputDelegate>delegate;

@end

@implementation BLAudioOutput

- (instancetype)initWithSampleRate:(double)sampleRate
                          channels:(int)channels
                          delegate:(id <BLAudioOutputDelegate>)delegate {
    if (self = [super init]) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    // 1. 设置音频播放环境
    [self setupAudioSession];
    // 2. 初始化缓冲空间
    [self setupBuffer];
    // 3. 初始化AUGraph&AUnit
    [self setupAUGraph];
}

- (void)setupAudioSession {
    [[BLAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback];
    [[BLAudioSession sharedInstance] setPreferredSampleRate:_sampleRate];
    [[BLAudioSession sharedInstance] setAction:YES];
}

- (void)setupBuffer {
    sampleBuffer = (short *)malloc(1024*10*4);
}

- (void)setupAUGraph {
    NewAUGraph(&ioGraph);
    AUGraphOpen(ioGraph);
    
    // 添加Node
    AudioComponentDescription ioComponent;
    ioComponent.componentType           = kAudioUnitType_Output;
    ioComponent.componentSubType        = kAudioUnitSubType_RemoteIO;
    ioComponent.componentManufacturer   = kAudioUnitManufacturer_Apple;
    ioComponent.componentFlags          = 0;
    ioComponent.componentFlagsMask      = 0;
    AUGraphAddNode(ioGraph, &ioComponent, &ioNode);
    AUGraphNodeInfo(ioGraph, ioNode, NULL, &ioUnit);
    
    AudioComponentDescription cvtComponent;
    cvtComponent.componentType           = kAudioUnitType_FormatConverter;
    cvtComponent.componentSubType        = kAudioUnitSubType_AUConverter;
    cvtComponent.componentManufacturer   = kAudioUnitManufacturer_Apple;
    cvtComponent.componentFlags          = 0;
    cvtComponent.componentFlagsMask      = 0;
    AUGraphAddNode(ioGraph, &cvtComponent, &cvtNode);
    AUGraphNodeInfo(ioGraph, cvtNode, NULL, &cvtUnit);
    
    AUGraphConnectNodeInput(ioGraph, ioNode, BL_IO_ELEMENT_OUTPUT, cvtNode, BL_CVT_ELEMENT);
    
    [self setupUnitProperty];
    
    AUGraphInitialize(ioGraph);
}

- (void)setupUnitProperty {
    
}

- (AudioStreamBasicDescription *)outputFormat {
    AudioStreamBasicDescription *format = NULL;
    
    return format;
}

@end
