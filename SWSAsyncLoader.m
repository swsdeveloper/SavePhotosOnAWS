//
//  SWSAsyncLoader.m
//  SavePhotosOnAWS
//
//  Created by Steven Shatz on 3/18/15.
//  Copyright (c) 2015 Steven Shatz. All rights reserved.
//

#import "SWSAsyncLoader.h"
#import "SWSConstants.h"

#define LOG_HTTP_ACTIONS NO         // Set to YES to see HTTP POST requests and results
#define LOG_LOADER_ACTIONS YES      // Set to YES to see SAVE_IMAGE, DELETE_IMAGE, and other actions

@interface SWSAsyncLoader ()

@property (nonatomic,copy) NSString *params;

@property (nonatomic) id delegate;

-(void)p_displayHTTPFieldsForRequest:(NSURLRequest *)request;

-(void)p_requestMethod:(NSURLRequest *)request withRetryCounter:(int)retryCounter;

@end


@implementation SWSAsyncLoader

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
-(void)load:(NSString*)aUrl txt:(NSString*)txt delegate:(id)dg imageName:(NSString *)imageName {
    
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s, params:%@",__FUNCTION__, imageName);}
    
    self.textTag = txt;
    self.delegate = dg;
    self.imageName = imageName;
    self.params = nil;
    
    if ([self.textTag isEqualToString:BACKGROUND_LOAD_IMAGE]) {
        self.params = [NSString stringWithFormat:@"getFile=uploads/%@",imageName];
        
    } else if ([self.textTag isEqualToString:LOAD_IMAGE]) {
        self.params = [NSString stringWithFormat:@"getFile=uploads/%@",imageName];
        
    } else if ([self.textTag isEqualToString:LIST_FILES]) {
        self.params = [NSString stringWithFormat:@"listFile=uploads/"];
        
    } else if ([self.textTag isEqualToString:DELETE_IMAGE]) {
        self.params = [[NSString alloc] initWithFormat:@"delFile=%@",imageName];
        
    } else {
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:aUrl]
                                                           cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                       timeoutInterval:15]; // 15 seconds
    request.HTTPMethod = @"POST";
    
    NSData *ndata = [self.params dataUsingEncoding:NSUTF8StringEncoding];
    
    // Append to an HTTP header field (filling in values for certain keys)
    [request addValue:@"8bit" forHTTPHeaderField:@"Content-Transfer-Encoding"];
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[ndata length]] forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:ndata];
    
    [self p_displayHTTPFieldsForRequest:request];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
        [self p_requestMethod:request withRetryCounter:5];
    });
}

//This routine is only invoked by SAVE_IMAGE
-(void)load:(NSString*)aUrl txt:(NSString*)txt delegate:(id)dg paramKeys:(NSArray*)keys paramVals:(NSArray*)vals
      image:(UIImage*)image imageName:(NSString *)imageName {
    
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s",__FUNCTION__);}
    
    if (!image) {
        if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] - Missing Image");}
        return;
    }

    self.textTag = txt;
    self.delegate = dg;
    self.image = image;
    self.imageName = imageName;
    self.params = imageName;
    
    if (self.imageName == nil) {
        self.imageName = [[NSString alloc] initWithFormat:@"%f.jpg", [[NSDate date] timeIntervalSince1970]];  // Use number of secs since 1/1/1970 as filename
        if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] -  Assigned Image Name: %@",self.imageName);}
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:aUrl]
                                                           cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                       timeoutInterval:15]; // 15 seconds
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

    [self p_displayHTTPFieldsForRequest:request];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
        [self p_requestMethod:request withRetryCounter:5];
    });
}

-(void)p_requestMethod:(NSURLRequest *)request withRetryCounter:(int)retryCounter {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s retryCounter:%d", __FUNCTION__, retryCounter);}
    
    if (retryCounter <= 0) {
        NSLog(@"\nWARNING: request failed after max retries --> Type:%@, Params:%@", self.textTag, self.params);
        [self.delegate loaderDidFail:self];
        return;
    }
    retryCounter--;
    
    __weak typeof (self) weakSelf = self;
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue new]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError) {
                                   NSLog(@"\nCONNECTION ERROR: %@\nType:%@, Params:%@",connectionError, self.textTag, self.params);
                                   
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                                       [weakSelf p_requestMethod:request withRetryCounter:retryCounter];
                                   });
                                   return;
                               }
                               
                               if ([self.textTag isEqualToString:BACKGROUND_LOAD_IMAGE]) {
                                   self.image = [[UIImage alloc] initWithData:data];
                                   self.imageName = [self.params stringByReplacingOccurrencesOfString:@"getFile=uploads/" withString:@""];
                                   
                               } else if ([self.textTag isEqualToString:LOAD_IMAGE]) {
                                   self.image = [[UIImage alloc] initWithData:data];
                                   
                               } else if ([self.textTag isEqualToString:LIST_FILES]) {
                                   self.ldData = data;
                                   
                               } else if ([self.textTag isEqualToString:DELETE_IMAGE]) {
                                   //do nothing - for possible future use
                                   
                               } else if ([self.textTag isEqualToString:SAVE_IMAGE]) {
                                   //do nothing - for possible future use
                                   
                               } else {
                                   return;
                               }
                               
                               [self.delegate loaderDidLoad:self];
                           }];
}

-(void)p_displayHTTPFieldsForRequest:(NSURLRequest *)request {
    if (!LOG_HTTP_ACTIONS) {
        return;
    }
    NSDictionary *dict = [request allHTTPHeaderFields];
    NSArray *dictKeys = [dict allKeys];
    NSArray *dictValues = [dict allValues];
    NSMutableString *strH = [NSMutableString new];
    for (int i=0; i<[dictKeys count]; ++i) {
        [strH appendFormat:@" - %@ : %@\n",dictKeys[i],dictValues[i]];
    }
    NSString *strB = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSASCIIStringEncoding];
    NSLog(@"\n");
    NSLog(@"[HTTP:] Request:%@",[[request URL] absoluteString]);
    NSLog(@"        Method:%@",[request HTTPMethod]);
    NSLog(@"        Body:%@",strB);
    NSLog(@"        Header:%@",strH);
}

-(NSString *)encode:(NSString *)string {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] Asyncloader Encode string: %@",string);}
    
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
        NULL,                                   // CFAllocatorRef object (allocates memory)
        (CFStringRef)string,                    // URL string to be adjusted
        NULL,                                   // List of chars that should NOT be escaped
        (CFStringRef)@"!*'();:@&=+$,/?%#[]",    // List of chars that need to be % escaped
        kCFStringEncodingUTF8                   // Type of encoding to use for new URL string
    ));
    return encodedString;
}

-(void)dealloc {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] AsyncLoader [%@] Deallocated", _textTag);}
}

#pragma mark -
#pragma mark Session Upload Delegate Methods
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}
    //float status = (double)totalBytesSent / (double)totalBytesExpectedToSend;
    //[[MTFileStreamer sharedFileStreamer] setCurrentStatus:status];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}
}

@end
