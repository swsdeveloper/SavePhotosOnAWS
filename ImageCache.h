//
//  ImageCache.h
//  CameraTest
//
//  Created by Steven Shatz on 3/18/15.
//  Copyright (c) 2015 Aditya. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageCache : NSObject

//if this name is not already in cache, image is added. Otherwise nothing changes
-(void)addToCache:(NSString *)imageName image:(UIImage *)image compressionQuality:(CGFloat)compressionQuality;

//if found in cache, returns UIImage
//if not found, returns nil
-(id)getFromCache:(NSString *)imageName;

//if in cache, image is deleted. Otherwise, nothing changes
-(void)deleteFromCache:(NSString *)imageName;

@end
