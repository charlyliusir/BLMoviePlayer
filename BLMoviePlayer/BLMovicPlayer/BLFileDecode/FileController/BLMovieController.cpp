//
//  BLMovieController.cpp
//  BLMoviePlayer
//
//  Created by Simon on 2019/10/15.
//  Copyright © 2019 刘朝龙. All rights reserved.
//

#include "BLMovieController.hpp"

// 8*sizeof(Float16), sizeof(Float16) 占两个字节(byte)
#define BL_BYTE_PER_CHANNELS 16
// 1bit是一个二级制字符, 1byte=8个二级制字符
#define BL_BITS_PER_BYTE 8
#define MIN(a, b) ((a)>(b))?(b):(a)
#define MAX(a, b) ((a)>(b))?(a):(b)

BLMovieController::BLMovieController() {
    
}

BLMovieController::~BLMovieController() {
    
}

int BLMovieController::getMusicMeta(const char *file, int *metaData) {
    BLFileDecoder *fileDecoder = new BLFileDecoder();
    fileDecoder->getMusicMeta(file, metaData);
    delete fileDecoder;
    accompanyChannels    = metaData[0];
    accompanySampleRate  = metaData[1];
    accompanyBitRate     = metaData[2];
    return 1;
}

void BLMovieController::setupDecoder(const char *file) {
    decoder = new BLFileDecoder();
    decoder->init(file, accompanyPacketBufferSize);
}

int BLMovieController::init(const char *file, float packetBufferTimePercent) {
    // 1、获取音频相关信息
    int metaData[3];
    getMusicMeta(file, &metaData[0]);
    
    // 2、初始化解码器
    // 计算出伴奏和原唱的bufferSize
    // accompanySampleRate  一个声道的采样率, 字节
    // BL_OUTPUT_CHANNELS   声道数
    // BL_BYTE_PER_CHANNELS 每个声道所占比特数
    // BL_BITS_PER_BYTE     一个字节对应的比特数
    // 原采样率*声道数*比特数/字节单位 = 1s音频字节数
    int accompanyByteCountPerSec = accompanySampleRate * accompanyChannels * BL_BYTE_PER_CHANNELS / BL_BITS_PER_BYTE;
    // 单个声道, 指定时间内的字节大小
    accompanyPacketBufferSize = (accompanyByteCountPerSec / 2) * packetBufferTimePercent;
    setupDecoder(file);
    
    // 4. 初始化音视频包队列
    audioQueue = new BLFileQueue();
    videoQueue = new BLFileQueue();
    
    // 3. 开启解码线程
    isRuning = true;
    setupDecoderThread();
    
    return 0;
}

int BLMovieController::readSamples(short *samples, int numberFrames) {
    // 先做音频解码
    int sampleSize = numberFrames;
    while (sampleSize > 0) {
        if (currAudioPacket && currAudioPacket->size == audioPacketCrosor) {
            delete currAudioPacket;
            currAudioPacket = NULL;
        }
        if (currAudioPacket) {
            int size = MIN(sampleSize, currAudioPacket->size - audioPacketCrosor);
            memcpy(samples + (numberFrames - sampleSize), currAudioPacket->data + audioPacketCrosor, size * 2);
            sampleSize -= size;
            audioPacketCrosor += size;
        } else {
            audioPacketCrosor = 0;
            currAudioPacket = (BLAudioPacket *)audioQueue->pop();
            if (currAudioPacket) {
                int size = MIN(sampleSize, currAudioPacket->size - audioPacketCrosor);
                memcpy(samples + (numberFrames - sampleSize), currAudioPacket->data + audioPacketCrosor, size * 2);
                sampleSize -= size;
                audioPacketCrosor += size;
            } else if (isRuning == false) {
                break;
            }
        }
    }
    return numberFrames - sampleSize;
}

void BLMovieController::setupDecoderThread() {
    pthread_create(&fileDecodeThread, NULL, startDecodeOnThread, (void *)this);
}

void BLMovieController::decodeFile() {
    
    BLFilePacketList *pktList = decoder->decodePacket();
    if (pktList->length() <= 0) {
        isRuning = false;
    }
    while (pktList->length() > 0) {
        BLFilePacket *pkt = pktList->popPacket();
        if (pkt->modelPacket == BLModelPacketAudio) {
            audioQueue->push(pkt);
        } else {
            videoQueue->push(pkt);
        }
    }
}

void *BLMovieController::startDecodeOnThread(void *ptr) {
    BLMovieController *controller = (BLMovieController *)ptr;
    while (controller->isRuning) {
        if (controller->audioQueue->length() >= 40 || controller->videoQueue->length() >= 40) {
            continue;
        }
        controller->decodeFile();
    }
    controller->decodeFile();
    return 0;
}
