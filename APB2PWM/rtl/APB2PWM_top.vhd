-- --------------------------------------------------------------------
-- Revision History :
-- --------------------------------------------------------------------
-- Revision 1.0  1971-07-11
-- --------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity apb_to_mem is
   port (
      -- clk_i and rst_n_i are kept out of standard APB SLAVE I/F
      clk_i   : in  std_logic; -- PCLK
      rst_n_i : in  std_logic; -- PRESETn
      -- clk_i and rst_n_i are kept out of standard APB SLAVE I/F
      PSEL    : in  std_logic;
      PENABLE : in  std_logic;
      PADDR   : in  std_logic_vector(7 downto 0);
      PWRITE  : in  std_logic;
      PWDATA  : in  std_logic_vector(31 downto 0);
      PRDATA  : out std_logic_vector(31 downto 0);
      PREADY  : out std_logic;
      PSLVERR : out std_logic;
	  PWM0OUT : out std_logic;
	  PWM1OUT : out std_logic
	  
   );
end apb_to_mem;

architecture rtl_apb_to_mem of apb_to_mem is
    signal MEM_ADDR : std_logic_vector(3 downto 0) ; 
	signal REG0_ADDR : std_logic_vector(31 downto 0) ; -- Duty cycle PWM0
	signal REG1_ADDR : std_logic_vector(31 downto 0) ; -- Control register PWM0, bit0 = enable
	signal REG2_ADDR : std_logic_vector(31 downto 0) ;
	signal REG3_ADDR : std_logic_vector(31 downto 0) ;

	-- declare external PWM block
	component led_pwm
		port(
		clk_in  		: in  std_logic;
		rstn_in 		: in  std_logic;
		enable  		: in  std_logic;
		dc_in 		: in  std_logic_vector(15 downto 0);
		pwm 		: out std_logic
		);
	end component;

   type fsm_state is (IDLE_ST, SETUP_ST, WAIT_CYCLE_0_ST, WAIT_CYCLE_1_ST);
   signal fsm_st : fsm_state;

begin
	
   MEM_ADDR <= PADDR(3 downto 0); -- split of lower 3 bits of the bus

	PWM0_BLOCK_INST: led_pwm
		port map(
			clk_in		=> clk_i,
			rstn_in		=> rst_n_i,
			enable		=> REG1_ADDR(0),
			dc_in        => REG0_ADDR(15 downto 0),
			pwm 		=> PWM0OUT
		);

	PWM1_BLOCK_INST: led_pwm
		port map(
			clk_in		=> clk_i,
			rstn_in		=> rst_n_i,
			enable		=> REG3_ADDR(0),
			dc_in        => REG2_ADDR(15 downto 0),
			pwm 		=> PWM1OUT
		);

   --------------
   -- FSM process
   --------------
   FSM_PROC: process(rst_n_i, clk_i)
   begin
      if (rst_n_i = '0') then
			-- reset
         fsm_st  <= IDLE_ST;
         PREADY  <= '0';
         PSLVERR <= '0';
         PRDATA  <= (others => '0');

      elsif (clk_i = '1' and clk_i'event) then
         -- default
         PREADY  <= '0';
         PSLVERR <= '0';
         PRDATA  <= (others => '0');
         -- default
         case fsm_st is
            when IDLE_ST =>
               if ((PSEL = '1') and (PENABLE = '0')) then
						------------------------------
						-- SETUP state, after transfer
						------------------------------
						fsm_st  <= SETUP_ST;

						-- WRITE
						if (PWRITE = '1') then
							-- WRITE transfer
							case MEM_ADDR is
								when "0000" =>
									REG0_ADDR  <= PWDATA;
								when "0100" =>
									REG1_ADDR  <= PWDATA;
								when "1000" =>
									REG2_ADDR  <= PWDATA;									
								when "1100" =>
									REG3_ADDR  <= PWDATA;		
							end case	;		
							-- WRITE transfer no wait state
							PREADY  <= '1';
							PSLVERR <= '0';
						-- READ
						else
							-- READ transfer wait state due to MEM read
							PREADY  <= '0';
							PSLVERR <= '0';
						end if;
               end if;
            when SETUP_ST =>
               if ((PSEL = '1') and (PENABLE = '1')) then
						-------------------------------
						-- ACCCESS state, WRITE or READ
						-------------------------------
						-- WRITE
						if (PWRITE = '1') then
							-- WRITE transfer already done
							PREADY   <= '0';
							PSLVERR  <= '0';
							fsm_st   <= IDLE_ST;
						else
							-- READ transfer, wait 1 cycle, data from MEM
							PREADY  <= '0';
							PSLVERR <= '0';
							fsm_st  <= WAIT_CYCLE_0_ST;
						end if;
					end if;
				when WAIT_CYCLE_0_ST =>
					if ((PSEL = '1') and (PENABLE = '1') and (PWRITE = '0')) then
						-------------------
						-- WAIT state, READ
						-------------------
							case MEM_ADDR is
								when "0000" =>
									PRDATA <= REG0_ADDR;
								when "0100" =>
									PRDATA <= REG1_ADDR;
								when "1000" =>
									PRDATA <= REG2_ADDR;									
								when "1100" =>
									PRDATA <= REG3_ADDR ;		
							end case	;
						PREADY  <= '1';
						PSLVERR <= '0';
						fsm_st  <= WAIT_CYCLE_1_ST;
					end if;
            when WAIT_CYCLE_1_ST =>
					if ((PSEL = '1') and (PENABLE = '1') and (PWRITE = '0')) then
						-------------------
						-- IDLE state, READ
						-------------------
						PREADY  <= '0';
						PSLVERR <= '0';
						fsm_st  <= IDLE_ST;
					end if;
				when others =>
					fsm_st  <= IDLE_ST;
					PREADY  <= '0';
					PSLVERR <= '0';
         end case;
      end if;
   end process FSM_PROC;

end rtl_apb_to_mem;