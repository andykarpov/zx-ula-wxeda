library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;    

entity zx_wxeda is                   
	port(

		-- Clock (48MHz)
		CLK				: in std_logic;

		-- SDRAM (32MB 16x16bit)
		SDRAM_DQ		: inout std_logic_vector(15 downto 0);
		SDRAM_A			: out std_logic_vector(12 downto 0);
		SDRAM_BA		: out std_logic_vector(1 downto 0);
		SDRAM_CLK		: out std_logic;
		SDRAM_DQML		: out std_logic;
		SDRAM_DQMH		: out std_logic;
		SDRAM_WE_N		: out std_logic;
		SDRAM_CAS_N		: out std_logic;
		SDRAM_RAS_N		: out std_logic;
		SDRAM_CKE      	: out std_logic := '1';
		SDRAM_CS_N     	: out std_logic := '0';

		-- SPI FLASH (W25Q32)
		DATA0			: in std_logic;
		NCSO			: out std_logic;
		DCLK			: out std_logic;
		ASDO			: out std_logic;

		-- VGA 5:6:5
		VGA_R			: out std_logic_vector(4 downto 0);
		VGA_G			: out std_logic_vector(5 downto 0);
		VGA_B			: out std_logic_vector(4 downto 0);
		VGA_HS			: out std_logic;
		VGA_VS			: out std_logic;

		-- SD/MMC Memory Card
		SD_SO			: in std_logic;
		SD_SI			: out std_logic;
		SD_CLK			: out std_logic;
		SD_CS_N			: out std_logic;

		-- External I/O
		DAC_OUT_L		: out std_logic; 
		DAC_OUT_R		: out std_logic; 
		KEYS			: in std_logic_vector(3 downto 0);
		BUZZER			: out std_logic;

		-- UART
		UART_TXD		: inout std_logic;
		UART_RXD		: inout std_logic;

		-- PS/2 Keyboard
		PS2_CLK			: inout std_logic;
		PS2_DAT 		: inout std_logic

	);
end zx_wxeda;  

architecture zx_wxeda_arch of zx_wxeda is

-- CLock / reset
signal clk_84 		: 	std_logic;
signal clk_28 		: 	std_logic;
signal clk_14 		: 	std_logic;
signal clk_7 		: 	std_logic;
signal locked 		: 	std_logic;
signal areset		:	std_logic;
signal reset		: 	std_logic;

signal ena_14mhz	: std_logic;
signal ena_7mhz		: std_logic;
signal ena_3_5mhz	: std_logic;
signal ena_1_75mhz	: std_logic;
signal ena_0_4375mhz	: std_logic;
signal ena_cnt		: std_logic_vector(5 downto 0);

signal clk_sdram	: std_logic;
signal clk_ula		: std_logic;
signal clk_mem 		: std_logic;
signal clk_audio 	: std_logic;
signal clk_kbd 		: std_logic;
signal clk_loader   : std_logic;

-- CPU signals
signal cpu_reset_n 	: 	std_logic;
signal cpu_clk		:	std_logic;
signal cpu_int_n	:	std_logic;
signal cpu_nmi_n	:	std_logic;
signal cpu_m1_n		:	std_logic;
signal cpu_mreq_n	:	std_logic;
signal cpu_iorq_n	:	std_logic;
signal cpu_rd_n		:	std_logic;
signal cpu_wr_n		:	std_logic;
signal cpu_rfsh_n	:	std_logic;
signal cpu_a_bus	:	std_logic_vector(15 downto 0);
signal cpu_di_bus	:	std_logic_vector(7 downto 0);
signal cpu_do_bus	:	std_logic_vector(7 downto 0);

-- Video RAM
signal video_ram_a	:	std_logic_vector(13 downto 0);
signal video_ram_do	:	std_logic_vector(7 downto 0);
signal video_ram_di	:	std_logic_vector(7 downto 0);
signal video_ram_oe	:	std_logic;
signal video_ram_cs	:	std_logic;
signal video_ram_we	:	std_logic;
signal vram_cs       :  std_logic;

-- RAM
signal ram_cs 		:	std_logic;

