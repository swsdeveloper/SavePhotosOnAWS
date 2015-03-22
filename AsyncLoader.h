//
//  AsyncLoader.h
//  DiscussionForum
//
//  Created by Akshay on 05/04/13.
//  Copyright (c) 2013 QCD Systems LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@class AsyncLoader;

@protocol AsyncLoaderDelegate

@optional -(void)loaderDidLoad:(AsyncLoader *)loader;

@end


@interface AsyncLoader : NSObject

@property (nonatomic)  NSString *textTag;

@property (nonatomic)  NSString *imageName; // used by SAVE_IMAGE and DELETE_IMAGE
@property (nonatomic)  UIImage *image;      // used by BACKGROUND_LOAD_IMAGE and LOAD_IMAGE
@property (nonatomic)  NSData *ldData;      // used by LIST_FILES

//@property (nonatomic,weak) NSMutableDictionary *completionHandlerDictionary;

//@property (nonatomic,weak) NSURLSession *defaultSession;

-(void)load:(NSString*)anUrl txt:(NSString*)txt delegate:(id)dg params:(NSString*)params;

-(void)load:(NSString*)anUrl txt:(NSString*)txt delegate:(id)dg paramKeys:(NSArray*)keys paramVals:(NSArray*)vals
      image:(UIImage*)image imageName:(NSString*)imageName;

-(NSString *)encode:(NSString*)str;

@end

