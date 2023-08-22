#ifndef __BLURHASH_ENCODE_H__
#define __BLURHASH_ENCODE_H__

#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

const char *blurHashForPixels(int xComponents, int yComponents, int width, int height, const uint8_t *rgb, bool hasAlpha);

#endif
