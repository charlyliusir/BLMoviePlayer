//
//  BLBaseViewController.m
//  BLMoviePlayer
//
//  Created by Simon on 2019/8/2.
//  Copyright © 2019 Simon. All rights reserved.
//

#import "BLBaseViewController.h"

@interface BLBaseViewController ()

@end

@implementation BLBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 设置允许摇一摇功能
    [UIApplication sharedApplication].applicationSupportsShakeToEdit = YES;
}

- (void)setupViews
{
    
}

- (void)registRACsignal
{
    RAC(self.navigationItem, title) = RACObserve(_viewModel, navTitle);
}

- (void)bandingViewModel:(BLBaseViewModel *)viewModel
{
    _viewModel = viewModel;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - 摇一摇
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.subtype == UIEventSubtypeMotionShake) { // 判断是否是摇动结束
        NSLog(@"摇动结束");
        
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"UI调试模式" message:@"请选择调试模式" preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:@"导出当前UI结构" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Lookin_Export" object:nil];
        }]];
        [controller addAction:[UIAlertAction actionWithTitle:@"审查元素" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Lookin_2D" object:nil];
        }]];
        [controller addAction:[UIAlertAction actionWithTitle:@"3D模式" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"Lookin_3D" object:nil];
        }]];
        [controller addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
    }
    return;
}

@end
