(* ORIG_MODULE_NAME="adc_fsm", LATTICE_IP_GENERATED="0" *) module adc_fsm (
    // Data interfacing
	output   [11:0]	ADC0_12BIT, 
	output   [11:0]	ADC1_12BIT, 
	input    [3:0]	ADC0_SELECT, 	
	input    [3:0]	ADC1_SELECT, 	
	// Analog IO
	input			ADC_DN0,
	input			ADC_DP0,
	input			ADC_DN1,
	input			ADC_DP1,
	// Alive output
	output 			alive_o,
	// PLL input
	input pll_pclk_50MHz_w,
	input pll_sclk4_50MHz_w,
	input pll_lock_w,
	input resetn_i
);


// fsm clock
wire adc_fab_clk_w;
assign adc_fab_clk_w = pll_pclk_50MHz_w;

// ADC signals
wire [11:0] adc0_out_w;
wire [11:0] adc1_out_w;
reg  [11:0] adc0_result_r;
reg  [11:0] adc1_result_r;
wire [11:0] adc_result_w;
wire		adc_conv_ongoing_w;
wire		adc_eoc_w;
wire		adc_calrdy_w;
reg			adc_resetn_r;
reg			adc_enable_r;
reg			adc_start_cnvt_r;
reg			adc_start_cal_r;

reg  [14:0]	adc_delay_r;
parameter ADC_DELAY_ZERO	= 15'd0 ;
parameter ADC_DELAY_INC		= 15'd1 ;
parameter ADC_DELAY_5		= 15'd5 ;
parameter ADC_DELAY_10		= 15'd10 ;
parameter ADC_DELAY_18		= 15'd18 ;

assign ADC0_12BIT = adc0_result_r;
assign ADC1_12BIT = adc1_result_r;


/////////////////////////////////////////////////////////////////////////////////////////
// ADC State Machine
// Clock = 50 MHz
/////////////////////////////////////////////////////////////////////////////////////////
reg [9:0]adc_state_r;

localparam ADC_ST_ENABLE			= 10'b0000000001;
localparam ADC_ST_RESET				= 10'b0000000010;
localparam ADC_ST_STUP_DLY			= 10'b0000000100;
localparam ADC_ST_START_CAL			= 10'b0000001000;
localparam ADC_ST_WAIT4CAL_DONE		= 10'b0000010000;
localparam ADC_ST_IDLE				= 10'b0000100000;
localparam ADC_ST_SAMPLE			= 10'b0001000000;
localparam ADC_ST_START_CNVT		= 10'b0010000000;
localparam ADC_ST_WAIT4CNVT_DONE	= 10'b0100000000;
localparam ADC_ST_UPDATE			= 10'b1000000000;