-- ROM
signal rom_a_bus	: 	std_logic_vector(13 downto 0);
signal rom_di_bus	:	std_logic_vector(7 downto 0);
signal rom_do_bus	: 	std_logic_vector(7 downto 0);
signal rom_cs 		:	std_logic;

-- Keyboard
signal kb_rows		:	std_logic_vector(7 downto 0);
signal kb_cols		:	std_logic_vector(4 downto 0);
signal kb_f			:	std_logic_vector(12 downto 1);

-- ULA
signal ula_mode		:   std_logic;
signal ula_r 		:	std_logic;
signal ula_g		:	std_logic;
signal ula_b		: 	std_logic;
signal ula_i 		:	std_logic;
signal ula_csync	:	std_logic;	
signal ula_hsync	:	std_logic;
signal ula_vsync	:	std_logic;
signal ula_cs 		: 	std_logic;
signal port255_cs	: 	std_logic;
signal ula_ear		: 	std_logic;
signal ula_mic		: 	std_logic;
signal ula_spk		:	std_logic;
signal ula_di_bus 	:  std_logic_vector(7 downto 0);
signal ula_do_bus 	:  std_logic_vector(7 downto 0);
signal ulaplus_data_cs : std_logic;
signal ulaplus_addr_cs : std_logic;

-- Internal VGA			
signal vga_red		:	std_logic_vector(1 downto 0);
signal vga_green	:	std_logic_vector(1 downto 0);
signal vga_blue		:	std_logic_vector(1 downto 0);
signal vga_red_out	: std_logic_vector(2 downto 0);
signal vga_green_out : std_logic_vector(2 downto 0);
signal vga_blue_out  : std_logic_vector(2 downto 0);
signal vga_hsync	:	std_logic;
signal vga_vsync	:	std_logic;
signal vga_sblank	:	std_logic;

-- RAM controller
signal sdr_a_bus	: std_logic_vector(24 downto 0);
signal sdr_di_bus	: std_logic_vector(7 downto 0);
signal sdr_do_bus	: std_logic_vector(7 downto 0);
signal sdr_wr		: std_logic;
signal sdr_rd		: std_logic;
signal sdr_rfsh		: std_logic;
signal sdr_cs 		: std_logic;

-- Loader
signal loader_host_reset : std_logic;
signal loader_busy 	: std_logic;

-- Host SD card
signal host_sd_clk	: std_logic;
signal host_sd_cs	: std_logic;
signal host_sd_mosi : std_logic;
signal host_sd_miso : std_logic;

-- Host memory
signal host_mem_a_bus	: std_logic_vector(24 downto 0);
signal host_mem_di_bus	: std_logic_vector(7 downto 0);
signal host_mem_wr		: std_logic;
signal host_mem_rd		: std_logic;
signal host_mem_rfsh	: std_logic;
signal host_mem_cs 		: std_logic;

-- Host VGA
signal host_vga_r		: std_logic_vector(7 downto 0);
signal host_vga_g		: std_logic_vector(7 downto 0);
signal host_vga_b		: std_logic_vector(7 downto 0);
signal host_vga_hs 		: std_logic;
signal host_vga_vs 		: std_logic;

-- Audio
signal audio_l		: std_logic_vector(11 downto 0);
signal audio_r		: std_logic_vector(11 downto 0);
signal dac_s_l		: std_logic_vector(11 downto 0);
signal dac_s_r		: std_logic_vector(11 downto 0);

begin

-- Clocks
-- todo: incapsulate into clock unit (inc ena_*)
U0: entity work.altpll1
	port map (
		areset		=> areset,
		inclk0		=> CLK,		--  48.0 MHz
		locked		=> locked,
		c0			=> clk_84, 	-- 84 MHz
		c1			=> clk_28, 	-- 28 MHz
		c2			=> clk_14, 	-- 14 MHz
		c3			=> clk_7	-- 7 MHz
	);

