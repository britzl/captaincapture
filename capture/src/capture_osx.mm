#include <dmsdk/sdk.h>
#include "capture.h"

#if defined(DM_PLATFORM_OSX)

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface RecordingDelegate : NSObject <AVCaptureFileOutputRecordingDelegate>
{
@private
	AVCaptureSession *m_Session;
	AVCaptureMovieFileOutput *m_MovieFileOutput;
	bool m_Recording;
}

-(void)startRecording:(NSURL *)destPath;
-(void)stopRecording;

@end


struct Recorder
{
	RecordingDelegate* m_RecordingDelegate;

	Recorder() : m_RecordingDelegate(0)
	{
	}
};

Recorder g_Recorder;


@implementation RecordingDelegate

-(void)startRecording:(NSURL *)destPath
{
	NSLog(@"startRecording %@", destPath);
	if (self->m_Recording) {
		NSLog(@"startRecording - already recording");
		return;
	}

	// Create a capture session
	self->m_Session = [[AVCaptureSession alloc] init];

	// Set the session preset as you wish
	self->m_Session.sessionPreset = AVCaptureSessionPresetMedium;

	// If you're on a multi-display system and you want to capture a secondary display,
	// you can call CGGetActiveDisplayList() to get the list of all active displays.
	// For this example, we just specify the main display.
	// To capture both a main and secondary display at the same time, use two active
	// capture sessions, one for each display. On Mac OS X, AVCaptureMovieFileOutput
	// only supports writing to a single video track.
	CGDirectDisplayID displayId = kCGDirectMainDisplay;

	// Create a ScreenInput with the display and add it to the session
	AVCaptureScreenInput *screenInput = [[[AVCaptureScreenInput alloc] initWithDisplayID:displayId] autorelease];
	if (!screenInput) {
		NSLog(@"startRecording no screen input");
		[self->m_Session release];
		self->m_Session = nil;
		return;
	}
	if ([self->m_Session canAddInput:screenInput]) {
		[self->m_Session addInput:screenInput];
	}

	/*NSError *error = nil;
	AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error];
	if (!audioInput) {
		NSLog(@"startRecording no audio input");
		[self->m_Session release];
		self->m_Session = nil;
		return;
	}
	if ([self->m_Session canAddInput:audioInput]) {
		NSLog(@"startRecording adding audio input");
		[self->m_Session addInput:audioInput];
	}*/

	// Create a MovieFileOutput and add it to the session
	self->m_MovieFileOutput = [[[AVCaptureMovieFileOutput alloc] init] autorelease];
	if ([self->m_Session canAddOutput:self->m_MovieFileOutput]) {
		[self->m_Session addOutput:self->m_MovieFileOutput];
	}

	// Delete any existing movie file first
	if ([[NSFileManager defaultManager] fileExistsAtPath:[destPath path]])
	{
		NSError *err;
		if (![[NSFileManager defaultManager] removeItemAtPath:[destPath path] error:&err])
		{
			NSLog(@"Error deleting existing movie %@",[err localizedDescription]);
		}
	}

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		// Start running the session
		[self->m_Session startRunning];

		// Start recording to the destination movie file
		// The destination path is assumed to end with ".mov", for example, @"/users/master/desktop/capture.mov"
		// Set the recording delegate to self
		[self->m_MovieFileOutput startRecordingToOutputFileURL:destPath recordingDelegate:self];

		self->m_Recording = 1;
	});
}

-(void)stopRecording
{
	NSLog(@"stopRecording");
	if (!self->m_Recording) {
		NSLog(@"stopRecording - not recording");
		return;
	}

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		// Stop recording to the destination movie file
		[self->m_MovieFileOutput stopRecording];
		self->m_Recording = 0;
	});
}

// AVCaptureFileOutputRecordingDelegate methods

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
	NSLog(@"Did finish recording to %@ due to error %@", [outputFileURL description], [error description]);

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		// Stop running the session
		[self->m_Session stopRunning];

		// Release the session
		[self->m_Session release];
		self->m_Session = nil;
	});
}
@end


Recorder Capture_GetRecorder() {
	NSLog(@"Capture_CreateRecorder");
	@try {
		if(g_Recorder.m_RecordingDelegate == 0)
		{
			g_Recorder.m_RecordingDelegate = [[RecordingDelegate alloc] init];
		}
	}
	@catch ( NSException *e ) {
		NSLog(@"Capture_CreateRecorder exception %@", e);
	}
	return g_Recorder;
}

void Capture_PlatformStart(const char* path) {
	NSLog(@"Capture_PlatformStart %s", path);

	@try {
		NSURL *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:path]];
		//NSURL *url = [NSURL URLWithString:@"file://localhost/Users/bjornritzl/Downloads/foo.mov"];
		NSLog(@"Capture_PlatformStart url %@", url);
		[Capture_GetRecorder().m_RecordingDelegate startRecording:url];
		NSLog(@"Capture_PlatformStart after start");
	}
	@catch ( NSException *e ) {
		NSLog(@"Capture_PlatformStart exception %@", e);
	}
	NSLog(@"Capture_PlatformStart - done");
}

void Capture_PlatformStop() {
	NSLog(@"Capture_PlatformStop");

	@try {
		[Capture_GetRecorder().m_RecordingDelegate stopRecording];
	}
	@catch ( NSException *e ) {
		NSLog(@"Capture_PlatformStop exception %@", e);
	}
	NSLog(@"Capture_PlatformStop - done");
}

#endif
