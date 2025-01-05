-- --------------------------------------------------------------------
-- Revision History : 1.0.0
-- --------------------------------------------------------------------
-- Example code IP Pacakger LAttice Propel APB Bus
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
      PSLVERR : out std_logic
   );
end apb_to_mem;

architecture rtl_apb_to_mem of apb_to_mem is
    signal MEM_ADDR : std_logic_vector(2 downto 0) ; 		-- use 5 out of 7 address lines for long word address decoding:  effective 3 bits
	signal REG1_ADDR : std_logic_vector(31 downto 0) ;
	signal REG2_ADDR : std_logic_vector(31 downto 0) ;
	signal REG3_ADDR : std_logic_vector(31 downto 0) ;
	signal REG4_ADDR : std_logic_vector(31 downto 0) ;
	signal REG5_ADDR : std_logic_vector(31 downto 0) ;
	signal REG6_ADDR : std_logic_vector(31 downto 0) ;
	signal REG7_ADDR : std_logic_vector(31 downto 0) ;

   type fsm_state is (IDLE_ST, SETUP_ST, WAIT_CYCLE_0_ST, WAIT_CYCLE_1_ST);
   signal fsm_st : fsm_state;

begin
	
   MEM_ADDR <= PADDR(4 downto 2); -- split of 3 bits of the bus: lower 2 bits unused due to long word addressing.

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
								when "001" =>					-- Byte Address 0x04 onwards are Memory Location, Adress 0x0 is reserved for Id reading only
									REG1_ADDR  <= PWDATA;
								when "010" =>
									REG2_ADDR  <= PWDATA;									
								when "011" =>
									REG3_ADDR  <= PWDATA;		
								when "100" =>
									REG4_ADDR  <= PWDATA;
								when "101" =>
									REG5_ADDR  <= PWDATA;									
								when "110" =>
									REG6_ADDR  <= PWDATA;	
								when "111" =>
									REG7_ADDR  <= PWDATA;										
							end case;		
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
								when "000" =>		-- Address 0 = ID is 0xB19B00B1 - 32 bits, hard coded
									PRDATA <= x"B19B00B1";
								when "001" =>
									PRDATA <= REG1_ADDR;
								when "010" =>
									PRDATA <= REG2_ADDR;									
								when "011" =>
									PRDATA <= REG3_ADDR ;	
								when "100" =>
									PRDATA <= REG4_ADDR;
								when "101" =>
									PRDATA <= REG5_ADDR;									
								when "110" =>
									PRDATA <= REG6_ADDR ;	
								when "111" =>
									PRDATA <= REG7_ADDR ;																								
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