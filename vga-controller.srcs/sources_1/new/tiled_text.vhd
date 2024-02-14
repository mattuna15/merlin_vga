library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;
use IEEE.MATH_REAL.ALL;    -- For using the CEIL and LOG functions

entity tiled_text_display is
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
end tiled_text_display;

architecture behavioral of tiled_text_display is


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

   constant GLYPH_X_WIDTH: integer := log2ceil(G_TILE_WIDTH);
   constant GLYPH_Y_WIDTH: integer := log2ceil(G_TILE_HEIGHT);
   
   signal glyph_x :  std_logic_vector(GLYPH_X_WIDTH-1 downto 0); 
   signal glyph_y : std_logic_vector(GLYPH_Y_WIDTH-1 downto 0);
   signal bit_pos : natural;
   
   signal ena,wea : std_logic := '0';
    
    signal addra : std_logic_vector(19 downto 0);
    signal addrb : std_logic_vector(12 downto 0);

    attribute dont_touch : string;
    attribute dont_touch of rd_i, wr_i, glyph_x : signal is "true";
    attribute dont_touch of glyph_y : signal is "true";
    attribute dont_touch of index_x, pix_x_i : signal is "true";
    attribute dont_touch of index_y, pix_y_i : signal is "true";
    attribute dont_touch of tile_addr, disp_char_i, disp_char_o, addra, addrb : signal is "true";

-- Declaration of intermediate signals for two-cycle latency
--signal glyph_x_delay1 : std_logic_vector(GLYPH_X_WIDTH-1 downto 0);
--signal glyph_y_delay1 : std_logic_vector(GLYPH_Y_WIDTH-1 downto 0);
        signal pixel : std_logic_vector(7 downto 0);
        
begin

palette_set : process (clk_i, pal_wr_i)
variable colour_index : integer;

begin
 
    if rising_edge (pal_wr_i) then
        colour_index := to_integer(unsigned(tile_pal_index_i));
        colours(colour_index) <= tile_pal_color_i;
    end if;

end process;

textgrid : dmem
   generic map (
      G_ADDR_BITS => 13,
      G_DATA_WIDTH => 8
   )
   port map (
      -- Port A
      a_clk_i => cpu_clock,
      a_addr_i => addra(12 downto 0),
      a_data_o => disp_char_o,
      a_data_i => disp_char_i,
      a_wren_i => wea,

      -- Port B
      b_clk_i   => clk_i,
      b_addr_i => addrb,
      b_data_o => tile_addr
   );
  
  addra <= "0000" & std_logic_vector(unsigned(char_y_i) * G_TILEMAP_WIDTH + unsigned(char_x_i)) 
                when rd_i = '1' or wr_i = '1' else (others => '0');
                
  ena <= '1' when wr_i = '1' or rd_i = '1' else '0';
  wea <= '1' when wr_i = '1' else '0';
  
  glyph_x <= pix_x_i(GLYPH_X_WIDTH-1 downto 0);
  glyph_y <= pix_y_i(GLYPH_Y_WIDTH-1 downto 0);
  
  addrb <= std_logic_vector(to_unsigned(index_y * G_TILEMAP_WIDTH + index_x, 13));
  index_x <= to_integer(unsigned(pix_x_i(9 downto GLYPH_X_WIDTH))); --+ to_integer(unsigned(scroll_x));
  index_y <= to_integer(unsigned(pix_y_i(9 downto GLYPH_Y_WIDTH))); --+ to_integer(unsigned(scroll_y));
  tile <= tile_data(to_integer(unsigned(tile_addr)));
  pixel <= tile(to_integer(unsigned(glyph_y))*G_TILE_WIDTH + to_integer(unsigned(glyph_x)));
  rgb_o <= colours(to_integer(unsigned(pixel)));      
 
   
end Behavioral;