always @(posedge adc_fab_clk_w or negedge resetn_i) begin
	if(~resetn_i) begin
		adc_state_r			<= ADC_ST_ENABLE;
		adc0_result_r		<= 12'h001;
		adc1_result_r		<= 12'h800;
		adc_start_cnvt_r	<= 1'b0;
		adc_start_cal_r		<= 1'b0;
		adc_resetn_r		<= 1'b0;
		adc_enable_r		<= 1'b0;
		adc_delay_r			<= ADC_DELAY_ZERO;
	end

	else begin
		case(adc_state_r)
		ADC_ST_ENABLE : begin
			adc_enable_r	<= 1'b1;
			if(pll_lock_w == 1'b1) begin
				adc_state_r		<= ADC_ST_RESET;
			end
		end
		ADC_ST_RESET : begin
			adc_resetn_r		<= 1'b1;
			adc_state_r			<= ADC_ST_STUP_DLY;
		end
		ADC_ST_STUP_DLY : begin
			if(adc_delay_r < ADC_DELAY_18) begin
				adc_delay_r		<= adc_delay_r + ADC_DELAY_INC;
			end
			else begin
				adc_delay_r		<= ADC_DELAY_ZERO;
				adc_state_r		<= ADC_ST_START_CAL;
			end
		end
		ADC_ST_START_CAL : begin
			if(adc_delay_r < ADC_DELAY_5) begin
				adc_delay_r		<= adc_delay_r + ADC_DELAY_INC;
				adc_start_cal_r <= 1'b1;
			end
			else begin
				adc_delay_r		<= ADC_DELAY_ZERO;
				adc_state_r		<= ADC_ST_WAIT4CAL_DONE;
			end
		end
		ADC_ST_WAIT4CAL_DONE : begin
			adc_start_cal_r <= 1'b0;
			if (adc_calrdy_w == 1'b1) begin
				adc_state_r		<= ADC_ST_IDLE;
			end
		end
		
		ADC_ST_IDLE : begin
				adc_state_r		<= ADC_ST_SAMPLE;
		end
		
		// Set Start Convert Signal to sample the ADC input
		ADC_ST_SAMPLE : begin
			adc_start_cnvt_r	<=1'b1;
			adc_state_r			<= ADC_ST_START_CNVT;
		end

		// Reset Start Convert Signal to begin ADC conversion
		ADC_ST_START_CNVT : begin
			// Need a delay to meet minimum 4 ADC Clock Cycles
			if(adc_delay_r	< ADC_DELAY_10) begin
				adc_delay_r			<= adc_delay_r + ADC_DELAY_INC;
			end
			else begin
				adc_delay_r			<= ADC_DELAY_ZERO;
				adc_start_cnvt_r	<= 1'b0;
				adc_state_r			<= ADC_ST_WAIT4CNVT_DONE;
			end
		end

		// Wait for the conversion to finish
		ADC_ST_WAIT4CNVT_DONE : begin
			if(adc_eoc_w ==1'b1) begin
				adc_state_r		<= ADC_ST_UPDATE;
				adc_start_cnvt_r	<= 1'b1;
			end
		end

		// Store the result from each ADC 
		ADC_ST_UPDATE : begin
			adc0_result_r	<= adc0_out_w;
			adc1_result_r	<= adc1_out_w;
			adc_state_r		<= ADC_ST_SAMPLE;
		end

	endcase
	end
end




// Led blink by clock, 26 bits -> ~1sec @ 50Mhz
reg blink_out;
reg [25:0] cycle_counter;
always @(posedge pll_pclk_50MHz_w) begin
	if (!resetn_i) begin
		 blink_out = 1;
		 cycle_counter = 0;
		end
	else begin
		cycle_counter = cycle_counter+1; // counting
			if (cycle_counter[25]==1)
				blink_out = 0;
			else
				blink_out=1;
		end
end

//outout wire
assign alive_o = blink_out;


// ADC Instantiation
ADCBLOCK ADCBLOCK_Inst (
	// Clock & Reset Inputs
	.adc_clk_i		(pll_sclk4_50MHz_w), 
	.fab_clk_i		(adc_fab_clk_w), 
	.adc_resetn_i	(adc_resetn_r),
	
	// Digital Inputs
	.adc_en_i		(adc_enable_r), 
	.adc_cal_i		(adc_start_cal_r), 
	.adc_soc_i		(adc_start_cnvt_r), 
	.adc0_ch_sel_i	(ADC0_SELECT),   // ADC input Channel0 - DP0 
	.adc1_ch_sel_i	(ADC1_SELECT), 	// ADC input Channel1 - DTR - Temperature
	.adc_convstop_i	(1'b0),
	
	// Digital Outputs
	.adc0_o			(adc0_out_w), 
	.adc1_o			(adc1_out_w),
	.adc_cog_o		(adc_cog_w), 
	.adc_eoc_o		(adc_eoc_w),
	.adc_calrdy_o	(adc_calrdy_w), 
	
	// Analog Inputs
    .ADC_DN0		(ADC_DN0), 
    .ADC_DP0		(ADC_DP0),
    .ADC_DN1		(ADC_DN1), 
    .ADC_DP1		(ADC_DP1)
	) ;
		

endmodule