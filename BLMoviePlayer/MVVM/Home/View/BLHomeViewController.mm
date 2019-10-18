//
//  BLHomeViewController.m
//  BLMoviePlayer
//
//  Created by Simon on 2019/8/2.
//  Copyright © 2019 Simon. All rights reserved.
//

#import "BLHomeViewController.h"
#include "BLMovieController.hpp"
#import "BLAudioOutput.h"

@interface BLHomeViewController () <BLAudioOutputDelegate> {
    BLMovieController *controller;
}

@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;

@property (nonatomic, strong) BLAudioOutput *output;

@property (nonatomic, strong) NSInputStream *iStream;

@end

@implementation BLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self registRACsignal];
    
    const char *filepath = [[[NSBundle mainBundle] pathForResource:@"abc" ofType:@"aac"] UTF8String];
    
    controller = new BLMovieController();
    controller->init(filepath, 0.2);
    
    _output = [[BLAudioOutput alloc] initWithSampleRate:controller->accompanySampleRate * 1.0f channels:controller->accompanyChannels delegate:self];
    
//    _iStream = [NSInputStream inputStreamWithFileAtPath:[[NSBundle mainBundle] pathForResource:@"pcm" ofType:@"aac"]];
}

- (void)registRACsignal
{
    [super registRACsignal];
    
    @weakify(self)
    [[_btnPlay rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        [self.output play];
    }];
    
    [[_btnStop rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        [self.output stop];
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)readSamples:(short *)samples withNumberFrame:(UInt32)numberFrame channels:(UInt32)channels {
    memset(samples, 0, numberFrame * channels * sizeof(SInt16));
//    [_iStream read:(uint8_t *)samples maxLength:numberFrame * channels * 2];
    controller->readSamples(samples, numberFrame * channels);
}


@end
