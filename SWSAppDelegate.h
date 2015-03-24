//
//  SWSAppDelegate.h
//  SavePhotosOnAWS
//
//  Created by Steven Shatz on 3/18/15.
//  Copyright (c) 2015 Steven Shatz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SWSViewController;

@interface SWSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SWSViewController *viewController;

@end
