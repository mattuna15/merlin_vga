library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity vga_controller is
    generic (
        SCREEN_WIDTH : integer := 640;  -- Adjust as needed
        SCREEN_HEIGHT : integer := 480; -- Adjust as needed
        H_SYNC_CYCLES : integer := 96;  -- H_SYNC length
        H_BACK_PORCH : integer := 48;   -- H_BACK_PORCH length
        H_ACTIVE_VIDEO : integer := 640; -- Active video
        H_FRONT_PORCH : integer := 16;  -- H_FRONT_PORCH length
        H_LINE_TOTAL : integer := 800;  -- Total line length
        V_SYNC_CYCLES : integer := 2;   -- V_SYNC length
        V_BACK_PORCH : integer := 31;   -- V_BACK_PORCH length
        V_ACTIVE_VIDEO : integer := 480; -- Active video
        V_FRONT_PORCH : integer := 10;  -- V_FRONT_PORCH length
        V_LINE_TOTAL : integer := 525   -- Total frame length
    );
    port (
        clk_i : in std_logic;
        reset_i : in std_logic;
        irq : out std_logic;
        pix_x_o : out std_logic_vector(9 downto 0);
        pix_y_o : out std_logic_vector(9 downto 0);
        vga_hs_o : out std_logic;
        vga_vs_o : out std_logic;
        
        -- text memory
        text_enabled : std_logic;
        scroll_i : in std_logic;
        rd_i : in std_logic;
        wr_i : in std_logic;
        char_x_i : in std_logic_vector(7 downto 0);
        char_y_i : in std_logic_vector(7 downto 0);
        disp_char : inout std_logic_vector(7 downto 0); --character to be displayed
        
        videoR0		: out std_logic;
		videoG0		: out std_logic;
		videoB0		: out std_logic;
		videoR1		: out std_logic;
		videoG1		: out std_logic;
		videoB1		: out std_logic;
		videoR2		: out std_logic;
		videoG2		: out std_logic;
		videoB2		: out std_logic;
		videoR3		: out std_logic;
		videoG3		: out std_logic;
		videoB3		: out std_logic
    );
end vga_controller;

architecture behavioral of vga_controller is

component text_display is
   generic (
      G_FONT_FILE : string
   );
    port (
        clk_i : in std_logic;
        reset_i : in std_logic;
        
        -- text signals
        rd_i : in std_logic;
        wr_i : in std_logic;
        char_x_i : in std_logic_vector(7 downto 0);
        char_y_i : in std_logic_vector(7 downto 0);
        disp_char : inout std_logic_vector(7 downto 0); --character to be displayed
        
        -- vga signals
        pix_x_i : in std_logic_vector(9 downto 0);
        pix_y_i : in std_logic_vector(9 downto 0);
        pix_o : out std_logic_vector(11 downto 0)  -- 8-bit color output
    );
end component;

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
        pix_o : out std_logic_vector(11 downto 0)  -- 8-bit color output);
        );
end component;

component tile_display is
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
end component;

constant HS_START : integer := H_ACTIVE_VIDEO + H_FRONT_PORCH;
constant VS_START :  integer := V_ACTIVE_VIDEO + V_FRONT_PORCH;
   
    signal h_counter : std_logic_vector(9 downto 0) := (others => '0');
    signal v_counter : std_logic_vector(9 downto 0) := (others => '0');
    
signal text_colour, bitmap_colour, tile_1_colour, tile_2_colour, input_color : std_logic_vector(11 downto 0);
signal red_4bit, green_4bit, blue_4bit : std_logic_vector(3 downto 0);
signal colour : std_logic_vector(7 downto 0);
signal h_active, v_active : std_logic;

    
    attribute dont_touch : string;
    attribute dont_touch of videoR0 : signal is "true";
    attribute dont_touch of videoR1 : signal is "true";
    attribute dont_touch of videoR2 : signal is "true";
    attribute dont_touch of videoR3 : signal is "true";
    attribute dont_touch of videoG0 : signal is "true";
    attribute dont_touch of videoG1 : signal is "true";
    attribute dont_touch of videoG2 : signal is "true";
    attribute dont_touch of videoG3 : signal is "true";
    attribute dont_touch of videoB0 : signal is "true";
    attribute dont_touch of videoB1 : signal is "true";
    attribute dont_touch of videoB2 : signal is "true";
    attribute dont_touch of videoB3 : signal is "true";
    attribute dont_touch of h_counter : signal is "true";
    attribute dont_touch of v_counter : signal is "true";
    attribute dont_touch of vga_hs_o : signal is "true";
    
    
    attribute dont_touch of rd_i : signal is "true";
    attribute dont_touch of wr_i : signal is "true";
    attribute dont_touch of char_x_i : signal is "true";
    attribute dont_touch of char_y_i : signal is "true";
    attribute dont_touch of disp_char : signal is "true";
    attribute dont_touch of input_color : signal is "true";
    
    
