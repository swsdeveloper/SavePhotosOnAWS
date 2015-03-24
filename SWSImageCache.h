//
//  ImageCache.h
//  SavePhotosOnAWS
//
//  Created by Steven Shatz on 3/18/15.
//  Copyright (c) 2015 Steven Shatz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SWSImageCache : NSObject

//if the identifier is not already in the cache, the identifier and its corresponding image are added to it. Otherwise nothing changes.
-(void)addImage:(UIImage *)image identifier:(NSString *)imageName compressionQuality:(CGFloat)compressionQuality;

//if the identifier is in the cache, returns a copy of the corresponding UIImage; otherwise returns nil.
-(id)imageWithIdentifier:(NSString *)identifier;

//if the identifier is in the cache, the identifier and its corresponding image are deleted from the cache. Otherwise, nothing changes.
-(void)deleteImageWithIdentifier:(NSString *)identifier;

@end
