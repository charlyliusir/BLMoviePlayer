//
//  BLFileDecoder.cpp
//  BLMoviePlayer
//
//  Created by 刘朝龙 on 2019/10/13.
//  Copyright © 2019年 刘朝龙. All rights reserved.
//

#include "BLFileDecoder.hpp"

BLFileDecoder::BLFileDecoder() {
    fmtContext = NULL;
    packet     = NULL;
    audioCodecContext = NULL;
    audioSwrContext   = NULL;
    audioFrame        = NULL;
    swrBuffer         = NULL;
    videoCodecContext = NULL;
    videoSwsContext   = NULL;
    
    audioIndex      = -1;
    swrBufferSize   = 0;
    audioTimeBase   = 0;
    
    videoIndex      = -1;
    videoTimeBase   = 0;
    isVaildPicture  = false;
}

BLFileDecoder::~BLFileDecoder() {
    destory();
}

int BLFileDecoder::getMusicMeta(const char* filePath, int *metaData) {
    if (init(filePath)) {
        int channels    = audioCodecContext->channels;
        int sampleRate  = audioCodecContext->sample_rate;
        int bitRate     = (int)audioCodecContext->bit_rate;
        
        metaData[0] = channels;
        metaData[1] = sampleRate;
        metaData[2] = bitRate;
        
        return 1;
    }
    return -1;
}

int BLFileDecoder::init(const char* filePath, int pktSize) {
    packetBufferSize = pktSize;
    return init(filePath);
}

int BLFileDecoder::init(const char* filePath) {
    if (filePath == NULL || strlen(filePath) == 0) {
        printf("[ERROR] file path must not be null\n");
        return -1;
    }
    // 1. 获取文件格式化上下文
    fmtContext = avformat_alloc_context();
    // 2. 打开文件
    if (avformat_open_input(&fmtContext, filePath, NULL, NULL) != 0) {
        printf("[ERROR] open file error\n");
        return -1;
    }
    // 3. 查找所有的数据流
    fmtContext->probesize = 1000 * 1024;
    fmtContext->max_analyze_duration = 10 * AV_TIME_BASE;
    if (avformat_find_stream_info(fmtContext, NULL) < 0) {
        printf("[ERROR] find file stream info error\n");
        return -1;
    }
    // 4. 查找音视频流信息
    AVStream* audioStream = NULL;
    AVStream* videoStream = NULL;
    for (int i = 0; i < fmtContext->nb_streams; i ++) {
        AVStream* stream = fmtContext->streams[i];
        if (stream->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioIndex = i;
            audioStream = stream;
        } else if (stream->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoIndex = i;
            videoStream = stream;
        }
    }
    // 5. 音频解码器设置
    if (audioIndex != -1 && NULL != audioStream) {
        audioCodecContext = avcodec_alloc_context3(NULL);
        if (NULL == audioCodecContext) {
            printf("[ERROR]音频编解码器初始化失败\n");
            return -1;
        }
        if (avcodec_parameters_to_context(audioCodecContext, audioStream->codecpar) < 0) {
            printf("[ERROR]音频编码器参数设置失败\n");
            return -1;
        }
        AVCodec* audioCodec = avcodec_find_decoder(audioStream->codecpar->codec_id);
        if (NULL == audioCodec) {
            printf("[ERROR]找不到音频解码器\n");
            return -1;
        }
        if (audioStream->time_base.den && audioStream->time_base.num) {
            audioTimeBase = av_q2d(audioStream->time_base);
        } else if (audioCodecContext->time_base.den && audioCodecContext->time_base.num) {
            audioTimeBase = av_q2d(audioCodecContext->time_base);
        }
        // 打开解码器
        if (avcodec_open2(audioCodecContext, audioCodec, NULL) != 0) {
            printf("[ERROR]音频解码器打开失败\n");
        }
        // 判断是否需要转码
        if (!audioCodecIsSupport()) {
            
            int64_t outChLayout = av_get_default_channel_layout(audioCodecContext->channels);
            AVSampleFormat outSampleFMT = AV_SAMPLE_FMT_S16;
            int outSampleRate = audioCodecContext->sample_rate;
            int64_t inChLayout = av_get_default_channel_layout(audioCodecContext->channels);
            AVSampleFormat inSampleFMT = audioCodecContext->sample_fmt;
            int inSampleRate = audioCodecContext->sample_rate;
            audioSwrContext = swr_alloc_set_opts(NULL, outChLayout, outSampleFMT, outSampleRate, inChLayout, inSampleFMT, inSampleRate, 0, NULL);
            if (!audioSwrContext || swr_init(audioSwrContext)) {
                if (audioSwrContext) {
                    swr_free(&audioSwrContext);
                    audioSwrContext = NULL;
                }
                avcodec_close(audioCodecContext);
            }
        }
        audioFrame = av_frame_alloc();
    }
    // 6. 视频解码器设置
    if (videoIndex != -1 && NULL != videoStream) {
        videoCodecContext = avcodec_alloc_context3(NULL);
        if (NULL == videoCodecContext) {
            printf("[ERROR]视频编解码器初始化失败\n");
            return -1;
        }
        if (avcodec_parameters_to_context(videoCodecContext, videoStream->codecpar) < 0) {
            printf("[ERROR]视频编码器参数设置失败\n");
            return -1;
        }
        AVCodec* videoCodec = avcodec_find_decoder(videoStream->codecpar->codec_id);
        if (NULL == videoCodec) {
            printf("[ERROR]找不到视频解码器\n");
            return -1;
        }
        if (videoStream->time_base.den && videoStream->time_base.num) {
            videoTimeBase = av_q2d(videoStream->time_base);
        } else if (videoCodecContext->time_base.den && videoCodecContext->time_base.num) {
            videoTimeBase = av_q2d(audioCodecContext->time_base);
        }
        if (avcodec_open2(videoCodecContext, videoCodec, NULL) < 0) {
            printf("[ERROR]打开视频解码器失败\n");
            return -1;
        }
        if (!videoCodecIsSupport()) {
            AVPixelFormat dstFormat = AV_PIX_FMT_YUV420P;
            int dstW = videoCodecContext->width;
            int dstH = videoCodecContext->height;
            
            /// 旧版本
//            isVaildPicture = avpicture_alloc(&videoPicture, dstFormat, dstW, dstH) == 0;
//            if (!isVaildPicture) {
//                printf("创建视频重采样失败\n");
//                return -1;
//            }
            
            /// 新版本
            int yuvSize = av_image_get_buffer_size(dstFormat, dstW, dstH, 1);
            uint8_t* outBuf = (uint8_t *)av_malloc(yuvSize);
            yuvFrame = av_frame_alloc();
            
            isVaildPicture = av_image_fill_arrays(yuvFrame->data, yuvFrame->linesize, (const uint8_t*)outBuf, dstFormat, dstW, dstH, 1) != 0;
            
            if (!isVaildPicture) {
                printf("....\n");
                return -1;
            }
            
            int srcW = dstW;
            int srcH = dstH;
            AVPixelFormat srcFormat = videoCodecContext->pix_fmt;
            videoSwsContext = sws_getCachedContext(videoSwsContext, srcW, srcH, srcFormat, dstW, dstH, dstFormat, SWS_FAST_BILINEAR, NULL, NULL, NULL);
        }
        videoFrame = av_frame_alloc();
    }
    return 1;
}

