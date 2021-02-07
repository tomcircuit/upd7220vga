-- UPD7220 GDP-VGA falling edge processing
-- January 29, 2021   
-- T. LeMense
-- CC BY SA 4.0

library ieee;
use ieee.std_logic_1164.all;

entity hsync_fall is port(
    hsync   : in std_logic;   -- ale signal from gdp
    a17     : in std_logic;   -- a17 is image at hsync falling edge
    clk     : in std_logic;   -- sampling clock
    clr     : in std_logic;   -- async. clear.
    hsync_f : out std_logic;  -- falling edge detected (active high) delayed by 2 clk cycles
    image   : out std_logic   -- a17 input latched at time of hsync fall
);
end hsync_fall;

architecture arch of hsync_fall is
begin
   signal
      hs0, hs1 : std_logic;   -- hsync signal samples
      a0, a1 : std_logic;     -- d input delay lines
      fall : std_logic;       -- high when falling edge detected  
      
   edge : process(clk, clr)   -- two-sample hsync falling edge detector
   begin
      if clr = '1' then       -- async clear 
         hs0 <= '0';
         hs1 <= '0';
         a0 <= '0';
         a1 <= '0';
     elsif rising_edge(clk) then    -- keep two samples of hsync and a17 
         hs0 <= hsync;        
         hs1 <= hs0;
         a0 <= a17;
         a1 <= a0;
     end if;
  end process edge;

  fall <= (not hs0) and hs1;    -- when newest hsync is low, previous is high, we have an edge
  hsync_f <= fall;  
    
  hold : process(clk, clr)      -- latch to hold A17 value (image bit) taken when hsync fell
  begin
     if clr = '1' then
         image <= '0';
     elsif rising_edge(clk) then
        if fall = '1' then
           image <= a1;
        end if;
     end if;
   end process hold;    
end arch;


entity ale_fall is port(
    ale     : in std_logic;   -- ALE signal from GDP
    a16     : in std_logic;   -- a16 input 
    a17     : in std_logic;   -- a17 input is cursor at ALE falling edge
    blank   : in std_logic;   -- BLANK input
    vsync   : in std_logic;   -- VSYNC input
    hsync   : in std_logic;   -- HSYNC input
    clk     : in std_logic;   -- sampling clock
    clr     : in std_logic;   -- async. clear.
    ale_f   : out std_logic;  -- ALE falling edge detected (active high) delayed by 2 clk cycles
    blink   : out std_logic;  -- a16 input latched at time of ALE fall
    cursor  : out std_logic;  -- a17 input latched at time of ALE fall
    qblank  : out std_logic;  -- blank input latched at time of ALE fall
    qvsync  : out std_logic;  -- vsync input latched at time of ALE fall
    qhsync  : out std_logic   -- hsync input latched at time of ALE fall    
);
end ale_fall;

architecture arch of ale_fall is
begin
   signal
      ale0, ale1 : std_logic; -- hsync signal samples
      a160, a161 : std_logic; -- a16 input delay lines
      a170, a171 : std_logic; -- a17 input delay lines
      bl0, bl1 : std_logic;   -- blank input delay lines
      vs0, vs1 : std_logic;   -- vsync input delay lines
      hs0, hs1 : std_logic;   -- hsync input delay lines      
      fall : std_logic;       -- high when falling edge detected  
      
   edge : process(clk, clr)   -- two-sample ale falling edge detector
   begin
      if clr = '1' then       -- async clear 
         ale0 <= '0';
         ale1 <= '0';
         a160 <= '0';
         a161 <= '0';
         a170 <= '0';
         a171 <= '0';
         bl0 <= '0';
         bl1 <= '0';
         vs0 <= '0';
         vs1 <= '0';
         hs0 <= '0';
         hs1 <= '0';
     elsif rising_edge(clk) then    -- keep two samples of ale and the sampled inputs
         ale0 <= ale;
         ale1 <= ale0;
         a160 <= a16;
         a161 <= a160;
         a170 <= a17;
         a171 <= a170;
         bl0 <= blank;
         bl1 <= bl0;
         vs0 <= vsync;        
         vs1 <= vs0;
         hs0 <= hsync;        
         hs1 <= hs0;
     end if;
  end process edge;

  fall <= (not ale0) and ale1;    -- when newest ale is low, previous is high, we have an edge
  ale_f <= fall;  
    
  hold : process(clk, clr)      -- latch to hold A17 value (image bit) taken when hsync fell
  begin
     if clr = '1' then
         image <= '0';
     elsif rising_edge(clk) then
        if fall = '1' then
           blink <= a161;
           cursor <= a171;
           qblank <= bl1;
           qvsync <= vs1;
           qhsync <= hs1;
        end if;
     end if;
   end process hold;    
end arch;



