//
//  PuzzleVideoController.m
//  PuzzleAnalyzer
//
//  Created by Wong Shing Chi Teddy on 23/12/15.
//  Copyright © 2015 Wong Shing Chi Teddy. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <CoreMediaIO/CMIOHardware.h>

#import "PuzzleManager.h"
#import "PuzzleVideoController.h"



@interface PuzzleVideoController () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    BOOL snapshot;
    
    PuzzleManager *puzzleManager;
}

@property (nonatomic, strong) AVCaptureSession *videoSession;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) NSArray *observers;
@property (nonatomic, strong) NSMutableArray *orbIndicators;
@property (nonatomic, strong) PuzzleManager *puzzleManager;

@end

@implementation PuzzleVideoController

@synthesize videoSession;
@synthesize videoDeviceInput;
@synthesize observers;
@synthesize orbIndicators;
@synthesize puzzleManager;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self)
    {
        orbIndicators = [[NSMutableArray alloc]init];
        puzzleManager = [[PuzzleManager alloc]init];
        
        //Allow iOS device to be seen
        CMIOObjectPropertyAddress prop =
        {
            kCMIOHardwarePropertyAllowScreenCaptureDevices,
            kCMIOObjectPropertyScopeGlobal,
            kCMIOObjectPropertyElementMaster
        };
        UInt32 allow = 1;
        CMIOObjectSetPropertyData(kCMIOObjectSystemObject, &prop, 0, NULL, sizeof(allow), &allow);
        
        //Create capture session
        AVCaptureSession *videocapturesession = [[AVCaptureSession alloc]init];
        self.videoSession = videocapturesession;
        
        // Capture Notification Observers
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        id runtimeErrorObserver = [notificationCenter addObserverForName:AVCaptureSessionRuntimeErrorNotification
                                                                  object:videocapturesession
                                                                   queue:[NSOperationQueue mainQueue]
                                                              usingBlock:^(NSNotification *note) {
                                                                  dispatch_async(dispatch_get_main_queue(), ^(void) {
                                                                      [self presentError:[[note userInfo] objectForKey:AVCaptureSessionErrorKey]];
                                                                  });
                                                              }];
        id didStartRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStartRunningNotification
                                                                     object:videocapturesession
                                                                      queue:[NSOperationQueue mainQueue]
                                                                 usingBlock:^(NSNotification *note) {
                                                                     NSLog(@"did start running");
                                                                 }];
        id didStopRunningObserver = [notificationCenter addObserverForName:AVCaptureSessionDidStopRunningNotification
                                                                    object:videocapturesession
                                                                     queue:[NSOperationQueue mainQueue]
                                                                usingBlock:^(NSNotification *note) {
                                                                    NSLog(@"did stop running");
                                                                }];
        id deviceWasConnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification
                                                                        object:nil
                                                                         queue:[NSOperationQueue mainQueue]
                                                                    usingBlock:^(NSNotification *note) {
                                                                        [self attemptDisplayScreen];
                                                                    }];
//        id deviceWasDisconnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification
//                                                                           object:nil
//                                                                            queue:[NSOperationQueue mainQueue]
//                                                                       usingBlock:^(NSNotification *note) {
//                                                                           [self refreshDevices];
//                                                                       }];
        observers = [[NSArray alloc] initWithObjects:runtimeErrorObserver, didStartRunningObserver, didStopRunningObserver, deviceWasConnectedObserver, nil];//, deviceWasDisconnectedObserver, nil];
        
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc]init];
        [output setAlwaysDiscardsLateVideoFrames:YES]; //necessary?
        [output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        
        dispatch_queue_t outputQuene = dispatch_queue_create("outputQueue", DISPATCH_QUEUE_SERIAL);
        [output setSampleBufferDelegate:self queue:outputQuene];
        
        if ([videoSession canAddOutput:output])
        {
            [videoSession addOutput:output];
        }
        else
        {
            NSLog(@"ERROR: videoSession %@ cannot addoutput %@",videoSession,output);
        }

        [self attemptDisplayScreen];
    }
    return self;
}

