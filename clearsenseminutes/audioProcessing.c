//
//  audioProcessing.c
//  MuitiChannelMic
//
//  Created by 이동건 on 2023/07/19.
//

#include "audioProcessing.h"

void audioProcessingCallback(float* inputData, float* outputData, unsigned int numFrames, unsigned int numChannels) {
//    FILE *file = fopen("debug_log.txt", "w");
//    if (file != NULL) {
//        fprintf(file, "This is a debug message from C code\n");
////
//        for (unsigned int i = 0; i < numFrames * numChannels; i++) {
//            outputData[i] = inputData[i];
////            fprintf(file, "%d %d %d %f %f\n", numChannels, numFrames, i, inputData[i], outputData[i]);
//        }
        for (unsigned int i = 0; i < numFrames ; i++) {
            outputData[i] = inputData[i];
    //            fprintf(file, "%d %d %d %f %f\n", numChannels, numFrames, i, inputData[i], outputData[i]);
        }
//        
//        fclose(file);
//    }
}