begin

-- counters
    process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            h_counter <= (others => '0');
            v_counter <= (others => '0');
        elsif rising_edge(clk_i) then
            if h_counter < H_LINE_TOTAL-1 then
                h_counter <= h_counter + 1;
            else
                h_counter <= (others => '0');
                if v_counter < V_LINE_TOTAL-1 then
                    v_counter <= v_counter + 1;
                else
                    v_counter <= (others => '0');
                end if;
            end if;
        end if;
    end process;

counters: process (clk_i)
begin

    if rising_edge(clk_i) then
        vga_hs_o <= '0' when (h_counter >= HS_START and h_counter < HS_START + H_SYNC_CYCLES) else '1';
        vga_vs_o <= '0' when (v_counter >= VS_START and v_counter < VS_START + V_SYNC_CYCLES) else '1';
        
        pix_x_o <= h_counter when h_active = '1' else (others => '0');
        pix_y_o <= v_counter when v_active = '1' else (others => '0');
        
        -- Check if we are in the active video region horizontally
        h_active <= '1' when (h_counter < SCREEN_WIDTH) else '0';

        -- Check if we are in the active video region vertically
        v_active <= '1' when (v_counter < SCREEN_HEIGHT) else '0';

        -- Frame interrupt (can be generated at the start or end of the vertical blanking)
        irq <= '1' when (v_counter = SCREEN_HEIGHT and h_counter = 0) else '0';  -- Adjust as per requirements

    end if;
end process;

colours : process (clk_i)
begin

    if rising_edge(clk_i) then
        if (text_colour = "111111111111"  and text_enabled = '1') then
            input_color <= text_colour;
        else
            if (tile_2_colour > X"000") then
                input_color <= tile_2_colour;
            elsif (tile_1_colour > X"000") then
                input_color <= tile_1_colour;
            elsif (bitmap_colour > X"000") then
                input_color <= bitmap_colour;
            end if;
        end if;
    end if;

end process;

-- text display

text_vga :  text_display
   generic map (
      G_FONT_FILE => "D:/Xilinx/vga-controller/vga-controller.srcs/sources_1/imports/fpga/font8x8.txt"
   )
    port map (
        clk_i => clk_i,
        reset_i => reset_i,
        
        -- text signals
        rd_i => rd_i,
        wr_i => wr_i,
        char_x_i => char_x_i,
        char_y_i => char_y_i,
        disp_char => disp_char,
        
        -- vga signals
        pix_x_i => h_counter,
        pix_y_i => v_counter,
        pix_o => text_colour --  8-bit color output
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
        pix_x_i => h_counter,
        pix_y_i => v_counter,
        pix_o => bitmap_colour --  12-bit color 
        );
        
        
tile_1: tile_display
    port map (
        clk_i => clk_i,
        reset_i => reset_i,
        
        tile_pal_index_i => x"00",
        tile_pal_color_i => x"000000",
        pal_wr_i => '0',
        
        -- text signals
        rd_i => rd_i,
        wr_i => '0',
        tile_x_i => char_x_i,
        tile_y_i => char_y_i,
        disp_tile => disp_char,
        
        -- vga signals
        pix_x_i => h_counter,
        pix_y_i => v_counter,
        pix_o => tile_1_colour --  12-bit color output
    );

tile_2: tile_display
    port map (
        clk_i => clk_i,
        reset_i => reset_i,
        
        tile_pal_index_i => x"00",
        tile_pal_color_i => x"000000",
        pal_wr_i => '0',
        
        -- text signals
        rd_i => rd_i,
        wr_i => '0',
        tile_x_i => char_x_i,
        tile_y_i => char_y_i,
        disp_tile => disp_char,
        
        -- vga signals
        pix_x_i => h_counter,
        pix_y_i => v_counter,
        pix_o => tile_2_colour --  12-bit color output
    );

-- colour generation.


red_4bit   <= input_color(11 downto 8);
green_4bit <=  input_color(7 downto 4);
blue_4bit  <= input_color(3 downto 0);

    -- Map these to your output pins (assuming you have the corresponding signals defined elsewhere in your VHDL code):
videoR0 <= red_4bit(0);
videoR1 <= red_4bit(1);
videoR2 <= red_4bit(2);
videoR3 <= red_4bit(3);

videoG0 <= green_4bit(0);
videoG1 <= green_4bit(1);
videoG2 <= green_4bit(2);
videoG3 <= green_4bit(3);

videoB0 <= blue_4bit(0);
videoB1 <= blue_4bit(1);
videoB2 <= blue_4bit(2);
videoB3 <= blue_4bit(3);


end behavioral;

