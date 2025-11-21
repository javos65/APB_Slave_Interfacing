/*
 * nexus_adc.c
 *
 *  Created on: 5 Jan 2025
 *      Author: javos
 */

#include "nexus_adc.h"


uint32_t ADC_ADDRESS =0;

// initialise base memory address to Global variable ADC_ADDRES
// Or address is given (base<>0), or address is searched (base=0) at obvious locations
// RiscV Peripheral memory locations :0x00004000 (4K base mem) to 0x00042000 (256K base mem) in steps of 0x0400 (1K)
uint32_t adc_init(uint32_t base)
{
	uint32_t t;
	if (base == 0x00000000) // trigger ID search
	{
		for(t=0x00004000; t<0x00042000 ;t=t+0x00000400)
		{
			if ( *((volatile uint32_t *)(t)) == ADC_ID )
					{
					ADC_ADDRESS=t; // found, store base address
					t = 0x00080000; // end loop
					}
		}
		return(ADC_ADDRESS);
	}
	else		// Address is given as input
	{
		ADC_ADDRESS = base;
		return(ADC_ADDRESS);
	}
}

// get Base address LocalMem Peripheral
uint32_t adc_getbase()
{
	return(ADC_ADDRESS);
}


// write ADC select, location 0x08 or 0x10
uint8_t  adc_select(uint8_t adc,  uint8_t select)
{
if(adc> MAXADC || ADC_ADDRESS==0)
	{
	return(0);
	}
else
	{
	*( (volatile uint32_t *)(ADC_ADDRESS + (adc*2+2)*4) ) = (uint32_t) select;  	// set ADC select [3:0]
	return(1);
	}
}

// get raw ADC value
uint8_t adc_getraw(uint8_t adc, uint16_t *raw)
{
if(adc> MAXADC || ADC_ADDRESS==0)
	{
	return(0);
	}
else
	{
	*raw = (uint16_t) *( (volatile uint32_t *)(ADC_ADDRESS + (adc*2+1)*4) );	// get ADC value [11:0]
	return(1);
	}
}

// get raw adc value - unchecked
uint16_t adc_getraw_(uint8_t adc)
{
if(adc> MAXADC || ADC_ADDRESS==0)
	{
	return(0x8000); // return non-12bit number -1
	}
else
	{
	return( (uint16_t) *( (volatile uint32_t *)(ADC_ADDRESS + (adc*2+1)*4) ) );	// get ADC value [11:0]
	}
}



// get raw ADC value converted to mVolts
uint8_t adc_getmvolts(uint8_t adc, int32_t *mvolts)
{
uint32_t raw;
if(adc> MAXADC || ADC_ADDRESS==0)
	{
	return(0);
	}
else
	{
	raw = (uint16_t) *( (volatile uint32_t *)(ADC_ADDRESS + (adc*2+1)*4) );	// get ADC value [11:0]
	*mvolts = (int32_t) ((raw*VREF)/4096);
	return(1);
	}
}



// get raw ADC value converted to mVolts
uint8_t adc_getmcelcius(uint8_t adc, int32_t *mcelcius)
{
uint32_t raw;
if(adc!=1 || ADC_ADDRESS==0) // works only for ADC1 - Select 0xA
	{
	return(0);
	}
else
	{
	raw = (uint16_t) *( (volatile uint32_t *)(ADC_ADDRESS + (adc*2+1)*4) );	// get ADC value [11:0]
	*mcelcius = (int32_t) ( 440600 - (raw*VREF)/7);
	return(1);
	}
}

