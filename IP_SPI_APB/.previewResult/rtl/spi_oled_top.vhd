-- --------------------------------------------------------------------
-- Revision History :
-- --------------------------------------------------------------------
-- Revision 1.0  JayFox 2025
-- --------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity apb_to_spi is
   port (
      -- clk_i and rst_n_i are kept out of standard APB SLAVE I/F
      clk_i   : in  std_logic; -- PCLK
      rst_n_i : in  std_logic; -- PRESETn
	  sclk_i   : in  std_logic; -- seperate SPI-CLK
      -- clk_i and rst_n_i are kept out of standard APB SLAVE I/F
      PSEL    : in  std_logic;
      PENABLE : in  std_logic;
      PADDR   : in  std_logic_vector(7 downto 0);
      PWRITE  : in  std_logic;
      PWDATA  : in  std_logic_vector(31 downto 0);
      PRDATA  : out std_logic_vector(31 downto 0);
      PREADY  : out std_logic;
      PSLVERR : out std_logic;
	  -- spi ports
	  SCLK		: out std_logic;
	  DC		: out std_logic;
	  CS 		: out std_logic;
	  SDIN 		: out std_logic;
	  RST 		: out std_logic
   );
end apb_to_spi;

architecture rtl_apb_to_spi of apb_to_spi is
    -- APB Short address register
    signal MEM_ADDR : std_logic_vector(1 downto 0) ;  			-- Address register 2 bits = 4 32 bit locations :
    -- APB memory mapped  registers	
	signal REG0_ID : std_logic_vector(31 downto 0) ; 			-- 32 bit Memory b'00' read only : IP-ID for SPI
	signal REG1_STATUS : std_logic_vector(31 downto 0) ; 	    -- 32 bit Memory b'01' read only : bit [17] = error [16]=byte ready, [0] = spi ready
	signal REG2_CONTROL : std_logic_vector(31 downto 0) ; 		-- 32 bit Memory b'10' bit[0] = start send DATA0
	signal REG3_DATA0 : std_logic_vector(31 downto 0) ; 		-- 32 bit Memory b'11' write only :[31:9]XXX [8]C/~D [7:0] DATA
    -- SPI control FSM registers and signals
    signal DATA_IN : std_logic_vector(8 downto 0) ; 	
	signal READY : std_logic;
	signal START : std_logic;

	-- declare external SPI block for oled
	component spi_oled
		port(
		dclk_i  		: in  std_logic;
		rst_n_i 		: in  std_logic;
		start_in		: in  std_logic; 			-- handshake_in
		data_in			: in  std_logic_vector(8 downto 0);
		spi_clk			: out std_logic;
		spi_dnc			: out std_logic;
		spi_ncs			: out std_logic;
		spi_data		: out std_logic;
		spi_ready  		: out std_logic	;	  		-- handshake out
		spi_rst  		: out std_logic			
		);
	end component;

   type fsm1_state is (IDLE_ST, SETUP_ST, WAIT_CYCLE_0_ST, WAIT_CYCLE_1_ST);
   signal apb_control_st : fsm1_state;

   type fsm2_state is (IDLE_ST, WAIT_CYCLE_ST,WAIT_FOR_READY_ST);
   signal spi_control_st : fsm2_state;

