//
//  BLFileDecoder.hpp
//  BLMoviePlayer
//
//  Created by 刘朝龙 on 2019/10/13.
//  Copyright © 2019年 刘朝龙. All rights reserved.
//

#ifndef BLFileDecoder_hpp
#define BLFileDecoder_hpp

#include <stdio.h>
#include "BLFilePacketList.hpp"

extern "C" {
    #include <libavformat/avformat.h>
    #include <libavcodec/avcodec.h>
    #include <libswresample/swresample.h>
    #include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
}

class BLFileDecoder {
    AVFormatContext* fmtContext; // 格式化上下文
    AVPacket *packet;            // 数据包
    
    AVCodecContext* audioCodecContext; // 音频编解码上下文
    SwrContext* audioSwrContext;       // 音频转码上下文
    AVFrame* audioFrame;               // 音频帧对象
    
    AVCodecContext* videoCodecContext; // 视频编解码上下文
    SwsContext* videoSwsContext;       // 视频转码上下文
    AVFrame* videoFrame;               // 音频帧对象
    AVFrame* yuvFrame;           // 视频帧对象
    
    void* swrBuffer;    // 音频转码缓存
    int audioIndex;     // 音频流索引
    int swrBufferSize;  // 音频转码缓存大小
    double audioTimeBase;  // 音频时间基数
    
    int videoIndex;     // 视频流索引
    double videoTimeBase;  // 视频时间基数
    bool isVaildPicture;
    
    int packetBufferSize;
    
    int init(const char* filePath);
    bool audioCodecIsSupport();
    bool videoCodecIsSupport();
    void readFrame(BLFilePacketList* pktList);
    void copyBufferData(uint8_t *srcData, uint8_t *dstData, int linesize, int width, int height);
    
    BLAudioPacket* decodeAudioPacket();
    BLVideoPacket* decodeVideoPacket();
    
public:
    BLFileDecoder();
    virtual ~BLFileDecoder();
    
    int getMusicMeta(const char* filePath, int *metaData);
    int init(const char *filePath, int pktSize);
    BLFilePacketList* decodePacket();
    
    int vWidth() {
        if (videoCodecContext) {
            return videoCodecContext->width;
        }
        return 0;
    }
    
    int vHeight() {
        if (videoCodecContext) {
            return videoCodecContext->height;
        }
        return 0;
    }
    
    void destory();
};

#endif /* BLFileDecoder_hpp */
