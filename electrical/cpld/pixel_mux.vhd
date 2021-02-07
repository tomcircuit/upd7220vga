-- UPD7220 GDP-VGA Pixel MUX
-- February 1, 2021   
-- T. LeMense
-- CC BY SA 4.0

-- PIXEL MUX is simply a 2-input MUX with 6-bit registered
-- inputs. 

library ieee;
use ieee.std_logic_1164.all;

entity pixel_mux is port(
      acolor   : in std_logic_vector(5 downto 0);
      icolor   : in std_logic_vector(5 downto 0);
      pixel    : in std_logic;
      ld       : in std_logic;
      clk      : in std_logic;      
      q        : out std_logic_vector(5 downto 0)
);
end pixel_mux;

architecture arch of pixel_mux is
signal
      areg : std_logic_vector(5 downto 0);
      ireg : std_logic_vector(5 downto 0);
begin

   process(clk)
   begin
      if rising_edge(clk) then
         if ld = '1' then
            areg <= acolor;
            ireg <= icolor;
         end if;
      end if;
   end process;

   with pixel select
      q <= areg when '1',
           ireg when others;
      
end arch;


