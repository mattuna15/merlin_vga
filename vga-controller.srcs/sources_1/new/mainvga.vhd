library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;

entity vga_controller is
    generic (
        SCREEN_WIDTH : integer := 640;  -- Adjust as needed
        SCREEN_HEIGHT : integer := 480 -- Adjust as needed
    );
    port (
        cpu_clock : in std_logic;
        clk_i : in std_logic;
        fast_clock_i : std_logic;
        reset_i : in std_logic;
        irq_o : out std_logic;
        
        address_i : in std_logic_vector(31 downto 0);
        data_i : in std_logic_vector(15 downto 0);
        data_o : out std_logic_vector(15 downto 0);
        vga_cs_n : in std_logic;
        cpu_rw_n : in std_logic;
        vga_dtack_n : out std_logic;
        
--        --hdmi
        hdmi_tx_clk_p  : out std_logic;
        hdmi_tx_clk_n   : out std_logic;
        hdmi_tx_n : out std_logic_vector(2 downto 0);
        hdmi_tx_p : out std_logic_vector(2 downto 0)
        
    );
end vga_controller;


architecture behavioral of vga_controller is

component timing_generator is
    generic (
        RESOLUTION   : string  := "VGA"; -- hd1080p, hd720p, svga, vga
        GEN_PIX_LOC  : boolean := true;
        OBJECT_SIZE  : natural := 16
    );
    port(
        clk           : in  std_logic;
        hsync, vsync  : out std_logic;
        video_active  : out std_logic;
        pixel_x       : out std_logic_vector(OBJECT_SIZE-1 downto 0);
        pixel_y       : out std_logic_vector(OBJECT_SIZE-1 downto 0)
    );
end component timing_generator;

component rgb2hdmi IS
  PORT (
    TMDS_Clk_p : OUT STD_LOGIC;
    TMDS_Clk_n : OUT STD_LOGIC;
    TMDS_Data_p : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    TMDS_Data_n : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    aRst : IN STD_LOGIC;
    vid_pData : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    vid_pVDE : IN STD_LOGIC;
    vid_pHSync : IN STD_LOGIC;
    vid_pVSync : IN STD_LOGIC;
    PixelClk : IN STD_LOGIC;
    SerialClk : IN STD_LOGIC
  );
END component;

component bitmap_vga is
 Port (        
 
        clk_i : in std_logic;
        reset_i : in std_logic;
        
        -- bmp signals
        bmp_pal_index_i : in std_logic_vector(7 downto 0);
        bmp_pal_color_i : in std_logic_vector(23 downto 0);
        pal_wr_i : in std_logic;
      
        wr_i : std_logic;
        bmp_x_i : in std_logic_vector(9 downto 0);
        bmp_y_i : in std_logic_vector(9 downto 0);
        disp_pix : inout std_logic_vector(7 downto 0); --colour to be displayed
   
        -- vga signals
        pix_x_i : in std_logic_vector(9 downto 0);
        pix_y_i : in std_logic_vector(9 downto 0);
        rgb_o : out std_logic_vector(23 downto 0)
        );
end component;

component tile_display is
    generic (
      G_PALETTE_FILE : string;
      G_TILESET_FILE : string;
      G_TILEMAP_FILE : string;
      G_NUMBER_OF_TILES : integer := 256;
      G_TILEMAP_HEIGHT : integer := 40;
      G_TILEMAP_WIDTH : integer := 30;
      G_TILE_HEIGHT : integer := 16;
      G_TILE_WIDTH : integer := 16
    );
    port (
        clk_i : in std_logic;
        reset_i : in std_logic;
        
        -- palette signals
        
        tile_pal_index_i : in std_logic_vector(7 downto 0);
        tile_pal_color_i : in std_logic_vector(23 downto 0);
        pal_wr_i : in std_logic;

        
        -- vga signals
        pix_x_i : in std_logic_vector(9 downto 0);
        pix_y_i : in std_logic_vector(9 downto 0);
        rgb_o : out std_logic_vector(23 downto 0)
    );
end component;


