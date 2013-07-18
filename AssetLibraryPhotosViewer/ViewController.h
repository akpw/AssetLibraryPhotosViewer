//
//  ViewController.h
//  AssetLibraryPhotosViewer
//
//  Created by Arseniy on 18/7/13.
//  Copyright (c) 2013 Arseniy Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIStepper *stepper;

- (IBAction)stepperValueChanged:(id)sender;

@end
