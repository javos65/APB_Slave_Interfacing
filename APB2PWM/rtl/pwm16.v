
(* ORIG_MODULE_NAME="pwm16", LATTICE_IP_GENERATED="0" *) module pwm16 (
input          	clk_in , 
input			rstn_in,
input			enable,
input			clear,
input   		[15:0]	dc_in,
output         	pwm 
);


// Led pwm by clock, 16 bits
reg pwm_out;
reg [15:0] cycle_counter;
always @(posedge clk_in) begin
	if (!rstn_in) begin
		 pwm_out = 1;
		 cycle_counter = 0;
		end
	else begin
		if (clear) begin
			cycle_counter = 0;
		    pwm_out = 1;			
			end
		else if (enable) begin
			if( dc_in == 16'hffff) // always on, no counting
				pwm_out=0;
			else if	( dc_in == 0) // always off, no counting
				pwm_out=1;
			else begin				
				cycle_counter = cycle_counter+1; // counting
				if (cycle_counter == 0)
					pwm_out = 0;
				if (cycle_counter == dc_in) 
					pwm_out=1;
			end // end if enable	
		end
	end
end

assign pwm = ~pwm_out;
 
endmodule