component tiled_text_display is
    generic (
      G_PALETTE_FILE : string;
      G_TILESET_FILE : string;
      G_TILEMAP_FILE : string;
      G_NUMBER_OF_TILES : integer := 256;
      G_TILEMAP_HEIGHT : integer := 40;
      G_TILEMAP_WIDTH : integer := 30;
      G_TILE_HEIGHT : integer := 16;
      G_TILE_WIDTH : integer := 16
    );
    port (
        clk_i : in std_logic;
        cpu_clock : in std_logic;
        reset_i : in std_logic;
        
        -- palette signals
        
        tile_pal_index_i : in std_logic_vector(7 downto 0);
        tile_pal_color_i : in std_logic_vector(23 downto 0);
        pal_wr_i : in std_logic;
        
                        -- text signals
        rd_i : in std_logic;
        wr_i : in std_logic;
        char_x_i : in std_logic_vector(7 downto 0);
        char_y_i : in std_logic_vector(7 downto 0);
        disp_char_i : in std_logic_vector(7 downto 0); --character to be displayed
        disp_char_o : out std_logic_vector(7 downto 0); --character to be displayed

        
        -- vga signals
        pix_x_i : in std_logic_vector(9 downto 0);
        pix_y_i : in std_logic_vector(9 downto 0);
        rgb_o : out std_logic_vector(23 downto 0)
    );
end component;

component sprite_display is
    generic (
    NUMBER_OF_SPRITES : integer := 128
    );
    port (
        clk_i : in std_logic;
        reset_i : in std_logic;
        
        -- tile signals
        rd_i : in std_logic;
        wr_i : in std_logic;
        sprite_index_i : inout std_logic_vector(7 downto 0);
        x: inout std_logic_vector(9 downto 0);
        y: inout std_logic_vector(9 downto 0);
        sprite_pixels : inout std_logic_vector(7*256 downto 0);
        sprite_palette : inout std_logic_vector(32*23 downto 0);
        priority : inout std_logic_vector(7 downto 0);
        collision : inout std_logic_vector(7 downto 0);
      --  alpha: inout std_logic_vector(7 downto 0); -- Optional for transparency
        
        -- vga signals
        pix_x_i : in std_logic_vector(9 downto 0);
        pix_y_i : in std_logic_vector(9 downto 0);
        rgb_o : out std_logic_vector(23 downto 0)
    );
end component;

component dmem is
   generic (
      G_ADDR_BITS : integer;
      G_DATA_WIDTH : integer
   );
   port (
      -- Port A
      a_clk_i  : in  std_logic;
      a_addr_i : in  std_logic_vector(G_ADDR_BITS-1 downto 0);
      a_data_o : out std_logic_vector(G_DATA_WIDTH-1 downto 0);
      a_data_i : in  std_logic_vector(G_DATA_WIDTH-1 downto 0);
      a_wren_i : in  std_logic;

      -- Port B
      b_clk_i  : in  std_logic;
      b_addr_i : in  std_logic_vector(G_ADDR_BITS-1 downto 0);
      b_data_o : out std_logic_vector(G_DATA_WIDTH-1 downto 0)
   );
end component dmem;

       signal pix_x_o, addrb :  std_logic_vector(9 downto 0);
       signal pix_y_o :  std_logic_vector(9 downto 0);
       signal vga_hs_o :  std_logic;
       signal vga_vs_o :  std_logic;
    
signal colour, disp_tile : std_logic_vector(7 downto 0);
signal v_active : std_logic;
signal  text_colour24, bitmap_colour24, tile_1_colour24, tile_2_colour24, sprite_colour24, 
            rgb24, rgb1_24_i, rgb2_24_i, rgb1_24_o, rgb2_24_o : std_logic_vector(23 downto 0) := x"000000";

signal update_req, read_req, preparation_complete : std_logic := '0';
type T_State is (IDLE, CALC_REGISTER, UPDATE_COORDINATES, READ_TEXT, UPDATE_TEXT, UPDATE_TILES, UPDATE_SPRITES, UPDATE_BITMAP, UPDATE_COMPLETE);
signal state : T_State := IDLE;

    signal buffer_switch, buffer1_wren, buffer2_wren, first_line : std_logic := '1';
    attribute dont_touch : string;
    attribute dont_touch of v_active,rgb24, pix_x_o, pix_y_o, address_i,data_i,data_o : signal is "true";
    
      attribute dont_touch of text_1, composer : label is "true";
      
      -- Define constants for addresses with text data
      
