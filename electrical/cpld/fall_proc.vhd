-- UPD7220 GDP-VGA simulated falling edge triggered DFF
-- February 8, 2021   
-- T. LeMense
-- CC BY SA 4.0

library ieee;
use ieee.std_logic_1164.all;

entity fall_reg1 is port(
    gate    : in std_logic;   -- gating signal (falling edge 'clock' input)
    d       : in std_logic;   -- input signal (to be sampled at falling edge)
    clk     : in std_logic;   -- sampling clock
    clr     : in std_logic;   -- async. clear.
    q       : out std_logic;  -- input signal latched at/near fall of gate    
    fall    : out std_logic;  -- falling edge detected (active high) delayed by 2 clk cycles
    sync    : out std_logic   -- synchronized gate signal (delayed by 1 clk cycle)
);
end fall_reg1;

architecture arch of fall_reg1 is
begin
   signal
      g0, g1 : std_logic;     -- gate input delay lines
      d0, d1 : std_logic;     -- d input delay lines
      
   edge : process(clk, clr)   -- two-sample hsync falling edge detector
   begin
      if clr = '1' then       -- async clear 
         g0 <= '0';
         g1 <= '0';
     elsif rising_edge(clk) then    -- keep two samples of hsync and a17 
         g0 <= gate;        
         g1 <= g0;
     end if;
  end process edge;

  sync <= g0;                 -- supply a synchronized gate signal
  fall <= (not g0) and g1;    -- when newest gate is low and previous is high, falling edge has occurred
    
  capt : process(clk, clr)    -- capture d values while gate is high
  begin
     if clr = '1' then
         d0 <= '0';
     elsif rising_edge(clk) then    -- capture d input while gate is high
        if gate = '1' then
           d0 <= d;
        end if;
     end if;
   end process capt;    

  hold : process(clk, clr)    -- sample d0 signal while gate is low
  begin
     if clr = '1' then
         d1 <= '0';
     elsif rising_edge(clk) then    -- udpate d1 output while gate is low
        if gate = '0' then
           d1 <= d0;
        end if;
     end if;
   end process hold;    
   
   q <= d1;                 -- q = d sampled while gate is high, but updated only while gate is low
   
end arch;
