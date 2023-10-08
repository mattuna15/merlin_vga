----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.09.2023 21:14:10
-- Design Name: 
-- Module Name: bitmap_vga - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;

--use IEEE.STD_LOGIC_ARITH.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bitmap_vga is
 Port (        
 
        clk_i : in std_logic;
        reset_i : in std_logic;
        
        -- text signals
        
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
        pix_o : out std_logic_vector(11 downto 0)  -- 8-bit color output);
        );
end bitmap_vga;

architecture Behavioral of bitmap_vga is

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
   
   signal colours : palette_vector_t := InitRamFromFile("D:/Xilinx/vga-controller/vga-controller.srcs/sources_1/imports/Downloads/merlin_palette_data.txt");

   signal addr_a, addr_b : std_logic_vector(18 downto 0);
   signal read_color, write_color, palette_index : std_logic_vector(7 downto 0);
    

component blk_mem_gen_0 IS
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END component;


begin

bitmap: blk_mem_gen_0 
  PORT map (
    clka => clk_i,
    wea(0) => wr_i,
    addra => addr_a,
    dina => write_color,
    douta => read_color,
    clkb => clk_i,
    web(0) => '0',
    addrb => addr_b,
    dinb => x"00",
    doutb => palette_index
  );

palette_set : process (clk_i, pal_wr_i)
variable colour_index : integer;

begin
 
    if rising_edge (pal_wr_i) then
        colour_index := to_integer(unsigned(bmp_pal_index_i));
        colours(colour_index) <= bmp_pal_color_i;
    end if;

end process;

bitmap_proc : process (clk_i)
    variable RGB24: std_logic_vector(23 downto 0);
    variable addr_temp : integer;
begin

    if rising_edge(clk_i) then
    
            addr_temp := to_integer(unsigned(pix_y_i)) * 640 + to_integer(unsigned(pix_x_i));
            addr_b <= std_logic_vector(to_unsigned(addr_temp, addr_b'length));
            RGB24 := colours(TO_INTEGER(unsigned(palette_index)));
            
            pix_o <= RGB24(23 downto 20) & RGB24(15 downto 12) & RGB24(7 downto 4);
            
    end if;

end process;

    get_col: process (clk_i)
    variable RGB24: std_logic_vector(23 downto 0);
    variable addr_temp : integer;
    begin
    
        if rising_edge(clk_i) then
        
            addr_temp := to_integer(unsigned(bmp_y_i)) * 640 + to_integer(unsigned(bmp_x_i));
        
            if (wr_i = '1') then
                addr_a <= std_logic_vector(to_unsigned(addr_temp, addr_a'length));
                disp_pix <= write_color;
            else
                addr_a <= std_logic_vector(to_unsigned(addr_temp, addr_a'length));
                disp_pix <= read_color;
            end if;
            
       end if;
    
    end process;

end Behavioral;