- (void)attemptDisplayScreen
{
    
    NSLog(@"Devices:%@",[AVCaptureDevice devices]);
    
    AVCaptureDevice *videodevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeMuxed];
    if (videodevice)
    {
        [videoSession beginConfiguration];
        
        if (videoDeviceInput)
        {
            [videoSession removeInput:videoDeviceInput];
            self.videoDeviceInput = nil;
        }
        
        NSError *error = nil;
        AVCaptureDeviceInput *deviceinput = [AVCaptureDeviceInput deviceInputWithDevice:videodevice error:&error];
        if (deviceinput == nil)
        {
            NSLog(@"Error, input %@ is nil",deviceinput);
        }
        else
        {
            if (![videodevice supportsAVCaptureSessionPreset:videoSession.sessionPreset])
            {
                [videoSession setSessionPreset:AVCaptureSessionPresetHigh];
            }
            [videoSession addInput:deviceinput];
            self.videoDeviceInput = deviceinput;
        }
        [videoSession commitConfiguration];
    }
    else
    {
        NSLog(@"ERROR: Unable to find Video Device :%@",videodevice);
    }

}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSLog(@"Window Did Load");
    
    CALayer *viewlayer = [CALayer layer];
//    [viewlayer setBackgroundColor:CGColorCreateGenericRGB(0, 0, 0, 0.4)];
    [videoPreviewView setWantsLayer:YES];
    [videoPreviewView setLayer:viewlayer];
    
    AVCaptureVideoPreviewLayer *videopreviewlayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:videoSession];
    [videopreviewlayer setFrame:videoPreviewView.layer.bounds];
    [videopreviewlayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
    [videoPreviewView.layer addSublayer:videopreviewlayer];
    [videoPreviewView.layer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
    NSLog(@"videoPreviewView:%@",videoPreviewView);
    NSLog(@"layer:%@",videoPreviewView.layer);
    [videoSession startRunning];
    
    [self.window.contentView addSubview:snapShotButton positioned:NSWindowAbove relativeTo:videoPreviewView];
    
    [self.window.contentView addSubview:orbLocationView positioned:NSWindowAbove relativeTo:videoPreviewView];
    [self.window.contentView addSubview:showHideOrbButton positioned:NSWindowAbove relativeTo:videoPreviewView];
    [self.window.contentView addSubview:patternButton positioned:NSWindowAbove relativeTo:videoPreviewView];

    NSLog(@"orblocationview layer:%@",orbLocationView.layer);
//    [orbLocationView.layer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];

    //Generate 6x 5y orb views
    int columns = 6;
    int rows = 5;
    for (int x = 0; x<6; x++)
    {
        for (int y = 0; y<5; y++)
        {//goes from top, to down, then left to right = y+x*5
            NSView *orbview = [[NSView alloc]initWithFrame:NSRectFromCGRect(CGRectMake(0, 0, 100, 100))];
            orbview.translatesAutoresizingMaskIntoConstraints = NO;
            [orbLocationView addSubview:orbview];
            [orbLocationView addConstraint:[NSLayoutConstraint constraintWithItem:orbview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:orbLocationView attribute:NSLayoutAttributeHeight multiplier:1.0f/5.0f constant:0.0f]];
            [orbLocationView addConstraint:[NSLayoutConstraint constraintWithItem:orbview attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:orbLocationView attribute:NSLayoutAttributeWidth multiplier:1.0f/6.0f constant:0.0f]];
            
            [orbLocationView addConstraint:[NSLayoutConstraint constraintWithItem:orbview attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:orbLocationView attribute:NSLayoutAttributeCenterX multiplier:(x*2+1)/6.0f constant:0.0f]];//1/6, 3/6, 5/6, 7/6, 9/6, 11/6
            
            [orbLocationView addConstraint:[NSLayoutConstraint constraintWithItem:orbview attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:orbLocationView attribute:NSLayoutAttributeCenterY multiplier:(y*2+1)/5.0f constant:0.0f]];
            
            [orbIndicators addObject:orbview];
        }
    }
}

- (IBAction)snapShot:(id)sender
{
    snapshot = YES;
}

- (IBAction)showHideOrbIndicators:(id)sender
{
    orbLocationView.hidden = !orbLocationView.hidden;
}

- (IBAction)analysePatterns:(id)sender
{
    [puzzleManager generatePatterns];
}

- (void)changeOrbIndicator:(int)i forColor:(CGColorRef)color
{
//    NSLog(@"changing orbindicator :%i",i);
    NSView *indicator = [orbIndicators objectAtIndex:i];
    [indicator.layer setBackgroundColor:color];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    NSLog(@"Capture Output didOutputSampleBuffer");
    [self processFrames:sampleBuffer];
}

- (void)processFrames:(CMSampleBufferRef)sampleBuffer
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    size_t rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer);
    float pixelBytes = (float)rowBytes/(float)bufferWidth; //Pixel Per Byte
    
    unsigned char *base = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
