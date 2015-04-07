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
		--FLASH_SO		: in std_logic;
		--FLASH_CLK		: out std_logic;
		--FLASH_SI		: out std_logic;
		--FLASH_CS_N		: out std_logic;

		-- EPCS4
		--EPCS_SO			: in std_logic;
		--EPCS_CLK		: out std_logic;
		--EPCS_SI			: out std_logic;
		--EPCS_CS_N		: out std_logic;

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

		-- ADC
		ADC_CLK			: out std_logic;
		ADC_DAT			: in std_logic;
		ADC_CS_N		: out std_logic;

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
signal locked 		: 	std_logic;
signal areset		:	std_logic;
signal reset		: 	std_logic;

signal clk_sdram	: std_logic;
signal clk_ula		: std_logic;
signal clk_mem 		: std_logic;
signal clk_audio 	: std_logic;
signal clk_kbd 		: std_logic;
signal clk_loader   : std_logic;
signal clk_video 	: std_logic;
signal clk_adc : std_logic;

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

-- debug DAC out
signal out_dac 		: std_logic_vector(7 downto 0);

-- UART
signal uart_di_bus 				: std_logic_vector(7 downto 0);
signal uart_do_bus              : std_logic_vector(7 downto 0);
signal uart_wr                  : std_logic;
signal uart_rd                  : std_logic;
signal uart_tx_busy             : std_logic;
signal uart_rx_avail    : std_logic;
signal uart_rx_error    : std_logic;

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

begin

-- Clock generator
U0: entity work.clock 
	port map(
		clk => CLK,
		reset => areset,

		locked => locked,
		clk_ula => clk_ula,
		clk_mem => clk_mem,
		clk_sdram => clk_sdram,
		clk_audio => clk_audio,
		clk_kbd => clk_kbd,
		clk_loader => clk_loader,
		clk_video => clk_video,
		clk_adc => clk_adc
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

-- Memory controller
U3: entity work.memory
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

-- Keyboard controller
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

-- Video controller
U5: entity work.video 
	port map(

		reset => reset,
		clk_7 => clk_video,
		clk_14 => clk_ula,
		clk_28 => clk_mem,

		ula_r => ula_r,
		ula_g => ula_g,
		ula_b => ula_b,
		ula_i => ula_i,
		ula_c => ula_csync,
		ula_hs => ula_hsync,
		ula_vs => ula_vsync,

		vga_r => host_vga_r,
		vga_g => host_vga_g,
		vga_b => host_vga_b,
		vga_hs => host_vga_hs,
		vga_vs => host_vga_vs
 	);	

U6: entity work.audio 
	port map(
		clk => CLK,
		clk_dac => clk_audio,
		clk_adc => clk_adc,
		clk_ula => clk_ula,
		reset => reset,
        enable => not(loader_busy),

		ula_spk => ula_spk,
		ula_mic => ula_mic,
		ula_ear => ula_ear,

		ADC_DAT => ADC_DAT,
		ADC_CLK => ADC_CLK,
		ADC_CS_N => ADC_CS_N,

		out_buzzer => BUZZER,
		out_dac => out_dac,
		out_l => DAC_OUT_L,
		out_r => DAC_OUT_R
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

U16: entity work.uart
generic map (
        -- divisor = 28MHz / 115200 Baud = 243
        divisor         => 243)
port map (
        CLK                     => clk_mem,
        RESET           		=> reset,
        WR                      => uart_wr,
        RD                      => uart_rd,
        DI                      => uart_di_bus,
        DO                      => uart_do_bus,
        TXBUSY          		=> uart_tx_busy,
        RXAVAIL         		=> uart_rx_avail,
        RXERROR         		=> uart_rx_error,
        RXD                     => UART_TXD,
        TXD                     => UART_RXD
    );


-------------------------------------------------------------
areset <= not KEYS(3);					-- global reset
reset <= areset or loader_host_reset or not locked;			-- hot reset
cpu_reset_n <= not(reset); -- and not(kb_f_bus(4));	-- CPU reset
ula_mode <= '0';

-------------------------------------------------------------
rom_cs 	<= '1' when (cpu_a_bus(15 downto 14) = "00" and cpu_mreq_n = '0' and cpu_rd_n = '0') else '0';
vram_cs <= '1' when (cpu_a_bus(15 downto 14) = "01" and cpu_mreq_n = '0') else '0';
ram_cs 	<= '1' when (cpu_a_bus(15) = '1' 			and cpu_mreq_n = '0' and (cpu_rd_n = '0' or cpu_wr_n = '0')) else '0';
ula_cs 	<= '1' when (cpu_a_bus(0) = '0' and cpu_iorq_n = '0') else '0';
port255_cs <= '1' when (cpu_iorq_n = '0' and cpu_a_bus(7 downto 0) = "11111111" and cpu_rd_n = '0') else '0';

ula_di_bus <= cpu_do_bus;
rom_a_bus <= cpu_a_bus(13 downto 0);

process (rom_cs, ula_cs, vram_cs, port255_cs, ram_cs, rom_do_bus, ula_do_bus, sdr_do_bus)
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

uart_wr <= '1';
uart_rd <= '0';
uart_di_bus <= out_dac;

-- Host RAM
host_mem_a_bus <= "0000000000" & cpu_a_bus(14 downto 0);
host_mem_di_bus <= cpu_do_bus;
host_mem_rd <= '1' when ram_cs='1' and cpu_rd_n='0' else '0';
host_mem_wr <= '1' when ram_cs='1' and cpu_wr_n='0' else '0';
host_mem_rfsh <= not cpu_rfsh_n;
host_mem_cs <= ram_cs;

-- Global levels
SDRAM_CKE <= '1'; -- pullup
SDRAM_CS_N <= '0'; -- pulldown

end zx_wxeda_arch;