constant TEXT_CHAR_ADDR : std_logic_vector(7 downto 0) := "00000010"; -- Address for TEXT_CHAR
 signal text_rd_i : std_logic;
 signal text_wr_i : std_logic;
 signal text_char_x_i : std_logic_vector(7 downto 0)  ;
 signal text_char_y_i :  std_logic_vector(7 downto 0);
 signal text_disp_char_i : std_logic_vector(7 downto 0); --character to be displayed
 signal text_disp_char_o :  std_logic_vector(7 downto 0); --character to be displayed
 
 signal buffer_switch_delayed : std_logic := '0'; -- Initialize as needed
 signal delayed_write_addr1 : std_logic_vector(9 downto 0) := (others => '0');
 signal delayed_write_addr2 : std_logic_vector(9 downto 0) := (others => '0');
 
 
 function SelectColor(sprite_color, tile2_color, tile1_color, text_color, bitmap_color: std_logic_vector(23 downto 0)) return std_logic_vector is
begin
    if sprite_color > x"000000" then
        return sprite_color;
    elsif tile2_color > x"000000" then
        return tile2_color;
    elsif tile1_color > x"000000" then
        return tile1_color;
    elsif text_color > x"000000" then
        return text_color;
    elsif bitmap_color > x"000000" then
        return bitmap_color;
    else
        return x"000000";  -- Default color if none is above the threshold
    end if;
end function;

begin

StateMachine_Process : process(cpu_clock,reset_i)
begin

    if reset_i = '1' then 
        vga_dtack_n <= '1';
        text_rd_i <= '0';
        text_wr_i <= '0';
        state <= IDLE;
    else
    if rising_edge(cpu_clock) then
    
        update_req <= '1' when vga_cs_n = '0' and  cpu_rw_n = '0' else '0';
        read_req <= '1' when vga_cs_n = '0' and  cpu_rw_n = '1' else '0';
    
        case state is
            when IDLE =>
                vga_dtack_n <= '1';
                text_rd_i <= '0';
                text_wr_i <= '0';
                if update_req or read_req then
                    state <= CALC_REGISTER;
                end if;
        when CALC_REGISTER =>
            if (address_i = x"02000002" or address_i = x"02000003") and update_req = '1' then
                state <= UPDATE_COORDINATES;
            elsif (address_i = x"02000004" or address_i = x"02000005") and update_req = '1' then 
                state <= UPDATE_TEXT;
            elsif (address_i = x"02000004" or address_i = x"02000005") and read_req = '1' then 
                state <= READ_TEXT;
            else
                vga_dtack_n <= '0';
                state <= UPDATE_COMPLETE;
            end if;
                    
         when READ_TEXT =>
            
                text_rd_i <= '1';
                text_wr_i <= '0';
                
                data_o <= x"00" & text_disp_char_o; --character to be displayed
                vga_dtack_n <= '0';
                state <= UPDATE_COMPLETE;
                
        when UPDATE_COORDINATES =>
            -- Handle 16-bit data for X/Y coordinates
                
                if address_i = x"02000002" then
                    text_char_x_i <= data_i(15 downto 8);
                end if;
                text_char_y_i <= data_i(7 downto 0);
                vga_dtack_n <= '0';
                state <= UPDATE_COMPLETE;
                
            when UPDATE_TEXT =>
            
                text_rd_i <= read_req and not vga_cs_n;
                text_wr_i <= update_req and not vga_cs_n;
                text_disp_char_i <= data_i(7 downto 0); --character to be displayed
                if address_i = x"02000004" then
                    data_o <= x"00" & text_disp_char_o;
                elsif address_i = x"02000005" then
                    data_o <= text_disp_char_o & text_disp_char_o;
                end if;
                vga_dtack_n <= '0';
                state <= UPDATE_COMPLETE;
            
            when UPDATE_BITMAP =>
                -- Implement logic to update bitmap layer
                -- ...
                state <= UPDATE_TILES;

            when UPDATE_TILES =>
                -- Implement logic to update tile layer
                -- ...
                state <= UPDATE_SPRITES;

            when UPDATE_SPRITES =>
                -- Implement logic to update sprite layer
                -- ...
                state <= UPDATE_BITMAP;

            when UPDATE_COMPLETE =>

                state <= IDLE;
                
            when others =>
                state <= IDLE;
        end case;
    end if;
    
    end if;
