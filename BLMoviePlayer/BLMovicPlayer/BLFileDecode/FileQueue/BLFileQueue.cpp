//
//  BLFileQueue.cpp
//  BLMoviePlayer
//
//  Created by 刘朝龙 on 2019/10/13.
//  Copyright © 2019年 刘朝龙. All rights reserved.
//

#include "BLFileQueue.hpp"

BLFileQueue::BLFileQueue() {
    first = NULL;
    last  = NULL;
    len   = 0;
}

BLFileQueue::~BLFileQueue() {
    destory();
}

int BLFileQueue::push(BLFilePacket *pkt) {
    BLFileNode *node = new BLFileNode();
    node->fileNode(pkt, NULL);
    if (NULL == first) {
        first = node;
    } else {
        last->next = node;
    }
    last = node;
    len ++;
    
    return 1;
}

BLFilePacket *BLFileQueue::pop() {
    if (NULL == first) {
        return NULL;
    }
    BLFileNode *node = first;
    first = first->next;
    len --;
    if (len == 0) {
        first = NULL;
        last  = NULL;
    }
    BLFilePacket *pkt = node->pkt;
//    delete node;
    return pkt;
}

void BLFileQueue::destory() {
    clear();
    
    if (first) {
        delete first;
        first = NULL;
    }
    if (last) {
        delete last;
        last = NULL;
    }
}

void BLFileQueue::clear() {
    
}