-- Zilog Z80A CPU
U1: entity work.T80s
	generic map (
		Mode		=> 0,	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write		=> 1,	-- 0 => WR_n active in T3, 1 => WR_n active in T2
		IOWait		=> 1)	-- 0 => Single cycle I/O, 1 => Std I/O cycle
	port map(
		RESET_n		=> cpu_reset_n,
		CLK_n		=> cpu_clk,
		WAIT_n		=> '1',
		INT_n		=> cpu_int_n,
		NMI_n		=> '1',
		BUSRQ_n		=> '1',
		M1_n		=> cpu_m1_n,
		MREQ_n		=> cpu_mreq_n,
		IORQ_n		=> cpu_iorq_n,
		RD_n		=> cpu_rd_n,
		WR_n		=> cpu_wr_n,
		RFSH_n		=> cpu_rfsh_n,
		HALT_n		=> open,
		BUSAK_n		=> open,
		A			=> cpu_a_bus,
		DI			=> cpu_di_bus,
		DO			=> cpu_do_bus,
		SavePC      => open,
		SaveINT     => open,
		RestorePC   => (others => '1'),
		RestoreINT  => (others => '1'),
		RestorePC_n => '1'
	);

-- ULA
U2:	entity	work.ula_top
	port map (
		
		--mode =>	ula_mode,
		clk14 => 	clk_ula,
	    a => 		cpu_a_bus,
	    din => 		ula_di_bus,
		dout => 	ula_do_bus,
	    mreq_n => 	cpu_mreq_n,
	    iorq_n => 	cpu_iorq_n,
	    rd_n => 	cpu_rd_n,
	    wr_n => 	cpu_wr_n,
		rfsh_n => 	cpu_rfsh_n, 
		clkcpu => 	cpu_clk,
		msk_int_n => cpu_int_n,

	    va => 		video_ram_a,
		vramdout => video_ram_do,
		vramdin => 	video_ram_di,
	    vramoe => 	video_ram_oe,
	    vramcs => 	video_ram_cs,
	    vramwe => 	video_ram_we,

	    ear => ula_ear,
	    mic => ula_mic,
	    spk => ula_spk,

		kbrows => kb_rows,
	    kbcolumns => kb_cols,

	    r => 	ula_r,
	    g => 	ula_g,
	    b => 	ula_b,
	    i => 	ula_i,
	    csync => ula_csync,
	    hsync => ula_hsync,
	    vsync => ula_vsync
	);

-- RAM
-- todo: rename to memory
U3: entity work.ram
	port map (

		-- clock
		clk 		=> clk_mem,
		clk_sdr		=> clk_sdram,

		-- bank 0 ROM
		a0			=> rom_a_bus,
		cs0_n		=> not rom_cs,
		oe0_n		=> not rom_cs,
		dout0		=> rom_do_bus,

		-- bank 1 Video RAM
		a1 			=> "00" & video_ram_a,
		cs1_n		=> not video_ram_cs,
		oe1_n		=> not video_ram_oe,
		we1_n		=> not video_ram_we,
		din1		=> video_ram_di,
		dout1		=> video_ram_do,

		-- bank 2 Upper RAM
		a2			=> sdr_a_bus,
		cs2_n		=> not sdr_cs,
		oe2_n		=> not sdr_rd,
		we2_n		=> not sdr_wr,
		din2		=> sdr_di_bus,
		dout2		=> sdr_do_bus,
		rfsh2		=> sdr_rfsh,

		-- SDRAM signals
		CK			=> SDRAM_CLK,
		RAS_n		=> SDRAM_RAS_N,
		CAS_n		=> SDRAM_CAS_N,
		WE_n		=> SDRAM_WE_N,
		DQML		=> SDRAM_DQML,
		DQMH		=> SDRAM_DQMH,
		BA			=> SDRAM_BA,
		MA			=> SDRAM_A,
		DQ			=> SDRAM_DQ
	);

-- Keyboard
U4: entity work.keyboard
	port map(
		CLK			=> clk_kbd,
		RESET		=> areset,
		ROWS  		=> cpu_a_bus(15 downto 8),
		-- ula makes a strange reassignment of the rows address bits
		--ROWS 		=> kb_rows,
		COLS 		=> kb_cols,
		F 			=> kb_f,
		PS2_CLK 	=> PS2_CLK,
		PS2_DAT 	=> PS2_DAT
	);

