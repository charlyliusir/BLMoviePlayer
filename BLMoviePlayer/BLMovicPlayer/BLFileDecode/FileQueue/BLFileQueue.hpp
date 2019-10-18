//
//  BLFileQueue.hpp
//  BLMoviePlayer
//
//  Created by 刘朝龙 on 2019/10/13.
//  Copyright © 2019年 刘朝龙. All rights reserved.
//

#ifndef BLFileQueue_hpp
#define BLFileQueue_hpp

#include <stdio.h>
#include "BLFilePacketList.hpp"

struct BLFileNode {
    BLFileNode *next;
    BLFilePacket *pkt;
    
    BLFileNode() {
        next = NULL;
        pkt  = NULL;
    }
    
    virtual ~BLFileNode() {
        if (next) {
            delete next;
            next = NULL;
        }
    }
    
    void fileNode(BLFilePacket *pkt, BLFileNode *next) {
        this->pkt  = pkt;
        this->next = next;
    }
};

class BLFileQueue {
    BLFileNode *first;
    BLFileNode *last;
    
    int len;
    
public:
    BLFileQueue();
    virtual ~BLFileQueue();
    
    int push(BLFilePacket *pkt);
    BLFilePacket *pop();
    
    void destory();
    void clear();
    
    int length() {
        return len;
    }
};

#endif /* BLFileQueue_hpp */
