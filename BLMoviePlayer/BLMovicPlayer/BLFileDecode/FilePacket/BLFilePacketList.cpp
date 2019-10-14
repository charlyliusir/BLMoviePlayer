//
//  BLFilePacketList.cpp
//  BLMoviePlayer
//
//  Created by 刘朝龙 on 2019/10/13.
//  Copyright © 2019年 刘朝龙. All rights reserved.
//

#include "BLFilePacketList.hpp"

BLFilePacketList::BLFilePacketList() {
    modelPacket = BLModelPacketUnKnow;
    first = NULL;
    last  = NULL;
    len   = 0;
}

BLFilePacketList::~BLFilePacketList() {
    destory();
}

int BLFilePacketList::addPacket(BLFilePacket* filePacket) {
    
    if (first == NULL) {
        first = filePacket;
    } else {
        first->next = filePacket;
    }
    last  = filePacket;
    len ++;
    return 1;
}

BLFilePacket* BLFilePacketList::popPacket() {
    if (len == 0) {
        return NULL;
    }
    BLFilePacket *packet = first;
    first = first->next;
    len --;
    if (len == 0) {
        first = NULL;
        last  = NULL;
    }
    if (packet->size <= 0) {
        delete packet;
        return NULL;
    }
    return packet;
}

int BLFilePacketList::length() {
    return len;
}

BLModelPacket BLFilePacketList::model() {
    return modelPacket;
}

void BLFilePacketList::clear() {
    while (first) {
        BLFilePacket *packet = first;
        first = first->next;
        delete packet;
        if (len == 0) {
            first = NULL;
            last  = NULL;
        }
    }
    len = 0;
}

void BLFilePacketList::destory() {
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
