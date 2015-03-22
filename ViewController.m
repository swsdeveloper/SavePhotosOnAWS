//
//  ViewController.m
//  CameraTest
//
//  Created by Aditya on 02/10/13.
//  Copyright (c) 2013 Aditya. All rights reserved.
//

#import "ViewController.h"
#import "ImageCache.h"
#import "Constants.h"


#define AWS_URL @"http://bengalboard.com:8080/AmazonS3Web/AWSService"

#define LIST_FILES @"ListFiles"
#define BACKGROUND_LOAD_IMAGE @"BackgroundLoadImage"
#define LOAD_IMAGE @"LoadImage"
#define SAVE_IMAGE @"SaveImage"
#define DELETE_IMAGE @"DeleteImage"


@interface ViewController ()

@property (nonatomic,strong) ImageCache *myCache;

@end

@implementation ViewController

- (void)viewDidLoad {
    NSLog(@"..................%s",__FUNCTION__);
    [super viewDidLoad];
    urlStr = AWS_URL;
    _myCache = [ImageCache new];
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action methods

- (IBAction)edit:(id)sender {
    if (pop) {
        [pop dismissPopoverAnimated:TRUE];
    }
    
    if ([tblView isEditing]) {          // Default is no, so 1st time Edit button is tapped, isEditing is false
        [sender setTitle:@"Edit"];
    } else {
        [sender setTitle:@"Done"];
    }
    [tblView setEditing:![tblView isEditing]];
    
    // When edit button is pressed, highlight the currently selected table entry
    
    NSIndexPath *idx = [NSIndexPath indexPathForRow:lastClickedRow inSection:0];
    [tblView selectRowAtIndexPath:idx animated:YES scrollPosition:UITableViewScrollPositionNone];

}

- (IBAction)takePicture:(id)sender {
    [tblView setEditing:TRUE animated:YES];
    [self edit:self.editButton];
    
    if ([pop isPopoverVisible]) {
        [pop dismissPopoverAnimated:YES];
        pop = nil;
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
    
    pop = [[UIPopoverController alloc] initWithContentViewController:ip];
    [pop setDelegate:self];
    [pop presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark - Convenience method for invoking AsyncLoader - loads images fm AWS server into our table

-(void)loadData {
    NSLog(@"..................%s",__FUNCTION__);
    AsyncLoader *loader = [[AsyncLoader alloc] init];
    [loader load:urlStr txt:LIST_FILES delegate:self params:@"listFile=uploads/"];
}

#pragma mark - AsyncLoader Delegate Protocol methods - called from within AsyncLoader.m (because this object is the AsyncLoader's delegate)

//-(void)loaderDidFail:(AsyncLoader *)loader {
//    NSLog(@"..................%s --> Retrying...",__FUNCTION__);
//    [loader load:urlStr txt:loader.textTag delegate:self params:loader.params];
//}

-(void)loaderDidLoad:(AsyncLoader *)loader {
    NSLog(@"..................%s",__FUNCTION__);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([loader.textTag isEqualToString:LIST_FILES]) {
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData: loader.ldData options: NSJSONReadingMutableContainers error: nil];
            tableData = [NSMutableArray arrayWithArray:jsonArray];
            NSLog(@"\nLoading.........%ld Records",[tableData count]);
            
            if ([tableData count] < 1) {return;}

            [tblView reloadData];
            
            // When images are loaded, reposition selection at top of table
            NSIndexPath *idx = [NSIndexPath indexPathForRow:0 inSection:0];
            [tblView selectRowAtIndexPath:idx animated:YES scrollPosition:UITableViewScrollPositionTop];
            
            //get and display 1st image in table
            for (int i=0; i<[tableData count]; i++) {
                tableData[i] = [tableData[i] stringByReplacingOccurrencesOfString:@"uploads/" withString:@""];
                if (i == 0) {
                    NSString *params = [[NSString alloc] initWithFormat:@"getFile=uploads/%@",tableData[i]];
                    AsyncLoader *loader = [[AsyncLoader alloc] init];
                    [loader load:urlStr txt:LOAD_IMAGE delegate:self params:params];
                }
            }
            
            //For each filename in table, get image and cache it (so image is in memory before user taps on it)
            for (NSString *imageName in tableData) {
                NSString *params = [[NSString alloc] initWithFormat:@"getFile=uploads/%@",imageName];
                AsyncLoader *loader = [[AsyncLoader alloc] init];
                [loader load:urlStr txt:BACKGROUND_LOAD_IMAGE delegate:self params:params];
            }
            return;
        }
        
        //There is nothing more to do after saving a new image (it is already been sent to AWS and added to the cache and the table)
        // NOTE: If the save to AWS fails, handle it here
        if ([loader.textTag isEqualToString:SAVE_IMAGE]) {
            NSLog(@"\nSave Image:%@", loader.imageName);
            return;
        }
        
        //After deleting an image from AWS, delete it from the cache and update the table
        if ([loader.textTag isEqualToString:DELETE_IMAGE]) {
            NSLog(@"\nDelete Image:%@", loader.imageName);
            
            //after deleting an image, remove it from our cache (if present)
            NSString *imageName = tableData[lastClickedRow];
            [self.myCache deleteFromCache:imageName];
            
            //delete image from table data source
            NSUInteger index = [tableData indexOfObject:imageName];
            [tableData removeObjectAtIndex:index];
            
            //reload the table view
            [tblView reloadData];

            //select new item (at same index location as deleted item, or at last index loc if we are at end of table)
            if ([tableData count] < 1) {return;}                                //we deleted last entry - nothing to display
            if (index >= [tableData count]) {index = [tableData count] - 1;}    //we deleted item at end of table - display item that is now at end of table
            NSIndexPath *idx = [NSIndexPath indexPathForRow:index inSection:0];
            [tblView selectRowAtIndexPath:idx animated:YES scrollPosition:UITableViewScrollPositionNone];
            
            //display image from selected row
            imageView.image = [self.myCache getFromCache:tableData[index]];

            return;
        }
        
        if ([loader.textTag isEqualToString:LOAD_IMAGE]) {
            imageView.image = loader.image;
            
            //cache image if it hasn't already been cached
            NSString *imageName = tableData[lastClickedRow];
            [self.myCache addToCache:imageName image:imageView.image compressionQuality:0.5];
            return;
        }
        
        if ([loader.textTag isEqualToString:BACKGROUND_LOAD_IMAGE]) {
            NSLog(@"Background Load Image");
            //cache image if it hasn't already been cached
            [self.myCache addToCache:loader.imageName image:loader.image compressionQuality:0.5];
            [tblView reloadData];
            return;
        }
        
    }); // end of dispatch_async
}

# pragma mark - UIImagePickerController Delegate methods (all are optional)

// The picker does not dismiss itself; the client dismisses it in these callbacks.
// The delegate will receive one or the other, but not both, depending whether the user
// confirms or cancels.

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [pop dismissPopoverAnimated:YES];
    pop = nil;
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];    // as opposed to UIImagePickerControllerOriginalImage
    [imageView setImage:image];
    
    //Name the new image
    NSString *imageName = [[NSString alloc] initWithFormat:@"%f.jpg", [[NSDate date] timeIntervalSince1970]];  // Use number of secs since 1/1/1970 as filename
    
    //cache new image
    [self.myCache addToCache:imageName image:imageView.image compressionQuality:0.5];
    
    //add new image to table data source and redisplay table
    [tableData addObject:imageName];
    [tblView reloadData];
    
    //scroll to and select new image in table
    NSIndexPath *idx = [NSIndexPath indexPathForRow:[tableData count]-1 inSection:0];
    [tblView selectRowAtIndexPath:idx animated:YES scrollPosition:UITableViewScrollPositionBottom];
    
    //upload image to AWS
    AsyncLoader *loader = [[AsyncLoader alloc] init];
    [loader load:urlStr txt:SAVE_IMAGE delegate:self paramKeys:@[@"fileSave"] paramVals:@[@"TRUE"] image:image imageName:imageName];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [pop dismissPopoverAnimated:YES];
}