bool BLFileDecoder::audioCodecIsSupport() {
    return audioCodecContext->sample_fmt == AV_SAMPLE_FMT_S16;
}

bool BLFileDecoder::videoCodecIsSupport() {
    return videoCodecContext->pix_fmt == AV_PIX_FMT_YUV420P || videoCodecContext->pix_fmt == AV_PIX_FMT_YUVJ422P;
}

BLFilePacketList* BLFileDecoder::decodePacket() {
    BLFilePacketList* pktList = new BLFilePacketList();
    readFrame(pktList);
    return pktList;
}

void BLFileDecoder::readFrame(BLFilePacketList* pktList) {
    packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    while (true) {
        if (av_read_frame(fmtContext, packet) < 0) {
            printf("End of file\n");
            break;
        }
        if (packet->stream_index == audioIndex) {
            if (avcodec_send_packet(audioCodecContext, packet) != 0) {
                printf("\n");
                continue;
            }
            while (avcodec_receive_frame(audioCodecContext, audioFrame) == 0) {
                BLAudioPacket* audioPkt = decodeAudioPacket();
                if (audioPkt) {
                    pktList->addPacket(audioPkt);
                }
                
//                av_strerror(<#int errnum#>, <#char *errbuf#>, <#size_t errbuf_size#>)
            }
            break;
        } else if (packet->stream_index == videoIndex) {
            if (avcodec_send_packet(videoCodecContext, packet) != 0) {
                printf("\n");
                continue;
            }
            while (avcodec_receive_frame(videoCodecContext, videoFrame) == 0) {
                BLVideoPacket* videoPkt = decodeVideoPacket();
                if (videoPkt) {
                    pktList->addPacket(videoPkt);
                }
            }
            break;
        }
    }
    free(packet);
}

