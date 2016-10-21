
#ifndef svm_brdg_h
#define svm_brdg_h

#include "svm.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C"{
#endif
    typedef struct {
        double *elements;
        int length;
        bool positive;
    } Sample;
    
    struct svm_model* train(Sample *samples, int length, int sampleCount, double C, double gamma);
    bool predict(struct svm_model *model, Sample sample);
    void destroy(struct svm_model *model);

#ifdef __cplusplus
}
#endif

#endif /* svm_brdg_h */
