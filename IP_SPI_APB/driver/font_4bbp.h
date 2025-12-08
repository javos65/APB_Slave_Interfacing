/*
 * Font library, see https://lvgl.io/tools/font_conv_v5_3
 *
 * J.Vos 2025
 *
*/
#ifndef LVGL_FONT
#define LVGL_FONT

#include <stdio.h>

typedef struct {
  const uint8_t *fontmap;  // Glyph bitmaps, concatenated
  const uint16_t *fontindex;  //< Glyph bitmaps index
  uint16_t first;   ///< ASCII extents (first char)
  uint16_t last;    ///< ASCII extents (last char)
  uint8_t bpp;
  uint8_t height;
  char name[20];        // name in Text
  char table[20];       // table name required for font conversion
} font4bpp;

extern font4bpp ArialRND12p;
extern const uint8_t  arial12pfonttable[];
extern const uint16_t arial12pindex[59][2];

void draw_text( const char *text, font4bpp myfont, uint8_t x, uint8_t y,uint16_t color1);
void draw_font(uint8_t *pSrc, uint8_t x, uint8_t y,uint8_t xSize, uint8_t ySize,uint16_t color);


#endif //LVGL_FONT
