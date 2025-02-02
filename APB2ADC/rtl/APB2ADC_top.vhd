-- --------------------------------------------------------------------
-- Revision History :
-- --------------------------------------------------------------------
-- Revision 1.0  1971-07-11
-- --------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity apb_to_adc is
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
	  alive 	  : out std_logic;
      -- extra ADC signals  
      pll_adc_i		: in  std_logic; -- PLL ADC clock
	  pll_fsm_i		: in  std_logic; -- PLL StateMachine clock
	  pll_lock_i		: in  std_logic; -- PLL lock
	  adc_dn0		: in  std_logic; -- 
	  adc_dn1		: in  std_logic; -- 
	  adc_dp0		: in  std_logic; -- 
	  adc_dp1		: in  std_logic  -- 
   );
end apb_to_adc;

architecture rtl_apb_to_adc of apb_to_adc is
	signal MEM_ADDR : std_logic_vector(2 downto 0) ; 
	--signal REG0_ADDR : std_logic_vector(31 downto 0) ; -- ADC0 - result - read only, no write 
	signal REG1_ADDR : std_logic_vector(31 downto 0) ; -- ADC0 - select
	--signal REG2_ADDR : std_logic_vector(31 downto 0) ; -- ADC1 - result - read only, no write 
	signal REG3_ADDR : std_logic_vector(31 downto 0) ; -- ADC1 - select

	-- declare external ADC block
	component adc_fsm 
		port(
		ADC0_12BIT : out  	std_logic_vector(11 downto 0);
		ADC1_12BIT : out  	std_logic_vector(11 downto 0); 
		ADC0_SELECT : in 	std_logic_vector(3 downto 0); 	
		ADC1_SELECT : in 	std_logic_vector(3 downto 0); 	 	
		
		ADC_DN0	: in  std_logic;
		ADC_DP0	: in  std_logic;
		ADC_DN1	: in  std_logic;
		ADC_DP1	: in  std_logic;
		alive_o	: out  std_logic;

		pll_pclk_50MHz_w		: in  std_logic;
		pll_sclk4_50MHz_w	: in  std_logic;
		pll_lock_w			: in  std_logic;
		resetn_i 			: in std_logic
		);
	end component;	

   -- signals to map 12 bit to 32 bit interfaces
   signal adc0_result : std_logic_vector(11 downto 0);
   signal adc1_result : std_logic_vector(11 downto 0);
   signal adc0_result_all : std_logic_vector(31 downto 0);
   signal adc1_result_all : std_logic_vector(31 downto 0);

   type fsm_state is (IDLE_ST, SETUP_ST, WAIT_CYCLE_0_ST, WAIT_CYCLE_1_ST);
   signal fsm_st : fsm_state;


begin

   adc0_result_all (11 downto 0) <= adc0_result;
   adc0_result_all (31 downto 12) <= x"00000";
   adc1_result_all (31 downto 12) <= x"00000";
   adc1_result_all (11 downto 0) <= adc1_result;

    MEM_ADDR <= PADDR(4 downto 2); -- split of 3 bits of the bus, lower 2 bis unused due to longword adressing
    -- assign ADC block
	ADC_BLOCK_INST: adc_fsm
		port map(
		ADC0_12BIT  => adc0_result,
		ADC1_12BIT  => adc1_result,
		ADC0_SELECT  => REG1_ADDR(3 downto 0),	
		ADC1_SELECT  => REG3_ADDR(3 downto 0), 	
		ADC_DN0  => adc_dn0,
		ADC_DP0  => adc_dp0,
		ADC_DN1  => adc_dn1,
		ADC_DP1  => adc_dp1,
		alive_o  => alive,
		pll_pclk_50MHz_w  => pll_fsm_i,
		pll_sclk4_50MHz_w => pll_adc_i,
		pll_lock_w	=> pll_lock_i,
		resetn_i => rst_n_i
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
							-- WRITE transfer  - no write to address 4 and c, aadres 8 and 10 are ADC_select
							case MEM_ADDR is
								when "010" =>
									REG1_ADDR  <= PWDATA;
								when "100" =>
									REG3_ADDR  <= PWDATA;
								when others => null;						
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
								when "000" => 	-- Address 0 = ID is 0xB19B00B3 - 32 bits, hard coded
									PRDATA <= x"B19B00B3";							
								when "001" =>
									PRDATA <= adc0_result_all;
								when "010" =>
									PRDATA <= REG1_ADDR;
								when "011" =>
									PRDATA <= adc1_result_all;									
								when "100" =>
									PRDATA <= REG3_ADDR ;
								when others => null;										
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

end rtl_apb_to_adc;