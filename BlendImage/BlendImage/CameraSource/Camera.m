//
//  Camera.m
//  BlendImage
//
//  Created by suntongmian on 16/12/13.
//  Copyright © 2016年 suntongmian. All rights reserved.
//

#import "Camera.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface SampleBufferCallback: NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    Camera *m_source;
}

- (void)setSource:(Camera *)source;
@end

@implementation SampleBufferCallback

- (void)setSource:(Camera *)source {
    m_source = source;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (m_source) {
        [m_source bufferCaptured:sampleBuffer];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

- (void)orientationChanged:(NSNotification*)notification {
    if (m_source && ![m_source orientationLocked]) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [m_source reorientCamera];
        });
    }
}
@end

@interface Camera ()
{
    void* m_captureSession;
    void* m_captureDevice;
    void* m_callbackSession;
    void* m_previewLayer;
    
    int  m_fps;
    bool m_torchOn;
    bool m_useInterfaceOrientation;
    bool m_orientationLocked;
    
    CameraState  _cameraState;
    BOOL _cameraTorch;
}
@end

@implementation Camera

- (instancetype)init {
    self = [super init];
    if (self) {
        m_captureDevice = NULL;
        m_callbackSession = NULL;
        m_previewLayer = NULL;
        m_orientationLocked = false;
        m_torchOn = false;
        m_useInterfaceOrientation = false;
        m_captureSession = NULL;
        _cameraState = CameraStateBack;
    }
    return self;
}

- (void)dealloc {
    if(m_captureSession) {
        [((AVCaptureSession*)m_captureSession) stopRunning];
        [((AVCaptureSession*)m_captureSession) release];
    }
    if(m_callbackSession) {
        [[NSNotificationCenter defaultCenter] removeObserver:(id)m_callbackSession];
        [((SampleBufferCallback*)m_callbackSession) release];
    }
    if(m_previewLayer) {
        [(id)m_previewLayer release];
    }
    NSLog(@"%s", __FUNCTION__);
    
    [super dealloc];
}

- (CameraState)cameraState {
    return _cameraState;
}

- (void)setCameraState:(CameraState)cameraState {
    if(_cameraState != cameraState) {
        _cameraState = cameraState;
        [self toggleCamera];
    }
}

- (BOOL)cameraTorch {
    return _cameraTorch;
}

- (void)setCameraTorch:(BOOL)cameraTorch {
    _cameraTorch = [self setTorch:cameraTorch];
}


- (void)setupCameraFPS:(int)fps
              useFront:(bool)useFront
useInterfaceOrientation:(bool)useInterfaceOrientation
         sessionPreset:(NSString*)sessionPreset
         callbackBlock:(CallbackBlock)callbackBlock {
    
    m_fps = fps;
    m_useInterfaceOrientation = useInterfaceOrientation;
    
    __block Camera* bThis = self;
    
    void (^permissions)(BOOL) = ^(BOOL granted) {
        @autoreleasepool {
            if(granted) {
                
                int position = useFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
                
                NSArray* devices = [AVCaptureDevice devices];
                for(AVCaptureDevice* d in devices) {
                    if([d hasMediaType:AVMediaTypeVideo] && [d position] == position)
                    {
                        bThis->m_captureDevice = d;
                        NSError* error;
                        [d lockForConfiguration:&error];
                        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                            [d setActiveVideoMinFrameDuration:CMTimeMake(1, fps)];
                            [d setActiveVideoMaxFrameDuration:CMTimeMake(1, fps)];
                        }
                        [d unlockForConfiguration];
                    }
                }
                
                AVCaptureSession* session = [[AVCaptureSession alloc] init];
                AVCaptureDeviceInput* input;
                AVCaptureVideoDataOutput* output;
                if(sessionPreset) {
                    session.sessionPreset = (NSString*)sessionPreset;
                }
                bThis->m_captureSession = session;
                
                input = [AVCaptureDeviceInput deviceInputWithDevice:((AVCaptureDevice*)m_captureDevice) error:nil];
                
                output = [[AVCaptureVideoDataOutput alloc] init] ;
                
                output.videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA) };
                
                if(!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                    AVCaptureConnection* conn = [output connectionWithMediaType:AVMediaTypeVideo];
                    if([conn isVideoMinFrameDurationSupported]) {
                        [conn setVideoMinFrameDuration:CMTimeMake(1, fps)];
                    }
                    if([conn isVideoMaxFrameDurationSupported]) {
                        [conn setVideoMaxFrameDuration:CMTimeMake(1, fps)];
                    }
                }
                if(!bThis->m_callbackSession) {
                    bThis->m_callbackSession = [[SampleBufferCallback alloc] init];
                    [((SampleBufferCallback*)bThis->m_callbackSession) setSource:self];
                }
                dispatch_queue_t camQueue = dispatch_queue_create("com.PL.camera", 0);
                
                [output setSampleBufferDelegate:((SampleBufferCallback*)bThis->m_callbackSession) queue:camQueue];
                
                dispatch_release(camQueue);
                
                if([session canAddInput:input]) {
                    [session addInput:input];
                }
                if([session canAddOutput:output]) {
                    [session addOutput:output];
                    
                }
                
                [self reorientCamera];
                
                [session startRunning];
                
                if(!bThis->m_orientationLocked) {
                    if(bThis->m_useInterfaceOrientation) {
                        [[NSNotificationCenter defaultCenter] addObserver:((id)bThis->m_callbackSession) selector:@selector(orientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
                    } else {
                        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
                        [[NSNotificationCenter defaultCenter] addObserver:((id)bThis->m_callbackSession) selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
                    }
                }
                [output release];
            }
            if (callbackBlock) {
                callbackBlock();
            }
        }
    };
    @autoreleasepool {
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            AVAuthorizationStatus auth = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            
            if(auth == AVAuthorizationStatusAuthorized || !SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
                permissions(true);
            }
            else if(auth == AVAuthorizationStatusNotDetermined) {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:permissions];
            }
        } else {
            permissions(true);
        }
        
    }
}

