
/*
 *
 * SSD1351 Include file
 *
 * J.Vos 2025
 *
 * Define Control set
 * Define Color codes in RGB565
 * Define Memory mapped registers to SPI
 *
 */
#include <stdio.h> // for printf funtion
#include "utils.h" // for delay function

#ifndef SSD1351_H_
#define SSD1351_H_


#define ID_REGISTER 0x00			// offset ID 		read only
#define STATUS_REGISTER 0x04		// offset Status 	read only
#define CONTROL_REGISTER 0x08		// offset Control 	read / write
#define DATA_REGISTER 0x0c			// offset Data 		read / write

#define STATUS_SPI_READY  0
#define STATUS_SPI_ERROR 17
#define STATUS_SPI_SEND  16

#define SSD1351WIDTH 128  ///< DEPRECATED screen width
#define SSD1351HEIGHT 128 ///< DEPRECATED screen height, set to 96 for 1.27"


#define SSD1351_CMD_SETCOLUMN 0x15      ///< See datasheet
#define SSD1351_CMD_SETROW 0x75         ///< See datasheet
#define SSD1351_CMD_WRITERAM 0x5C       ///< See datasheet
#define SSD1351_CMD_READRAM 0x5D        ///< Not currently used
#define SSD1351_CMD_SETREMAP 0xA0       ///< See datasheet
#define SSD1351_CMD_STARTLINE 0xA1      ///< See datasheet
#define SSD1351_CMD_DISPLAYOFFSET 0xA2  ///< See datasheet
#define SSD1351_CMD_DISPLAYALLOFF 0xA4  ///< Not currently used
#define SSD1351_CMD_DISPLAYALLON 0xA5   ///< Not currently used
#define SSD1351_CMD_NORMALDISPLAY 0xA6  ///< See datasheet
#define SSD1351_CMD_INVERTDISPLAY 0xA7  ///< See datasheet
#define SSD1351_CMD_FUNCTIONSELECT 0xAB ///< See datasheet
#define SSD1351_CMD_DISPLAYOFF 0xAE     ///< See datasheet
#define SSD1351_CMD_DISPLAYON 0xAF      ///< See datasheet
#define SSD1351_CMD_PRECHARGE 0xB1      ///< See datasheet
#define SSD1351_CMD_DISPLAYENHANCE 0xB2 ///< Not currently used
#define SSD1351_CMD_CLOCKDIV 0xB3       ///< See datasheet
#define SSD1351_CMD_SETVSL 0xB4         ///< See datasheet
#define SSD1351_CMD_SETGPIO 0xB5        ///< See datasheet
#define SSD1351_CMD_PRECHARGE2 0xB6     ///< See datasheet
#define SSD1351_CMD_SETGRAY 0xB8        ///< Not currently used
#define SSD1351_CMD_USELUT 0xB9         ///< Not currently used
#define SSD1351_CMD_PRECHARGELEVEL 0xBB ///< Not currently used
#define SSD1351_CMD_VCOMH 0xBE          ///< See datasheet
#define SSD1351_CMD_CONTRASTABC 0xC1    ///< See datasheet
#define SSD1351_CMD_CONTRASTMASTER 0xC7 ///< See datasheet
#define SSD1351_CMD_MUXRATIO 0xCA       ///< See datasheet
#define SSD1351_CMD_COMMANDLOCK 0xFD    ///< See datasheet
#define SSD1351_CMD_HORIZSCROLL 0x96    ///< Not currently used
#define SSD1351_CMD_STOPSCROLL 0x9E     ///< Not currently used
#define SSD1351_CMD_STARTSCROLL 0x9F    ///< Not currently used
#define SSD1351_CMD_DISPLAY_INVERT 0xA7
#define SSD1351_CMD_DISPLAY_NORMAL 0xA6

#define ORIENTATION_1 0x34 //COL0 mapped to SEG0 / Scan COM 127 - COM0 (color seq swapped, 65K)
#define ORIENTATION_2 0x36 //COL127 mapped to SEG0 / Scan COM 127 - COM0 (color seq swapped, 65K)
#define ORIENTATION_3 0x24 //COL0 mapped to SEG0 / Scan COM 0 - COM127 (color seq swapped,65K)
#define ORIENTATION_4 0x26 //COL127 mapped to SEG0 / Scan COM 0 - COM127 (color seq swapped,65K)




// SPI memory mapped routines
uint32_t readSPIMemory(uint8_t offset);
void writeSPIMemory(uint8_t offset,uint32_t data);

// SPI ssd1351 routines
void base_ssd1351(uint32_t address);
void init_ssd1351();
uint8_t command_ssd1351(uint8_t command);
uint8_t data_ssd1351(uint8_t data);


// Graphics routines
void set_orientation(uint8_t orientation);
void set_block(uint8_t c0,uint8_t c1,uint8_t r0,uint8_t r1);
void fill_block(uint16_t color);
void draw_rectangle(uint8_t x,uint8_t y,uint8_t w,uint8_t h,uint16_t color);
void draw_image(uint8_t x,uint8_t y,uint8_t w,uint8_t h,const uint16_t *i);
void draw_testpattern();
void draw_lattice_logo(uint8_t x,uint8_t y,uint8_t s);

// define Logo array
#define LOGO_L_HEIGHT 32
#define LOGO_L_WIDTH 32
extern const uint16_t logo_1[1024];

// RGB565 Defines
#define MAGENTA 0xF81F
#define BLACK 0x0000
#define WHITE 0XFFFF
#define YELLOW 0xFFE0
#define GREEN 0x07E0
#define BLUE 0x001F
#define RED 0xF800
#define CYAN 0x07FF
#define GRAY 0x8430
#define GOLD 0xFEA0

#endif				/* SSD1351_H_ */
