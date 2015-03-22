//
//  AsyncLoader.m
//  DiscussionForum
//
//  Created by Akshay on 05/04/13.
//  Copyright (c) 2013 QCD Systems LLC. All rights reserved.
//



#import "AsyncLoader.h"
#import "Constants.h"


#define LIST_FILES @"ListFiles"
#define LOAD_IMAGE @"LoadImage"
#define BACKGROUND_LOAD_IMAGE @"BackgroundLoadImage"
#define SAVE_IMAGE @"SaveImage"
#define DELETE_IMAGE @"DeleteImage"

#define HTTP_DEBUG NO           // Set to YES to see HTTP POST requests and results


@interface AsyncLoader ()

@property (nonatomic) id delegate;
@property (nonatomic) NSString *params;

@property (nonatomic)  NSString *url;

@end


@implementation AsyncLoader

//-(void)setUpURLSession {
//    self.completionHandlerDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
//
//    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
//    
////    self.defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
//    
//    self.defaultSession = [NSURLSession sharedSession];
//    
//    NSURLSessionDataTask *dataTask = [self.defaultSession dataTaskWithRequest:<#(NSURLRequest *)#> completionHandler:<#^(NSData *data, NSURLResponse *response, NSError *error)completionHandler#> {
//        
//    }];
//    
//    defaultConfigObject.HTTPMaximumConnectionsPerHost = 10;   // change to # of images to be downloaded
//    
//    //[self.defaultSession invalidateAndCancel];
//}

//This routine is for all AWS requests other than SAVE_IMAGE
-(void)load:(NSString*)anUrl txt:(NSString*)txt delegate:(id)dg params:(NSString*)params {
    NSLog(@"..................%s, params:%@",__FUNCTION__, params);
    self.textTag = txt;
    self.delegate = dg;
    self.params = params;
    
//    NSLog(@"URL:%@",anUrl);
//    NSLog(@"PARAMS:%@",params);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:anUrl]
                                                           cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                       timeoutInterval:10];
    request.HTTPMethod = @"POST";
    
    NSData *ndata = [params dataUsingEncoding:NSUTF8StringEncoding];
    
    // Append to an HTTP header field (filling in values for certain keys)
    [request addValue:@"8bit" forHTTPHeaderField:@"Content-Transfer-Encoding"];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[ndata length]] forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:ndata];
    
    if (HTTP_DEBUG) {[self displayHTTPFieldsForRequest:request];}
    
    [self requestMethod:request withRetryCounter:5];
}

//This routine is only invoked by SAVE_IMAGE
-(void)load:(NSString*)anUrl txt:(NSString*)txt delegate:(id)dg paramKeys:(NSArray*)keys paramVals:(NSArray*)vals
      image:(UIImage*)image imageName:(NSString *)imageName {
    
    NSLog(@"..................%s",__FUNCTION__);
    
    if (!image) {
        return;
    }

    self.textTag = txt;
    self.image = image;
    self.imageName = imageName;
    self.params = imageName;    //for requestMethod:withRetryCounter:
    
    if (self.imageName == nil) {
        self.imageName = [[NSString alloc] initWithFormat:@"%f.jpg", [[NSDate date] timeIntervalSince1970]];  // Use number of secs since 1/1/1970 as filename
        if (HTTP_DEBUG) {NSLog(@"\ndata: %@\n",self.imageName);}
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:anUrl]
                                                           cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                       timeoutInterval:10];
    request.HTTPMethod = @"POST";
    
	//Add content-type to Header. Need to use a string boundary for data uploading.
	NSString *boundary = @"0xKhTmLbOuNdArY";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
	[request addValue:contentType forHTTPHeaderField: @"Content-Type"];
	
	//create the post body
	NSMutableData *body = [NSMutableData data];
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSASCIIStringEncoding]];

    NSData *imageData = UIImageJPEGRepresentation(self.image,1.0);  // returns the image in JPEG format; 1=no compression (0=max compression)
    
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", @"files[]", self.imageName]
                      dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@",boundary] dataUsingEncoding:NSASCIIStringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
	//add (key,value) pairs (no idea why all the \r's and \n's are necessary ... but everyone seems to have them)
	for (int i=0; i<[keys count]; i++) {
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",[keys objectAtIndex:i]]
                          dataUsingEncoding:NSASCIIStringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"%@",[vals objectAtIndex:i]] dataUsingEncoding:NSASCIIStringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@",boundary] dataUsingEncoding:NSASCIIStringEncoding]];
        
        if (i<[keys count]-1) {
            [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSASCIIStringEncoding]];
        } else {
            [body appendData:[[NSString stringWithFormat:@"--"] dataUsingEncoding:NSASCIIStringEncoding]];
        }
	}
	
	// set the body of the post to the request
	[request setHTTPBody:body];
    
    if (HTTP_DEBUG) {[self displayHTTPFieldsForRequest:request];}
    
    [self requestMethod:request withRetryCounter:5];
}

