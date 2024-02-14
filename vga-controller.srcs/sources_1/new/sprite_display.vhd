library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;
use IEEE.MATH_REAL.ALL;    -- For using the CEIL and LOG functions

entity sprite_display is
    generic (
    NUMBER_OF_SPRITES : integer := 1;
    SPRITE_WIDTH : integer := 16;
    SPRITE_HEIGHT : integer := 16
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
        
        -- vga signals
        pix_x_i : in std_logic_vector(9 downto 0);
        pix_y_i : in std_logic_vector(9 downto 0);
        rgb_o : out std_logic_vector(23 downto 0)
    );
end sprite_display;

architecture behavioral of sprite_display is

function log2ceil(val: natural) return natural is
begin
    if val <= 1 then
        return 0;
    else
        return natural(ceil(log2(real(val))));
    end if;
end function;

   subtype palette_colour_t is std_logic_vector(23 downto 0);
   type palette_vector_t is array (0 to 31) of palette_colour_t;
   
   subtype pixel_t is std_logic_vector(7 downto 0);
   type pixel_vector_t is array (0 to (SPRITE_HEIGHT * SPRITE_WIDTH)-1) of pixel_t;
   
type Sprite_Type is record
    x: std_logic_vector(9 downto 0);
    y: std_logic_vector(9 downto 0);
    sprite_pixels: pixel_vector_t;
    sprite_palette : palette_vector_t;
    priority : std_logic_vector(7 downto 0);
    collision : std_logic_vector(7 downto 0);
    alpha: std_logic_vector(7 downto 0); -- Optional for transparency
end record;

    type Sprite_Array is array (0 to NUMBER_OF_SPRITES-1) of Sprite_Type;
    signal Sprites : Sprite_Array;
    signal current_sprite_pixel: pixel_t;
    signal is_sprite_pixel: boolean;
    
   constant GLYPH_X_WIDTH: integer := log2ceil(SPRITE_WIDTH);
   constant GLYPH_Y_WIDTH: integer := log2ceil(SPRITE_WIDTH);
   signal glyph_x :  std_logic_vector(GLYPH_X_WIDTH-1 downto 0); 
   signal glyph_y : std_logic_vector(GLYPH_Y_WIDTH-1 downto 0);
    
begin

Sprite_init: process(clk_i) 
variable init_done: boolean := false;
begin

    if (rising_edge(clk_i) and init_done = false) then
        
        Sprites(0).priority <= x"01";
        Sprites(0).x <= "0101000000";
        Sprites(0).y <= "0011110000";
        Sprites(0).sprite_pixels <= (X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0A",X"04",X"05",X"0B",X"04",X"04",X"05",X"05",X"0A",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0A",X"05",X"04",X"0B",X"04",X"04",X"04",X"05",X"05",X"05",X"0A",X"0D",X"0D",X"0D",X"0D",X"0D",X"0A",X"05",X"05",X"0A",X"05",X"04",X"0B",X"05",X"05",X"05",X"0A",X"0D",X"0D",X"0D",X"0D",X"0D",X"0A",X"05",X"0A",X"0A",X"05",X"05",X"02",X"0B",X"05",X"05",X"0A",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0A",X"0A",X"05",X"0C",X"01",X"02",X"0C",X"05",X"0A",X"0A",X"0D",X"0D",X"0D",X"0D",X"0D",X"0A",X"00",X"00",X"07",X"01",X"01",X"01",X"01",X"07",X"00",X"00",X"0A",X"0D",X"0D",X"0D",X"0A",X"00",X"00",X"00",X"00",X"07",X"02",X"02",X"07",X"00",X"00",X"00",X"00",X"0A",X"0D",X"0A",X"02",X"01",X"03",X"07",X"00",X"00",X"00",X"00",X"00",X"00",X"07",X"03",X"01",X"02",X"0A",X"0A",X"01",X"01",X"0A",X"07",X"03",X"00",X"00",X"00",X"00",X"03",X"07",X"0A",X"01",X"01",X"0A",X"0A",X"01",X"01",X"0A",X"03",X"03",X"00",X"00",X"00",X"00",X"03",X"03",X"0A",X"01",X"01",X"0A",X"0D",X"0D",X"0D",X"0A",X"08",X"08",X"08",X"08",X"08",X"08",X"09",X"09",X"0A",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0A",X"08",X"08",X"0A",X"0A",X"0A",X"09",X"09",X"0A",X"0D",X"0D",X"0D",X"0D",X"0D",X"0D",X"0A",X"0A",X"03",X"03",X"0A",X"0A",X"0A",X"07",X"07",X"0A",X"0A",X"0D",X"0D",X"0D");
        Sprites(0).sprite_palette <= (X"FFFFFF",
        X"FFE9C5",
        X"F5B784",
        X"98DCFF",
        X"BEEB71",
        X"6AB417",
        X"F68F37",
        X"A675FE",
        X"E03C28",
        X"871646",
        X"151515",
        X"004E00",
        X"0D2030",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000",
        X"000000");
        
        init_done := true;
        
    end if;

end process;

Sprite_Rendering: process (pix_x_i, pix_y_i)
    variable RGB24: palette_colour_t;
    variable HighestPriority: integer;
    variable SelectedSpriteIndex: integer;
begin
        is_sprite_pixel <= false;
        HighestPriority := -1;  -- No sprite selected
        SelectedSpriteIndex := -1;  -- No sprite selected
        
        -- Loop over all sprites
        for i in 0 to NUMBER_OF_SPRITES-1 loop
            if (pix_x_i >= Sprites(i).x and pix_x_i < Sprites(i).x + SPRITE_WIDTH and 
                pix_y_i >= Sprites(i).y and pix_y_i < Sprites(i).y + SPRITE_HEIGHT) then
                
                -- Check for a higher priority sprite (assuming 0 is highest priority)
                if to_integer(unsigned(Sprites(i).priority)) < HighestPriority or HighestPriority = -1 then
                    HighestPriority := TO_INTEGER(unsigned(Sprites(i).priority));
                    SelectedSpriteIndex := i;
                end if;
            end if;
        end loop;

        -- Render the selected sprite
        if SelectedSpriteIndex /= -1 then
            glyph_x <= pix_x_i(GLYPH_X_WIDTH-1 downto 0);
            glyph_y <= pix_y_i(GLYPH_Y_WIDTH-1 downto 0);
                
            -- Fetch pixel from sprite graphic using sprite_addr and relative x,y
            current_sprite_pixel <= Sprites(SelectedSpriteIndex).sprite_pixels(to_integer(unsigned(glyph_y))*SPRITE_HEIGHT + to_integer(unsigned(glyph_x)));
            RGB24 := Sprites(SelectedSpriteIndex).sprite_palette(to_integer(unsigned(current_sprite_pixel)));      
            rgb_o <= RGB24;
            is_sprite_pixel <= true;
        else 
            rgb_o <= X"000000";
            --pix_o <= X"000";
        end if;
end process Sprite_Rendering;

    
    tile_mem : process (clk_i) 
    begin
    -- adjust ascii to match the array
        if rising_edge(clk_i) then
            if (rd_i = '1') then
              --  disp_tile <= myGrid(TO_INTEGER(unsigned(tile_y_i)) * 40 + TO_INTEGER(unsigned(tile_x_i)));
            elsif (wr_i = '1') then
              --  myGrid(TO_INTEGER(unsigned(tile_y_i)) * 40 + TO_INTEGER(unsigned(tile_x_i))) <= disp_tile; 
            end if;
        end if;
        
    end process;
   
end Behavioral;

