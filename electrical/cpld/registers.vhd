-- 1FF and 8FF and 16FF with load enable
-- 2Series Flip Flop with 2nd stage enable
-- UPD7220 GDP-VGA 
-- January 29, 2021   
-- T. LeMense
-- CC BY SA 4.0

library ieee;
use ieee.std_logic_1164.all;

-- reg1; 1ff with load enable
entity reg1 is port(
    d   : in std_logic;
    ld  : in std_logic; -- load/enable.
    clr : in std_logic; -- async. clear.
    clk : in std_logic; -- clock.
    q   : out std_logic
);
end reg1;

architecture arch of reg1 is
begin
    process(clk, clr)
    begin
        if clr = '1' then
            q <= '0';
        elsif rising_edge(clk) then
            if ld = '1' then
                q <= d;
            end if;
        end if;
    end process;
end arch;


-- reg6; 6FF with load enable
entity reg6 is port(
    d   : in std_logic_vector(5 downto 0);
    ld  : in std_logic; -- load/enable.
    clr : in std_logic; -- async. clear.
    clk : in std_logic; -- clock.
    q   : out std_logic_vector(5 downto 0)
);
end reg6;

architecture arch of reg6 is
begin
    process(clk, clr)
    begin
        if clr = '1' then
            q <= "000000";
        elsif rising_edge(clk) then
            if ld = '1' then
                q <= d;
            end if;
        end if;
    end process;
end arch;


-- reg8; 8FF with load enable
entity reg8 is port(
    d   : in std_logic_vector(7 downto 0);
    ld  : in std_logic; -- load/enable.
    clr : in std_logic; -- async. clear.
    clk : in std_logic; -- clock.
    q   : out std_logic_vector(7 downto 0)
);
end reg8;

architecture arch of reg8 is
begin
    process(clk, clr)
    begin
        if clr = '1' then
            q <= x"00";
        elsif rising_edge(clk) then
            if ld = '1' then
                q <= d;
            end if;
        end if;
    end process;
end arch;



-- reg16; 16FF with load enable
entity reg16 is port(
    d   : in std_logic_vector(15 downto 0);
    ld  : in std_logic; -- load/enable.
    clr : in std_logic; -- async. clear.
    clk : in std_logic; -- clock.
    q   : out std_logic_vector(15 downto 0)
);
end reg16;

architecture arch of reg16 is
begin
    process(clk, clr)
    begin
        if clr = '1' then
            q <= x"0000";
        elsif rising_edge(clk) then
            if ld = '1' then
                q <= d;
            end if;
        end if;
    end process;
end arch;

-- ser2ff; two series flip flops with clock enable on second stage.
-- This is intended to be used for the signals that are latched on 
-- falling edges of ALE and HSYNC. Concept: u0 samples the signal
-- on every rising clock edge. u1 captures u0 output on a rising
-- clock edge when ld is asserted. This avoids any chance of
-- setup or hold issues.
entity ser2ff is port(
    d   : IN STD_LOGIC;
    ld  : IN STD_LOGIC;  -- u1 enable.
    clr : IN STD_LOGIC;  -- async. clear.
    clk : IN STD_LOGIC;  -- clock.
    q   : OUT STD_LOGIC  -- output captured from previous clock, updated this clock
         );
end ser2ff;

architecture arch of ser2ff is
signal q0 : STD_LOGIC;

begin         
    u0 : reg1 port map (clk => clk,
                        d => d,
                        clr => clr,
                        ld => '1',
                        q => q0);
                           
    u1 : reg1 port map (clk => clk,
                        d => q0,
                        clr => clr,
                        ld => ld,
                        q => q);
end arch;