-- VGA converter
U5 : entity work.scan_convert
	generic map (
		-- mark active area of input video
		cstart      	=>  38,  -- composite sync start
		clength     	=> 352,  -- composite sync length
		-- output video timing
		hA		=>  24,	-- h front porch
		hB		=>  32,	-- h sync
		hC		=>  40,	-- h back porch
		hD		=> 352,	-- visible video
	--	vA		=>   0,	-- v front porch (not used)
		vB		=>   2,	-- v sync
		vC		=>  10,	-- v back porch
		vD		=> 284,	-- visible video
		hpad		=>   0,	-- create H black border
		vpad		=>   0	-- create V black border
	)
	port map (
		I_VIDEO		=> (ula_i and ula_r) & ula_r & (ula_i and ula_g) & ula_g & (ula_i and ula_b) & ula_b,
		I_HSYNC		=> ula_hsync,
		I_VSYNC		=> ula_vsync,
		O_VIDEO(5 downto 4)	=> vga_red,
		O_VIDEO(3 downto 2)	=> vga_green,
		O_VIDEO(1 downto 0)	=> vga_blue,
		O_HSYNC		=> vga_hsync,
		O_VSYNC		=> vga_vsync,
		O_CMPBLK_N	=> vga_sblank,
		CLK			=> ena_7mhz,
		CLK_x2		=> ena_14mhz
	);

-- RGB converter
U6 : entity work.rgb_builder
	port map (
		mode => '0',
		clk => clk_28,
		reset => reset,
		r => vga_red(0) and vga_sblank,
		g => vga_green(0) and vga_sblank,
		b => vga_blue(0) and vga_sblank,
		i => (vga_red(1) or vga_green(1) or vga_blue(1)) and vga_sblank,
		red => vga_red_out,
		green => vga_green_out,
		blue => vga_blue_out,
		rgbulaplus => "00000000"
	);

-- Loader
U7: entity work.loader 
generic map (
	mem_a_offset 		=> 17301504, 	-- 82.ROM start point (0x1080000) 
	loader_filesize 	=> 16384,  		-- 82.ROM filesize (bytes)
	use_osd				=> true, 		-- show OSD
	clk_frequency 		=> 840 			-- loader clk frequency * 10
)
port map (
	clk 				=> clk_sdram, 		 -- 84 MHz for loader_ctl and vga_master
	clk_low 			=> clk_loader,			 -- 3.5 MHz for mem write 
	reset 				=> areset or not locked, -- global reset

	-- physical connections to SD card
	sd_clk 				=> SD_CLK,
	sd_cs 				=> SD_CS_N,
	sd_mosi 			=> SD_SI,
	sd_miso 			=> SD_SO,

	-- physical connections to VGA out		
	vga_r(7 downto 3) 	=> VGA_R,
	vga_g(7 downto 2) 	=> VGA_G,
	vga_b(7 downto 3) 	=> VGA_B,
	vga_hs 				=> VGA_HS,
	vga_vs 				=> VGA_VS,

	-- loader to ram controller connections
	mem_di_bus 			=> sdr_di_bus,
	mem_a_bus 			=> sdr_a_bus,
	mem_wr 				=> sdr_wr,
	mem_rd 				=> sdr_rd,
	mem_rfsh 			=> sdr_rfsh,
	mem_cs 				=> sdr_cs,

	-- host to loader signals
	host_sd_clk 			=> host_sd_clk,
	host_sd_cs 				=> host_sd_cs,
	host_sd_mosi 			=> host_sd_mosi,
	host_sd_miso 			=> host_sd_miso,

	host_vga_r			 	=> host_vga_r,
	host_vga_g			 	=> host_vga_g,
	host_vga_b 				=> host_vga_b,
	host_vga_hs 			=> host_vga_hs,
	host_vga_vs 			=> host_vga_vs,

	host_mem_di_bus 		=> host_mem_di_bus,
	host_mem_a_bus 			=> host_mem_a_bus,
	host_mem_wr 			=> host_mem_wr,
	host_mem_rd 			=> host_mem_rd,
	host_mem_rfsh 			=> host_mem_rfsh,
	host_mem_cs 			=> host_mem_cs,

	-- loader output signals
	host_reset 				=> loader_host_reset,
	busy 					=> loader_busy
);

-- Delta-Sigma L
U8: entity work.dac
port map (
    CLK   		=> clk_audio,
    RESET 		=> areset,
    DAC_DATA	=> dac_s_l,
    DAC_OUT   	=> DAC_OUT_L);

