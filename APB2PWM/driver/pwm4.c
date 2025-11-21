/*
 * pwm4.c
 *
 *  Created on: 5 Jan 2025 / reviewed Oct 2025
 *      Author: jayfox
 *
 *     Driver code is independ from sys_platform.h definitions
 *     Initialize the pwm-driver with the right address, or let it search for the address
 *
 *     Check pwm4.h for use details
 *
 */
#include <stdio.h>
#include "pwm4.h"
#include "reg_access.h"

uint32_t G_pmw4_base =0; // Global variable for base address of pwm4

// initialise base memory address to Global variable G_pmw4_base
// Or address is given (base<>0), or address is searched (base=0) at obvious locations
// RiscV Peripheral memory locations example 1 :0x00004000 (4K base mem) to 0x00040000 (256K base mem) in steps of 0x0400 (1K)
uint32_t pwm4_init(uint32_t base)
{
	uint32_t t,d;
	if (base == 0x00000000) // trigger ID search
	{
		for(t=BASE_ADDRESS_START; t<BASE_ADDRESS_END ;t=t+0x00000400)  //ADAPT in pwm4.h you address range
		{
			reg_32b_read(t,	&d); // read Memory
			//printf("Mem[0x%08X] = [0x%08X]\n", t, d);
			if ( d == PWM4_ID )
					{
					G_pmw4_base=t; // found, store base address
					t = BASE_ADDRESS_END; // end loop
					}
		}
		return(G_pmw4_base);
	}
	else		// Address is given as input
	{
		G_pmw4_base = base;
		return(G_pmw4_base);
	}
}

// get Base address LocalMem Peripheral
uint32_t pwm4_getbase()
{
	return(G_pmw4_base);
}

//read from pwm location into local register
uint8_t pwm4_getregister(uint8_t pwm,uint32_t *pwmregister)
{
uint32_t addr;
addr =G_pmw4_base + (pwm+1)*4;
if(pwm > MAXPWM || G_pmw4_base==0)
	{
	*pwmregister=0;
	return(0);
	}
else
	{
	reg_32b_read(addr, pwmregister );
	return(1);
	}
}


//read from pwm location into, get DC - lower 16 bits
uint8_t pwm4_getcycle(uint8_t pwm, uint16_t *dutycycle)
{
uint32_t reg,addr;
addr =G_pmw4_base + (pwm+1)*4;
if(pwm > MAXPWM || G_pmw4_base==0)
	{
	*dutycycle=0;
	return(0);
	}
else
	{
	reg_32b_read(addr,&reg ); // read register
	*dutycycle = (uint16_t) (0x0000FFFF&reg);  // lower 16 bits = DC
	return(1);
	}
}


//read from pwm location and write back: set/clear enable bit 16
uint8_t  pwm4_enable(uint8_t pwm, uint8_t logiclevel)
{
uint32_t reg,addr;
addr =G_pmw4_base + (pwm+1)*4;
if(pwm > MAXPWM || G_pmw4_base==0)
	{
	return(0);
	}
else
	{
	reg_32b_read(addr ,&reg ); // read register
	if(logiclevel ==1) 	reg_32b_write(addr , reg| 0x00010000 );  // set bit 16
	else reg_32b_write(addr,  reg & 0xFFFEFFFF); 				 // clear bit 16
	return(1);
	}
}

//read from pwm location and write beack: set/clear clear-bit 17
uint8_t  pwm4_clear(uint8_t pwm, uint8_t logiclevel)
{
uint32_t reg,addr;
addr =G_pmw4_base + (pwm+1)*4;
if(pwm > MAXPWM || G_pmw4_base==0)
	{
	return(0);
	}
else
	{
	reg_32b_read(addr ,&reg ); // read register
	if(logiclevel ==1) 	reg_32b_write(addr, reg| 0x00020000 );  // set bit 17
	else reg_32b_write(addr ,  reg & 0xFFFDFFFF); 				 // clear bit 17
	return(1);
	}
}



//read from pwm location and write beack: set/clear clear-bit 17
uint8_t  pwm4_setcycle(uint8_t pwm,uint16_t dutycycle)
{
uint32_t reg,addr;
addr =G_pmw4_base + (pwm+1)*4;
if(pwm > MAXPWM || G_pmw4_base==0)
	{
	return(0);
	}
else
	{
	reg_32b_read(addr,&reg ); // read register
	reg_32b_write(addr ,   (reg & 0xFFFF0000) + dutycycle);  	// set bit 15:0 as duty cycle
	return(1);
	}
}





