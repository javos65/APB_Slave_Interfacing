/*
 * pwm4.h
 *
 *  Created on: 5 Jan 2025
 *      Author: jayFox
 *
 *      Dricers for 4 Channel 16 bit PWM : PWM0, 1, 2, 3
 *      Memory mapped through APB bus as 32 bit register
 *      Register MSB             LSB
 *                [31:18][17][16][15:0]
 *                   X   CLR  EN   DC
 *      Use:
 *          1. : call pwm4_init(base)  base = known 32bit base address or :
 *                                     base = 0x00 -> looks for base address by checking Memory space for IP-ID
 *          2. : clear PWM : pwm4_clear(pwm,0x01);
 *      	3. : set PWM DC : pwm4_setcycle( pwm,dutycycle);
 *          4. : reset clear-bit : pwm4_clear(pwm,0x00);
 *      	5. : enable PWM: pwm4_enable(pwm,  0x01);
 *
 *      	Other function explain themselves.
  *
 *  Main.c example for initalisation :
 *
 *	if (!pwm4_init(0) ) { // added : get PWM4 base adress, if ok, turn on PWM's
 *	}
 *	for(uint8_t i=0; i<MAXPWM; ++i) {
 *		pwm4_clear(i,0x1); 					// clear all PWM counters
 *		pwm4_setcycle(i,(uint16_t) (0x1000 + i*0x0200) ); // Set DutyCycles
 *		pwm4_clear(i,0x0); 				    // release PWM counters
 *		pwm4_enable(i,0x01);		 		// Enable PWM's, start counting
 *	}
 *
 *
 */

#ifndef PWM4_H_
#define PWM4_H_

#include <stdint.h>
#include <stdbool.h>

#define PWM4_ID 0xB19B00B2 	// IP defined ID number in VHDL-code
#define MAXPWM 4		 	// MAX memory locations 0 to 4 -> Mapped to memory to =>  [BASE + 1 + LocationAddress]
#define BASE_ADDRESS_START 0x4000A000	//	pwm4_init() address searcher start = start of your Peripheal address space !!!
#define BASE_ADDRESS_END   0x40010000	//  pwm4_init() address searcher end

#define PWM0	0 // PWM index
#define PWM1	1
#define PWM2	2
#define PWM3	3

uint32_t pwm4_init(uint32_t base);
uint8_t  pwm4_enable(uint8_t pwm,  uint8_t logiclevel);
uint8_t  pwm4_clear(uint8_t pwm,  uint8_t logiclevel);
uint8_t  pwm4_setcycle(uint8_t pwm,uint16_t dutycycle);
uint8_t pwm4_getcycle(uint8_t pwm, uint16_t *dutycycle);
uint8_t pwm4_getregister(uint8_t pwm, uint32_t *pwmregister);
uint32_t pwm4_getbase();

#endif /* PWM4_H_ */
