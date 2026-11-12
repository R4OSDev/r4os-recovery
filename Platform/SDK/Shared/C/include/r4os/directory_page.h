#ifndef R4OS_DIRECTORY_PAGE_H
#define R4OS_DIRECTORY_PAGE_H
#include "storage_helpers.h"
#include "heap.h"

enum { R4_DIALOG_FILE=0, R4_DIALOG_DIRECTORY=1, R4_DIALOG_PREVIOUS=2, R4_DIALOG_NEXT=3 };
typedef struct R4DialogRow { uint32_t kind; R4FilePath path; uint8_t label[256]; } R4DialogRow;
typedef struct R4DialogPage { R4FilePath directory; R4DialogRow *rows; uint32_t capacity,count,number; } R4DialogPage;
static inline int r4_dialog_page_init(R4DialogPage *page,R4DialogRow *rows,uint32_t capacity) {
    if(!page||!rows||capacity<4u)return 0;
    *page=(R4DialogPage){0};page->rows=rows;page->capacity=capacity;return 1;
}
static inline int r4_dialog_page_add(R4DialogPage *page,uint32_t kind,const R4FilePath *path,const uint8_t *label,uintptr_t len) {
    if(page->count>=page->capacity)return 0;
    R4DialogRow *row=&page->rows[page->count];*row=(R4DialogRow){0};row->kind=kind;
    if(path)row->path=*path;
    if(!R4SdkTextLabel(row->label,sizeof(row->label),label,len))return 0;
    ++page->count;return 1;
}
/* scratch must contain capacity rows and must not overlap the published page.
 * Enumerate through the real end before publishing, including hidden entries. */
static inline int r4_dialog_page_load(R4DialogPage *page,R4DialogRow *scratch,uint32_t scratch_capacity,R4Files files,const R4FilePath *directory,uint32_t number,const uint8_t *extension,uintptr_t extension_len) {
    if(!page||!page->rows||!directory||!scratch||scratch_capacity<page->capacity||page->capacity<4u||(!extension&&extension_len))return 0;
    R4DialogPage next={0};next.rows=scratch;next.capacity=page->capacity;next.directory=*directory;next.number=number;
    R4DirectoryIterator it=r4_files_iterate(files,directory);it.index=1u;
    R4DirectoryNext parent=r4_directory_next(&it);
    if(parent.state!=R4_DIRECTORY_ENTRY||!r4_dialog_page_add(&next,R4_DIALOG_DIRECTORY,&parent.path,(const uint8_t *)"[DIR] ..",8u))return 0;
    if(number&&!r4_dialog_page_add(&next,R4_DIALOG_PREVIOUS,0,(const uint8_t *)"<< Previous page",16u))return 0;
    uint64_t page_size=page->capacity-3u,first=(uint64_t)number*page_size,seen=0;
    for(;;){
        R4DirectoryNext entry=r4_directory_next(&it);
        if(entry.state==R4_DIRECTORY_END)break;
        if(entry.state!=R4_DIRECTORY_ENTRY)return 0;
        uintptr_t len=entry.path.length;
        if(!entry.is_directory&&extension_len&&(extension_len>len||!r4_path_equal_ignore_case(entry.path.bytes+len-extension_len,extension_len,extension,extension_len)))continue;
        if(seen>=first&&seen-first<page_size){
            uintptr_t tail=0;for(uintptr_t n=0;n<len;++n)if(entry.path.bytes[n]=='/'||entry.path.bytes[n]=='\\')tail=n+1u;
            uint8_t label[256]={0};uintptr_t prefix=entry.is_directory?6u:0u;
            if(prefix)__builtin_memcpy(label,"[DIR] ",prefix);
            if(!R4SdkTextLabel(label+prefix,sizeof(label)-prefix,entry.path.bytes+tail,len-tail))return 0;
            uintptr_t label_len=0;while(label_len<sizeof(label)&&label[label_len])++label_len;
            if(!r4_dialog_page_add(&next,entry.is_directory?R4_DIALOG_DIRECTORY:R4_DIALOG_FILE,&entry.path,label,label_len))return 0;
        }
        ++seen;
    }
    if(seen>first+page_size&&!r4_dialog_page_add(&next,R4_DIALOG_NEXT,0,(const uint8_t *)"Next page >>",12u))return 0;
    __builtin_memcpy(page->rows,next.rows,(uintptr_t)next.count*sizeof(R4DialogRow));
    page->directory=next.directory;page->number=number;page->count=next.count;return 1;
}

