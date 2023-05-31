#!/bin/bash

g++ `pkg-config opencv --cflags` -g framecap.cpp  -o framecap -lriffa `pkg-config opencv --libs`
