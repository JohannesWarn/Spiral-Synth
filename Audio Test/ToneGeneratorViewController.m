//
//  ToneGeneratorViewController.m
//  Audio Test
//
//  Created by Johannes Wärn on 30/06/16.
//  Copyright © 2016 Johannes Wärn. All rights reserved.
//

#import "ToneGeneratorViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "KeyboardView.h"

@interface ToneGeneratorViewController () {
    AudioComponentInstance toneUnit;
@public
    double theta[20];
    double frequency[20];
    double sampleRate;
}

@property (nonatomic) NSMutableDictionary *touces;
@property (nonatomic) IBOutlet KeyboardView *keyboardView;

@property (weak, nonatomic) IBOutlet UITextField *scaleTextField;

@end

OSStatus RenderTone(void *inRefCon,
                    AudioUnitRenderActionFlags *ioActionFlags,
                    const AudioTimeStamp *inTimeStamp,
                    UInt32 inBusNumber,
                    UInt32 inNumberFrames,
                    AudioBufferList *ioData)

{
    // Fixed amplitude is good enough for our purposes
    const double amplitude = 0.25;
    
    // This is a mono tone generator so we only need the first buffer
    const int channel = 0;
    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
    
    double theta[20];
    double theta_increment[20];

    ToneGeneratorViewController *viewController = (__bridge ToneGeneratorViewController *)inRefCon;
    for (int i = 0; i < 20; i++) {
        theta[i] = viewController->theta[i];
        theta_increment[i] = 2.0 * M_PI * viewController->frequency[i] / viewController->sampleRate;
    }
    
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
        double waveSum = 0;
        for (int i = 0; i < 20; i++) {
            //waveSum += sin(theta[i]);
            //waveSum += sin(theta[i]) - sin(theta[i]) * cos(theta[i]);
            waveSum += sin(theta[i]) - sin(theta[i]) * cos(theta[i]) + cos(theta[i]) - cos(theta[i])*cos(theta[i])*cos(theta[i]);
            theta[i] += theta_increment[i];
            if (theta[i] > 2.0 * M_PI) {
                theta[i] -= 2.0 * M_PI;
            }
        }
        
        buffer[frame] = waveSum * amplitude;
    }
    
    // Store the updated theta back in the view controller
    for (int i = 0; i < 20; i++) {
        viewController->theta[i] = theta[i];
    }
     
    return noErr;
}

