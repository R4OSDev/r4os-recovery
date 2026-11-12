/* Original synthetic ICC fixtures. These do not characterize any real monitor.
 * Public LittleCMS APIs serialize real LUT/VCGT tags for the existing CMM tests.
 */
#include "lcms2.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void fail(const char *message) { fprintf(stderr, "%s\n", message); exit(1); }
static void save(cmsHPROFILE profile, const char *directory, const char *name) {
    cmsUInt32Number length = 0;
    unsigned char *bytes;
    char filename[4096];
    FILE *file;
    const unsigned char date[12] = {7,234,0,9,0,14,0,0,0,0,0,0};
    if (!cmsSaveProfileToMem(profile, NULL, &length) || length < 132) fail("serialize size");
    bytes = malloc(length);
    if (!bytes || !cmsSaveProfileToMem(profile, bytes, &length)) fail("serialize data");
    /* Stable byte fixtures on either host: fixed creation time, unspecified
     * host platform and profile ID. The transforms themselves are unchanged. */
    memcpy(bytes + 24, date, sizeof(date));
    memset(bytes + 40, 0, 4); memset(bytes + 84, 0, 16);
    if (snprintf(filename, sizeof(filename), "%s/%s", directory, name) >= (int)sizeof(filename)) fail("fixture path");
    file = fopen(filename, "wb");
    if (!file || fwrite(bytes, 1, length, file) != length || fclose(file)) fail("fixture write");
    free(bytes); cmsCloseProfile(profile);
}
static cmsHPROFILE linear(void) {
    cmsCIExyY white = {0.3127,0.3290,1};
    cmsCIExyYTRIPLE primaries = {{0.64,0.33,1},{0.30,0.60,1},{0.15,0.06,1}};
    cmsToneCurve *curves[3];
    cmsHPROFILE result;
    unsigned i;
    for (i=0;i<3;++i) if (!(curves[i]=cmsBuildGamma(NULL,1))) fail("linear curve");
    result=cmsCreateRGBProfile(&white,&primaries,curves);
    for (i=0;i<3;++i) cmsFreeToneCurve(curves[i]);
    if (!result) fail("linear profile");
    cmsSetProfileVersion(result,4.3);
    return result;
}
static void calibrated(const char *directory, int descending) {
    cmsHPROFILE profile=linear();
    cmsToneCurve *curves[3];
    cmsUInt16Number values[256];
    const unsigned maxima[3]={49151,32768,65535};
    unsigned channel,i;
    for (channel=0;channel<3;++channel) {
        for (i=0;i<256;++i) values[i]=(cmsUInt16Number)(((descending ? 255-i : i)*maxima[channel]+127)/255);
        curves[channel]=cmsBuildTabulatedToneCurve16(NULL,256,values);
        if (!curves[channel]) fail("calibration curve");
    }
    if (!cmsWriteTag(profile,cmsSigVcgtTag,curves)) fail("calibration tag");
    for (channel=0;channel<3;++channel) cmsFreeToneCurve(curves[channel]);
    save(profile,directory,descending ? "vcgt-descending.icc" : "vcgt-display.icc");
}
static int forward(const cmsUInt16Number in[], cmsUInt16Number out[], void *unused) {
    unsigned i; (void)unused;
    /* ICC PCS XYZ16 uses32768 for1.0. Device RGB is normalized to65535. */
    for (i=0;i<3;++i) out[i]=(cmsUInt16Number)(((unsigned)in[i]*32768+32767)/65535);
    return 1;
}
static int reverse(const cmsUInt16Number in[], cmsUInt16Number out[], void *unused) {
    unsigned i; (void)unused;
    for (i=0;i<3;++i) out[i]=(cmsUInt16Number)(in[i] >= 32768 ? 65535 : (unsigned)in[i]*2);
    return 1;
}
static void lut(const char *directory) {
    cmsHPROFILE profile=cmsCreateProfilePlaceholder(NULL);
    cmsPipeline *pipeline;
    cmsStage *stage;
    unsigned direction;
    if (!profile) fail("LUT profile");
    cmsSetProfileVersion(profile,2.1); cmsSetDeviceClass(profile,cmsSigDisplayClass);
    cmsSetColorSpace(profile,cmsSigRgbData); cmsSetPCS(profile,cmsSigXYZData);
    if (!cmsWriteTag(profile,cmsSigMediaWhitePointTag,cmsD50_XYZ())) fail("LUT white point");
    for (direction=0;direction<2;++direction) {
        pipeline=cmsPipelineAlloc(NULL,3,3);
        stage=cmsStageAllocCLut16bit(NULL,direction ? 3 : 2,3,3,NULL);
        if (!pipeline || !stage || !cmsStageSampleCLut16bit(stage,direction ? reverse : forward,NULL,0)) fail("LUT cube");
        if (!cmsPipelineInsertStage(pipeline,cmsAT_END,cmsStageAllocToneCurves(NULL,3,NULL)) ||
            !cmsPipelineInsertStage(pipeline,cmsAT_END,stage) ||
            !cmsPipelineInsertStage(pipeline,cmsAT_END,cmsStageAllocToneCurves(NULL,3,NULL)) ||
            !cmsWriteTag(profile,direction ? cmsSigBToA0Tag : cmsSigAToB0Tag,pipeline)) fail("LUT pipeline");
        cmsPipelineFree(pipeline);
    }
    save(profile,directory,"lut-display.icc");
}
int main(int argc,char **argv) {
    if (argc!=2) fail("usage: MakeFixtures output-directory");
    calibrated(argv[1],0); calibrated(argv[1],1); lut(argv[1]);
    return 0;
}