-- Delta-Sigma R
U9: entity work.dac
port map (
    CLK   		=> clk_audio,
    RESET 		=> areset,
    DAC_DATA	=> dac_s_r,
    DAC_OUT   	=> DAC_OUT_R);


-------------------------------------------------------------
areset <= not KEYS(3);					-- global reset
reset <= areset or loader_host_reset or not locked;			-- hot reset
cpu_reset_n <= not(reset); -- and not(kb_f_bus(4));	-- CPU reset
ula_mode <= '0';

-- clk divider
process (clk_28)
begin
	if rising_edge(clk_28) then
		ena_cnt <= ena_cnt + 1;
	end if;
end process;

ena_14mhz 		<= ena_cnt(0);
ena_7mhz 		<= ena_cnt(1) and ena_cnt(0);
ena_3_5mhz 		<= ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
ena_1_75mhz 	<= ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
ena_0_4375mhz 	<= ena_cnt(5) and ena_cnt(4) and ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);

clk_ula <= ena_14mhz;
clk_mem <= clk_28;
clk_sdram <= clk_84;
clk_audio <= ena_14mhz;
clk_kbd <= CLK;
clk_loader <= ena_3_5mhz;

-------------------------------------------------------------
rom_cs 	<= '1' when (cpu_a_bus(15 downto 14) = "00" and cpu_mreq_n = '0' and cpu_rd_n = '0') else '0';
vram_cs <= '1' when (cpu_a_bus(15 downto 14) = "01" and cpu_mreq_n = '0') else '0';
ram_cs 	<= '1' when (cpu_a_bus(15) = '1' 			and cpu_mreq_n = '0' and (cpu_rd_n = '0' or cpu_wr_n = '0')) else '0';
ula_cs 	<= '1' when (cpu_a_bus(0) = '0' and cpu_iorq_n = '0') else '0';
port255_cs <= '1' when (cpu_iorq_n = '0' and cpu_a_bus(7 downto 0) = "11111111" and cpu_rd_n = '0') else '0';

ula_di_bus <= cpu_do_bus;
rom_a_bus <= cpu_a_bus(13 downto 0);

process (rom_cs, ula_cs, vram_cs, port255_cs, ram_cs)
begin
	if (rom_cs = '1') then 
		cpu_di_bus <= rom_do_bus;
	elsif (ula_cs = '1' or vram_cs = '1' or port255_cs = '1') then
		cpu_di_bus <= ula_do_bus;
	elsif (ram_cs = '1') then
		cpu_di_bus <= sdr_do_bus;
	else 
		cpu_di_bus <= "11111111";
	end if;
end process;

-- VGA output
host_vga_r <= vga_red_out(2 downto 0) 	& "00000";
host_vga_g <= vga_green_out(2 downto 0) & "00000";
host_vga_b <= vga_blue_out(2 downto 0) 	& "00000";
host_vga_hs <= vga_hsync;
host_vga_vs <= vga_vsync;

-- Host RAM
host_mem_a_bus <= "0000000000" & cpu_a_bus(14 downto 0);
host_mem_di_bus <= cpu_do_bus;
host_mem_rd <= '1' when ram_cs='1' and cpu_rd_n='0' else '0';
host_mem_wr <= '1' when ram_cs='1' and cpu_wr_n='0' else '0';
host_mem_rfsh <= not cpu_rfsh_n;
host_mem_cs <= ram_cs;

-- Audio
audio_l <= 	  ("0000" & ula_spk & "0000000") + ("0000" & ula_mic & "0000000");  
audio_r <=    ("0000" & ula_spk & "0000000") + ("0000" & ula_mic & "0000000");
-- Convert signed audio data (range 127 to -128) to simple unsigned value.
dac_s_l <= std_logic_vector(unsigned(audio_l + 2048));
dac_s_r <= std_logic_vector(unsigned(audio_r + 2048));

-- TODO: ADC (tape in)

-- TODO
UART_TXD <= 'Z';
UART_RXD <= 'Z';
BUZZER <= '1'; --ula_spk;
SDRAM_CKE <= '1'; -- pullup
SDRAM_CS_N <= '0'; -- pulldown
DCLK <= '0';
ASDO <= '0';
NCSO <= '1';

end zx_wxeda_arch;