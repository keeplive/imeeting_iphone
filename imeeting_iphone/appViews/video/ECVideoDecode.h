//
//  ECVideoDecode.h
//  imeeting_iphone
//
//  Created by star king on 12-6-28.
//  Copyright (c) 2012年 elegant cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libavformat/avformat.h"
#import "libavcodec/avcodec.h"
#import "libswscale/swscale.h"
#import "ECVideoFetchDelegate.h"

@interface VideoFetchExecutor : NSObject {
    AVFormatContext *inputFormatContext;
    AVCodecContext *videoCodecContext;
    AVCodec *videoCodec;
    int videoStream;
    AVFrame *videoFrame;
    AVFrame *videoPicture;
    
    struct SwsContext *img_convert_ctx;    
    enum PixelFormat dst_pix_fmt;
    
    BOOL readFrame;
    
}
@property (nonatomic, retain) id delegate;
@property (nonatomic) int imgWidth;
@property (nonatomic) int imgHeight;
@property (nonatomic, retain) NSString *rtmpUrl;

- (void)startFetchVideoPictureWithUsername:(NSString*)username;
- (void)stopFetchVideoPicture;
- (void)handleError;
- (int)openVideoInputStream:(const char*)playPath;
- (void)readVideoFrame;
- (void)closeVideoInputStream;
- (UIImage*)imageFromAVPicture:(AVFrame*)picture width:(int)width height:(int)height;

@end

@interface ECVideoDecode : NSObject {
    VideoFetchExecutor *executor;
    NSThread *exeThread;

}
@property (nonatomic,retain) NSString *rtmpUrl;
@property (nonatomic) int dstImgWidth;
@property (nonatomic) int dstImgHeight;
@property (nonatomic,retain) id delegate;

- (void)setupVideoDecode;
- (void)releaseVideoDecode;
- (void)startFetchVideoPictureWithUsername:(NSString*)username;
- (void)stopFetchVideoPicture;
@end