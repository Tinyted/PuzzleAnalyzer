//
//  PuzzleVideoController.m
//  PuzzleAnalyzer
//
//  Created by Wong Shing Chi Teddy on 23/12/15.
//  Copyright © 2015 Wong Shing Chi Teddy. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <CoreMediaIO/CMIOHardware.h>

#import "PuzzleVideoController.h"

@interface PuzzleVideoController () <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    
}

@property (nonatomic, strong) AVCaptureSession *videoSession;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) NSArray *observers;

@end

@implementation PuzzleVideoController

@synthesize videoSession;
@synthesize videoDeviceInput;
@synthesize observers;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self)
    {
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
//    [videopreviewlayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
    [videoPreviewView.layer addSublayer:videopreviewlayer];
    [videoPreviewView.layer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
    NSLog(@"videoPreviewView:%@",videoPreviewView);
    NSLog(@"layer:%@",videoPreviewView.layer);
    [videoSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
}

@end
