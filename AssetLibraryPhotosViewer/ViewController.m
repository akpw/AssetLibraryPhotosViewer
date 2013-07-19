//
//  ViewController.m
//  AssetLibraryPhotosViewer
//
//  Created by Arseniy on 18/7/13.
//  Copyright (c) 2013 Arseniy Kuznetsov. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "ViewController.h"

typedef void(^ImageProcessingBlock)(UIImage *);

@interface ViewController ()
    @property (nonatomic, strong) NSMutableArray *imagesURLArray;
    @property (nonatomic, copy) ImageProcessingBlock imageProcessingBlock;
@end

typedef NS_ENUM(NSUInteger, ImageFormats) {
    kImageThumbnail = 0,
    kImageFullScreen
};

@implementation ViewController

#pragma mark -
#pragma mark - Initialization
- (NSMutableArray *)imagesURLArray {
    if (!_imagesURLArray) {
        _imagesURLArray = [[NSMutableArray alloc] init];
    }
    return _imagesURLArray;
}

#pragma mark - AssetsLibrary processing
// iterate over ALAssetsLibrary images, storing their URL to _imagesURLArray for later retrieval
// for the first image, runs it through imageProcessingBlock to initialize the imageView
- (void)fetchAssetsLibraryPhotosURLWithCompletionBlock:(void(^)())completionBlock {
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    ALAssetsLibraryGroupsEnumerationResultsBlock libGroupEnumerationResult = ^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            NSUInteger numAssets = group.numberOfAssets;
            [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *innerstop) {
                if (asset) {
                    ALAssetRepresentation *rep = [asset defaultRepresentation];
                    NSURL *imageURL = [rep url];
                    UIImage *image = nil;                   
                    if (index == 0) {
                        CGImageRef iref = [rep fullScreenImage];
                        if (iref) {
                            image = [UIImage imageWithCGImage:iref scale:rep.scale
                                                           orientation:(UIImageOrientation)rep.orientation];
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.imagesURLArray addObject:imageURL];
                        if (image) {
                            self.imageProcessingBlock(image);
                        }
                        if (index + 1 == numAssets) {
                            completionBlock();
                        }
                    });
                }
            }];
        }
    };
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                  usingBlock:libGroupEnumerationResult
                                  failureBlock:^(NSError *error) {
          NSLog(@"failure: %@", [error localizedDescription]);
     }];
}
- (void)assetLibraryProcessImageAtURL:(NSURL *)assetLibraryPath
                          ImageFormat:(ImageFormats)format
                          WithBlock:(void(^)(UIImage *theImage))block {
    if (!assetLibraryPath) return;
    
    /// -- failure block --- ///
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *theError) {
        NSLog(@"Can't get image from the asset library %@", [theError localizedDescription]);
    };
    /// -- full screen image block --- ///
    ALAssetsLibraryAssetForURLResultBlock fullScreenProcessResultBlock = ^(ALAsset *theAsset) {
        ALAssetRepresentation *rep = [theAsset defaultRepresentation];
        CGImageRef iref = [rep fullScreenImage];
        if (iref) {
            UIImage *image = [UIImage imageWithCGImage:iref scale:rep.scale
                                           orientation:(UIImageOrientation)rep.orientation];
            block (image);
        }
    };
    /// -- thumbnail image block --- ///
    ALAssetsLibraryAssetForURLResultBlock thumbnailProcessResultblock = ^(ALAsset *theAsset) {
        CGImageRef iref = [theAsset thumbnail];
        if (iref) {
            UIImage *image = [UIImage imageWithCGImage:iref];
            block (image);
        }
    };
    /////////
    ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:assetLibraryPath
                   resultBlock:(format == kImageThumbnail) ? thumbnailProcessResultblock : fullScreenProcessResultBlock
                   failureBlock:failureblock];
}


#pragma mark - view lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // initialize the image processing block
    __weak typeof (self) weakSelf = self;
    self.imageProcessingBlock =  ^(UIImage *theImage) {
        [weakSelf.imageView setImage:theImage];
    };

    // the navigation stepper will be set & enabled after processing images URL
    _navigationStepper.enabled = NO;
    
    [self fetchAssetsLibraryPhotosURLWithCompletionBlock:^{
        NSUInteger imagesCount = [self.imagesURLArray count];
        if (imagesCount > 1) {
            _navigationStepper.enabled = YES;           
            _navigationStepper.maximumValue = imagesCount - 1;
        }
    }];
}

#pragma mark - use the stepper to navigate images, loading them for display as needed
- (IBAction)navigationStepperValueChanged:(id)sender {
    NSUInteger stepperValue = _navigationStepper.value;
    
    NSURL *imageURL = (NSURL *)[self.imagesURLArray objectAtIndex:stepperValue];
    [self assetLibraryProcessImageAtURL:imageURL ImageFormat:kImageFullScreen WithBlock:self.imageProcessingBlock];
    
    // for thumbnail image, just use below
    // [self assetLibraryProcessImageAtURL:imageURL ImageFormat:kImageThumbnail WithBlock:imageProcessingBlock];
}


@end