end process;


rgb24 <= 
    rgb1_24_o when buffer_switch = '1' and v_active = '1' and first_line = '0' else
    rgb2_24_o when buffer_switch = '0' and v_active = '1' and first_line = '0' else
    SelectColor(sprite_colour24, tile_2_colour24, tile_1_colour24, text_colour24, bitmap_colour24) 
    when v_active = '1' and first_line = '1' else
    x"000000";
         
        first_line <= '1' when pix_y_o = 0 else '0';
       

timing: timing_generator
    generic map(
        OBJECT_SIZE => 10
        )
    port map (
        clk       => clk_i,
        hsync => vga_hs_o,
        vsync => vga_vs_o,
        video_active => v_active,
        pixel_x   => pix_x_o,
        pixel_y   => pix_y_o
    );
    
    rgb1_24_i <= SelectColor(sprite_colour24, tile_2_colour24, tile_1_colour24, text_colour24, bitmap_colour24) when 
                buffer_switch = '0' and v_active = '1'
        else x"000000";
        
    rgb2_24_i <= SelectColor(sprite_colour24, tile_2_colour24, tile_1_colour24, text_colour24, bitmap_colour24) when 
            buffer_switch = '1' and v_active = '1'
        else x"000000";
        
counters: process (clk_i)
begin

   if rising_edge(clk_i) then
   
           -- Update delayed addresses
        if buffer_switch_delayed = '0' then
            delayed_write_addr1 <= pix_x_o; -- This will be delayed inherently by the process
            buffer1_wren <= '1';
            buffer2_wren <= '0';
        else
            delayed_write_addr2 <= pix_x_o; -- Similarly, delayed for the other buffer
            buffer1_wren <= '0';
            buffer2_wren <= '1';
        end if;
        
        -- Frame interrupt (can be generated at the start or end of the vertical blanking)
        irq_o <= '1' when (pix_x_o = SCREEN_WIDTH-1 and pix_y_o = SCREEN_HEIGHT-1) else '0';  -- Adjust as per requirements
        buffer_switch <= not buffer_switch when (pix_x_o = SCREEN_WIDTH - 1);
                -- Introduce one pixel clock cycle delay for buffer switch
        buffer_switch_delayed <= buffer_switch;
        
   end if;

end process;

line_buffer1 : dmem
   generic map (
      G_ADDR_BITS => 10,
      G_DATA_WIDTH => 24
   )
   port map (
      -- Port A
      a_clk_i => clk_i,
      a_addr_i => delayed_write_addr1,
      a_data_o => open,
      a_data_i => rgb1_24_i,
      a_wren_i => buffer1_wren,

      -- Port B
      b_clk_i   => clk_i,
      b_addr_i => pix_x_o,
      b_data_o => rgb1_24_o
   );

line_buffer2 : dmem
   generic map (
      G_ADDR_BITS => 10,
      G_DATA_WIDTH => 24
   )
   port map (
      -- Port A
      a_clk_i => clk_i,
      a_addr_i => delayed_write_addr2,
      a_data_o => open,
      a_data_i => rgb2_24_i,
      a_wren_i => buffer2_wren,

      -- Port B
      b_clk_i   => clk_i,
      b_addr_i => pix_x_o,
      b_data_o => rgb2_24_o
   );

bitmap_display : bitmap_vga 
 Port map (        
        clk_i => clk_i,
        reset_i => reset_i,
        
        -- text signals
        
        bmp_pal_index_i => x"00",
        bmp_pal_color_i => x"000000",
        pal_wr_i => '0',
      
        wr_i => '0',
        bmp_x_i => "0000000001",
        bmp_y_i => "0000000001",
        disp_pix => colour,
   
        -- vga signals
        pix_x_i => pix_x_o,
        pix_y_i => pix_y_o,
        rgb_o => bitmap_colour24
        );