BLAudioPacket* BLFileDecoder::decodeAudioPacket() {
    void *audioData = NULL;
    AVSampleFormat sampleFormat = AV_SAMPLE_FMT_S16;
    int ratio           = 2;
    int numberFrames    = 0;
    int numberChannels  = audioCodecContext->channels;
    int numberSamples   = audioFrame->nb_samples;
    if (audioSwrContext) {
        
        int bufSize = av_samples_get_buffer_size(NULL, numberChannels, numberSamples * ratio, sampleFormat, 1);
        
        if (swrBufferSize != bufSize) {
            swrBufferSize  = bufSize;
            swrBuffer = (void *)realloc(swrBuffer, swrBufferSize);
        }
        
        uint8_t *outData[2] = {(uint8_t *)swrBuffer, 0};
        
        numberFrames = swr_convert(audioSwrContext, outData, numberSamples * ratio, (const uint8_t **)audioFrame->data, numberSamples);
        if (numberFrames < 0) {
            printf("重采样转换失败\n");
            return NULL;
        }
        audioData = swrBuffer;
    } else {
        if (audioCodecContext->sample_rate != sampleFormat) {
            printf("不支持音频格式\n");
            return NULL;
        }
        numberFrames = numberSamples;
        audioData    = audioFrame->data[0];
    }
    
    // 音频杂音处理, 由于开始没有做copy工作, 导致出现杂音
    short *data = (short *)malloc(numberChannels * numberFrames * sizeof(short));
    memcpy(data, audioData, numberChannels * numberFrames * sizeof(short));
    BLAudioPacket* packet = new BLAudioPacket();
    packet->size = numberFrames * numberChannels;
    packet->data = data;
    packet->timebase = audioTimeBase;
    return packet;
}

BLVideoPacket* BLFileDecoder::decodeVideoPacket() {
    BLVideoPacket *vPacket = new BLVideoPacket();
    int size = videoCodecContext->width * videoCodecContext->height;
    vPacket->luma = (uint8_t *)av_malloc(size);
    vPacket->chromaB = (uint8_t *)av_malloc(size / 4);
    vPacket->chromaR = (uint8_t *)av_malloc(size / 4);
    if (isVaildPicture) {
        sws_scale(videoSwsContext, videoFrame->data, videoFrame->linesize, 0, videoCodecContext->height, yuvFrame->data, yuvFrame->linesize);
        copyBufferData(yuvFrame->data[0], vPacket->luma, yuvFrame->linesize[0], videoCodecContext->width, videoCodecContext->height);
        copyBufferData(yuvFrame->data[1], vPacket->chromaB, yuvFrame->linesize[1], videoCodecContext->width / 2, videoCodecContext->height / 2);
        copyBufferData(yuvFrame->data[2], vPacket->chromaR, yuvFrame->linesize[2], videoCodecContext->width / 2, videoCodecContext->height / 2);
    } else {
        copyBufferData(videoFrame->data[0], vPacket->luma, videoFrame->linesize[0], videoCodecContext->width, videoCodecContext->height);
        copyBufferData(videoFrame->data[1], vPacket->chromaB, videoFrame->linesize[1], videoCodecContext->width / 2, videoCodecContext->height / 2);
        copyBufferData(videoFrame->data[2], vPacket->chromaR, videoFrame->linesize[2], videoCodecContext->width / 2, videoCodecContext->height / 2);
    }
    vPacket->width = videoCodecContext->width;
    vPacket->height = videoCodecContext->height;
    vPacket->linesize = videoFrame->linesize[0];
    vPacket->size = vPacket->width * vPacket->height;
    vPacket->position = videoFrame->best_effort_timestamp * videoTimeBase;
    return vPacket;
}

void BLFileDecoder::copyBufferData(uint8_t *srcData, uint8_t *dstData, int linesize, int width, int height) {
    width = linesize < width ? linesize : width;
    for (int i = 0; i < height; i ++) {
        memcpy(dstData, srcData, width);
        dstData += width;
        srcData += linesize;
    }
}

void BLFileDecoder::destory() {
    if (swrBuffer) {
        free(swrBuffer);
        swrBuffer = NULL;
    }
    if (audioSwrContext) {
        swr_free(&audioSwrContext);
        audioSwrContext = NULL;
    }
    if (videoSwsContext) {
        sws_freeContext(videoSwsContext);
        videoSwsContext = NULL;
    }
    if (audioFrame) {
        av_free(audioFrame);
        audioFrame = NULL;
    }
    if (audioCodecContext) {
        avcodec_close(audioCodecContext);
        avcodec_free_context(&audioCodecContext);
        audioCodecContext = NULL;
    }
    if (videoCodecContext) {
        avcodec_close(videoCodecContext);
        avcodec_free_context(&videoCodecContext);
        videoCodecContext = NULL;
    }
    if (fmtContext) {
        avformat_close_input(&fmtContext);
        avformat_free_context(fmtContext);
        fmtContext = NULL;
    }
}
