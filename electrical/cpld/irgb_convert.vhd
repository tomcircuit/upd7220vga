-- UPD7220 GDP-VGA IRGB->RRGGBB convert
-- January 29, 2021   
-- T. LeMense
-- CC BY SA 4.0

library ieee;
use ieee.std_logic_1164.all;

entity irgb_convert is port(
      irgb_i     : in   std_logic_vector(3 downto 0);   -- irgb input 
      rgb_o      : out  std_logic_vector(5 downto 0)    -- rrggbb output
);
end irgb_convert;

architecture dataflow of irgb_convert is
begin
   with irgb_i select
      rgb_o   <= "000001" when "0001",  -- navy
                 "000100" when "0010",  -- green
                 "000101" when "0011",  -- teal            
                 "010000" when "0100",  -- maroon
                 "010001" when "0101",  -- purple
                 "010100" when "0110",  -- olive
                 "010101" when "0111",  -- gray
                 "101010" when "1000",  -- silver
                 "000011" when "1001",  -- blue
                 "001100" when "1010",  -- lime
                 "001111" when "1011",  -- cyan
                 "110000" when "1100",  -- red
                 "110011" when "1101",  -- magenta
                 "001111" when "1110",  -- yellow
                 "111111" when "1111",  -- white
                 "000000" when others;  -- black
end dataflow;

-- define an RGB->RRGGBB converter, too
-- (in case we want different char background vs. foreground hues)

entity rgb_convert is port(
      rgb_i      : in   std_logic_vector(2 downto 0);   -- rgb input 
      rgb_o      : out  std_logic_vector(5 downto 0)    -- rrggbb output
);
end rgb_convert;

architecture dataflow of rgb_convert is
begin
   with rgb_i select
      rgb_o   <= "000001" when "001",   -- navy
                 "000100" when "010",   -- green
                 "000101" when "011",   -- teal            
                 "010000" when "100",   -- maroon
                 "010001" when "101",   -- purple
                 "010100" when "110",   -- olive
                 "010101" when "111",   -- gray
                 "000000" when others;  -- black
end dataflow;
