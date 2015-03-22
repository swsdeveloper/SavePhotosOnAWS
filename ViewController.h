//
//  ViewController.h
//  CameraTest
//
//  Created by Aditya on 02/10/13.
//  Copyright (c) 2013 Aditya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncLoader.h"

@interface ViewController : UIViewController
<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate,
UITableViewDelegate, UITableViewDataSource>
{
    NSString *urlStr;
    UIPopoverController *pop;
    __weak IBOutlet UIImageView *imageView;
    __weak IBOutlet UITableView *tblView;
    NSMutableArray *tableData;
    NSInteger lastClickedRow;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;

@property (nonatomic,strong) NSMutableDictionary *cachedImages;

-(void)loadData;
- (IBAction)takePicture:(id)sender;
- (IBAction)edit:(id)sender;

@end
