//
//  audioProcessing.h
//  MuitiChannelMic
//
//  Created by 이동건 on 2023/07/19.
//

#ifndef audioProcessing_h
#define audioProcessing_h

#include <stdio.h>
void audioProcessingCallback(float* inputData, float* outputData, unsigned int numFrames, unsigned int numChannels);
#endif /* audioProcessing_h */
