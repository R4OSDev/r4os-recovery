/* Current shared R4STD boundaries, through the public C SDK only. */
#include <r4os/storage_helpers.h>
#include <stdint.h>
int sdk86_text_boundaries(void) {
    const uint8_t text[]={'A',0xcc,0x88,0xe4,0xb8,0xad,0xf0,0x9f,0x9a,0x80};
    uintptr_t value=77;
    if(!R4SdkTextNext(text,sizeof(text),0,&value)||value!=3)return 1;
    if(!R4SdkTextNext(text,sizeof(text),1,&value)||value!=3)return 2;
    if(!R4SdkTextNext(text,sizeof(text),3,&value)||value!=6)return 3;
    if(!R4SdkTextPrevious(text,sizeof(text),sizeof(text),&value)||value!=6)return 4;
    if(!R4SdkTextPrevious(text,sizeof(text),4,&value)||value!=3)return 5;
    if(!R4SdkTextNext(text,sizeof(text),UINTPTR_MAX,&value)||value!=sizeof(text))return 6;
    if(!R4SdkTextPrevious(text,sizeof(text),UINTPTR_MAX,&value)||value!=6)return 7;
    const uint8_t bad[]={'A',0xcc};value=77;
    if(R4SdkTextNext(bad,sizeof(bad),0,&value)||value!=77)return 8;
    if(R4SdkTextPrevious(bad,sizeof(bad),sizeof(bad),&value)||value!=77)return 9;
    if(R4SdkTextNext(0,1,0,&value)||value!=77)return 10;
    if(R4SdkTextNext(text,sizeof(text),0,0))return 11;
    if(R4SdkTextPrevious(text,UINTPTR_MAX,0,&value)||value!=77)return 12;
    if(!R4SdkTextNext(0,0,0,&value)||value!=0)return 13;
    return 0;
}
