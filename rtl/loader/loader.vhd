library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
USE ieee.std_logic_arith.all;

entity loader is
	generic(
		mem_a_offset : integer := 0; -- physical mem write address offset
		loader_filesize : integer := 32768; -- loader rom filesize
		use_osd : boolean := true; -- show osd
		clk_frequency : integer := 280 -- loader clk frequency * 10
	);
	port
	(
		clk : in std_logic;
		clk_low : in std_logic;
		reset : in std_logic;

		sd_clk : out std_logic;
		sd_cs : out std_logic;
		sd_mosi : out std_logic;
		sd_miso : in std_logic;

--		uart_rxd : in std_logic;
--		uart_txd : out std_logic;

--		ps2_clk : inout std_logic;
--		ps2_dat : inout std_logic;

		vga_r : out std_logic_vector(7 downto 0);
		vga_g : out std_logic_vector(7 downto 0);
		vga_b : out std_logic_vector(7 downto 0);
		vga_hs : out std_logic;
		vga_vs : out std_logic;

		mem_di_bus: out std_logic_vector(7 downto 0);
		mem_a_bus: out std_logic_vector(24 downto 0);
		mem_rd : out std_logic;
		mem_wr : out std_logic;
		mem_rfsh : out std_logic;
		mem_cs : out std_logic;

		host_sd_clk : in std_logic;
		host_sd_cs : in std_logic;
		host_sd_mosi : in std_logic;
		host_sd_miso : out std_logic;

		host_vga_r : in std_logic_vector(7 downto 0);
		host_vga_g : in std_logic_vector(7 downto 0);
		host_vga_b : in std_logic_vector(7 downto 0);
		host_vga_hs : in std_logic;
		host_vga_vs : in std_logic;

		host_mem_di_bus : in std_logic_vector(7 downto 0);
		host_mem_a_bus : in std_logic_vector(24 downto 0);
		host_mem_rd : in std_logic;
		host_mem_wr : in std_logic;
		host_mem_rfsh : in std_logic;
		host_mem_cs: in std_logic;

		busy : out std_logic;
		host_reset : out std_logic
	);
END entity;

architecture rtl of loader is

signal loader_sd_clk : std_logic;
signal loader_sd_mosi : std_logic;
signal loader_sd_miso : std_logic;
signal loader_sd_cs : std_logic;

signal loader_uart_txd : std_logic;
signal loader_uart_rxd : std_logic;

signal loader_ps2_clk_in : std_logic;
signal loader_ps2_dat_in : std_logic;

signal loader_mem_di_bus : std_logic_vector(7 downto 0);
signal loader_mem_a_bus : std_logic_vector(24 downto 0);
signal loader_mem_rd : std_logic;
signal loader_mem_wr : std_logic;
signal loader_mem_rfsh : std_logic;

signal loader_vga_hs : std_logic;
signal loader_vga_vs : std_logic;
signal loader_vga_r : std_logic_vector(7 downto 0);
signal loader_vga_g : std_logic_vector(7 downto 0);
signal loader_vga_b : std_logic_vector(7 downto 0);
signal end_of_frame : std_logic;

signal loader_boot_ack : std_logic := '0';
signal loader_boot_req : std_logic := '1';
signal loader_boot_data: std_logic_vector(7 downto 0) := (others=>'0');
signal loader_address : integer := 0;
signal loader_bootdone : std_logic := '0';
signal loader_bootdone_resp : std_logic := '0';

signal loader_act : std_logic := '1';

signal loader_window   : std_logic;
signal loader_pixel    : std_logic;
signal loader_dipswitches: std_logic_vector(11 downto 0);
signal loader_host_reset_n : std_logic;
signal loader_host_divert_sdcard : std_logic;
signal loader_host_divert_keyboard : std_logic;
signal host_reset_out : std_logic := '0';

begin

-- PS/2
loader_ps2_clk_in <= '1';
loader_ps2_dat_in <= '1';

-- loader mem
loader_mem_rd <= '0';
loader_mem_rfsh <= '0';

-- boot flags
loader_act <= not loader_bootdone;
host_reset <= host_reset_out;
busy <= loader_act;

-- One tick to reset host on boot done
process (reset, clk_low)
variable reset_sent : boolean := false;
begin
	if reset = '1' then
		
		host_reset_out <= '0';
		reset_sent := false;

	elsif rising_edge(clk_low) then
		if loader_bootdone = '1' and not reset_sent then
			reset_sent := true;
			host_reset_out <= '1';
		else 
			host_reset_out <= '0';
		end if;
	end if;
end process;

-- SD
sd_clk <= host_sd_clk when loader_act='0' else loader_sd_clk;
sd_cs <= host_sd_cs when loader_act='0' else loader_sd_cs;
sd_mosi <= host_sd_mosi when loader_act='0' else loader_sd_mosi;
host_sd_miso <= sd_miso when loader_act='0' else '0';
loader_sd_miso <= sd_miso when loader_act='1' else '0';

