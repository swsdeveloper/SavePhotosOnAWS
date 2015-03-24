//
//  SWSViewController.h
//  SavePhotosOnAWS
//
//  Created by Steven Shatz on 3/18/15.
//  Copyright (c) 2015 Steven Shatz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWSAsyncLoader.h"

@interface SWSViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UITableViewDelegate, UITableViewDataSource> {

    NSMutableArray *tableData;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tblView;

- (void)loadData;

- (IBAction)takePicture:(id)sender;

- (IBAction)edit:(id)sender;

@end
