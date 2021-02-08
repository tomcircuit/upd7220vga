-- UPD7220 GDP-VGA Memory Control FSM
-- February 8, 2021   
-- T. LeMense
-- CC BY SA 4.0
--
-- Supports MIXED mode
-- Supports 1X and 2X ZOOM factors
-- Supports CFG load during RMW cycles

library ieee;
use ieee.std_logic_1164.all;

entity memory_state_machine is             
   port(                                   
      clk      : in   std_logic;            -- 50MHz clock 
      s_ale    : in   std_logic;            -- synchronized ALE from GDP
      s_dbin   : in   std_logic;            -- synchronized DBIN from GDP
      l_image  : in   std_logic:            -- IMAGE latched at end of HSYNC
      w2clk    : in   std_logic;            -- W2xCLK signal to GDP
      clear    : in   std_logic;            -- asynch. clear
      samux    : out  std_logic_vector(1 downto 0));  -- SRAM ADDR MUX control outputs
      ld_gdpad : out  std_logic;            -- GDPAD register clock enable (A0-A15 from GDP)      
      ld_msb   : out  std_logic;            -- SRAM MSB register clock enable (D8-D15 from SRAM)      
      ld_lsb   : out  std_logic;            -- SRAM LSB register clock enable (D7-D0 from SRAM)
      ld_conf  : out  std_logic;            -- CFGx register clock enable
      load_inh : out  std_logic;            -- inhibit loading of pixel shift reg on CLK #11
      ram_cs_l : out  std_logic;            -- SRAM output enable (active low)
      ram_oe_l : out  std_logic;            -- SRAM output enable (active low)
      ram_we_l : out  std_logic;            -- SRAM write enable (active low)
      gdpbuf_l : out  std_logic             -- GDP AD0-15 buffer enable (active low)
end state_machine;   

                      
architecture arch of state_machine is      
   type state_type is (s0, s1, s2, s3, s4, s5, s6, s8, s9, s10, s16, s17, s18, s19, s20, s21, s22, s23, s24);
   signal state   : state_type;            
begin                                      

-- input synch logic
-- all inputs are synchronized externally except for aynch clear

-- state transition logic
   process (clk, clear)                    
   begin                                   
      if clear = '1' then                  
         state <= s0;                      
      elsif rising_edge(clk) then 
         case state is                     
            when s0=>                   -- s0 is waiting for ALE or DBIN to assert
               if s_ale = '1' then      -- this is generally "idle" time of the GDP
                  state <= s1;                  
               elsif s_dbin = '0' then  
                  state <= s16;         
               else                     
                  state <= s0;          
               end if;                  
            when s1=>                   -- s1 is waiting for ALE to negate
               if s_ale = '0' then      -- this allows FSM to latch address from GDP
                  state <= s2;          
               else                     
                  state <= s1;          
               end if;                  
            when s2=>                   -- s2 allows the SRAM time to access the data byte
               state <= s3;             
            when s3=>                   -- s3 is when the SRAM data is loaded
               if l_image = '1' then    -- next state depends on MIXED APA or MIXED CHAR modes
                  state <= s8;          
               else                     
                  state <= s4;          
               end if;                  
            when s4=>                   -- s4,s5,s6 are fetching glyph pixes in MIXED CHAR mode
               state <= s5;             
            when s5=>                   
               state <= s6;             
            when s6=>                   
               state <= s0;             -- return to s0 to process next MIXED CHAR cycle
-- s7 not used                          
            when s8=>                   -- s8 waits for ALE to assert within dummy D1/D2 cycle in MIXED APA
               if s_ale = '1' then      
                  state <= s9;                  
               elseif s_dbin = '0' then 
                  state <= s16;         
               else                     
                  state <= s8;          
               end if;                 
            when s9=>                   -- s9 waits for ALE to negate during dummy D1/D2 cycle in MIXED APA 
               if s_ale = '0' then      
                  state <= s10;        
               else                    
                  state <= s9;         
               end if;                 
            when s10=>                  -- s10 waits for ALE to assert at the end of dummy D2 in MIXED APA 
               if s_ale = '1' then      -- once ALE is found, go back to s1 to process D1 of next cycle
                  state <= s1;         
               else                    
                  state <= s10;        
               end if;                 
               
