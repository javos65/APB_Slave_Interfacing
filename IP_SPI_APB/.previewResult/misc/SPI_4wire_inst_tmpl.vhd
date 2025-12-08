component SPI_4wire_inst is
    port(
        clk_i: in std_logic;
        rst_n_i: in std_logic;
        sclk_i: in std_logic;
        PSEL: in std_logic;
        PENABLE: in std_logic;
        PADDR: in std_logic_vector(7 downto 0);
        PWRITE: in std_logic;
        PWDATA: in std_logic_vector(31 downto 0);
        PRDATA: out std_logic_vector(31 downto 0);
        PREADY: out std_logic;
        PSLVERR: out std_logic;
        SCLK: out std_logic;
        DC: out std_logic;
        CS: out std_logic;
        SDIN: out std_logic;
        RST: out std_logic
    );
end component;

__: SPI_4wire_inst port map(
    clk_i=>,
    rst_n_i=>,
    sclk_i=>,
    PSEL=>,
    PENABLE=>,
    PADDR=>,
    PWRITE=>,
    PWDATA=>,
    PRDATA=>,
    PREADY=>,
    PSLVERR=>,
    SCLK=>,
    DC=>,
    CS=>,
    SDIN=>,
    RST=>
);
