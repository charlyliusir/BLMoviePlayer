//
//  BLBaseViewController.h
//  BLMoviePlayer
//
//  Created by Simon on 2019/8/2.
//  Copyright © 2019 Simon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLBaseViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BLBaseViewController : UIViewController

@property (nonatomic, strong) BLBaseViewModel *viewModel;

- (void)setupViews;
- (void)registRACsignal;
- (void)bandingViewModel:(BLBaseViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