//    NSLog(@"pixelBytes %f",pixelBytes);
    
    
//    NSLog(@"buffer %zu %zu",bufferWidth,bufferHeight);
    
    int orbs_width = 6;
    int orbs_height = 5;
    
    if ((int)pixelBytes == 4)
    {
        if (snapshot)
        {
            snapshot = NO;
            
            
            int **orbs_x = malloc(sizeof(int *)*6);
            for (int i=0; i<orbs_width; i++)
            {
                int *orbs_y = malloc(sizeof(int)*5);
                orbs_x[i] = orbs_y;
            }
            
            
            for (int x = 0; x < 6; x++)
            {
                for (int y = 0; y < 5; y++)
                {
                    int borderpixel = 4;
                    
                    int orbborderpixel = 1;
                    
                    int orbsize = 104; //102 pixels
                    
                    int searchWidth = 20;
                    int searchHeight = 20;
                    
                    float r = 0;
                    float g = 0;
                    float b = 0;
                    int a = 1.0f;
                    
                    int row = (int)bufferHeight-(y*orbsize)-(orbsize/2)-(y*orbborderpixel); //Y direction up, and down
                    int column =  (orbsize/2)+(x*orbsize)+borderpixel+(x+1)*orbborderpixel;//X direction left and right
//                    row+=10;
//                    column-=10;
                
                    for (int searchX = column; searchX < column+searchWidth; searchX++)
                    {
                        for (int searchY = row; searchY < row+searchWidth; searchY++)
                        {
                            unsigned char *pixel = base + (searchY * rowBytes) + (searchX * (size_t)pixelBytes);
                            
                            int intr = pixel[2];
                            int intg = pixel[1];
                            int intb = pixel[0];
                            r += intr;
                            g += intg;
                            b += intb;
                        }
                    }
                    
//                    unsigned char *pixel = base + (row * rowBytes) + (column * (size_t)pixelBytes);
                    
                    r = r/(searchWidth*searchHeight);
                    g = g/(searchWidth*searchHeight);
                    b = b/(searchWidth*searchHeight);

//                    int r = pixel[2];
//                    int g = pixel[1];
//                    int b = pixel[0];
                    
                    dispatch_async(dispatch_get_main_queue(), ^
                    {
                        int reversey = -y+4;
                        [self changeOrbIndicator:(x*5+reversey) forColor:CGColorCreateGenericRGB(r/255.0f, g/255.0f, b/255.0f, 1.0f)];
                    });
                    
                    //Dark
                    if ((r >= 130 && r <= 210) && (g >= 60 && g <= 160) && (b >= 150 && b <= 240))
                    {
                        //                        NSLog(@"Dark %i %i",x,y);
                        int *orbs_y = orbs_x[x];
                        orbs_y[y] = oDark; //Enhance orb checked
                    }
                    else if ((r >= 230 && r <= 255) && (g >= 210 && g <= 255) && (b >= 60 && b <= 160))
                    {
                        //                        NSLog(@"Light %i %i",x,y);
                        int *orbs_y = orbs_x[x];
                        orbs_y[y] = oLight; //Enhance orb checked
                    }
                    else if ((r >= 230 && r <= 255) && (g >= 90 && g <= 200) && (b >= 60 && b <= 160))
                    {
                        //                        NSLog(@"Fire %i %i",x,y);
                        int *orbs_y = orbs_x[x];
                        orbs_y[y] = oFire; //Enhance orb checked
                    }
                    else if ((r >= 40 && r <= 150) && (g >= 130 && g <= 220) && (b >= 210 && b <= 250))
                    {
                        //                        NSLog(@"Water %i %i",x,y);
                        int *orbs_y = orbs_x[x];
                        orbs_y[y] = oWater; //Enhance orb checked
                    }
                    else if ((r >= 40 && r <= 140) && (g >= 150 && g <= 220) && (b >= 70 && b <= 180))
                    {
                        //                        NSLog(@"Grass %i %i",x,y);
                        int *orbs_y = orbs_x[x];
                        orbs_y[y] = oGrass; //Enhance orb checked
                    }
                    else if ((r >= 210 && r <= 255) && (g >= 20 && g <= 100) && (b >= 130 && b <= 210))
                    {
                        //                        NSLog(@"Heart %i %i",x,y);
                        int *orbs_y = orbs_x[x];
                        orbs_y[y] = oHeart; //Enhance orb checked
                    }
                    else
                    {
                        NSLog(@"x|%i|y:%i   |R%0.01f|G%0.01f|B%0.01f|A%i      px:%i,py:%i",x,y,r,g,b,a,column,row);
                        int *orbs_y = orbs_x[x];
                        orbs_y[y] = oUndefined;
                    }
//                    NSLog(@"x|%i|y:%i   |R%0.01f|G%0.01f|B%0.01f|A%i      px:%i,py:%i",x,y,r,g,b,a,column,row);
                
                }
                
            }
            
            int fire = 0;
            int water = 0;
            int grass = 0;
            int light = 0;
            int dark = 0;
            int heart = 0;
            
            for (int y=4; y>=0; y--)
            {
                NSString *appendstring = @"";
                for (int x=0; x<=5; x++)
                {
                    NSString *element = @"";
                    int *orbs_y = orbs_x[x];
                    int result = orbs_y[y];
                    if (result == oFire)
                    {
                        element = @"F";
                        fire++;
                    }
                    else if (result == oWater)
                    {
                        element = @"W";
                        water++;
                    }
                    else if (result == oGrass)
                    {
                        element = @"G";
                        grass++;
                    }
                    else if (result == oLight)
                    {
                        element = @"L";
                        light++;
                    }
                    else if (result == oDark)
                    {
                        element = @"D";
                        dark++;
                    }
                    else if (result == oHeart)
                    {
                        element = @"H";
                        heart++;
                    }
                    else
                    {
                        element = [NSString stringWithFormat:@"U%i,%i",x,y];
                    }
//                    element = [NSString stringWithFormat:@"%i|%i",x,y];
                    
                    appendstring = [appendstring stringByAppendingFormat:@"%@ [%i,%i]",element,x,y];
                }
                NSLog(@"%@",appendstring);
            }
            NSLog(@"fire:%i water:%i grass:%i light:%i dark:%i heart:%i",fire,water,grass,light,dark,heart);
            if (puzzleManager)
                [puzzleManager generateBoard:orbs_x width:orbs_width height:orbs_height];
            
            for (int i=0;i<6;i++)
            {
                int *orbs_y = orbs_x[i];
                free(orbs_y);
            }
            free(orbs_x);
        }
    }
    else
    {
        //        NSLog(@"pixelBytes incorrect:%f",pixelBytes);
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}




@end
