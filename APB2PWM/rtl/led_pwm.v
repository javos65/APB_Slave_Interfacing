
(* ORIG_MODULE_NAME="led_pwm", LATTICE_IP_GENERATED="0" *) module led_pwm (
input          	clk_in , 
input			rstn_in,
input			enable,
input   		[15:0]dc_in,
output         	pwm 
);


// Led pwm by clock, 16 bits
reg pwm_out;
reg [15:0] cycle_counter;
always @(posedge clk_in) begin
	if (!rstn_in) begin
		 pwm_out = 0;
		 cycle_counter = 0;
		end
	else begin
		if (enable)
			cycle_counter = cycle_counter+1;
		if (cycle_counter == 0)
			pwm_out = 0;
		if (cycle_counter == dc_in) 
			pwm_out=1;
		end
end

assign pwm = pwm_out;
 
endmodule

