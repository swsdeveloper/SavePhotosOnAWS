//
//  SWSViewController.m
//  SavePhotosOnAWS
//
//  Created by Steven Shatz on 3/18/15.
//  Copyright (c) 2015 Steven Shatz. All rights reserved.
//

#import "SWSViewController.h"
#import "SWSImageCache.h"
#import "SWSConstants.h"

#define AWS_URL @"http://bengalboard.com:8080/AmazonS3Web/AWSService"

@interface SWSViewController ()

@property (nonatomic, copy, readwrite) NSString *urlStr;
@property (nonatomic, strong) SWSImageCache *myCache;
@property (nonatomic, strong) UIPopoverController *pop;
@property (nonatomic, assign) NSInteger lastClickedRow;

@end

@implementation SWSViewController

- (void)viewDidLoad {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s",__FUNCTION__);}
    [super viewDidLoad];
    _urlStr = AWS_URL;
    _myCache = [SWSImageCache new];
    _pop = nil;
    _lastClickedRow = 0;
    
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action methods

- (IBAction)edit:(id)sender {
    if (self.pop) {
        [self.pop dismissPopoverAnimated:TRUE];
    }
    
    if ([self.tblView isEditing]) {          // Default is no, so 1st time Edit button is tapped, isEditing is false
        [sender setTitle:@"Edit"];
    } else {
        [sender setTitle:@"Done"];
    }
    [self.tblView setEditing:![self.tblView isEditing]];
    
    // When edit button is pressed, highlight the currently selected table entry
    NSIndexPath *idx = [NSIndexPath indexPathForRow:self.lastClickedRow inSection:0];
    [self.tblView selectRowAtIndexPath:idx animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (IBAction)takePicture:(id)sender {
    [self.tblView setEditing:TRUE animated:YES];
    [self edit:self.editButton];
    
    if ([self.pop isPopoverVisible]) {
        [self.pop dismissPopoverAnimated:YES];
        self.pop = nil;
        return;
    }
    
    UIImagePickerController *ip = [[UIImagePickerController alloc] init]; 
    if( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ){
        [ip setSourceType:UIImagePickerControllerSourceTypeCamera];
    } else {
        [ip setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    [ip setAllowsEditing:TRUE];
    [ip setDelegate:self];
    
    self.pop = [[UIPopoverController alloc] initWithContentViewController:ip];
    [self.pop setDelegate:self];
    [self.pop presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark - Convenience method for invoking SWSAsyncLoader - loads images fm AWS server into our table

-(void)loadData {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s",__FUNCTION__);}
    NSLog(@"> Getting list of image filenames from AWS");

    SWSAsyncLoader *loader = [[SWSAsyncLoader alloc] init];
    [loader load:self.urlStr txt:LIST_FILES delegate:self imageName:nil];
}

#pragma mark - SWSAsyncLoader Delegate Protocol methods

-(void)loaderDidLoad:(SWSAsyncLoader *)loader {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s",__FUNCTION__);}
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([loader.textTag isEqualToString:LIST_FILES]) {
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData: loader.ldData options: NSJSONReadingMutableContainers error: nil];
            tableData = [NSMutableArray arrayWithArray:jsonArray];
            [self.tblView reloadData];
            
            NSLog(@"\nLoading %ld Records into tableView",[tableData count]);
            
            if ([tableData count] < 1) {return;}
            
            // When images are loaded, reposition selection at top of table
            NSIndexPath *idx = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.tblView selectRowAtIndexPath:idx animated:YES scrollPosition:UITableViewScrollPositionTop];
            
            // Trim path off filenames
            for (int i=0; i<[tableData count]; i++) {
                tableData[i] = [tableData[i] stringByReplacingOccurrencesOfString:@"uploads/" withString:@""];
                
                //For each filename in table, get image and cache it (so image is in memory before user taps on it)
                NSString *identifier = tableData[i];
                NSLog(@"[AWS:] > Downloading image %@ from AWS",identifier);
                SWSAsyncLoader *loader = [[SWSAsyncLoader alloc] init];
                [loader load:self.urlStr txt:BACKGROUND_LOAD_IMAGE delegate:self imageName:identifier];
            }
            
            // Display 1st image (fm cache if background load finished; otherwise from AWS)
            NSString *identifier = tableData[0];
            SWSAsyncLoader *loader = [[SWSAsyncLoader alloc] init];
            [loader load:self.urlStr txt:LOAD_IMAGE delegate:self imageName:identifier];

            return;
        }
        
        //There is nothing more to do after saving a new image (it is already been sent to AWS and added to the cache and the table)
        if ([loader.textTag isEqualToString:SAVE_IMAGE]) {
            //NSLog(@"\nSave Image:%@", loader.imageName);
            return;
        }
        
        //After deleting an image from AWS, delete it from the cache and update the table
        if ([loader.textTag isEqualToString:DELETE_IMAGE]) {
            //NSLog(@"\nDelete Image:%@", loader.imageName);
            
            //after deleting an image, remove it from our cache (if present)
            [self.myCache deleteImageWithIdentifier:loader.imageName];
            
            //delete image from table data source
            NSUInteger index = [tableData indexOfObject:loader.imageName];
            [tableData removeObjectAtIndex:index];
            [self.tblView reloadData];

            //select new item (at same index location as deleted item, or at last index loc if we are at end of table)
            if ([tableData count] < 1) {return;}                                //we deleted last entry - nothing to display
            if (index >= [tableData count]) {index = [tableData count] - 1;}    //we deleted item at end of table - display item that is now at end of table
            NSIndexPath *idx = [NSIndexPath indexPathForRow:index inSection:0];
            [self.tblView selectRowAtIndexPath:idx animated:YES scrollPosition:UITableViewScrollPositionNone];
            
            //display image from selected row
            NSString *identifier = [tableData objectAtIndex:index];
            self.imageView.image = [self.myCache imageWithIdentifier:identifier];
            return;
        }
        
        if ([loader.textTag isEqualToString:LOAD_IMAGE]) {
            NSLog(@"Load Image:%@", loader.imageName);
            self.imageView.image = loader.image;
            [self.tblView reloadData];
            
            NSIndexPath *idx = [NSIndexPath indexPathForRow:self.lastClickedRow inSection:0];
            [self.tblView selectRowAtIndexPath:idx animated:YES scrollPosition:UITableViewScrollPositionNone];

            //cache image if it hasn't already been cached
            [self.myCache addImage:loader.image identifier:loader.imageName compressionQuality:0.5];
            return;
        }
        
        if ([loader.textTag isEqualToString:BACKGROUND_LOAD_IMAGE]) {
            //NSLog(@"Background Load Image:%@", loader.imageName);
            [self.tblView reloadData];
            
            // After reload, re-highlight currently selected table entry
            NSIndexPath *idx = [NSIndexPath indexPathForRow:self.lastClickedRow inSection:0];
            [self.tblView selectRowAtIndexPath:idx animated:YES scrollPosition:UITableViewScrollPositionNone];
            
            //cache image if it hasn't already been cached
            [self.myCache addImage:loader.image identifier:loader.imageName compressionQuality:0.5];
            return;
        }
        
    }); // end of dispatch_async
}

-(void)loaderDidFail:(SWSAsyncLoader *)loader {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s",__FUNCTION__);}
}

# pragma mark - UIImagePickerController Delegate methods (all are optional)

// The picker does not dismiss itself; the client dismisses it in these callbacks.
// The delegate will receive one or the other, but not both, depending whether the user
// confirms or cancels.

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}

    [self.pop dismissPopoverAnimated:YES];
    self.pop = nil;
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];    // as opposed to UIImagePickerControllerOriginalImage
    self.imageView.image = image;
    
    //Name the new image
    NSString *imageName = [[NSString alloc] initWithFormat:@"%f.jpg", [[NSDate date] timeIntervalSince1970]];  // Use number of secs since 1/1/1970 as filename
    
    //cache new image
    [self.myCache addImage:image identifier:imageName compressionQuality:0.5];
    
    //add new image to table data source and redisplay table
    [tableData addObject:imageName];
    [self.tblView reloadData];
    
    //scroll to and select new image in table
    NSIndexPath *idx = [NSIndexPath indexPathForRow:[tableData count]-1 inSection:0];
    [self.tblView selectRowAtIndexPath:idx animated:YES scrollPosition:UITableViewScrollPositionBottom];
    
    //upload image to AWS
    NSLog(@"[AWS:] > Uploading image %@ to AWS",imageName);
    SWSAsyncLoader *loader = [[SWSAsyncLoader alloc] init];
    [loader load:self.urlStr txt:SAVE_IMAGE delegate:self paramKeys:@[@"fileSave"] paramVals:@[@"TRUE"] image:image imageName:imageName];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if (LOG_METHOD_NAMES) {NSLog(@"[METHOD:] %s", __FUNCTION__);}
    
    [self.pop dismissPopoverAnimated:YES];
    self.pop = nil;
}

