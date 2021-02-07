-- UPD7220 GDP-VGA Top Level
-- February 1, 2021   
-- T. LeMense
-- CC BY SA 4.0

library ieee;
use ieee.std_logic_1164.all;

-- Toplevel Entity for GDP-VGA CPLD

entity gdp_vga_top is port(
-- master clock
      clk50    : in std_logic;             -- 50 MHz clock input
-- interface to GDP
      ad_bus   : in std_logic_vector(15 downto 0);   -- GDP address/data bus + SRAM data bus
      a16      : in std_logic;             -- GDP A16
      a17      : in std_logic;             -- GDP A17
      ale      : in std_logic;             -- GDP ALE
      dbin_l   : in std_logic;             -- GDP DBIN (active low)
      blank    : in std_logic;             -- GDP BLANK
      hsync    : in std_logic;             -- GDP HSYNC
      vsync    : in std_logic;             -- GDP VSYNC
      w2clk_o  : out std_logic;            -- GDP W2xCLK
      gdpbuf_l : out std_logic;            -- GDP AD buffer enable (active low)
-- interface to SRAM      
      ram_addr : out std_logic_vector(15 downto 0);     -- SRAM address bus
      ram_cs_l : out std_logic;            -- SRAM chip select (active low)      
      ram_oe_l : out std_logic;            -- SRAM output enable (active low)
      ram_we_l : out std_logic;            -- SRAM write enable (active low)      
      ram_lb_l : out std_logic;            -- SRAM low byte enable (active low)
      ram_hb_l : out std_logic;            -- SRAM high byte enable (active low)
-- interface to host
      h_rst_l  : in std_logic;             -- RESET signal from host (active low)
      h_sel_l  : in std_logic;             -- SEL signal from host (active low)
      h_rd_l   : in std_logic;             -- READ signal from host (active low)
      h_wr_l   : in std_logic;             -- WRITE signal from host (active low)
      h_addr   : in std_logic_vector(3 downto 0);     -- host A4, A5, A6 and A7
      h_int    : out std_logic;            -- host interrupt signal
-- VGA output      
      red_o    : out std_logic_vector(1 downto 0);    -- red hue output
      green_o  : out std_logic_vector(1 downto 0);    -- green hue output 
      blue_o   : out std_logic_vector(1 downto 0);    -- blue hue output       
      hsync_o  : out std_logic;            -- horiz sync output
      vsync_o  : out std_logic;            -- vert sync output
      pclk_o   : out std_logic;            -- pixel clock output
      pixel_o  : out std_logic;            -- raw pixel output
-- debug
      debug    : out std_logic_vector(7 downto 0)     -- debug output pins
);
end gdp_vga_top;

-- s_xxxx are signals from GDP that are synchronized to clk50 domain. e.g. s_ale
-- f_xxxx are signals that are high for one CLK50 pulse when falling edge is detected. e.g. f_ale
-- c_xxxx are signals from GDP that are valid for current display cycle.  e.g. c_blank
-- l_xxxx are signals from GDP that are valid for current dipslay line. e.g. l_image
-- v_xxxx are 6-bit color signals
-- cfg_xxxx are control signals from the CONFIG registers.

