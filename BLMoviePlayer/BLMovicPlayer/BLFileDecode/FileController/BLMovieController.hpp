//
//  BLMovieController.hpp
//  BLMoviePlayer
//
//  Created by Simon on 2019/10/15.
//  Copyright © 2019 刘朝龙. All rights reserved.
//

#ifndef BLMovieController_hpp
#define BLMovieController_hpp

#include <stdio.h>
#include <pthread.h>
#include "BLFileQueue.hpp"
#include "BLFileDecoder.hpp"

class BLMovieController {
    BLFileQueue *videoQueue;
    BLFileQueue *audioQueue;
    BLFileDecoder *decoder;
    
    BLAudioPacket *currAudioPacket;
    int audioPacketCrosor;
    
    BLVideoPacket *currVideoPacket;
    int videoPacketCrosor;
    
    pthread_t fileDecodeThread;
    int accompanyPacketBufferSize; // 解码的包大小
    bool isRuning;
    
    void setupDecoder(const char *file);
    void setupDecoderThread();
    void decodeFile();
    
    static void *startDecodeOnThread(void *ptr);
    
public:
    int accompanySampleRate;
    int accompanyChannels;
    int accompanyBitRate;
    
    BLMovieController();
    virtual ~BLMovieController();
    
    int getMusicMeta(const char *file, int *metaData);
    int init(const char *file, float packetBufferTimePercent);
    
    int readSamples(short *samples, int numberFrames);
    
    void destory();
};

#endif /* BLMovieController_hpp */
