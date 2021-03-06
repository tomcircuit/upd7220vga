-- UPD7220 GDP-VGA pixel gating logic
-- February 9, 2021   
-- T. LeMense
-- CC BY SA 4.0

library ieee;
use ieee.std_logic_1164.all;

entity pixel_gate is port(
    d     : in std_logic;   -- output from pixel SR
    blank : in std_logic;   -- blanking output from GDP
    image : in std_logic;   -- image ouptut from GDP
    blink : in std_logic;   -- blinking ouptut from GDP
    battr : in std_logic;   -- blink attribute from SRAM
    clk   : in std_logic;   -- clock signal to hold gate signal
    ld    : in std_logic;   -- clock enable signal to hold gate signal
    q     : out std_logic   -- gated pixel signal (0 during blinking character inactive time)
);
end pixel_gate;

architecture arch of pixel_gate is
signal
   gate : std_logic;        -- gate control signal latched at same time as pixel shift reg
begin
   load_gate : process(clk)
   begin
      if rising_edge(clk) then
         if ld = '1' then
            gate <= '0' when ( blank or ((not image) and (not blink) and battr) ) else 1;
         end if;                          
       end if;
   end process load_gate;
   
   q <= d and gate;
   
end arch;

