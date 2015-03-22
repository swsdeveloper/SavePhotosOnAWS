//
//  ImageCache.m
//  CameraTest
//
//  Created by Steven Shatz on 3/18/15.
//  Copyright (c) 2015 Aditya. All rights reserved.
//

#import "ImageCache.h"
#import "Constants.h"


@interface ImageCache ()

@property (nonatomic,strong) NSMutableDictionary *cachedImages;

//inits the cachedImages dictionary
-(void)create;

@end


@implementation ImageCache

-(void)create {
    self.cachedImages = [NSMutableDictionary new];
}

-(void)addToCache:(NSString *)imageName image:(UIImage *)image compressionQuality:(CGFloat)compressionQuality {
    if (!self.cachedImages) {
        [self create];
    }
    if (!imageName || !image) {
        return;
    }
    if (compressionQuality < 0.0) {compressionQuality = 0.0;}
    if (compressionQuality > 1.0) {compressionQuality = 1.0;}
    if (![self.cachedImages objectForKey:imageName]) {
        NSLog(@"> Adding image %@ to cache",imageName);
        [self.cachedImages setObject:UIImageJPEGRepresentation(image,compressionQuality) forKey:imageName];
    }
}

-(id)getFromCache:(NSString *)imageName {
    if (!self.cachedImages || !imageName) {
        return nil;
    }
    NSData *data = [self.cachedImages objectForKey:imageName];
    if ([data length] > 0) {
        NSLog(@"> Getting image %@ from cache",imageName);
        return [UIImage imageWithData:data];
    }
    return nil;
}

-(void)deleteFromCache:(NSString *)imageName {
    if (!self.cachedImages || !imageName) {
        return;
    }
    NSLog(@"> Deleting image %@ from cache",imageName);
    [self.cachedImages removeObjectForKey:imageName];   // does nothing if image is not present
}

@end