architecture arch of gdp_vga_top is
   signal clear                           : std_logic;   -- master clear signal
   signal w2clk, s_w2clk, f_w2clk         : std_logic;   -- inernal w2clk   
   signal s_dbin, s_ale, f_ale            : std_logic;   -- synchronized dbin, processed ale
   signal c_hsync, c_vsync, f_hsync       : std_logic;   -- processed H and V synch signals   
   signal c_blink, c_cursor, c_blank      : std_logic;   -- character control signals 
   signal l_image                         : std_logic;   -- display line is APA mode 
   signal l_count                         : std_logic_vector(3 downto 0);   -- glyph line counter
   signal samux_sel                       : std_logic_vector(1 downto 0);   -- SRAM Address source mux
   signal ld_gpad, ld_lsb, ld_msb         : std_logic;   -- datapath register load clock enables
   signal ld_cfg, ld_conf                 : std_logic;   -- datapath register load clock enables
   signal pixel_word                      : std_logic_vector(15 downto 0);  -- word-wide pixel output from datapath
   signal pclk, pload_inh, pload, pshift  : std_logic;   -- pixel path signals 
   signal raw_pixel, pixel                : std_logic;   -- raw (ungated) final pixel (active/inactive)
   signal cfg0_data, cfg1_data            : std_logic_vector(15 downto 0);  -- CONFIG0 and 1 contents
   signal cfg2_data, cfg3_data            : std_logic_vector(15 downto 0);  -- CONFIG2 and 3 contents
   signal cfg_zoom, cfg_graphic           : std_logic;   -- ZOOM and GRAPHIC config bits
   signal cfg_hpol, cfg_vpol              : std_logic;   -- HSYNC and VSYNC polarity control
   signal p_hsync, p_vsync                : std_logic;   -- polarity corrected HSYNC and VSYNC   
   signal v_frame, v_cursor               : std_logic_vector(5 downto 0);   -- FRAME and CURSOR RRGGBB colors
   signal v_point, v_canvas               : std_logic_vector(5 downto 0);   -- APA POINT and CANVAS RRGGBB colors
   signal v_glon, v_gloff                 : std_logic_vector(5 downto 0);   -- GLYPH 'on' and 'off' colors
   signal v_inactive, v_active            : std_logic_vector(5 downto 0);   -- MUX'd 'active' and 'inactive' colors
   signal v_pixel                         : std_logic_vector(5 downto 0);   -- pixel color
   signal attr_blink                      : std_logic;   -- glyph blinking attribute

