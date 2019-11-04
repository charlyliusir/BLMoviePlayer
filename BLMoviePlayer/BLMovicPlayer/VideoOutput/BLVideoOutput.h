//
//  BLVideoOutput.h
//  BLVideoDecode
//
//  Created by Simon on 2019/10/17.
//  Copyright © 2019 Simon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLFileQueue.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface BLVideoOutput : UIView

- (void)displayVideoFrame:(BLVideoPacket *)vFrame;

@end

NS_ASSUME_NONNULL_END
