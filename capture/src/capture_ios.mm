#include <dmsdk/sdk.h>
#include "capture.h"

#if defined(DM_PLATFORM_IOS)

#import <ReplayKit/ReplayKit.h>

@interface RecordingDelegate : NSObject <RPScreenRecorderDelegate>
{
@private
	AVAssetWriterInput* m_AssetWriterInput;
	AVAssetWriter* m_AssetWriter;
	RPScreenRecorder* m_ScreenRecorder;
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

	NSDictionary *compressionProperties = @{
		AVVideoProfileLevelKey         : AVVideoProfileLevelH264HighAutoLevel,
		AVVideoH264EntropyModeKey      : AVVideoH264EntropyModeCABAC,
		AVVideoAverageBitRateKey       : @(1920 * 1080 * 11.4),
		AVVideoMaxKeyFrameIntervalKey  : @60,
		AVVideoAllowFrameReorderingKey : @NO};

	NSDictionary *videoSettings = @{
		AVVideoCompressionPropertiesKey : compressionProperties,
		AVVideoCodecKey                 : AVVideoCodecTypeH264,
		AVVideoWidthKey                 : @1080,
		AVVideoHeightKey                : @1920};

		self->m_AssetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];

		NSError *error = nil;
		self->m_ScreenRecorder =  RPScreenRecorder.sharedRecorder;
		self->m_AssetWriter = [AVAssetWriter assetWriterWithURL:destPath fileType:AVFileTypeMPEG4 error:&error];

		[self->m_ScreenRecorder startCaptureWithHandler:^(CMSampleBufferRef _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
			if (CMSampleBufferDataIsReady(sampleBuffer)) {
				if (self->m_AssetWriter.status == AVAssetWriterStatusUnknown) {
					[self->m_AssetWriter startWriting];
					[self->m_AssetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
				}

				if (self->m_AssetWriter.status == AVAssetWriterStatusFailed) {
					NSLog(@"An error occured.");
					return;
				}

				if (bufferType == RPSampleBufferTypeVideo) {
					if (self->m_AssetWriterInput.isReadyForMoreMediaData) {
						[self->m_AssetWriterInput appendSampleBuffer:sampleBuffer];
					}
				}
			}
		} completionHandler:^(NSError * _Nullable error) {
			if (!error) {
				NSLog(@"Recording started successfully.");
				self->m_Recording = 1;
			}
		}];
	}

	-(void)stopRecording
	{
		NSLog(@"stopRecording");
		if (!self->m_Recording) {
			NSLog(@"stopRecording - not recording");
			return;
		}

		[self->m_ScreenRecorder stopCaptureWithHandler:^(NSError * _Nullable error) {
			if (!error) {
				NSLog(@"Recording stopped successfully. Cleaning up...");
				[self->m_AssetWriterInput markAsFinished];
				[self->m_AssetWriter finishWritingWithCompletionHandler:^{
					self->m_AssetWriterInput = nil;
					self->m_AssetWriter = nil;
					self->m_ScreenRecorder = nil;
				}];
			}
		}];
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
		//NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:path]];
		//NSURL *url = [NSURL URLWithString:@"file://localhost/Users/bjornritzl/Downloads/foo.mov"];
		NSLog(@"Capture_PlatformStart url %@", url);
		[Capture_GetRecorder().m_RecordingDelegate startRecording:url];
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