@implementation ToneGeneratorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    sampleRate = 44100;
    [self setupAudioUnit];
    
    self.keyboardView.toneGenerator = self;
    [self updateScale:nil];
    
    self.touces = [NSMutableDictionary new];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)updateScale:(UIButton *)sender {
    [self.scaleTextField resignFirstResponder];
    
    NSMutableString *scaleString = [self.scaleTextField.text mutableCopy];
    
    NSLog(@"%@", scaleString);
    
    [scaleString replaceOccurrencesOfString:@"A#"	withString:@"1" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"C#"	withString:@"4" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"D#"	withString:@"6" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"F#"	withString:@"9" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"G#"	withString:@"11" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"A"	withString:@"0" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"B"	withString:@"2" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"C"	withString:@"3" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"D"	withString:@"5" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"E"	withString:@"7" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"F"	withString:@"8" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"G"	withString:@"10" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scaleString.length)];
    
    NSLog(@"%@", scaleString);
    
    // Remove everything but spaces and digits
    [scaleString replaceOccurrencesOfString:@"[^\\d\\. ]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, scaleString.length)];
    [scaleString replaceOccurrencesOfString:@"[\\s,+]" withString:@" " options:NSRegularExpressionSearch range:NSMakeRange(0, scaleString.length)];
    
    NSLog(@"%@", scaleString);
    
    NSMutableArray *scale = [NSMutableArray new];
    for (NSString *numberString in [scaleString componentsSeparatedByString:@" "]) {
        if ([numberString doubleValue] || [numberString isEqualToString:@"0"]) {
            [scale addObject:@(numberString.doubleValue)];
        }
    }
    
    NSLog(@"%@", scale);
    
    self.keyboardView.scale = [scale copy];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)playFrequency:(double)newFrequency forTouch:(UITouch *)touch
{
    [self.scaleTextField resignFirstResponder];
    
    NSNumber *touchID = nil;
    
    // Find existing ID for the touch
    for (NSNumber *aTouchID in self.touces) {
        if (self.touces[aTouchID] == touch) {
            touchID = aTouchID;
            break;
        }
    }
    
    // Create new and unique ID for the touch
    if (!touchID) {
        for (int i = 0; i < 20; i++) {
            if (!self.touces[@(i)]) {
                touchID = @(i);
                self.touces[touchID] = touch;
                break;
            }
        }
    }
    
    // Remove the touch
    if (newFrequency <= 1.0 && touchID) {
        [self.touces removeObjectForKey:touchID];
    }
    
    // Play the tone
    if (touchID) {
        frequency[ touchID.integerValue ] = MAX(0, newFrequency);
    }
    
    
#ifdef DEBUG
    double baseFrequency = frequency[0];
    while (baseFrequency > 110.0) {
        baseFrequency /= 2;
    }
    
    if (baseFrequency - 1 < 55.0) {
        NSLog(@"A	55.00");
    } else if (baseFrequency - 1 < 58.27) {
        NSLog(@"A#/Bb 	58.27");
    } else if (baseFrequency - 1 < 61.74) {
        NSLog(@"B	61.74");
    } else if (baseFrequency - 1 < 65.41) {
        NSLog(@"C	65.41");
    } else if (baseFrequency - 1 < 69.30) {
        NSLog(@"C#/Db 	69.30");
    } else if (baseFrequency - 1 < 73.42) {
        NSLog(@"D	73.42");
    } else if (baseFrequency - 1 < 77.78) {
        NSLog(@"D#/Eb 	77.78");
    } else if (baseFrequency - 1 < 82.41) {
        NSLog(@"E	82.41");
    } else if (baseFrequency - 1 < 87.31) {
        NSLog(@"F	87.31");
    } else if (baseFrequency - 1 < 92.50) {
        NSLog(@"F#/Gb 	92.50");
    } else if (baseFrequency - 1 < 98.00) {
        NSLog(@"G	98.00");
    } else if (baseFrequency - 1 < 103.83) {
        NSLog(@"G#/Ab 	103.83");
    } else if (baseFrequency - 1 < 110.00) {
        NSLog(@"A	110.00");
    }
    
    NSLog(@"%f", baseFrequency);
#endif
}

- (void)setupAudioUnit
{
    // Configure the search parameters to find the default playback output unit
    // (called the kAudioUnitSubType_RemoteIO on iOS but
    // kAudioUnitSubType_DefaultOutput on Mac OS X)
    AudioComponentDescription defaultOutputDescription;
    defaultOutputDescription.componentType = kAudioUnitType_Output;
    defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultOutputDescription.componentFlags = 0;
    defaultOutputDescription.componentFlagsMask = 0;
    
    // Get the default playback output unit
    AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
    NSAssert(defaultOutput, @"Can't find default output");
    
    // Create a new unit based on this that we'll use for output
    OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
    NSAssert1(toneUnit, @"Error creating unit: %hd", err);
    
    // Set our tone rendering function on the unit
    AURenderCallbackStruct input;
    input.inputProc = RenderTone;
    input.inputProcRefCon = (__bridge void * _Nullable)(self);
    err = AudioUnitSetProperty(toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
    NSAssert1(err == noErr, @"Error setting callback: %hd", err);
    
    // Set the format to 32 bit, single channel, floating point, linear PCM
    const int four_bytes_per_float = 4;
    const int eight_bits_per_byte = 8;
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = sampleRate;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    streamFormat.mBytesPerPacket = four_bytes_per_float;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBytesPerFrame = four_bytes_per_float;
    streamFormat.mChannelsPerFrame = 1;
    streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
    err = AudioUnitSetProperty (toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
    NSAssert1(err == noErr, @"Error setting stream format: %hd", err);
    
    // Finalize parameters on the unit
    err = AudioUnitInitialize(toneUnit);
    NSAssert1(err == noErr, @"Error initializing unit: %hd", err);
    
    // Start playback
    err = AudioOutputUnitStart(toneUnit);
    NSAssert1(err == noErr, @"Error starting unit: %hd", err);
}

@end
