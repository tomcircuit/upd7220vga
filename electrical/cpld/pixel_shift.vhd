-- pixel_shift; right shift with synch load enable and async clear
-- UPD7220 GDP-VGA 
-- February 10, 2021   
-- T. LeMense
-- CC BY SA 4.0

library ieee;
use ieee.std_logic_1164.all;

-- pixel_shift; right shift with synch load enable 
entity pixel_shift is port(
    d     : in std_logic_vector(15 downto 0);
    load  : in std_logic;          -- parallel load enable
    shift : in std_logic;          -- shift enable
    clk   : in std_logic;          -- master clock
    q0    : out std_logic          -- lsb shift output
);
end pixel_shift;

architecture arch of pixel_shift is
   signal sr : unsigned(15 downto 1);
begin
   process(clk)
   begin
      if rising_edge(clk) then
         if load = '1' then
            sr <= d(15 downto 1);
            q0 <= d(0);          
         elsif shift = '1' then         
            q0 <= sr(1);
            sr <= shift_right(sr, 1);
            sr(15) <= '0';
         end if;
      end if;
   end process;
end arch;