- (void)getPreviewLayer:(AVCaptureVideoPreviewLayer**)outAVCaptureVideoPreviewLayer {
    if(!m_previewLayer) {
        @autoreleasepool {
            AVCaptureSession* session = (AVCaptureSession*)m_captureSession;
            AVCaptureVideoPreviewLayer* previewLayer;
            previewLayer = [[AVCaptureVideoPreviewLayer layerWithSession:session] retain];
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            m_previewLayer = previewLayer;
        }
    }
    if(outAVCaptureVideoPreviewLayer) {
        *outAVCaptureVideoPreviewLayer = m_previewLayer;
    }
}

- (void*)cameraWithPosition:(int)pos {
    AVCaptureDevicePosition position = (AVCaptureDevicePosition)pos;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position) return device;
    }
    return nil;
    
}

- (bool)orientationLocked {
    return m_orientationLocked;
}

- (void)setOrientationLocked:(bool)orientationLocked {
    m_orientationLocked = orientationLocked;
}

- (bool)setTorch:(bool)torchOn {
    bool ret = false;
    if(!m_captureSession) return ret;
    
    AVCaptureSession* session = (AVCaptureSession*)m_captureSession;
    
    [session beginConfiguration];
    
    if (session.inputs.count > 0) {
        AVCaptureDeviceInput* currentCameraInput = [session.inputs objectAtIndex:0];
        
        if(currentCameraInput.device.torchAvailable) {
            NSError* err = nil;
            if([currentCameraInput.device lockForConfiguration:&err]) {
                [currentCameraInput.device setTorchMode:( torchOn ? AVCaptureTorchModeOn : AVCaptureTorchModeOff ) ];
                [currentCameraInput.device unlockForConfiguration];
                ret = (currentCameraInput.device.torchMode == AVCaptureTorchModeOn);
            } else {
                NSLog(@"Error while locking device for torch: %@", err);
                ret = false;
            }
        } else {
            NSLog(@"Torch not available in current camera input");
        }
        
    }
    
    [session commitConfiguration];
    m_torchOn = ret;
    return ret;
}

- (void)toggleCamera {
    if(!m_captureSession) return;
    
    NSError* error;
    AVCaptureSession* session = (AVCaptureSession*)m_captureSession;
    if(session) {
        [session beginConfiguration];
        [(AVCaptureDevice*)m_captureDevice lockForConfiguration: &error];
        
        if (session.inputs.count > 0) {
            AVCaptureInput* currentCameraInput = [session.inputs objectAtIndex:0];
            
            [session removeInput:currentCameraInput];
            [(AVCaptureDevice*)m_captureDevice unlockForConfiguration];
            
            AVCaptureDevice *newCamera = nil;
            if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack)
            {
                newCamera = (AVCaptureDevice*)[self cameraWithPosition:AVCaptureDevicePositionFront];
            }
            else
            {
                newCamera = (AVCaptureDevice*)[self cameraWithPosition:AVCaptureDevicePositionBack];
            }
            
            AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:nil];
            [newCamera lockForConfiguration:&error];
            [session addInput:newVideoInput];
            
            m_captureDevice = newCamera;
            [newCamera unlockForConfiguration];
            [session commitConfiguration];
            
            [newVideoInput release];
        }
        
        [self reorientCamera];
    }
}