typedef int (*R4PageLessFn)(void *,const void *,const void *);
typedef struct R4OrderedPage { uint8_t *entries; uintptr_t count,capacity,item_size; } R4OrderedPage;
static inline int r4_ordered_page_init(R4OrderedPage *page,void *entries,uintptr_t capacity,uintptr_t item_size){
    if(!page||!entries||!capacity||!item_size||item_size>UINTPTR_MAX/capacity)return 0;
    *page=(R4OrderedPage){(uint8_t *)entries,0,capacity,item_size};return 1;
}
/* value is a complete caller-owned record, disjoint from entries. */
static inline int r4_ordered_page_offer(R4OrderedPage *page,const void *value,R4PageLessFn less,void *context){
    if(!page||!value||!less||!page->capacity)return 0;
    if(page->count==page->capacity&&!less(context,value,page->entries+(page->capacity-1u)*page->item_size))return 0;
    uintptr_t at=page->count<page->capacity?page->count:page->capacity-1u;
    while(at&&less(context,value,page->entries+(at-1u)*page->item_size)){
        __builtin_memmove(page->entries+at*page->item_size,page->entries+(at-1u)*page->item_size,page->item_size);--at;
    }
    __builtin_memcpy(page->entries+at*page->item_size,value,page->item_size);
    if(page->count<page->capacity)++page->count;return 1;
}
typedef struct R4DirectorySnapshot { R4Heap heap; uint8_t *entries; uintptr_t count,capacity,limit,item_size,alignment; } R4DirectorySnapshot;
static inline int r4_snapshot_init(R4DirectorySnapshot *s,const R4Heap *heap,uintptr_t max_bytes,uintptr_t item_size,uintptr_t alignment){
    if(!s||!heap||!item_size||!alignment||(alignment&(alignment-1u)))return 0;
    *s=(R4DirectorySnapshot){0};s->heap=*heap;s->limit=max_bytes/item_size;s->item_size=item_size;s->alignment=alignment;return 1;
}
static inline int r4_snapshot_append(R4DirectorySnapshot *s,const void *value){
    if(!s||!value||s->count==s->limit)return 0;
    if(s->count==s->capacity){
        uintptr_t wanted=s->capacity>s->limit/2u?s->limit:s->capacity*2u;
        if(wanted<64u)wanted=s->limit<64u?s->limit:64u;
        void *next=r4_heap_realloc(&s->heap,s->entries,wanted*s->item_size,s->alignment);
        if(!next)return 0;s->entries=(uint8_t *)next;s->capacity=wanted;
    }
    __builtin_memcpy(s->entries+s->count*s->item_size,value,s->item_size);++s->count;return 1;
}
static inline void r4_snapshot_swap(R4DirectorySnapshot *s,uintptr_t a,uintptr_t b){
    for(uintptr_t i=0;i<s->item_size;++i){uint8_t t=s->entries[a*s->item_size+i];s->entries[a*s->item_size+i]=s->entries[b*s->item_size+i];s->entries[b*s->item_size+i]=t;}
}
static inline void r4_snapshot_sift(R4DirectorySnapshot *s,uintptr_t root,uintptr_t end,R4PageLessFn less,void *context){
    while(root<end/2u){
        uintptr_t child=root*2u+1u;
        if(child+1u<end&&less(context,s->entries+child*s->item_size,s->entries+(child+1u)*s->item_size))++child;
        if(!less(context,s->entries+root*s->item_size,s->entries+child*s->item_size))return;
        r4_snapshot_swap(s,root,child);root=child;
    }
}
static inline void r4_snapshot_sort(R4DirectorySnapshot *s,R4PageLessFn less,void *context){
    if(!s||!less||s->count<2u)return;
    for(uintptr_t n=s->count/2u;n;--n)r4_snapshot_sift(s,n-1u,s->count,less,context);
    for(uintptr_t n=s->count;n>1u;--n){r4_snapshot_swap(s,0,n-1u);r4_snapshot_sift(s,0,n-1u,less,context);}
}
static inline int32_t r4_snapshot_close(R4DirectorySnapshot *s){
    if(!s)return -1;int32_t rc=r4_heap_free(&s->heap,s->entries);
    if(!rc){s->entries=0;s->count=0;s->capacity=0;}return rc;
}
#endif
