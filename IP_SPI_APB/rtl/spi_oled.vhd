-- --------------------------------------------------------------------
-- Revision 2.0  JayFox 2025 
-- --------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity spi_oled is
   port (
      -- dclk_i and rst_n_i are kept out of standard APB SLAVE I/F
        dclk_i    : in  std_logic;  -- double clock, setting up SPI clock on half this speed.
        rst_n_i  : in  std_logic;   -- reset
        data_in   : in  std_logic_vector(8 downto 0) ; 	-- [8]:d/nc [7:0] byte to send	
        start_in : in  std_logic;   --
	  -- spi ports     
        spi_clk : out std_logic;
        spi_dnc : out std_logic;
        spi_ncs  : out std_logic;
        spi_data: out std_logic;
        spi_ready: out std_logic; -- spi
		spi_rst: out std_logic 
   );
end spi_oled;

architecture rtl_spi_oled of spi_oled is

   type spi_state is (IDLE_ST, 
                        SETUP_DATA7, SPI_DATA7, 
                        SETUP_DATA6, SPI_DATA6,
                        SETUP_DATA5, SPI_DATA5, 
                        SETUP_DATA4, SPI_DATA4, 
                        SETUP_DATA3, SPI_DATA3,
                        SETUP_DATA2, SPI_DATA2, 
                        SETUP_DATA1, SPI_DATA1, 
                        SETUP_DATA0, SPI_DATA0,                                                                                                 
                        STOP_SPI_ST);
   signal spi_st : spi_state;
   signal data_shadow : std_logic_vector(8 downto 0) ; 

begin
spi_rst <= rst_n_i;
--------------
   -- SPI process : SPI interface
--------------
   SPI_PROC: process(rst_n_i, dclk_i)
   begin
      if (rst_n_i = '0') then
			-- reset
         spi_ready  <= '1';
         spi_ncs  <= '1';
         spi_dnc  <= '0';
         spi_data <= '0';
		 spi_clk <= '0';
         spi_st  <= IDLE_ST;

      elsif (rising_edge(dclk_i) ) then
         -- default

		 -- default
         case spi_st is
            when IDLE_ST  =>
               if ( start_in = '1' ) then -- wait for start signal
						 data_shadow <= data_in; -- clock data to shadow register
			   			 spi_dnc <= data_in(8);  -- clock dnc to output
						 spi_ncs <= '0';    -- activate chip select						
                        spi_clk <= '0';
                        spi_data<= '0';
						 spi_ready<= '0';	-- signal spi is busy
                        spi_st  <= SETUP_DATA7; -- goto first bit						 
			   else
						 spi_ncs <= '1';    -- idle mode spi					
                        spi_clk <= '0';
                        spi_data<= '0';
						 spi_ready<= '1';                        
						 spi_st  <= IDLE_ST;
               end if;

            when SETUP_DATA7  =>
                spi_clk <= '0';
                spi_data <= data_shadow(7); -- setup data7
                spi_st  <= SPI_DATA7;
			when SPI_DATA7  =>
                spi_clk <= '1';  -- clock data7
                spi_st  <= SETUP_DATA6;

            when SETUP_DATA6  =>
                spi_clk <= '0';
                spi_data <= data_shadow(6); -- setup data6
                spi_st  <= SPI_DATA6;
			when SPI_DATA6  =>
                spi_clk <= '1';  -- clock data6
                spi_st  <= SETUP_DATA5;

            when SETUP_DATA5  =>
                spi_clk <= '0';
                spi_data <= data_shadow(5); -- setup data5
                spi_st  <= SPI_DATA5;
			when SPI_DATA5  =>
                spi_clk <= '1';  -- clock data5
                spi_st  <= SETUP_DATA4;

           when SETUP_DATA4  =>
                spi_clk <= '0';
                spi_data <= data_shadow(4); -- setup data4
                spi_st  <= SPI_DATA4;
			when SPI_DATA4  =>
                spi_clk <= '1';  -- clock data4
                spi_st  <= SETUP_DATA3;

            when SETUP_DATA3 =>
                spi_clk <= '0';
                spi_data <= data_shadow(3); -- setup data3
                spi_st  <= SPI_DATA3;
			when SPI_DATA3  =>
                spi_clk <= '1';  -- clock data3
                spi_st  <= SETUP_DATA2;

            when SETUP_DATA2  =>
                spi_clk <= '0';
                spi_data <= data_shadow(2); -- setup data2
                spi_st  <= SPI_DATA2;
			when SPI_DATA2  =>
                spi_clk <= '1';  -- clock data2
                spi_st  <= SETUP_DATA1;

            when SETUP_DATA1  =>
                spi_clk <= '0';
                spi_data <= data_shadow(1); -- setup data1
                spi_st  <= SPI_DATA1;
			when SPI_DATA1  =>
                spi_clk <= '1';  -- clock data1
                spi_st  <= SETUP_DATA0;

           when SETUP_DATA0  =>
                spi_clk <= '0';
                spi_data <= data_shadow(0); -- setup data0
                spi_st  <= SPI_DATA0;
			when SPI_DATA0  =>
                spi_clk <= '1';  -- clock data0
                spi_st  <= STOP_SPI_ST;

            when STOP_SPI_ST  =>
				 spi_ncs <= '1';    -- idle mode spi				
                spi_dnc <= '0';
                spi_clk <= '0';
                spi_data <= '0';
                spi_ready <= '1';  -- signal spi is ready
                spi_st  <= IDLE_ST;

         end case;
      end if;
   end process SPI_PROC;

end rtl_spi_oled;
