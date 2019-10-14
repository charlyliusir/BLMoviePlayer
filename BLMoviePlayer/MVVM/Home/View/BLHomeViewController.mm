//
//  BLHomeViewController.m
//  BLMoviePlayer
//
//  Created by Simon on 2019/8/2.
//  Copyright © 2019 Simon. All rights reserved.
//

#import "BLHomeViewController.h"
#include "BLFileDecoder.hpp"

@interface BLHomeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;

@end

@implementation BLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self registRACsignal];
    
    BLFileDecoder *decoder = new BLFileDecoder();
    decoder->init([[[NSBundle mainBundle] pathForResource:@"abc" ofType:@"aac"] UTF8String], 0);
    BLFilePacketList *pktList = decoder->decodePacket();
    while (pktList->length() > 0) {
        BLFilePacket *pkt = pktList->popPacket();
        NSLog(@"...pkt size...%d", pkt->size);
    }
}

- (void)registRACsignal
{
    [super registRACsignal];
    
    @weakify(self)
    [[_btnPlay rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
    }];
    
    [[_btnStop rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
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

@end
