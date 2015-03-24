//
//  Constants.h
//  SavePhotosOnAWS
//
//  Created by Steven Shatz on 3/18/15.
//  Copyright (c) 2015 Steven Shatz. All rights reserved.
//

// The next define strips off the date/time stamp and current directory info from the start of each NSLog line
#define NSLog(FORMAT, ...) printf("%s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

#define LOG_METHOD_NAMES NO

//AWS Actions
#define LIST_FILES @"ListFiles"
#define BACKGROUND_LOAD_IMAGE @"BackgroundLoadImage"
#define LOAD_IMAGE @"LoadImage"
#define SAVE_IMAGE @"SaveImage"
#define DELETE_IMAGE @"DeleteImage"


//To Do:
// 1. Switch to URLSession
// 2. Save myCache to NSUserDefaults
// 3. Switch to Collection View