begin
	
	MEM_ADDR <= PADDR(3 downto 2); -- split of 2 bits of the bus for decoding, bit0,1 are non 32bit aligned adresses : always zero

	SPI0_BLOCK_INST: spi_oled
		port map(
			dclk_i		=> sclk_i, 		-- Seperate clock for SPI
			rst_n_i		=> rst_n_i,
			start_in	=> START,
			data_in 	=> DATA_IN,
			spi_data	=> SDIN,		-- I/O pin
			spi_clk		=> SCLK,		-- I/O pin
			spi_dnc		=> DC,			-- I/O pin
			spi_ncs		=> CS,			-- I/O pin
			spi_ready  	=> READY,		-- Internal SPI READY signal
			spi_rst  	=> RST	
		);

		

   --------------
   -- FSM process : ABP interface
   --------------
   FSM_PROC: process(rst_n_i, clk_i)
   begin
      if (rst_n_i = '0') then
			-- reset
         apb_control_st  <= IDLE_ST;
         PREADY  <= '0';
         PSLVERR <= '0';
         PRDATA  <= (others => '0');
		 REG1_STATUS(31 downto 16) <= x"0000"; -- clear upper word in status register = SPI controller status

      elsif (clk_i = '1' and clk_i'event) then
         -- default
         PREADY  <= '0';
         PSLVERR <= '0';
         PRDATA  <= (others => '0');
         -- default
         case apb_control_st is
            when IDLE_ST =>
               if ((PSEL = '1') and (PENABLE = '0')) then
						------------------------------
						-- SETUP state, after transfer
						------------------------------
						apb_control_st  <= SETUP_ST;

						-- WRITE
						if (PWRITE = '1') then
							-- WRITE transfer - dont wait extra cycle !
							case MEM_ADDR is
								when "10" =>  -- memory mapped write register: CONTROL input
									REG2_CONTROL <= PWDATA; 
									if( READY = '1' AND PWDATA(0)='1' )  then		-- accept only byte start when ready : ok
										DATA_IN <= REG3_DATA0(8 downto 0);    	-- clock data in
										REG1_STATUS(16) <= '1';   				-- signal the SPI_controller : byte waiting
										REG1_STATUS(17) <= '0';   				-- clear error			
									end if;										
									if( READY = '0' AND PWDATA(0)='1' )  then 	-- accept only byte start when ready: not ok
										REG1_STATUS(17) <= '1';   				-- set error - starting while not ready
									end if;
								-- check bit[0], start SPI controller
								when "11" =>  -- memory mapped write register: DATA0 input
									REG3_DATA0  <= PWDATA;								
								when others => 
									null;			
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
							REG1_STATUS(16) <= '0'; -- clear byte waiting (!!)
							apb_control_st   <= IDLE_ST;
						else
							-- READ transfer, wait 1 cycle, data from MEM
							PREADY  <= '0';
							PSLVERR <= '0';
							apb_control_st  <= WAIT_CYCLE_0_ST;
						end if;
					end if;
				when WAIT_CYCLE_0_ST =>
					if ((PSEL = '1') and (PENABLE = '1') and (PWRITE = '0')) then
						-------------------
						-- WAIT state, READ
						-------------------
							case MEM_ADDR is
								when "00" =>				
									PRDATA <= x"B19B00B5";		-- Address 0x00 b'00' = ID is 0xB19B00B2 - 32 bits, hard coded				
								when "01" =>
									PRDATA <= REG1_STATUS;  	-- Address 0x04 b'01' = STATUS
								when "10" =>
									PRDATA <= REG2_CONTROL; 	-- Address 0x08 b'10' = CONTROL
								when "11" =>
									PRDATA <= REG3_DATA0; 		-- Address 0x0c b'10' = DATA0							
								when others =>
									PRDATA <= x"00000000";	
							end case	;
						PREADY  <= '1';
						PSLVERR <= '0';
						apb_control_st  <= WAIT_CYCLE_1_ST;
					end if;
            when WAIT_CYCLE_1_ST =>
					if ((PSEL = '1') and (PENABLE = '1') and (PWRITE = '0')) then
						-------------------
						-- IDLE state, READ
						-------------------
						PREADY  <= '0';
						PSLVERR <= '0';
						apb_control_st  <= IDLE_ST;
					end if;
			when others =>
					apb_control_st  <= IDLE_ST;
					PREADY  <= '0';
					PSLVERR <= '0';
         end case;
      end if;
   end process FSM_PROC;

   --------------
   -- FSM process : SPI CONTROL
   --------------
  SPI_CONTROL_PROC: process(rst_n_i, clk_i)
   begin
      if (rst_n_i = '0') then
			-- reset
         START <= '0';								-- clear Start signal
		 REG1_STATUS(15 downto 0) <= x"0000";    	-- clear lower word in status register = SPI core status
         spi_control_st  <= WAIT_FOR_READY_ST; 	-- go to wait for spi ready

      elsif (rising_edge(clk_i) ) then
         -- default

		 -- default
         case spi_control_st is
            when IDLE_ST  =>
               if (  REG1_STATUS(16)= '1' ) then 		-- check byte waiting in status register
			   			 START <= '1';
					     REG1_STATUS(0) <= '0'; -- clear spi ready bit
                        spi_control_st  <= WAIT_CYCLE_ST; 					 
			   else
						REG1_STATUS(0) <= '1';	 -- set spi ready status						
						spi_control_st  <= IDLE_ST;
               end if;
			   
			when WAIT_CYCLE_ST =>
						 --REG1_STATUS(1) <= '0'; -- clear byte waiting
						 START <= '0';
                        spi_control_st  <= WAIT_FOR_READY_ST; 	
						
            when WAIT_FOR_READY_ST  =>
				if ( READY = '1' ) then   			-- wait for spi signal ready
						REG1_STATUS(0) <= '1';		-- set spi ready status
						spi_control_st  <= IDLE_ST;
				else
						REG1_STATUS(0) <= '0';
						spi_control_st  <= WAIT_FOR_READY_ST;
				end if;
         end case;
      end if;
   end process SPI_CONTROL_PROC;

end rtl_apb_to_spi;