-(void)requestMethod:(NSURLRequest *)request withRetryCounter:(int)retryCounter {
    NSLog(@"%s retryCounter:%d", __FUNCTION__, retryCounter);
    if (retryCounter <= 0) {
        NSLog(@"\nWARNING: request failed after max retries --> Type:%@, Params:%@", self.textTag, self.params);
        return;
    }
    retryCounter--;
    
    __weak typeof (self) weakSelf = self;
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue new]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError) {
                                   NSLog(@"\nConnection error: %@\nType:%@, Params:%@",connectionError, self.textTag, self.params);
                                   
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                                       [weakSelf requestMethod:request withRetryCounter:retryCounter];
                                   });
                                   return;
                               }
                               
                               if ([self.textTag isEqualToString:BACKGROUND_LOAD_IMAGE]) {
                                   self.image = [[UIImage alloc] initWithData:data];
                                   self.imageName = [self.params stringByReplacingOccurrencesOfString:@"getFile=uploads/" withString:@""];
                                   if (HTTP_DEBUG) {NSLog(@"Image Name: %@\n",self.imageName);}
                                   
                               } else if ([self.textTag isEqualToString:LOAD_IMAGE]) {
                                   self.image = [[UIImage alloc] initWithData:data];
                                   
                               } else if ([self.textTag isEqualToString:LIST_FILES]) {
                                   self.ldData = data;
                                   
                               } else if ([self.textTag isEqualToString:DELETE_IMAGE]) {
                                   self.imageName = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                                   if (HTTP_DEBUG) {NSLog(@"\ndata: %@\n",self.imageName);}
                                   
                               } else if ([self.textTag isEqualToString:SAVE_IMAGE]) {
                                   //do nothing
                                   
                               } else {
                                   return;
                               }
                               
                               [self.delegate loaderDidLoad:self];
                           }];
}

-(void)displayHTTPFieldsForRequest:(NSURLRequest *)request {
    NSDictionary *dict = [request allHTTPHeaderFields];
    NSArray *dictKeys = [dict allKeys];
    NSArray *dictValues = [dict allValues];
    NSMutableString *strH = [[NSMutableString alloc] init];
    for (int i=0; i<[dictKeys count]; ++i) {
        [strH appendFormat:@" - %@ : %@\n",dictKeys[i],dictValues[i]];
    }
    NSString *strB = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSASCIIStringEncoding];
    if (HTTP_DEBUG) {
        NSLog(@"\nRequest:%@",[[request URL] absoluteString]);
        NSLog(@"HTTP Method:%@",[request HTTPMethod]);
        NSLog(@"HTTP Body:%@",strB);
        NSLog(@"HTTP Header:\n%@",strH);
    }
}

-(NSString *)encode:(NSString *)str {
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
        NULL,                                   // CFAllocatorRef object (allocates memory)
        (CFStringRef)str,                       // URL string to be adjusted
        NULL,                                   // List of chars that should NOT be escaped
        (CFStringRef)@"!*'();:@&=+$,/?%#[]",    // List of chars that need to be % escaped
        kCFStringEncodingUTF8                   // Type of encoding to use for new URL string
    ));
    return encodedString;
}

-(void)dealloc {
    NSLog(@"AsyncLoader Deallocated");
}

@end
