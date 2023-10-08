library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity top_level is
    port (
        sys_clock  : in std_logic;  -- Input clock
        cpu_resetn : in std_logic;  -- Reset signal (active-low)
        
        sw : in std_logic_vector (7 downto 0);
        
        -- VGA outputs
        videoR0: out std_logic;
		videoG0: out std_logic;
		videoB0: out std_logic;
		videoR1: out std_logic;
		videoG1: out std_logic;
		videoB1: out std_logic;
		videoR2: out std_logic;
		videoG2: out std_logic;
		videoB2: out std_logic;
		videoR3: out std_logic;
		videoG3: out std_logic;
		videoB3: out std_logic;
        hSync : out std_logic;
        vSync : out std_logic;
        led : out std_logic_vector(7 downto 0)
    );
end top_level;

architecture behavior of top_level is
    signal input_color: std_logic_vector(7 downto 0);
    signal pix_x, pix_y: std_logic_vector(9 downto 0);
    
    signal vga_clock: std_logic;
    
    component clk_wiz_0 is
    port (
        clk_in1  : in  std_logic;
        clk_out1 : out std_logic
    );
    end component clk_wiz_0;

        signal rd_i :  std_logic;
        signal wr_i :  std_logic;
        signal char_x_i :  std_logic_vector(7 downto 0);
        signal char_y_i :  std_logic_vector(7 downto 0);
        signal disp_char :  std_logic_vector(7 downto 0); --character to be displayed
        
begin

    clock: clk_wiz_0
    port map (
        clk_in1 => sys_clock,
        clk_out1 => vga_clock
    );
    
    -- VGA Controller
    vga_ctrl: entity work.vga_controller
    port map (
        clk_i    => vga_clock,
        reset_i  => not cpu_resetn,
        irq => open,
        vga_hs_o => hSync,
        vga_vs_o => vSync,
        
        -- text
        text_enabled => sw(0),
        scroll_i => '0',
        rd_i => rd_i,
        wr_i => wr_i,
        char_x_i => char_x_i,
        char_y_i => char_y_i,
        disp_char => disp_char, --character to be displayed
        
        videoR0  => videoR0,
		videoG0  => videoG0,
		videoB0  => videoB0,
		videoR1  => videoR1,
		videoG1  => videoG1,
		videoB1  => videoB1,
		videoR2  => videoR2,
		videoG2  => videoG2,
		videoB2  => videoB2,
		videoR3  => videoR3,
		videoG3  => videoG3,
		videoB3  => videoB3
    );
    
    
    create_Text: process (vga_clock)
    begin
    
        if rising_edge(vga_clock) then
            wr_i <= '1';
            rd_i <= '0';
            char_x_i <= X"20";
            char_y_i <= X"0F";
            disp_char <= x"42";
        end if;
        
    end process;
    
end behavior;

