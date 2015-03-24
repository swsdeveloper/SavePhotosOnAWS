//
//  ImageCache.m
//  SavePhotosOnAWS
//
//  Created by Steven Shatz on 3/18/15.
//  Copyright (c) 2015 Steven Shatz. All rights reserved.
//

#import "SWSImageCache.h"
#import "SWSConstants.h"

#define LOG_CACHE_ACTIONS YES

//Class-continuation Category
@interface SWSImageCache ()

@property (nonatomic,strong) NSMutableDictionary *cachedImages;     //key:value = NSString *identifier:UIImage *image

//inits the cachedImages dictionary
-(void)p_create;

@end


@implementation SWSImageCache

-(void)p_create {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}
    self.cachedImages = [NSMutableDictionary new];
}

-(void)addImage:(UIImage *)image identifier:(NSString *)identifier compressionQuality:(CGFloat)compressionQuality {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}
    
    if (!image || !identifier) {
        return;
    }
    if (compressionQuality < 0.0) {compressionQuality = 0.0;}
    if (compressionQuality > 1.0) {compressionQuality = 1.0;}
    
    if (!self.cachedImages) {
        [self p_create];
    }
    if (![self.cachedImages objectForKey:identifier]) {
        if (LOG_CACHE_ACTIONS) {NSLog(@"[CACHE:] > Adding image %@ to cache",identifier);}
        [self.cachedImages setObject:UIImageJPEGRepresentation(image,compressionQuality) forKey:identifier];
    }
}

-(id)imageWithIdentifier:(NSString *)identifier {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}
    
    if (!self.cachedImages || !identifier) {
        return nil;
    }
    NSData *data = [self.cachedImages objectForKey:identifier];
    if ([data length] > 0) {
        //if (LOG_CACHE_ACTIONS) {NSLog(@"[CACHE:] > Getting image %@ from cache",identifier);}
        return [UIImage imageWithData:data];
    }
    return nil;
}

-(void)deleteImageWithIdentifier:(NSString *)identifier {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}
    
    if (!self.cachedImages || !identifier) {
        return;
    }
    if (LOG_CACHE_ACTIONS) {NSLog(@"[CACHE:] > Deleting image %@ from cache",identifier);}
    [self.cachedImages removeObjectForKey:identifier];   // does nothing if image not present
}

@end
