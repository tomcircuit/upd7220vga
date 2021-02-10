-- 1FF and 8FF and 16FF with load enable
-- UPD7220 GDP-VGA 
-- February 10, 2021   
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
