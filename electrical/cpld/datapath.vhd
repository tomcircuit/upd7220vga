-- UPD7220 GDP-VGA datapath
-- February 1, 2021   
-- T. LeMense
-- CC BY SA 4.0

library ieee;
use ieee.std_logic_1164.all;

-- define the SRAM Address MUX used within the datapath

entity sram_addr_mux is port(
      gbank : in std_logic_vector(3 downto 0);
      glyph : in std_logic_vector(7 downto 0);
      line  : in std_logic_vector(3 downto 0);
      gdpad : in std_logic_vector(15 downto 0); 
      sel   : in std_logic_vector(1 downto 0);
      q     : out std_logic_vector(15 downto 0)
);
end sram_addr_mux;

architecture dataflow of sram_addr_mux is
begin
   with sel select
      q <= gbank & glyph & line when "01",          -- address into glyph table
           "11111111111111" & gdpad(1 downto 0) when "10",  -- 0xFFFx config address (FFFC,FFFD,FFFE,FFFF)
           gdpad when others;                       -- latched GDP address otherwise
end dataflow;

-- structural definition of datapath 
entity datapath is port(
    ad_bus     : in std_logic_vector(15 downto 0);     -- AD from GDP & external 64K x 16 SRAM DATA bus
    mux_sel    : in std_logic_vector(1 downto 0);      -- SRAM ADDR MUX control inputs    
    l_count    : in std_logic_vector(3 downto 0);      -- Glyph Line Counter inputs
    ld_gpad    : in std_logic;                         -- LOAD GDP ADDRESS register
    ld_lsb     : in std_logic;                         -- LOAD LSB DATA register
    ld_msb     : in std_logic;                         -- LOAD MSB and GLYPH registers
    ld_conf    : in std_logic;                         -- LOAD CONFIG register    
    clr        : in std_logic;                         -- async. clear.
    clk        : in std_logic;                         -- clock
    pq         : out std_logic_vector(15 downto 0);    -- output of pixel datapath
    ram_addr   : out std_logic_vector(15 downto 0);    -- external 64K x 16 SRAM ADDRESS bus
    cfg0_data  : out std_logic_vector(15 downto 0);    -- CONFIG0 contents
    cfg1_data  : out std_logic_vector(15 downto 0);    -- CONFIG1 contents
    cfg2_data  : out std_logic_vector(15 downto 0);    -- CONFIG2 contents
    cfg3_data  : out std_logic_vector(15 downto 0)     -- CONFIG3 contents
);
end datapath;

architecture struct of datapath is
   signal ld_cfg0  : std_logic;
   signal ld_cfg1  : std_logic;   
   signal ld_cfg2  : std_logic;
   signal ld_cfg3  : std_logic;   
   signal gl_bank  : std_logic_vector(3 downto 0);
   signal gl_num   : std_logic_vector(7 downto 0);
   signal gdp_addr : std_logic_vector(15 downto 0);
   
begin
   sam : sram_addr_mux port map (   -- SRAM Address Mux
      gbank => gl_bank,
      glyph => gl_num,
      line => l_count,
      gdpad => gdp_addr,
      sel => mux_sel,
      q => ram_addr
   );
   
   gl_bank <= cfg0_data(15 downto 12);      -- upper 4 bits of CFG0 are Glyph Bank
   
   reg_gdpad : reg16 port map (     -- GDP Address Register
      d => ad_bus,
      ld => ld_gdpad,
      clr => clear, 
      clk => clk,
      q => gdp_addr
   );
       
   reg_glnum : reg8 port map (      -- Glyph Number Register (CHAR Glyph Number)
      d => ad_bus(7 downto 0),
      ld => ld_msb,
      clr => clear, 
      clk => clk,
      q => glyph_num
   );

   reg_msb : reg8 port map (        -- MSB Data Register (CHAR ATTR, APA high order pixels)
      d => ad_bus(15 downto 8),
      ld => ld_msb,
      clr => clear, 
      clk => clk,
      q => msb_data
   );

   reg_lsb : reg8 port map (        -- LSB Data Register (CHAR Glyph pixels, APA low order pixels)
      d => ad_bus(7 downto 0),
      ld => ld_lsb,
      clr => clear, 
      clk => clk,
      q => msb_data
   );
   
   pq(15 downto 8) <= msb_data;     -- datapath output MSB (CHAR ATTR, APA high order pixels)
   pq(7 downto 0) <= lsb_data;      -- datapath output LSB (CHAR Glyph pixels, APA low order pixels)

   -- CONFIG register selection logic (uses 2 LSB od GDP address to select register to load)
   ld_cfg0 <= '1' when ( (ld_cfg = '1') and (gdp_addr(1 downto 0) = "00") ) else '0';
   ld_cfg1 <= '1' when ( (ld_cfg = '1') and (gdp_addr(1 downto 0) = "01") ) else '0';
   ld_cfg2 <= '1' when ( (ld_cfg = '1') and (gdp_addr(1 downto 0) = "10") ) else '0';
   ld_cfg3 <= '1' when ( (ld_cfg = '1') and (gdp_addr(1 downto 0) = "11") ) else '0';

   reg_cfg0 : reg16 port map (      -- CONFIG0 register
      d => ad_bus,
      ld => ld_cfg0,
      clr => clear, 
      clk => clk,
      q => cfg0_data
   );

   reg_cfg1 : reg16 port map (      -- CONFIG1 register
      d => ad_bus,
      ld => ld_cfg1,
      clr => clear, 
      clk => clk,
      q => cfg1_data
   );
   
   reg_cfg2 : reg16 port map (      -- CONFIG2 register
      d => ad_bus,
      ld => ld_cfg1,
      clr => clear, 
      clk => clk,
      q => cfg2_data
   );

   reg_cfg3 : reg16 port map (      -- CONFIG3 register
      d => ad_bus,
      ld => ld_cfg1,
      clr => clear, 
      clk => clk,
      q => cfg3_data
   );

end struct ;