-- s11,s12,s13,s14,s15 not used               
            when s16=>                  -- s16 during DBIN asserted, the 'read' part of RMW cycle
               if s_dbin = '1' then     
                  state <= s17;        
               else                    
                  state <= s16;        
               end if;                 
            when s17=>                  -- s17 after DBIN negated, to satisfy hold time of GDP
               state <= s18;           
            when s18=>                  -- s18, s19, s20 are CONFIG RAM read cycle during each RMW
               state <= s19;            -- this takes place during GDP 'modify' part of RMW cycle
            when s19=>                 
               state <= s20;           
            when s20=>                 
               state <= s21;           
            when s21=>                  -- s21 wait for W2CLK to negate
               if w2clk = '0' then     
                  state <= s22;        
               else                    
                  state <= s21;          
               end if;                 
            when s22=>                  -- s22, s23, s24 allow the GDP to 'write' to SRAM
               state <= s23;           
            when s23=>                 
               state <= s24;           
            when s24=>                 
               state <= s0;               
-- s25,s26,s27,s28,s29,s30,s31 not used                           
            when others =>              -- all unused states lead to S0
               state <= s0;            
         end case;                     
      end if;                          
   end process;                        
                         
-- output logic
   process (state)                     
   begin                               
      case state is                    
         when s0 =>             
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '1';    -- disable SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '1';    -- disable SRAM chip
            gdpbuf_l <= '0';    -- ENABLE GDP buffers
         when s1 =>             
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '1';    -- LOAD GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '1';    -- disable SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip            
            gdpbuf_l <= '0';    -- ENABLE GDP buffers
         when s2 =>             
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '0';    -- ENABLE SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '1';    -- disable GDP buffers
         when s3 =>             
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '1';      -- LOAD msb data reg (APA pixels, CHAR attr)
            lsb_ld <= '1';      -- LOAD lsb data reg (APA pixels, CHAR glyph number)
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '0';    -- ENABLE SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '1';    -- disable GDP buffers
         when s4 =>             
            samux <= "01";      -- glyph address
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '0';    -- ENABLE SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '1';    -- disable GDP buffers
         when s5 =>             
            samux <= "01";      -- glyph address
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '0';    -- ENABLE SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '1';    -- disable GDP buffers
         when s6 =>             
            samux <= "01";      -- glyph address
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '1';      -- LOAD lsb data reg (glyph pixels)
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '0';    -- ENABLE SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '1';    -- disable GDP buffers
-- s7 not used                  
         when s8 =>             
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '1';    -- disable SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '1';    -- disable GDP buffers
         when s9 =>             
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '1';    -- disable SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '1';    -- disable GDP buffers
         when s10 =>            
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '0';     -- INHIBIT pixel SR load
            ram_oe_l <= '1';    -- disable SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '1';    -- disable SRAM chip                        
            gdpbuf_l <= '0';    -- ENABLE GDP buffers
-- s11,s12,s13,s14,s15 not used 
         when s16 =>            
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '0';     -- INHIBIT pixel SR load
            ram_oe_l <= '0';    -- ENABLE SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '0';    -- ENABLE GDP buffers
         when s17 =>            
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '1';    -- disable SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '0';    -- ENABLE GDP buffers
         when s18 =>            
            samux <= "10";      -- config RAM address
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '0';    -- ENABLE SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '1';    -- disable GDP buffers
         when s19 =>            
            samux <= "10";      -- config RAM address
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '0';    -- ENABLE SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '1';    -- disable GDP buffers
         when s20 =>            
            samux <= "10";      -- config RAM address
            cfg_ld <= '1';      -- LOAD cfg register
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '0';    -- ENABLE SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '1';    -- disable GDP buffers
         when s21 =>            
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '1';    -- disable SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '0';    -- ENABLE GDP buffers
         when s22 =>            
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '1';    -- disable SRAM data ouputs
            ram_we_l <= '0';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '0';    -- ENABLE GDP buffers
         when s23 =>            
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '1';    -- disable SRAM data ouputs
            ram_we_l <= '0';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '0';    -- ENABLE GDP buffers
         when s24 =>            
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '1';     -- allow pixel SR load
            ram_oe_l <= '1';    -- disable SRAM data ouputs
            ram_we_l <= '0';    -- disable SRAM write
            ram_cs_l <= '0';    -- ENABLE SRAM chip                        
            gdpbuf_l <= '0';    -- ENABLE GDP buffers
-- s25,s26,s27,s28,s29,s30,s31 not used            
         when others =>         
            samux <= "00";      -- latched GDP Addr
            cfg_ld <= '0';      -- do not load cfg registers
            msb_ld <= '0';      -- do not load msb data reg
            lsb_ld <= '0';      -- do not load lsb data reg
            gdpad_ld <= '0';    -- do not load GDP Addr register
            load_en <= '0';     -- INHIBIT pixel SR load
            ram_oe_l <= '1';    -- disable SRAM data ouputs
            ram_we_l <= '1';    -- disable SRAM write
            ram_cs_l <= '1';    -- disable SRAM chip                        
            gdpbuf_l <= '1';    -- disable GDP buffers
      end case;                 
   end process;                 
                                
end arch;                       
                                
