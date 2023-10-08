library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;

entity sprite_display is
    generic (
    NUMBER_OF_SPRITES : integer := 128
    );
    port (
        clk_i : in std_logic;
        reset_i : in std_logic;
        
        -- palette signals
        
        tile_pal_index_i : in std_logic_vector(7 downto 0);
        tile_pal_color_i : in std_logic_vector(23 downto 0);
        pal_wr_i : in std_logic;
        
        -- tile signals
        rd_i : std_logic;
        wr_i : std_logic;
        sprite_x_i : in std_logic_vector(7 downto 0);
        sprite_y_i : in std_logic_vector(7 downto 0);
        disp_tile : inout std_logic_vector(7 downto 0); --character to be displayed
        
        -- vga signals
        pix_x_i : in std_logic_vector(9 downto 0);
        pix_y_i : in std_logic_vector(9 downto 0);
        pix_o : out std_logic_vector(11 downto 0)  -- 8-bit color output
    );
end sprite_display;

architecture behavioral of sprite_display is
   subtype palette_colour_t is std_logic_vector(23 downto 0);
   type palette_vector_t is array (0 to 31) of palette_colour_t;
   
   subtype pixel_t is std_logic_vector(7 downto 0);
   type pixel_vector_t is array(0 to 255) of pixel_t;
   
type Sprite_Type is record
    x: integer;
    y: integer;
    sprite_pixels: pixel_vector_t;
    sprite_palette : palette_vector_t;
    priority : integer;
    collision : boolean;
    alpha: std_logic_vector(7 downto 0); -- Optional for transparency
end record;

    type Sprite_Array is array (0 to NUMBER_OF_SPRITES-1) of Sprite_Type;
    signal Sprites : Sprite_Array;
    signal current_sprite_pixel: pixel_t;
    signal is_sprite_pixel: boolean;
    
    signal glyph_x :  std_logic_vector(3 downto 0); 
    signal glyph_y : std_logic_vector(4 downto 0);
    --signal bit_pos : natural;
    
begin



-- Rendering logic
Sprite_Rendering: process(clk_i)
    variable RGB24: palette_colour_t;
begin
    if rising_edge(clk_i) then
        is_sprite_pixel <= false;
    
        -- Loop over all sprites
        for i in 0 to NUMBER_OF_SPRITES-1 loop
            if (pix_x_i >= Sprites(i).x and pix_x_i < Sprites(i).x + 16 and 
                pix_y_i >= Sprites(i).y and pix_y_i < Sprites(i).y + 16) then
                
                glyph_x <= pix_x_i(3 downto 0);
                glyph_y <= pix_y_i(4 downto 0);
                
                -- Fetch pixel from sprite graphic using sprite_addr and relative x,y
                current_sprite_pixel <= Sprites(i).sprite_pixels(to_integer(unsigned(glyph_y))*16 + to_integer(unsigned(glyph_x)));
                RGB24 :=  Sprites(i).sprite_palette(to_integer(unsigned(current_sprite_pixel)));      
                pix_o <= RGB24(23 downto 20) & RGB24(15 downto 12) & RGB24(7 downto 4);
                is_sprite_pixel <= true;
                exit;  -- Exit once a sprite pixel is found. This won't support sprite stacking.
            end if;
        end loop;
    end if;
end process Sprite_Rendering;
    
    tile_mem : process (clk_i) 
    begin
    -- adjust ascii to match the array
        if rising_edge(clk_i) then
            if (rd_i = '1') then
 --               disp_tile <= myGrid(TO_INTEGER(unsigned(tile_y_i)) * 40 + TO_INTEGER(unsigned(tile_x_i)));
            elsif (wr_i = '1') then
 --               myGrid(TO_INTEGER(unsigned(tile_y_i)) * 40 + TO_INTEGER(unsigned(tile_x_i))) <= disp_tile; 
            end if;
        end if;
        
    end process;
   
end Behavioral;