begin                 
   clk0 : clock_gen port map (              -- clock generator 
      clear    => clear,                    -- master clear
      ale      => s_ale,                    -- synchronized ALE
      zoom     => cfg_zoom,                 -- ZOOM control bit
      graphic  => cfg_graphic,              -- GRAPHIC mode control bit
      clk      => clk50,                    -- master clock
      w2clk    => w2clk,                    -- W2xCLK (6.25MHz or 3.13MHz depending on GRAPHIC)
      pclk     => pclk,                     -- pixel clock output (25M or 12.5M depending on ZOOM)
      pshift   => pshift                    -- pixel shift gate output
   );
   
   w2clk_o <= w2clk;                        -- drive W2xCLK output to GDP
   
   w2f0 : fall_proc port map (              -- W2CLK falling edge detection (shift register load)
      d        => w2clk,                    -- W2CLK signal from clock generator
      clk      => clk50,                    -- master clock
      clr      => clear,                    -- master clear
      fall     => f_w2clk,                  -- W2CLK falling edge pulse (1 CLK50 period high)
      sync     => s_w2clk                   -- delayed W2CLK (not really needed for anything)
   );
   
   alef0 : fall_proc port map (             -- ALE synchronization and falling edge detection
      d        => ale,                      -- ALE signal from GDP
      clk      => clk50,                    -- master clock
      clr      => clear,                    -- master clear
      fall     => f_ale,                    -- ALE falling edge pulse (1 CLK50 period high)
      sync     => s_ale                     -- synchronized ALE output 
   );

   pload <= f_w2clk and not s_ale;          -- load shift register when W2CLK falls while delayed ALE is low
                                            -- per Intel 82720 Applications Manual, p. 2-7
   
   blir0 : reg1 port map (                  -- obtain BLINK signal 
      d        => a16,                      -- BLINK appears on A16 at ALE falling
      ld       => f_ale,                    -- load on falling of ALE
      clk      => clk50,                    -- master clock
      clr      => clear,                    -- master clear
      q        => c_blink                   -- synchronized BLINK output 
   );

   curr0 : reg1 port map (                  -- obtain CURSOR signal 
      d        => a17,                      -- CURSOR appears on A17 at ALE falling
      ld       => f_ale,                    -- load on falling of ALE
      clk      => clk50,                    -- master clock
      clr      => clear,                    -- master clear
      q        => c_cursor                  -- synchronized CURSOR output 
   );

   blnk0 : reg1 port map (                  -- synchronize BLANK signal 
      d        => blank,                    -- BLANK signal from GDP
      ld       => f_ale,                    -- load on falling of ALE
      clk      => clk50,                    -- master clock
      clr      => clear,                    -- master clear
      q        => c_blank                   -- synchronized BLANK output 
   );

   hsf0 : fall_proc port map (              -- HSYNC syncronization and falling edge detection
      d        => hsync,                    -- HSYNC signal from GDP
      clk      => clk50,                    -- master clock
      clr      => clear,                    -- master clear
      fall     => f_hsync,                  -- hsync falling edge pulse (1 CLK50 period high)
      sync     => c_hsync                   -- synchronized HSYNC output 
   );

   ima0 : reg1 port map (                   -- obtain IMAGE signal 
      d        => a17,                      -- IMAGE appears on A17 at HSYNC falling
      ld       => f_hsync,                  -- load on falling of HSYNC
      clk      => clk50,                    -- master clock
      clr      => clear,                    -- master clear
      q        => c_blank                   -- synchronized IMAGE output 
   );

   vs0 : reg1 port map (                    -- synchronize VSYNC signal 
      d        => vsync,                    -- VSYNC signal from GDP
      ld       => '1',                      -- always enable clock
      clk      => clk50,                    -- master clock
      clr      => clear,                    -- master clear
      q        => c_vsync                   -- synchronized VSYNC output 
   );
   
   dbin0 : reg1 port map (                  -- synchronize DBIN signal
      d        => dbin_l,                   -- DBIN signal from GDP (active low)
      ld       => '1',                      -- always enable clock
      clk      => clk50,                    -- master clock
      clr      => clear,                    -- master clear
      q        => s_dbin                    -- synchronized DBIN output 
   );

   lc0 : line_counter port map (            -- Glyph line counter (up to 15 lines/glyph)
      enab     => f_hsync,                  -- count/clear after HSYNC falls
      a16      => a16,                      -- clear line counter if A16 is asserted when HSYNC falls 
      clk      => clk50,                    -- master clock
      clr      => clear,                    -- master clear
      line     => l_count                   -- line counter output
   );
   
   data0 : datapath port map (
      ad_bus    => ad_bus,                  -- addr/data bus from GDP and external SRAM
      samux     => samux_sel,               -- SRAM addr MUX control
      l_count   => l_count,                 -- glyph line counter
      cfg_ld    => ld_cfg,                  -- CONFIGx register clock enable
      msb_ld    => ld_msb,                  -- MSB/GLYPH pixel register clock enable
      lsb_ld    => ld_lsb,                  -- LSB data clock enable
      gdpad_ld  => ld_gdpad,                -- GDP ADDR register clock enable
      clear     => clear,                   -- master clear
      clk       => clk50,                   -- master clock
      pq        => pixel_word,              -- output of pixel datapath
      sram_addr => ram_addr,                -- external SRAM address bus
      cfg0_data => cfg0_data,               -- config0 register contents
      cfg1_data => cfg1_data,               -- config1 register contents
      cfg2_data => cfg2_data,               -- config2 register contents
      cfg3_data => cfg3_data                -- config3 register contents
   );
   
   attr_blink <= pixel_word(15);            -- pull character blinking from attribute byte
                                            
   cfg_zoom <= cfg1_data(15);               -- ZOOM control is CFG1(15)
   cfg_hpol <= cfg1_data(14);               -- hsync pol is CFG1(14) 
   cfg_vpol <= cfg1_data(13);               -- vsync pol is CFG1(13) 
   cfg_graphic <= cfg1_data(12);            -- GRAPHIC is CFG1(12) ###not supported yet!###
   cfg_point <= cfg1_data(11 downto 6);     -- APA POINT color is CFG1(11:6)
   cfg_canvas <= cfg1_data(5 downto 0);     -- APA CANVAS color is CFG1(5:0)
   -- cfg0_data(15 downto 12) are GLYPH TABLE BANK and handled within datapath
   cfg_cursor <= cfg0_data(11 downto 6);    -- CHAR cursor color is CFG0(11:6)
   cfg_frame <= cfg0_data(5 downto 0);      -- FRAME color is CFG0(5:0)
   
   mem0 : memory_fsm port map (             -- memory controller
      clk      => clk50,                    -- master clock
      s_ale    => ale_s,                    -- synchronized ALE
      s_dbin   => dbin_s,                   -- synchronized DBIN
      l_image  => l_image,                  -- IMAGE flag for current display line
      w2clk    => w2clk,                    -- w2xCLK from clock gen
      clear    => clear,                    -- master clear
      samux    => samux_sel,                -- SRAM addr MUX control
      cfg_ld   => ld_cfg,                   -- CONFIGx register clock enable
      msb_ld   => ld_msb,                   -- MSB/GLYPH pixel register clock enable
      lsb_ld   => ld_lsb,                   -- LSB data clock enable
      gdpad_ld => ld_gdpad,                 -- GDP ADDR register clock enable
      load_inh => pload_inh,                -- pixel shader/shifter load inhibit
      ram_oe_l => ram_oe_l,                 -- external SRAM OE control (active low)
      ram_we_l => ram_we_l,                 -- external SRAM WE control (active low)
      gdpbuf_l => gdpbuf_l                  -- GDP translator buffer enable (active low)
   );
   
   ram_cs_l <= '0';                         -- SRAM chip select (active low)      
   ram_lb_l <= '0';                         -- SRAM low byte enable (active low)
   ram_hb_l <= '0';                         -- SRAM high byte enable (active low)
   
   psr0 : pixel_shift port map (            -- pixel shift register
      d        => pixel_word,
      load     => pload,
      shift    => pshift,
      inh      => pload_inh,
      clk      => clk50,
      q        => raw_pixel
   );
   
   gate0 : pixel_gate port map (            -- pixel gate unit
      d        => raw_pixel,
      blank    => c_blank,
      image    => l_image,
      blink    => c_blink,
      battr    => attr_blink,
      clk      => clk50,
      ld       => pload,
      q        => pixel
   );

   pixel_o <= pixel;                        -- drive gated pixel output for debug
   
   irgb0 : irgb_convert port map (
      irgb_i   => pixel_word(11 downto 8),  -- glyph foreground IRGB from attribute 
      rgb_o    => v_glon                    -- map to glyph 'on' color
   );
   
   rgb0 : rgb_convert port map (
      rgb_i    => pixel_word(14 downto 12), -- glyph background RGB from attribute 
      rgb_o    => v_gloff                   -- map to glyph 'off' color
   );

   cmux0 : color_mux port map (             -- INACTIVE PIXEL color mux
      glyph    => v_gloff,
      apa      => v_canvas,
      cursor   => v_cursor,
      frame    => v_frame,
      blank    => c_blank,
      cursor   => c_cursor,
      image    => l_image,
      color    => v_inactive
    );

   cmux1 : color_mux port map (             -- ACTIVE PIXEL color mux
      glyph    => v_glon,
      apa      => v_point,
      cursor   => v_cursor,
      frame    => v_frame,
      blank    => c_blank,
      cursor   => c_cursor,
      image    => l_image,
      color    => v_active
   );

   pmux : pixel_mux port map (              -- registered pixel mux
      acolor => v_active,
      icolor => v_inactive,
      pixel  => pixel,
      ld     => pload,
      clk    => clk50,
      q      => v_pixel
   );

   p_hsync <= c_hsync xor (not cfg_hpol);   -- adjust hsync polarity
   
   phs : reg1 port map (                    -- hsync pipe delay
      d      => p_hsync,
      ld     => pload,
      clr    => clear,
      clk    => clk50,
      q      => hsync_o                     -- drive hsync output
   );
   
   p_vsync <= c_vsync xor (not cfg_vpol);   -- adjust vsync polarity
   
   pvs : reg1 port map (                    -- vsync pipe delay
      d      => p_vsync,
      ld     => pload,
      clr    => clear,
      clk    => clk50,
      q      => vsync_o                     -- drive vsync output
   );

   -- drive video outputs
   pclk_o <= pclk;   
   red_o <= v_pixel(5 downto 4);
   green_o <= v_pixel (3 downto 2);
   blue_o <= v_pixel (1 downto 0);

end arch;