- (void)reorientCamera {
    if(!m_captureSession) return;
    
    int orientation = m_useInterfaceOrientation ? [[UIApplication sharedApplication] statusBarOrientation] : [[UIDevice currentDevice] orientation];
    
    // use interface orientation as fallback if device orientation is facedown, faceup or unknown
    if(orientation==UIDeviceOrientationFaceDown || orientation==UIDeviceOrientationFaceUp || orientation==UIDeviceOrientationUnknown) {
        orientation =[[UIApplication sharedApplication] statusBarOrientation];
    }
    
    //bool reorient = false;
    
    AVCaptureSession* session = (AVCaptureSession*)m_captureSession;
    // [session beginConfiguration];
    
    for (AVCaptureVideoDataOutput* output in session.outputs) {
        for (AVCaptureConnection * av in output.connections) {
            
            switch (orientation) {
                    // UIInterfaceOrientationPortraitUpsideDown, UIDeviceOrientationPortraitUpsideDown
                case UIInterfaceOrientationPortraitUpsideDown:
                    if(av.videoOrientation != AVCaptureVideoOrientationPortraitUpsideDown) {
                        av.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                        //    reorient = true;
                    }
                    break;
                    // UIInterfaceOrientationLandscapeRight, UIDeviceOrientationLandscapeLeft
                case UIInterfaceOrientationLandscapeRight:
                    if(av.videoOrientation != AVCaptureVideoOrientationLandscapeRight) {
                        av.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                        //    reorient = true;
                    }
                    break;
                    // UIInterfaceOrientationLandscapeLeft, UIDeviceOrientationLandscapeRight
                case UIInterfaceOrientationLandscapeLeft:
                    if(av.videoOrientation != AVCaptureVideoOrientationLandscapeLeft) {
                        av.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                        //   reorient = true;
                    }
                    break;
                    // UIInterfaceOrientationPortrait, UIDeviceOrientationPortrait
                case UIInterfaceOrientationPortrait:
                    if(av.videoOrientation != AVCaptureVideoOrientationPortrait) {
                        av.videoOrientation = AVCaptureVideoOrientationPortrait;
                        //    reorient = true;
                    }
                    break;
                default:
                    break;
            }
        }
    }
    
    //[session commitConfiguration];
    if(m_torchOn) {
        [self setTorch:m_torchOn];
    }
}

- (void)bufferCaptured:(CMSampleBufferRef)sampleBuffer {
    [self setOutput:sampleBuffer];
}

- (void)setOutput:(CMSampleBufferRef)sampleBuffer {
    [self.delegate cameraOutput:sampleBuffer];
}

- (bool)setContinuousAutofocus:(bool)wantsContinuous {
    AVCaptureDevice* device = (AVCaptureDevice*)m_captureDevice;
    AVCaptureFocusMode newMode = wantsContinuous ?  AVCaptureFocusModeContinuousAutoFocus : AVCaptureFocusModeAutoFocus;
    bool ret = [device isFocusModeSupported:newMode];
    
    if(ret) {
        NSError *err = nil;
        if ([device lockForConfiguration:&err]) {
            device.focusMode = newMode;
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error while locking device for autofocus: %@", err);
            ret = false;
        }
    } else {
        NSLog(@"Focus mode not supported: %@", wantsContinuous ? @"AVCaptureFocusModeContinuousAutoFocus" : @"AVCaptureFocusModeAutoFocus");
        if (wantsContinuous) {
            NSLog(@"Focus mode not supported: AVCaptureFocusModeContinuousAutoFocus");
        } else {
            NSLog(@"Focus mode not supported: AVCaptureFocusModeAutoFocus");
        }
    }
    
    return ret;
}

- (bool)setContinuousExposure:(bool)wantsContinuous {
    AVCaptureDevice *device = (AVCaptureDevice *) m_captureDevice;
    AVCaptureExposureMode newMode = wantsContinuous ? AVCaptureExposureModeContinuousAutoExposure : AVCaptureExposureModeAutoExpose;
    bool ret = [device isExposureModeSupported:newMode];
    
    if(ret) {
        NSError *err = nil;
        if ([device lockForConfiguration:&err]) {
            device.exposureMode = newMode;
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error while locking device for exposure: %@", err);
            ret = false;
        }
    } else {
        NSLog(@"Exposure mode not supported: %@", wantsContinuous ? @"AVCaptureExposureModeContinuousAutoExposure" : @"AVCaptureExposureModeAutoExpose");
        if (wantsContinuous) {
            NSLog(@"Exposure mode not supported: AVCaptureExposureModeContinuousAutoExposure");
        } else {
            NSLog(@"Exposure mode not supported: AVCaptureExposureModeAutoExpose");
        }
    }
    
    return ret;
}

- (bool)setFocusPointOfInterestWithX:(float)x andY:(float)y {
    AVCaptureDevice* device = (AVCaptureDevice*)m_captureDevice;
    bool ret = device.focusPointOfInterestSupported;
    
    if(ret) {
        NSError* err = nil;
        if([device lockForConfiguration:&err]) {
            [device setFocusPointOfInterest:CGPointMake(x, y)];
            if (device.focusMode == AVCaptureFocusModeLocked) {
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
            }
            device.focusMode = device.focusMode;
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error while locking device for focus POI: %@", err);
            ret = false;
        }
    } else {
        NSLog(@"Focus POI not supported");
    }
    
    return ret;
}

- (bool)setExposurePointOfInterestWithX:(float)x andY:(float)y {
    AVCaptureDevice* device = (AVCaptureDevice*)m_captureDevice;
    bool ret = device.exposurePointOfInterestSupported;
    
    if(ret) {
        NSError* err = nil;
        if([device lockForConfiguration:&err]) {
            [device setExposurePointOfInterest:CGPointMake(x, y)];
            device.exposureMode = device.exposureMode;
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error while locking device for exposure POI: %@", err);
            ret = false;
        }
    } else {
        NSLog(@"Exposure POI not supported");
    }
    
    return ret;
}
@end

