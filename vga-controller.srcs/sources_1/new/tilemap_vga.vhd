library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tile_display is
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
        tile_x_i : in std_logic_vector(7 downto 0);
        tile_y_i : in std_logic_vector(7 downto 0);
        disp_tile : inout std_logic_vector(7 downto 0); --character to be displayed
        
        -- vga signals
        pix_x_i : in std_logic_vector(9 downto 0);
        pix_y_i : in std_logic_vector(9 downto 0);
        pix_o : out std_logic_vector(11 downto 0)  -- 8-bit color output
    );
end tile_display;

architecture behavioral of tile_display is


--colours

  -- bitmap or background colour
   subtype palette_colour_t is std_logic_vector(23 downto 0);
   type palette_vector_t is array (0 to 255) of palette_colour_t;
   
      impure function InitRamFromFile(RamFileName : in string) return palette_vector_t is
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
   
   signal colours : palette_vector_t := InitRamFromFile("D:/games/cave_palette_data.hex");

-- tileset

type tile_t is array (0 to 255) of std_logic_vector(7 downto 0);
type tile_data_t is array (0 to 1) of tile_t;
signal tile_data : tile_data_t := ((X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D"),
(X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1B",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1B",X"12",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1B",X"12",X"19",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1B",X"12",X"16",X"12",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1B",X"16",X"16",X"12",X"18",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1B",X"16",X"16",X"19",X"11",X"18",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1B",X"1B",X"1B",X"16",X"19",X"11",X"12",X"12",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1B",X"12",X"18",X"16",X"16",X"18",X"11",X"12",X"12",X"1D",X"1D",X"1D",X"1D",X"1D",X"1D",X"1B",X"12",X"12",X"12",X"19",X"19",X"18",X"11",X"12",X"12",X"1D",X"1D",X"1D",X"1D",X"1D",X"1B",X"19",X"12",X"12",X"19",X"16",X"18",X"18",X"12",X"11",X"19",X"1D",X"1D",X"1D",X"1D",X"1B",X"19",X"18",X"19",X"16",X"19",X"16",X"19",X"19",X"19",X"19",X"19",X"1D",X"1D",X"1D",X"1B",X"16",X"19",X"19",X"16",X"19",X"18",X"16",X"19",X"19",X"19",X"16",X"19",X"1D",X"1D",X"1B",X"18",X"16",X"16",X"16",X"19",X"18",X"18",X"16",X"19",X"19",X"16",X"19",X"12",X"1D",X"1B",X"18",X"19",X"19",X"16",X"19",X"19",X"19",X"19",X"16",X"16",X"16",X"19",X"18",X"12",X"1B",X"16",X"19",X"19",X"16",X"16",X"19",X"19",X"19",X"19",X"19",X"16",X"19",X"18",X"11",X"12"));
signal tile : tile_t;
signal index_x, index_y : natural;
signal tile_addr : std_logic_vector(7 downto 0);

type tile_grid is array (natural range <>) of std_logic_vector(7 downto 0);
signal myGrid : tile_grid(0 to 1199) := (x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"01",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"); 
   
   signal glyph_x :  std_logic_vector(3 downto 0); 
   signal glyph_y : std_logic_vector(4 downto 0);
   signal bit_pos : natural;
    
begin

palette_set : process (clk_i, pal_wr_i)
variable colour_index : integer;

begin
 
    if rising_edge (pal_wr_i) then
        colour_index := to_integer(unsigned(tile_pal_index_i));
        colours(colour_index) <= tile_pal_color_i;
    end if;

end process;

    get_col: process (clk_i)
    variable pixel : std_logic_vector(7 downto 0);
    variable RGB24: std_logic_vector(23 downto 0);
    begin
    
        if rising_edge(clk_i) then
            -- Calculate the address of the character to be displayed based on the x and y position.
            index_x <= to_integer(unsigned(pix_x_i(9 downto 4)));
            index_y <= to_integer(unsigned(pix_y_i(9 downto 4)));
           
           tile_addr <= myGrid(index_y * 40 + index_x);  -- Corrected the signal name
           tile <= tile_data(to_integer(unsigned(tile_addr)));
           
            glyph_x <= pix_x_i(3 downto 0);
            glyph_y <= pix_y_i(4 downto 0);
            
            pixel := tile(to_integer(unsigned(glyph_y))*16 + to_integer(unsigned(glyph_x)));

           RGB24 := colours(to_integer(unsigned(pixel)));      
           pix_o <= RGB24(23 downto 20) & RGB24(15 downto 12) & RGB24(7 downto 4);
            
       end if;
    
    end process;
    
    
    tile_mem : process (clk_i) 
    begin
    -- adjust ascii to match the array
        if rising_edge(clk_i) then
            if (rd_i = '1') then
                disp_tile <= myGrid(TO_INTEGER(unsigned(tile_y_i)) * 40 + TO_INTEGER(unsigned(tile_x_i)));
            elsif (wr_i = '1') then
                myGrid(TO_INTEGER(unsigned(tile_y_i)) * 40 + TO_INTEGER(unsigned(tile_x_i))) <= disp_tile; 
            end if;
        end if;
        
    end process;
   
end Behavioral;