-- MEM
mem_di_bus <= host_mem_di_bus when loader_act='0' else loader_mem_di_bus;
mem_a_bus <= host_mem_a_bus when loader_act='0' else loader_mem_a_bus;
mem_rd <= host_mem_rd when loader_act='0' else loader_mem_rd;
mem_wr <= host_mem_wr when loader_act='0' else loader_mem_wr;
mem_rfsh <= host_mem_rfsh when loader_act='0' else loader_mem_rfsh;
mem_cs <= host_mem_cs when loader_act='0' else loader_mem_wr;

-- PS/2 kbd
--loader_ps2_dat_in <= ps2_dat;
--loader_ps2_clk_in <= ps2_clk;

-- UART
--uart_txd <= loader_uart_txd;
--loader_uart_rxd <= uart_rxd;

-- VGA
vga_hs <= host_vga_hs when loader_act='0' or not use_osd else loader_vga_hs;
vga_vs <= host_vga_vs when loader_act='0' or not use_osd else loader_vga_vs;
vga_r <= host_vga_r when loader_act='0' or not use_osd else loader_vga_r;
vga_g <= host_vga_g when loader_act='0' or not use_osd else loader_vga_g;
vga_b <= host_vga_b when loader_act='0' or not use_osd else loader_vga_b;

-- Loader VGA master sync generator
UL00: entity work.loader_vga_master
	port map (
		clk => clk,
		clkDiv =>TO_UNSIGNED((clk_frequency/280)-1, 4),

		hSync => loader_vga_hs,
		vSync => loader_vga_vs,

		endOfFrame => end_of_frame,

		-- Setup 640x480@60hz needs ~25 Mhz
		xSize => TO_UNSIGNED(800,12),
		ySize => TO_UNSIGNED(525,12),
		xSyncFr => TO_UNSIGNED(656,12),
		xSyncTo => TO_UNSIGNED(752,12),
		ySyncFr => TO_UNSIGNED(500,12),
		ySyncTo => TO_UNSIGNED(502,12)
	);

-- Loader OSD overlay
UL01 : entity work.loader_osd_overlay
port map
(
	clk => clk,
	red_in => "11111111",
	green_in => "11111111",
	blue_in => "11111111",
	window_in => '1',
	osd_window_in => loader_window,
	osd_pixel_in => loader_pixel,
	hsync_in => loader_vga_hs,
	red_out => loader_vga_r,
	green_out => loader_vga_g,
	blue_out => loader_vga_b,
	window_out => open,
	scanline_ena => '1'
);

-- Loader ctl 
UL02: entity work.loader_ctrl
	generic map (
		sysclk_frequency => clk_frequency,
		vsync_polarity => '0',
		detect_vblank => '0'
	)
	port map(
		clk => clk,
		reset_n => not reset,

		-- SD/MMC slot ports
		spi_clk => loader_sd_clk,
		spi_mosi => loader_sd_mosi,
		spi_cs => loader_sd_cs,
		spi_miso => sd_miso,
		 
		-- UART
		txd => loader_uart_txd,
		rxd => loader_uart_rxd,
		
		-- PS/2
		ps2k_clk_in => loader_ps2_clk_in,
		ps2k_dat_in => loader_ps2_dat_in,

		-- VGA
		vga_hsync => loader_vga_hs,
		vga_vsync => loader_vga_vs,
		osd_window => loader_window,
		osd_pixel => loader_pixel,
		vga_vblank => end_of_frame,

		-- boot data
		host_bootdata 	  => loader_boot_data,
		host_bootdata_req => loader_boot_req,
		host_bootdata_ack => loader_boot_ack,
		
		-- loader signals to host
		host_reset_n => loader_host_reset_n,
		host_bootdone => loader_bootdone_resp,
		host_divert_sdcard => loader_host_divert_sdcard,
		host_divert_keyboard => loader_host_divert_keyboard,
		dipswitches => loader_dipswitches,

		mouse_idle => '1'
);


-- mem write
process (reset, clk_low, loader_address, loader_boot_ack)
begin
	if reset = '1' then		

		loader_mem_wr <= '0';
		loader_boot_req <= '1';
		loader_bootdone <= '0';
		loader_address <= 0;

	elsif clk_low'event and clk_low = '1' then

		if loader_address >= loader_filesize then 

			loader_mem_wr <= '0';
			loader_boot_req <= '0';
			loader_bootdone <= '1';

		else 

			loader_bootdone <= '0';

			if loader_boot_ack = '1' then
				
				loader_mem_di_bus <= loader_boot_data;
				loader_mem_a_bus <= conv_std_logic_vector(mem_a_offset+loader_address, 25);
				loader_address <= loader_address + 1;

				loader_mem_wr <= '1';
				loader_boot_req <= '0';	
				
			else

				loader_mem_wr <= '0';
				loader_boot_req <= '1';	

			end if;

		end if;
	end if;
end process;
		
end architecture;