#pragma mark - UITableView Delegate and Data Source methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tableData count];
}

// Display the corresponding data (i.e., image filename) as the label for each cell
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    cell.backgroundColor = [UIColor clearColor];
    [[cell textLabel] setText:[tableData objectAtIndex:indexPath.row]];
    cell.imageView.image = [self.myCache getFromCache:cell.textLabel.text];
    return cell;
}

// Load image which corresponds to selected filename into our imageView
// At entry: urlString
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *params = [[NSString alloc] initWithFormat:@"getFile=%@",[tableData objectAtIndex:indexPath.row ]];
    
    //if image was previously selected, get it from our cache. Otherwise load it from AWS
    NSString *imageName = tableData[indexPath.row];
    imageView.image = [self.myCache getFromCache:imageName];
    if (!imageView.image) {
        NSLog(@"> Getting image %@ from AWS",imageName);
        AsyncLoader *loader = [[AsyncLoader alloc] init];
        [loader load:urlStr txt:LOAD_IMAGE delegate:self params:params];
    }
    lastClickedRow = indexPath.row;
}

// Delete image which corresponds to selected filename
// At entry: urlString
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *params = [[NSString alloc] initWithFormat:@"delFile=%@",[tableData objectAtIndex:indexPath.row]];
    AsyncLoader *loader = [[AsyncLoader alloc] init];
    [loader load:urlStr txt:DELETE_IMAGE delegate:self params:params];
    lastClickedRow = indexPath.row;
}

@end