#pragma mark - UITableView Delegate and Data Source methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableData count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    cell.backgroundColor = [UIColor clearColor];
    NSString *identifier = [tableData objectAtIndex:indexPath.row]; //get imageName
    cell.textLabel.text = identifier;
    cell.imageView.image = [self.myCache imageWithIdentifier:identifier];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //if image was previously selected, get it from our cache. Otherwise load it from AWS
    NSString *identifier = [tableData objectAtIndex:indexPath.row]; //get imageName
    self.imageView.image = [self.myCache imageWithIdentifier:identifier];
    if (!self.imageView.image) {
        NSLog(@"[AWS:] > Downloading selected image %@ from AWS",identifier);
        SWSAsyncLoader *loader = [[SWSAsyncLoader alloc] init];
        [loader load:self.urlStr txt:LOAD_IMAGE delegate:self imageName:identifier];
    }
    self.lastClickedRow = indexPath.row;
}

// Delete image which corresponds to selected filename
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = [tableData objectAtIndex:indexPath.row]; //get imageName
    NSLog(@"[AWS:] > Deleting image %@ from AWS",identifier);
    SWSAsyncLoader *loader = [[SWSAsyncLoader alloc] init];
    [loader load:self.urlStr txt:DELETE_IMAGE delegate:self imageName:identifier];
    self.lastClickedRow = indexPath.row;
}

@end
