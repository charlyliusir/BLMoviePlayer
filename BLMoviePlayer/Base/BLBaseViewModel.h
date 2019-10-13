//
//  BLBaseViewModel.h
//  BLMoviePlayer
//
//  Created by Simon on 2019/8/2.
//  Copyright © 2019 Simon. All rights reserved.
//

#import <Foundation/Foundation.h>]

NS_ASSUME_NONNULL_BEGIN

@interface BLBaseViewModel : NSObject

@property (nonatomic, readonly, strong) __kindof UIViewController *controller;
@property (nonatomic, readonly,   copy) NSString *vcName;
@property (nonatomic, copy) NSString *navTitle;
@property (nonatomic, readonly, assign) BLVCLoadType loadType;

- (instancetype)initWithControllerName:(NSString *)vcName;
- (instancetype)initWithControllerName:(NSString *)vcName loadType:(BLVCLoadType)loadType;

- (__kindof UIViewController *)loadController;
#pragma mark -
- (void)pushViewModel:(__kindof BLBaseViewModel *)viewModel animated:(BOOL)animated;
- (UIViewController *)popViewModelWithAnimated:(BOOL)animated;
- (NSArray<__kindof UIViewController *> *)popToViewModel:(__kindof BLBaseViewModel *)viewModel animated:(BOOL)animated;
- (NSArray<__kindof UIViewController *> *)popToRootViewModelWithAnimated:(BOOL)animated;

#pragma mark -
- (void)presentViewModel:(__kindof BLBaseViewModel *)viewModel animated:(BOOL)animated completion:(void(^)(void))completion;
- (void)dismissViewModelWithAnimated:(BOOL)animated completion:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
