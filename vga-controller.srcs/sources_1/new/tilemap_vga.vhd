library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;
use IEEE.MATH_REAL.ALL;    -- For using the CEIL and LOG functions

entity tile_display is
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
end tile_display;

architecture behavioral of tile_display is


function log2ceil(val: natural) return natural is
begin
    if val <= 1 then
        return 0;
    else
        return natural(ceil(log2(real(val))));
    end if;
end function;
--colours

  -- bitmap or background colour
   subtype palette_colour_t is std_logic_vector(23 downto 0);
   type palette_vector_t is array (0 to 255) of palette_colour_t;
   
   impure function InitPaletteFromFile(RamFileName : in string) return palette_vector_t is
      FILE RamFile : text;
      variable RamFileLine : line;
      variable RAM : palette_vector_t := (others => x"000000");
   begin
      file_open(RamFile, RamFileName, read_mode);
      for i in palette_vector_t'range loop
         readline (RamFile, RamFileLine);
         hread (RamFileLine, RAM(i));
         if endfile(RamFile) then
            return RAM;
         end if;
      end loop;
      return RAM;
   end function;
   
   signal colours : palette_vector_t := InitPaletteFromFile(G_PALETTE_FILE);

-- tileset

type tile_t is array (0 to (G_TILE_HEIGHT * G_TILE_WIDTH)-1 ) of std_logic_vector(7 downto 0);
type tile_data_t is array (0 to G_NUMBER_OF_TILES - 1) of tile_t;

   impure function InitTilesFromFile(RamFileName : in string) return tile_data_t is
      FILE RamFile : text;
      variable RamFileLine : line;
      variable RAM : tile_data_t := (others =>(others => x"00"));
      variable TILE : tile_t := (others => x"00");
   begin
      file_open(RamFile, RamFileName, read_mode);
      for i in tile_data_t'range loop
        for j in 0 to (G_TILE_HEIGHT * G_TILE_WIDTH)-1  loop
         readline (RamFile, RamFileLine);
         hread (RamFileLine, TILE(j));
         if endfile(RamFile) then
            return RAM;
         end if;
        end loop;
        RAM(i) := TILE;
      end loop;
      return RAM;
   end function;

signal tile_data : tile_data_t := InitTilesFromFile(G_TILESET_FILE);
signal tile : tile_t;
signal index_x, index_y : natural;
signal tile_addr : std_logic_vector(7 downto 0);

-- This reads the ROM contents from a text file
type tile_grid is array(0 to (G_TILEMAP_HEIGHT * G_TILEMAP_WIDTH)-1 ) of std_logic_vector(7 downto 0);

   impure function InitRamFromFile(RamFileName : in string) return tile_grid is
      FILE RamFile : text;
      variable RamFileLine : line;
      variable RAM : tile_grid := (others => (others => '0'));
   begin
      file_open(RamFile, RamFileName, read_mode);
      for i in tile_grid'range loop
         readline (RamFile, RamFileLine);
         hread (RamFileLine, RAM(i));
         if endfile(RamFile) then
            return RAM;
         end if;
      end loop;
      return RAM;
   end function;

signal myGrid : tile_grid := InitRamFromFile(G_TILEMAP_FILE);

   constant GLYPH_X_WIDTH: integer := log2ceil(G_TILE_WIDTH);
   constant GLYPH_Y_WIDTH: integer := log2ceil(G_TILE_HEIGHT);
   
   signal glyph_x :  std_logic_vector(GLYPH_X_WIDTH-1 downto 0); 
   signal glyph_y : std_logic_vector(GLYPH_Y_WIDTH-1 downto 0);
   signal bit_pos : natural;

    attribute dont_touch : string;
    attribute dont_touch of get_pixel_colour : label is "true";
    attribute dont_touch of glyph_x : signal is "true";
    attribute dont_touch of glyph_y : signal is "true";
    attribute dont_touch of index_x : signal is "true";
    attribute dont_touch of index_y : signal is "true";
    attribute dont_touch of tile_addr : signal is "true";
begin

palette_set : process (clk_i, pal_wr_i)
variable colour_index : integer;

begin
 
    if rising_edge (pal_wr_i) then
        colour_index := to_integer(unsigned(tile_pal_index_i));
        colours(colour_index) <= tile_pal_color_i;
    end if;

end process;

 get_pixel_colour : process (pix_x_i, pix_y_i)
    variable pixel : std_logic_vector(7 downto 0);
    variable RGB24: std_logic_vector(23 downto 0);
    variable tile_x, tile_y : natural; 
    
    begin
    
     --   if rising_edge(clk_i) then
--            -- Add logic to wrap around if scroll value exceeds tilemap dimensions
              if index_x >= G_TILEMAP_WIDTH then
                    tile_x := G_TILEMAP_WIDTH ; --- G_TILEMAP_WIDTH; stop scroll
              else 
                    tile_x := index_x;
              end if;
              if index_y >= G_TILEMAP_HEIGHT then
                    tile_y :=  G_TILEMAP_HEIGHT;
              else 
                    tile_y := index_y;
              end if;
--            elsif index_x < 0 then
--                index_x <= index_x + G_TILEMAP_WIDTH; 
--            end if;

--            if index_y >= G_TILEMAP_HEIGHT then
--                index_y <= index_y; -- - G_TILEMAP_HEIGHT;
--            elsif index_y < 0 then
--                index_y <= index_y + G_TILEMAP_HEIGHT;
--            end if;

            index_x <= to_integer(unsigned(pix_x_i(9 downto GLYPH_X_WIDTH))); --+ to_integer(unsigned(scroll_x));
            index_y <= to_integer(unsigned(pix_y_i(9 downto GLYPH_Y_WIDTH))); --+ to_integer(unsigned(scroll_y));
            glyph_x <= pix_x_i(GLYPH_X_WIDTH-1 downto 0);
            glyph_y <= pix_y_i(GLYPH_Y_WIDTH-1 downto 0);

            tile_addr <= myGrid(tile_y * G_TILEMAP_WIDTH + tile_x);
            tile <= tile_data(to_integer(unsigned(tile_addr)));
           
            pixel := tile(to_integer(unsigned(glyph_y))*G_TILE_WIDTH + to_integer(unsigned(glyph_x)));

            RGB24 := colours(to_integer(unsigned(pixel)));      
            rgb_o <= RGB24;
            
  --     end if; 
    
    end process;
   
end Behavioral;
