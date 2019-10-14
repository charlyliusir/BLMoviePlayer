//
//  BLFilePacketList.hpp
//  BLMoviePlayer
//
//  Created by 刘朝龙 on 2019/10/13.
//  Copyright © 2019年 刘朝龙. All rights reserved.
//

#ifndef BLFilePacketList_hpp
#define BLFilePacketList_hpp

#include <stdio.h>

#define byte int16_t

// 视频数据包的类型
enum BLModelPacket {
    BLModelPacketUnKnow, // 未知, 错误类型
    BLModelPacketAudio,  // 音频类型
    BLModelPacketVideo   // 视频类型
};

struct BLFilePacket {
    BLModelPacket modelPacket;  // 数据类型
    int size;                   // 数据大小
    int position;               //
    int timebase;               // 时间基数
    BLFilePacket* next;
    
    BLFilePacket() {
        modelPacket = BLModelPacketUnKnow;
        size        = 0;
        position    = 0;
        timebase    = 0;
        next        = NULL;
    }
    ~BLFilePacket() {
        
    }
};

struct BLAudioPacket : BLFilePacket {
    byte* data;
    BLAudioPacket() {
        modelPacket = BLModelPacketAudio;
        data        = NULL;
    }
    ~BLAudioPacket() {
        if (data) {
            delete data;
            data = NULL;
        }
    }
};

struct BLVideoPacket : BLFilePacket {
    byte* y_data;
    byte* u_data;
    byte* v_data;
    BLVideoPacket() {
        modelPacket = BLModelPacketVideo;
        y_data      = NULL;
        u_data      = NULL;
        v_data      = NULL;
    }
    ~BLVideoPacket() {
        if (y_data) {
            delete y_data;
            y_data = NULL;
        }
        if (u_data) {
            delete u_data;
            u_data = NULL;
        }
        if (v_data) {
            delete v_data;
            v_data = NULL;
        }
    }
};

class BLFilePacketList {
    
    BLFilePacket* first;
    BLFilePacket* last;
    
    int len;                    // 包列表长度
    BLModelPacket modelPacket;  // 包列表数据类型
    
    // 清空列表
    void clear();
    
public:
    // 初始化方法
    BLFilePacketList();
    // 析构方法, 也就是OC中dealloc方法
    virtual ~BLFilePacketList();
    
    // 添加数据包
    int addPacket(BLFilePacket* filePacket);
    // 读取并删除数据包
    BLFilePacket* popPacket();
    
    // 获取数据包列表的长度
    int length();
    // 获取数据包列表的类型, 视频 & 音频
    BLModelPacket model();
    
    // 销毁
    void destory();
};

#endif /* BLFilePacketList_hpp */
