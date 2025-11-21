/*
 * nexus_adc.h
 *
 *  Created on: 5 Jan 2025
 *      Author: javos
 */

#ifndef NEXUS_ADC_H_
#define NEXUS_ADC_H_



#include <stdint.h>
#include <stdbool.h>

#define ADC_ID 0xB19B00B3 		// IP defined ID number in VHDL
#define MAXADC 2		 	// MAX mem	ory locations 0 to 4 -> Mapped to memory to =>  [BASE + 1 + LocationAddress]

#define VREF	1200	 // Vref millivolts
#define ADC0	0
#define ADC1	1

#define ADC0_CP0	0xB
#define ADC1_CP1	0xB
#define ADC1_DTR	0xA

uint32_t adc_init(uint32_t base);
uint8_t  adc_select(uint8_t adc,  uint8_t select);
uint8_t adc_getraw(uint8_t adc, uint16_t *raw);
uint16_t adc_getraw_(uint8_t adc);
uint8_t adc_getmvolts(uint8_t adc, int32_t *mvolts);
uint8_t adc_getmcelcius(uint8_t adc, int32_t *mcelcius);
uint32_t adc_getbase();

#endif /* NEXUS_ADC_H_ */
