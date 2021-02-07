--
-- UPD7220 GDP-VGA Clock Generator 
-- January 31, 2021   
-- T. LeMense
-- CC BY SA 4.0
--
-- Supports 1X and 2X ZOOM factors
-- assumes a 50MHz input
-- generates a 25 or 12.5MHz PCLK output (depending on zoom input)
-- generates 6.25MHz W2xCLK output (for GDP in MIXED mode)
-- generates a shifter-shader LOAD gate

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_gen is
   port(
      ale      : in   std_logic;            -- ALE signal from GDP
      zoom     : in   std_logic;            -- 2x ZOOM enable
      clr      : in   std_logic;            -- asynch clear 
      clk      : in   std_logic;            -- 50 MHz clock 
      w2clk    : out  std_logic;            -- 6.25 MHz W2xCLK output to GDP
      pclk     : out  std_logic;            -- pixel shift register clock
      pshift   : out  std_logic;            -- pixel shift register shift clock enable
      pload    : out  std_logic             -- pixel shift register load clock enable
end clock_gen;

architecture arch of clock_gen is
      signal clkdiv : std_logic_vector(2 downto 0);  -- clock divider output vector
      signal clk111_ale : std_logic;        -- state of ALE sampled on clock '111'
      signal clk011 : std_logic;            -- high during clk '011'
      signal clk100 : std_logic;            -- high during clk '100'
      signal clk111 : std_logic;            -- high during clk '111'      
      signal clk25 : std_logic;             -- 25 MHz clock
      signal clk12 : std_logic;             -- 12.5 MHz clock
   begin

   count8 : process (clk,clr)
      variable tick : integer range 0 to 8;
   begin
      if clr = '1' then
         tick := 0;         -- asynchronous clear
      elsif rising_edge(clk) then
         tick := tick + 1;  -- count up by 1
      end if;
      count <= tick;        -- assign value to count output 
   end process count8;
   
   clk111 < '1' when (count = "111") else '0';
   clk011 < '1' when (count = "011") else '0';
   clk100 < '1' when (count = "100") else '0';
   
   sample_ale : process(clk, clr1, clr2)
   begin
      if clr1 = '1' then
         clk111_ale <= '0';
      elsif clr2 = '1' then
         clk111_ale <= '0';
      elsif rising_edge(clk) then
         if clk0 = '1' then
            clk111_ale <= ale
         end if;
      end if;
   end process sample_ale;
   
   clk25 <= count(0);
   clk12 <= count(1);
   w2clk <= count(2);
      
   -- pclk output is 12.5MHz (2x ZOOM) or 25MHz (no ZOOM)
   pclk <= clk12 when zoom='1' else clk25;
      
   -- pixel shift gate is at 25MHz or 12.5MHz rate, depending on zoom
   pshift <= (clk25 and not clk12) when zoom='1' else (not clk25);
      
   -- shift register load gate 
   pload <= (not clk111_ale) and (not load_inh) and clk011;

end arch;