text_1: tiled_text_display
      generic map (
      G_PALETTE_FILE => "D:/games/petscii_palette_data.hex",
      G_TILESET_FILE => "d:/games/petscii.hex",
      G_TILEMAP_FILE => "D:/games/letters.hex",
      G_NUMBER_OF_TILES => 256,
      G_TILEMAP_HEIGHT => 60,
      G_TILEMAP_WIDTH => 80,
      G_TILE_HEIGHT => 8,
      G_TILE_WIDTH => 8
    )
    port map (
        clk_i => clk_i,
        cpu_clock => cpu_clock,
        reset_i => reset_i,
        
        tile_pal_index_i => x"00",
        tile_pal_color_i => x"000000",
        pal_wr_i => '0',
        
        -- text signals
        rd_i => text_rd_i,
        wr_i => text_wr_i,
        char_x_i => text_char_x_i,
        char_y_i => text_char_y_i,
        disp_char_i => text_disp_char_i,  --character to be displayed
        disp_char_o => text_disp_char_o, --character to be displayed
        
        -- vga signals
        pix_x_i => pix_x_o,
        pix_y_i => pix_y_o,
        rgb_o => text_colour24
    );
        
tile_1: tile_display
      generic map (
      G_PALETTE_FILE => "D:/games/caveb_palette_data.hex",
      G_TILESET_FILE => "d:/games/caveb.hex",
      G_TILEMAP_FILE => "D:/games/cave1.hex",
      G_NUMBER_OF_TILES => 183,
      G_TILEMAP_HEIGHT => 30,
      G_TILEMAP_WIDTH => 40,
      G_TILE_HEIGHT => 16,
      G_TILE_WIDTH => 16
    )
    port map (
        clk_i => clk_i,
        reset_i => reset_i,
        
        tile_pal_index_i => x"00",
        tile_pal_color_i => x"000000",
        pal_wr_i => '0',
        
        -- vga signals
        pix_x_i => pix_x_o,
        pix_y_i => pix_y_o,
        rgb_o => tile_1_colour24
    );

--tile_2: tile_display
--      generic map (
--      G_PALETTE_FILE => "D:/games/windows_palette_data.hex",
--      G_TILESET_FILE => "d:/games/windows.hex",
--      G_TILEMAP_FILE => "D:/games/ui.hex",
--      G_NUMBER_OF_TILES => 256,
--      G_TILEMAP_HEIGHT => 30,
--      G_TILEMAP_WIDTH => 40,
--      G_TILE_HEIGHT => 16,
--      G_TILE_WIDTH => 16
--    )
--    port map (
--        clk_i => clk_i,
--        reset_i => reset_i,
        
--        tile_pal_index_i => x"00",
--        tile_pal_color_i => x"000000",
--        pal_wr_i => '0',
        
--        -- vga signals
--        pix_x_i => pix_x_o,
--        pix_y_i => pix_y_o,
--        rgb_o => tile_2_colour24
--    );
    
--sprites :    sprite_display 
--    port map (
--        clk_i => clk_i,
--        reset_i => reset_i,
        
--        -- tile signals
--        rd_i => '0',
--        wr_i => '0',
--        sprite_index_i => open,
--        x => open,
--        y => open,
--        sprite_pixels => open,
--        sprite_palette => open,
--        priority => open,
--        collision => open,
--        --alpha => open,-- Optional for transparency
        
--        -- vga signals
--        pix_x_i => pix_x_o,
--        pix_y_i => pix_y_o,
--        rgb_o => sprite_colour24
--    );

-- colour generation.

hdmi : rgb2hdmi
  PORT map (
    TMDS_Clk_p => hdmi_tx_clk_p,
    TMDS_Clk_n => hdmi_tx_clk_n,
    TMDS_Data_p => hdmi_tx_p,
    TMDS_Data_n => hdmi_tx_n,
    aRst => reset_i,
    vid_pData => rgb24(23 downto 16) & rgb24(7 downto 0) & rgb24(15 downto 8), -- RBG 
    vid_pVDE => v_active,
    vid_pHSync => vga_hs_o,
    vid_pVSync => vga_vs_o, 
    PixelClk => clk_i,
    SerialClk => fast_clock_i
  );

end behavioral;
