//
//  zdelta+blocks.c
//  zdelta
//
//  Created by Jens Alfke on 10/27/13.
//

#include "zdelta+blocks.h"
#include "zd_mem.h"     /* provides dynamic memory allocation */
#include "zutil.h"

// Expected delta compression ratio; copied from zdelta.c
#define EXPECTED_RATIO 4

// Maximum amount of memory to use for delta output buffer
#define DBUF_MAX_SIZE (32*1024)

static int call_writer(Bytef* buf, Bytef* next_out, zd_writer_block writer) {
  uLongf size = next_out - buf;
  if (size == 0) {
    return ZD_OK;
  }
  return writer(buf, size);
}

int ZEXPORT zd_compress_incr(const Bytef *ref, uLong rsize,
                             const Bytef *tar, uLong tsize,
                             zd_writer_block delta_writer)
{
  int rval;
  zd_stream strm;
  zd_mem_buffer dbuf;

  /* init io buffers */
  strm.base[0]  = (Bytef*) ref;
  strm.base_avail[0] = rsize;
  strm.base_out[0] = 0;
  strm.refnum      = 1;

  strm.next_in  = (Bytef*) tar;
  strm.total_in = 0;
  strm.avail_in = tsize;

  /* allocate the output buffer */
  uLong dbuf_size = tsize/EXPECTED_RATIO + 64;
  if (dbuf_size > DBUF_MAX_SIZE) {
    dbuf_size = DBUF_MAX_SIZE;
  }
  if (zd_alloc(&dbuf, dbuf_size) == 0) {
    return ZD_MEM_ERROR;
  }
  
  strm.next_out  = dbuf.pos;
  strm.total_out = 0;
  strm.avail_out = dbuf.size;

  strm.zalloc = (alloc_func)0;
  strm.zfree = (free_func)0;
  strm.opaque = (voidpf)0;

  /* init huffman coder */
  rval = zd_deflateInit(&strm, ZD_DEFAULT_COMPRESSION);
  if (rval != ZD_OK) {
    fprintf(stderr, "%s error: %d\n", "deflateInit", rval);
    zd_free(&dbuf);
    return rval;
  }

  /* compress the data */
  while((rval = zd_deflate(&strm,ZD_FINISH)) == ZD_OK || rval == ZD_STREAM_END){
    /* call the writer block with the data written to the output buffer */
    int wval = call_writer(dbuf.buffer, strm.next_out, delta_writer);
    if (wval != ZD_OK) {
      rval = wval;
      break;
    }
    if (rval == ZD_STREAM_END) {
      rval = ZD_OK;
      break;
    }

    /* reset the output buffer */
    strm.next_out = dbuf.buffer;
    strm.avail_out = dbuf.size;
  }

  zd_free(&dbuf);

  if(rval != ZD_OK){
    fprintf(stderr, "%s error: %d\n", "deflate", rval);
    zd_deflateEnd(&strm);
    return rval;
  }
  return zd_deflateEnd(&strm);
}


int ZEXPORT zd_uncompress_incr(const Bytef *ref, uLong rsize,
                               zd_writer_block target_writer,
                               const Bytef *delta, uLong dsize)
{
  int rval;
  int f = ZD_SYNC_FLUSH;
  zd_mem_buffer tbuf;  
  zd_stream strm;

  /* init io buffers */
  strm.base[0]       = (Bytef*) ref;
  strm.base_avail[0] = rsize;
  strm.refnum        = 1;

  /* allocate target buffer */
  uLong dbuf_size = rsize + EXPECTED_RATIO*dsize;
  if (dbuf_size > DBUF_MAX_SIZE) {
    dbuf_size = DBUF_MAX_SIZE;
  }
  if (zd_alloc(&tbuf, dbuf_size) == 0) {
    return ZD_MEM_ERROR;
  }
  strm.avail_out = tbuf.size;
  strm.next_out  = tbuf.buffer;
  strm.total_out = 0;

  strm.avail_in = dsize;
  strm.next_in  = (Bytef*) delta;
  strm.total_in = 0;

  strm.zalloc = (alloc_func)0;
  strm.zfree  = (free_func)0;
  strm.opaque = (voidpf)0;
  rval = zd_inflateInit(&strm);
  if (rval != ZD_OK) {
    fprintf(stderr, "%s error: %d\n", "zd_InflateInit", rval);
    zd_free(&tbuf);
    return rval;
  }

  while((rval = zd_inflate(&strm,f)) == ZD_OK || rval == ZD_STREAM_END){
    /* call the writer block with the data written to the output buffer */
    int wval = call_writer(tbuf.buffer, strm.next_out, target_writer);
    if (wval != ZD_OK) {
      rval = wval;
      break;
    }
    if (rval == ZD_STREAM_END) {
      rval = ZD_OK;
      break;
    }

    /* restore zstream internal pointer */
    strm.next_out = tbuf.buffer;
    strm.avail_out = tbuf.size;
  }

  zd_free(&tbuf);

  if(rval != ZD_OK){
    if(strm.msg!=NULL) fprintf(stderr,"%s\n",strm.msg);
    zd_inflateEnd(&strm);
    return rval;
  }

  return zd_inflateEnd(&strm);
}
