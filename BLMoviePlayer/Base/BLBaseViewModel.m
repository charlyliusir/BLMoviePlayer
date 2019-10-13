//
//  BLBaseViewModel.m
//  BLMoviePlayer
//
//  Created by Simon on 2019/8/2.
//  Copyright © 2019 Simon. All rights reserved.
//

#import "BLBaseViewModel.h"
#import "BLBaseViewController.h"

@implementation BLBaseViewModel

- (instancetype)initWithControllerName:(NSString *)vcName
{
    return [self initWithControllerName:vcName loadType:BLVCCodingLoad];
}

- (instancetype)initWithControllerName:(NSString *)vcName loadType:(BLVCLoadType)loadType
{
    if (self = [super init]) {
        _vcName = vcName;
        _loadType = loadType;
    }
    return self;
}

- (__kindof UIViewController *)loadController
{
    NSAssert(_vcName, @"控制器名称必须不为空!");
    if (_controller) {
        return _controller;
    }
    switch (_loadType) {
        case BLVCCodingLoad:
            _controller = [[NSClassFromString(_vcName) alloc] init];
            break;
        case BLVCXibLoad:
            _controller = [[NSClassFromString(_vcName) alloc] initWithNibName:_vcName bundle:nil];
            break;
        case BLVCStoryMainLoad:
            _controller = [[UIStoryboard storyboardWithName:BL_STORYBOARD_MAIN bundle:nil] instantiateViewControllerWithIdentifier:_vcName];
            break;
        default:
            break;
    }
    if (_controller) {
        [(BLBaseViewController *)_controller bandingViewModel:self];
    }
    return _controller;
}

#pragma mark -
- (void)pushViewModel:(__kindof BLBaseViewModel *)viewModel animated:(BOOL)animated
{
    [self checkNaviControllerVerfiy];
    [_controller.navigationController pushViewController:[self checkControllerFromViewModel:viewModel] animated:animated];
}

- (UIViewController *)popViewModelWithAnimated:(BOOL)animated
{
    [self checkNaviControllerVerfiy];
    return [_controller.navigationController popViewControllerAnimated:animated];
}

- (NSArray<__kindof UIViewController *> *)popToViewModel:(__kindof BLBaseViewModel *)viewModel animated:(BOOL)animated
{
    [self checkNaviControllerVerfiy];
    return [_controller.navigationController popToViewController:[self checkControllerFromViewModel:viewModel] animated:animated];
}

- (NSArray<__kindof UIViewController *> *)popToViewModel:(__kindof BLBaseViewModel *)popToRootViewModelWithAnimated:(BOOL)animated
{
    [self checkNaviControllerVerfiy];
    return [_controller.navigationController popToRootViewControllerAnimated:animated];
}

#pragma mark -
- (void)presentViewModel:(__kindof BLBaseViewModel *)viewModel animated:(BOOL)animated completion:(void(^)(void))completion
{
    [self checkControllerVerfiy];
    [_controller presentViewController:[self checkControllerFromViewModel:viewModel] animated:animated completion:completion];
}
- (void)dismissViewModelWithAnimated:(BOOL)animated completion:(void(^)(void))completion
{
    [self checkControllerVerfiy];
    [_controller dismissViewControllerAnimated:animated completion:completion];
}

#pragma mark -
- (__kindof UIViewController *)checkControllerFromViewModel:(__kindof BLBaseViewModel *)viewModel
{
    NSAssert(viewModel, @"VM 不存在, 不能执行下步操作");
    UIViewController *controller = [viewModel loadController];
    NSAssert(controller, @"VM 的 控制器不存在, 不能执行下步操作");
    return controller;
}

- (void)checkNaviControllerVerfiy
{
    [self checkControllerVerfiy];
    NSAssert(_controller.navigationController, @"导航控制器不存在, 不能执行下面操作");
}
- (void)checkControllerVerfiy
{
    NSAssert(_controller || [self loadController], @"控制器不存在, 不能执行下面操作");
}

@end
