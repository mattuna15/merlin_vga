library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;
Library UNISIM;
use UNISIM.vcomponents.all;

entity top_level is
    port (
        sys_clock  : in std_logic;  -- Input clock
        cpu_resetn : in std_logic;  -- Reset signal (active-low)
        
        sw : in std_logic_vector (7 downto 0);
        led : out std_logic_vector(7 downto 0);
        
        -- HDMI

        hdmi_tx_clk_p  : out std_logic;
        hdmi_tx_clk_n   : out std_logic;
        hdmi_tx_n : out std_logic_vector(2 downto 0);
        hdmi_tx_p : out std_logic_vector(2 downto 0);
        
              -- HyperRAM device interface
      hr_resetn   : out   std_logic;
      hr_csn_a      : out   std_logic_vector(3 downto 0);
      hr_ck,hr_ck_n       : out   std_logic;
      hr_rwds     : inout std_logic;
      hr_dq       : inout std_logic_vector(7 downto 0);
      
      fl_spi_cs : out std_logic;
      dq : inout std_logic_vector(3 downto 0);
      
     --   fl_spi_clk : out  std_logic;
        txd1 : out std_logic := '1';
        rxd1 : in std_logic
    );
end top_level;

architecture behavior of top_level is

    signal si,so : std_logic;
    signal input_color: std_logic_vector(7 downto 0);
    signal pix_x, pix_y: std_logic_vector(9 downto 0);
    signal start_up : std_logic := '0';
    signal fl_spi_clk :  std_logic;
    
    signal vga_clock, hdmi_clock, clk16, clk394, clk100,clk50: std_logic;
    signal buffer_mem_addr, buffer_mem_read, buffer_mem_write : std_logic_vector(31 downto 0);
    
    component vga_controller is
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
end component vga_controller;
    
    component clk_wiz_0 is
    port (
        clk_in1  : in  std_logic;
        hdmi_clk : out std_logic;
        vga_clk : out std_logic
    );
    end component clk_wiz_0;
    
    component cpu_clock is
    port (
        clk_in1  : in  std_logic;
        clk_out100 : out std_logic;
        clk_out50 : out std_logic;
        clk_out16 : out std_logic;
        clk_out147 : out std_logic;
        resetn  : in std_logic;
        locked  : out std_logic
    );
    end component cpu_clock;
    
     signal address_i : std_logic_vector(31 downto 0);
     signal data_i :  std_logic_vector(15 downto 0);
     signal data_o :  std_logic_vector(15 downto 0);
     signal vga_cs_n :  std_logic;
     signal cpu_rw_n :  std_logic;
     signal vga_dtack_n :  std_logic;

    signal ram_reset: std_logic := '0';
    
    signal counter: INTEGER range 0 to 15000 := 0;

       signal  clk_out147 :  std_logic;
       signal  resetn  :  std_logic;
       signal locked  :  std_logic;
       signal system_start : std_logic;
       signal system_reset : std_logic;
       
       attribute dont_touch : string;
    attribute dont_touch of        fl_spi_cs, fl_spi_clk  : signal is "true";
    attribute dont_touch of vga_ctrl : label is "true";

begin
    
    system_reset <= not (cpu_resetn and start_up and locked and system_start);

    cpu_clock1: cpu_clock
    port map (
        clk_in1 => sys_clock,
        clk_out100 => clk100,
        clk_out50 => clk50,
        clk_out16 => clk16,
        clk_out147 => clk_out147,
        resetn  => cpu_resetn,
        locked => locked
    );
   
   
    vid_clock: clk_wiz_0
    port map (
        clk_in1 => clk100,
        hdmi_clk => hdmi_clock,  --157.5
        vga_clk => vga_clock   --31.5 vga 72hz
    );
    
--    end process;
wait_process: process(clk50)
    begin
        if rising_edge(clk50) then
        
            if cpu_resetn = '0' then
                hr_resetn <= '0';
                start_up <= '0';
                counter <= 0;
            elsif counter < 15000 then --7500 for ram 15000 for flash
                hr_resetn <= '0';
                counter <= counter + 1;
                start_up <= '0';
            else
                hr_resetn <= '1';
                start_up <= '1';
            end if;
        end if;
    end process;
    
    cpu : entity work.nex030
     port map (
        clk_i	=> clk50, --clk50,
        reset_i	=> system_reset, --ACTIVE HIGH RESET!
        led => led,
        sw => sw,
        COM_TxD          => txd1,
        MFP_SI          => rxd1, 
        clk100 => clk100,
        CLK_PLL_16000 => clk16,
        CLK_PLL_1474 => clk_out147,
        
        address_o => address_i,
        data_i => data_o,
        data_o => data_i,
        vga_cs_n => vga_cs_n,
        cpu_rw_n => cpu_rw_n,
        vga_dtack_n => vga_dtack_n,
        
        hr_csn_a       => hr_csn_a,               -- Connect to chip select 0 signal in your VHDL design
        hr_ck        => hr_ck,            -- Connect to clock output signal in your VHDL design
        hr_ck_n       => hr_ck_n,           -- Connect to inverted clock output signal in your VHDL design
        hr_dq        => hr_dq,                 -- Connect to data I/O signal in your VHDL design
        hr_rwds      => hr_rwds,               -- Connect to read/write data strobe I/O signal in your VHDL design
        hr_resetn     => ram_reset,
        fl_spi_clk => fl_spi_clk, 
        fl_spi_cs => fl_spi_cs,
        dq => dq
	);

STARTUPE2_inst : STARTUPE2
   generic map (
      PROG_USR => "FALSE",    -- Activate program event security feature. Requires encrypted bitstreams.
      SIM_CCLK_FREQ => 10.0    -- Set the Configuration Clock Frequency(ns) for simulation.
   )
   port map (
      CFGCLK => open,                -- 1-bit output: Configuration main clock output
      CFGMCLK => open,               -- 1-bit output: Configuration internal oscillator clock output
      EOS => system_start,                   -- 1-bit output: Active high output signal indicating the End Of Startup.
      PREQ => open,                  -- 1-bit output: PROGRAM request to fabric output
      CLK => '0',                    -- 1-bit input: User start-up clock input
      GSR => '0',                    -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
      GTS => '0',                    -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
      KEYCLEARB => '0',              -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
      PACK => '0',                   -- 1-bit input: PROGRAM acknowledge input
      USRCCLKO => fl_spi_clk,              -- 1-bit input: User CCLK input
      USRCCLKTS => '0',              -- 1-bit input: User CCLK 3-state enable input
      USRDONEO => '1',               -- 1-bit input: User DONE pin output control
      USRDONETS => '0'               -- 1-bit input: User DONE 3-state enable output
   );
    
    -- VGA Controller
    vga_ctrl: vga_controller
    port map (
        cpu_clock  => clk50,
        clk_i    => vga_clock,
        fast_clock_i => hdmi_clock,
        reset_i  => not (cpu_resetn and start_up),
        irq_o => open,
        
        address_i => address_i,
        data_i => data_i,
        data_o => data_o,
        vga_cs_n => vga_cs_n,
        cpu_rw_n => cpu_rw_n,
        vga_dtack_n => vga_dtack_n,
        
        hdmi_tx_clk_p  => hdmi_tx_clk_p,
        hdmi_tx_clk_n  => hdmi_tx_clk_n,
        hdmi_tx_n => hdmi_tx_n,
        hdmi_tx_p => hdmi_tx_p
        
    );

end behavior;
