library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;

entity text_display is
   generic (
      G_FONT_FILE : string
   );
    port (
        clk_i : in std_logic;
        reset_i : in std_logic;
        
        -- text signals
        rd_i : std_logic;
        wr_i : std_logic;
        char_x_i : in std_logic_vector(7 downto 0);
        char_y_i : in std_logic_vector(7 downto 0);
        disp_char : inout std_logic_vector(7 downto 0); --character to be displayed
        
        
        -- vga signals
        pix_x_i : in std_logic_vector(9 downto 0);
        pix_y_i : in std_logic_vector(9 downto 0);
        rgb_o : out std_logic_vector(23 downto 0);
        pix_o : out std_logic_vector(11 downto 0)  -- 8-bit color output
    );
end text_display;

architecture behavioral of text_display is

signal index_x, index_y : natural;
signal char_addr : std_logic_vector(7 downto 0);


type text_grid is array (natural range <>, natural range <>) of std_logic_vector(7 downto 0);
signal myGrid : text_grid(0 to 79, 0 to 59) := (others => (others => "00100000")); 

   -- A single character bitmap is defined by 8x8 = 64 bits.
   subtype bitmap_t is std_logic_vector(63 downto 0);

   -- The entire font is defined by an array bitmaps, one for each character.
   type bitmap_vector_t is array (0 to 255) of bitmap_t;

-- This reads the ROM contents from a text file
   impure function InitRamFromFile(RamFileName : in string) return bitmap_vector_t is
      FILE RamFile : text;
      variable RamFileLine : line;
      variable RAM : bitmap_vector_t := (others => (others => '0'));
   begin
      file_open(RamFile, RamFileName, read_mode);
      for i in bitmap_vector_t'range loop
         readline (RamFile, RamFileLine);
         hread (RamFileLine, RAM(i));
         if endfile(RamFile) then
            return RAM;
         end if;
      end loop;
      return RAM;
   end function;
   
   signal bitmaps : bitmap_vector_t := InitRamFromFile(G_FONT_FILE);
   signal bitmap : std_logic_vector(63 downto 0);
   
   signal glyph_x :  std_logic_vector(2 downto 0); 
   signal glyph_y : std_logic_vector(3 downto 0);
   signal bit_pos : natural;
   
   signal pixel : std_logic;
    
begin

    get_col: process (clk_i)
    begin
    
        if rising_edge(clk_i) then
            -- Calculate the address of the character to be displayed based on the x and y position.
           index_x <= to_integer(pix_x_i(9 downto 3));
           index_y <= to_integer(pix_y_i(9 downto 3));  -- Corrected the signal name
           
           char_addr <= myGrid(index_x, index_y);  -- Corrected the signal name
           bitmap <= bitmaps(to_integer(char_addr));
           
           glyph_x <= pix_x_i(2 downto 0);
           glyph_y <= pix_y_i(3 downto 0);
            
           bit_pos <= (7 - to_integer(glyph_y)) * 8 + (7 - to_integer(glyph_x));
            
           pixel <= bitmap(bit_pos);
            
           rgb_o <= (others => '1') when pixel = '1' else (others => '0') ;
           pix_o <= "111111111111" when pixel = '1' else "000000000000"; 
       end if;
    
    end process;
    
    
    char_mem : process (clk_i) 
    variable init_done: boolean := false;
    begin
    -- adjust ascii to match the array
        if rising_edge(clk_i) then
        
            if (init_done = false) then
                myGrid(20, 10) <= x"41";
                myGrid(20, 11) <= x"42";
                myGrid(20, 12) <= x"43";
                init_done := true;
            elsif reset_i = '1' then
                myGrid <= (others => (others => "00100000"));
                myGrid(20, 10) <= x"41";
                myGrid(20, 11) <= x"42";
                myGrid(20, 12) <= x"43";
            elsif (rd_i = '1') then
                disp_char <=  myGrid(TO_INTEGER(char_x_i), TO_INTEGER(char_y_i)) + 1;
            elsif (wr_i = '1') then
                myGrid(TO_INTEGER(char_x_i), TO_INTEGER(char_y_i)) <= disp_char - 1; 
            end if;
        end if;
        
    end process;
   
end Behavioral;
