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
    
    SInt16 *sampleBuffer;
    
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
        _sampleRate = sampleRate;
        _channels   = channels;
        _delegate   = delegate;
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

- (void)play {
    AUGraphStart(ioGraph);
}

- (void)stop {
    AUGraphStop(ioGraph);
}

- (void)setupAudioSession {
    [[BLAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback];
    [[BLAudioSession sharedInstance] setPreferredSampleRate:_sampleRate];
    [[BLAudioSession sharedInstance] setAction:YES];
}

- (void)setupBuffer {
    sampleBuffer = (SInt16 *)calloc(8192, sizeof(SInt16));
}

- (void)setupAUGraph {
    CheckStatus(NewAUGraph(&ioGraph), @"创建ioGraph失败");
    CheckStatus(AUGraphOpen(ioGraph), @"打开ioGraph失败");
    
    // 添加Node
    AudioComponentDescription ioComponent;
    ioComponent.componentType           = kAudioUnitType_Output;
    ioComponent.componentSubType        = kAudioUnitSubType_RemoteIO;
    ioComponent.componentManufacturer   = kAudioUnitManufacturer_Apple;
    ioComponent.componentFlags          = 0;
    ioComponent.componentFlagsMask      = 0;
    CheckStatus(AUGraphAddNode(ioGraph, &ioComponent, &ioNode), @"添加ioNode失败");
    CheckStatus(AUGraphNodeInfo(ioGraph, ioNode, NULL, &ioUnit), @"获取ioUnit失败");
    
    AudioComponentDescription cvtComponent;
    cvtComponent.componentType           = kAudioUnitType_FormatConverter;
    cvtComponent.componentSubType        = kAudioUnitSubType_AUConverter;
    cvtComponent.componentManufacturer   = kAudioUnitManufacturer_Apple;
    cvtComponent.componentFlags          = 0;
    cvtComponent.componentFlagsMask      = 0;
    CheckStatus(AUGraphAddNode(ioGraph, &cvtComponent, &cvtNode), @"添加cvtNode失败");
    CheckStatus(AUGraphNodeInfo(ioGraph, cvtNode, NULL, &cvtUnit), @"获取cvtUnit失败");
    
    [self setupUnitProperty];
    
    CheckStatus(AUGraphConnectNodeInput(ioGraph, cvtNode, BL_CVT_ELEMENT, ioNode, BL_IO_ELEMENT_OUTPUT), @"链接失败");
    // 设置回调
    AURenderCallbackStruct cvtCallBack;
    cvtCallBack.inputProcRefCon = (__bridge void *)self;
    cvtCallBack.inputProc = CvtCallBack;

    CheckStatus(AudioUnitSetProperty(cvtUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, BL_CVT_ELEMENT, &cvtCallBack, sizeof(cvtCallBack)), @"设置转换回调失败");
    
//    CAShow(&ioGraph);
    CheckStatus(AUGraphInitialize(ioGraph), @"初始化失败");
}

- (void)setupUnitProperty {
    AudioStreamBasicDescription outputFormat = [self outputFormat];
    CheckStatus(AudioUnitSetProperty(ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, BL_IO_INPUT_BUS, &outputFormat, sizeof(outputFormat)), @"设置音频输出失败");
    
    UInt32 bytePerFrame = sizeof(SInt16);
    AudioStreamBasicDescription inputFormat;
    bzero(&inputFormat, sizeof(inputFormat));
    memset(&inputFormat, 0, sizeof(AudioStreamBasicDescription));
    inputFormat.mFormatID            = kAudioFormatLinearPCM;
    inputFormat.mSampleRate          = _sampleRate;
    inputFormat.mFormatFlags         = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    inputFormat.mFramesPerPacket     = 1;
    inputFormat.mChannelsPerFrame    = _channels;
    inputFormat.mBitsPerChannel      = 8 * bytePerFrame;
    inputFormat.mBytesPerFrame       = bytePerFrame * _channels;
    inputFormat.mBytesPerPacket      = bytePerFrame * _channels;
    inputFormat.mReserved = 0;
    
    CheckStatus(AudioUnitSetProperty(cvtUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, BL_CVT_ELEMENT, &inputFormat, sizeof(inputFormat)), @"设置音频转换输入失败");
    CheckStatus(AudioUnitSetProperty(cvtUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, BL_CVT_ELEMENT, &outputFormat, sizeof(outputFormat)), @"设置音频转换输出失败");
}

- (AudioStreamBasicDescription)outputFormat {
    UInt32 bytePerFrame = sizeof(Float32);
    AudioStreamBasicDescription format;
    bzero(&format, sizeof(format));
    format.mFormatID            = kAudioFormatLinearPCM;
    format.mSampleRate          = _sampleRate;
    format.mFormatFlags         = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    format.mFramesPerPacket     = 1;
    format.mChannelsPerFrame    = _channels;
    format.mBitsPerChannel      = 8 * bytePerFrame;
    format.mBytesPerFrame       = bytePerFrame;
    format.mBytesPerPacket      = bytePerFrame;
    
    return format;
}

- (OSStatus)readData:(AudioBufferList *)ioData
         atTimeStamp:(const AudioTimeStamp *)inTimeStamp
          forElement:(UInt32)element
         numberFrame:(UInt32)numberFrame
               flags:(AudioUnitRenderActionFlags *)flags {
    
    UInt32 mBuffer = ioData->mNumberBuffers;
    for (int i = 0; i < mBuffer; i ++) {
        memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
    }
    NSLog(@"我进来了，进来了，哈哈哈哈~");
    if (_delegate && [_delegate respondsToSelector:@selector(readSamples:withNumberFrame:channels:)]) {
        [_delegate readSamples:sampleBuffer withNumberFrame:numberFrame channels:_channels];
        for (int i = 0; i < mBuffer; i ++) {
            memcpy((SInt16 *)ioData->mBuffers[i].mData, sampleBuffer, ioData->mBuffers[i].mDataByteSize);
        }
    }
    
    return noErr;
}

static OSStatus CvtCallBack(void *                       inRefCon,
                            AudioUnitRenderActionFlags * ioActionFlags,
                            const AudioTimeStamp *       inTimeStamp,
                            UInt32                       inBusNumber,
                            UInt32                       inNumberFrames,
                            AudioBufferList * __nullable ioData) {
    BLAudioOutput *output = (__bridge BLAudioOutput *)inRefCon;
    return [output readData:ioData
                atTimeStamp:inTimeStamp
                 forElement:inBusNumber
                numberFrame:inNumberFrames flags:ioActionFlags];
}

static void CheckStatus(OSStatus status, NSString *errMessage) {
    if (status != noErr) {
        
        char fourCC[16];
        *fourCC = CFSwapInt32HostToBig(status);
        fourCC[4] = '\0';
        if (isprint(fourCC[0]) || isprint(fourCC[1]) || isprint(fourCC[2]) || isprint(fourCC[3])) {
            NSLog(@"%@:%s", errMessage, fourCC);
        } else {
            NSLog(@"%@", errMessage);
        }
        
        exit(-1);
    }
}

@end
