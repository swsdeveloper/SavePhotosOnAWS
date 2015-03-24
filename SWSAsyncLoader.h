//
//  SWSAsyncLoader.h
//  SavePhotosOnAWS
//
//  Created by Steven Shatz on 3/18/15.
//  Copyright (c) 2015 Steven Shatz. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SWSAsyncLoader;

@protocol SWSAsyncLoaderDelegate

@optional -(void)loaderDidLoad:(SWSAsyncLoader *)loader;
@optional -(void)loaderDidFail:(SWSAsyncLoader *)loader;

@end


@interface SWSAsyncLoader : NSObject

@property (nonatomic) NSString *textTag;   // identifies the action for which this loader was created (eg: SAVE_IMAGE, DELETE_IMAGE, etc.)
@property (nonatomic) NSString *imageName; // used by SAVE_IMAGE and DELETE_IMAGE
@property (nonatomic) UIImage *image;      // used by BACKGROUND_LOAD_IMAGE and LOAD_IMAGE
@property (nonatomic) NSData *ldData;      // used by LIST_FILES

//@property (nonatomic,weak) NSMutableDictionary *completionHandlerDictionary;
//@property (nonatomic,weak) NSURLSession *defaultSession;

-(void)load:(NSString*)aUrl txt:(NSString*)txt delegate:(id)dg imageName:(NSString *)imageName;

-(void)load:(NSString*)aUrl txt:(NSString*)txt delegate:(id)dg paramKeys:(NSArray*)keys paramVals:(NSArray*)vals
      image:(UIImage*)image imageName:(NSString*)imageName;

-(NSString *)encode:(NSString*)string;

@end

