-- UPD7220 GDP-VGA line counter
-- February 1, 2021   
-- T. LeMense
-- CC BY SA 4.0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity line_counter is port(
    enab  : in std_logic;   -- count and clear enable (hsync_fall)
    a16   : in std_logic;   -- A16 input (line counter clear)
    clk   : in std_logic;   -- sampling clock
    clr   : in std_logic;   -- asynch clear
    line  : out std_logic_vector (3 downto 0)  -- line count
);
end line_counter;

architecture arch of line_counter is
   process (clk,clr)
      variable   cnt         : integer range 0 to 15;
   begin
      if clr = '1' then
         cnt := 0;
      elsif rising_edge(clk) then   
         if enab = '1' then 
            if a16 = '1' then
               cnt := 0;            
            else
               cnt := cnt + 1;
            end if;
         end if;
      end if;
   line <= cnt;
   end process;
end arch;
