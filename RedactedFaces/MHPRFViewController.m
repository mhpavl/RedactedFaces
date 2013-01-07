//
//  MHPRFViewController.m
//  RedactedFaces
//
//  Created by Mark H Pavlidis on 1/6/2013.
//  Copyright (c) 2013 Grok Software. All rights reserved.
//

#import "MHPRFViewController.h"
#import <CoreImage/CoreImage.h>

@interface MHPRFViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) CIContext *context;

- (IBAction)tappedOriginal:(id)sender;
- (IBAction)tappedRedacted:(id)sender;


@end

@implementation MHPRFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageView.image = [UIImage imageNamed:@"faces"];
    self.context = [CIContext contextWithOptions:nil];
}

- (IBAction)tappedOriginal:(id)sender {
    self.imageView.image = [UIImage imageNamed:@"faces"];
}

- (IBAction)tappedRedacted:(id)sender {
    CIImage *image = [CIImage imageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"faces" withExtension:@"png"]];
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:nil];
    NSArray *faces = [detector featuresInImage:image options:nil];
    
    // Create a green circle to cover the rects that are returned.    
    CIImage *maskImage = nil;
    
    for (CIFeature *face in faces) {
        CIVector *centre = [CIVector vectorWithX:face.bounds.origin.x + face.bounds.size.width/2.0
                                               Y:face.bounds.origin.y + face.bounds.size.height/2.0];
        CGFloat radius = MIN([face bounds].size.width, [face bounds].size.height)/1.5;
        CIFilter *radialGradient = [CIFilter filterWithName:@"CIRadialGradient" keysAndValues:
                                    @"inputRadius0", @(radius),
                                    @"inputRadius1", @(radius + 1.0),
                                    @"inputColor0", [CIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0], // Green
                                    @"inputColor1", [CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0], // Transparent
                                    @"inputCenter", centre,
                                    nil];
        CIImage *circleImage = radialGradient.outputImage;

        if (nil == maskImage)
            maskImage = circleImage;
        else
            maskImage = [[CIFilter filterWithName:@"CISourceOverCompositing" keysAndValues:
                          @"inputImage", circleImage,
                          @"inputBackgroundImage", maskImage,
                          nil]
                         outputImage];        
    }
    
    CIImage *pixellatedImage = [[CIFilter filterWithName:@"CIPixellate" keysAndValues:
                                 kCIInputImageKey, image,
                                 @"inputScale", @(32),
                                 nil]
                               outputImage];
    
    CIImage *redactedImage = [[CIFilter filterWithName:@"CIBlendWithMask" keysAndValues:
                               kCIInputImageKey, pixellatedImage,
                               kCIInputBackgroundImageKey, image,
                               @"inputMaskImage", maskImage,
                               nil]
                              outputImage];
    
    
    CGImageRef cgImage = [self.context createCGImage:redactedImage fromRect:redactedImage.extent];
    self.imageView.image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
}

@end
