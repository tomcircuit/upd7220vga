-- UPD7220 GDP-VGA Shader Color MUX
-- February 1, 2021   
-- T. LeMense
-- CC BY SA 4.0

-- COLOR MUX is simply a 6-bit wide, 4-input MUX with some
-- logic to interpet C_BLANK, C_CURSOR, and L_IMAGE and decide
-- which color to use. Two instances of color mux are used;
-- one for 'active' and one for 'inactive' pixels (1 and 0
-- in the pixel SR, respectively)

library ieee;
use ieee.std_logic_1164.all;

entity color_mux is port(
      glyph    : in std_logic_vector(5 downto 0);
      apa      : in std_logic_vector(5 downto 0);
      cursor   : in std_logic_vector(5 downto 0);
      frame    : in std_logic_vector(5 downto 0);
      blank    : in std_logic;
      cursor   : in std_logic;
      image    : in std_logic;      
      color    : out std_logic_vector(5 downto 0)
);
end color_mux;

-- blank = GDP is in blanking (frame) portion of display
-- cursor = GDP is indicating that cursor shading is active
-- image = GDP is indicating that APA mode is active

architecture dataflow of color_mux is
signal
   sel : std_logic_vector(2 downto 0);
begin
   sel <= blank & image & cursor;
   with sel select
      color <= glyph  when "000",           -- glyph color when neither image, cursor, nor blanking
               cursor when "001",           -- cursor color when cursor but neither image nor blanking
               apa    when "010" | "011",   -- apa color when image but not blanking, ignore cursor
               frame  when others;          -- frame color otherwise (blanking)
end dataflow;


