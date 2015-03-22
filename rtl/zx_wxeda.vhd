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

signal clk_84 		: 	std_logic;
signal clk_28 		: 	std_logic;
signal clk_14 		: 	std_logic;
signal clk_7 		: 	std_logic;
signal clk_3_5		:	std_logic;
signal locked 		: 	std_logic;
signal areset		:	std_logic;
signal reset		: 	std_logic;

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

signal video_ram_a	:	std_logic_vector(13 downto 0);
signal video_ram_do	:	std_logic_vector(7 downto 0);
signal video_ram_di	:	std_logic_vector(7 downto 0);
signal video_ram_oe	:	std_logic;
signal video_ram_cs	:	std_logic;
signal video_ram_we	:	std_logic;
signal vram_cs       :  std_logic;

signal ram_a_bus	: 	std_logic_vector(11 downto 0);
signal ram_di_bus	:	std_logic_vector(7 downto 0);
signal ram_do_bus	: 	std_logic_vector(7 downto 0);
signal ram_cs 		:	std_logic;

signal rom_a_bus	: 	std_logic_vector(13 downto 0);
signal rom_di_bus	:	std_logic_vector(7 downto 0);
signal rom_do_bus	: 	std_logic_vector(7 downto 0);
signal rom_cs 		:	std_logic;

signal kb_rows		:	std_logic_vector(7 downto 0);
signal kb_cols		:	std_logic_vector(4 downto 0);
signal kb_f			:	std_logic_vector(12 downto 1);

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
signal ula_mode 	: std_logic;
signal ulaplus_data_cs : std_logic;
signal ulaplus_addr_cs : std_logic;
			
signal vga_red		:	std_logic_vector(1 downto 0);
signal vga_green		:	std_logic_vector(1 downto 0);
signal vga_blue		:	std_logic_vector(1 downto 0);
signal vga_red_out	: std_logic_vector(2 downto 0);
signal vga_green_out : std_logic_vector(2 downto 0);
signal vga_blue_out  : std_logic_vector(2 downto 0);
signal vga_hsync		:	std_logic;
signal vga_vsync		:	std_logic;
signal vga_sblank		:	std_logic;

begin

-- Clocks
U0: entity work.altpll1
	port map (
		areset		=> areset,
		inclk0		=> CLK,		--  48.0 MHz
		locked		=> locked,
		c0			=> clk_84, 	-- 84 MHz
		c1			=> clk_28, 	-- 28 MHz
		c2			=> clk_14, 	-- 14 MHz
		c3			=> clk_7		-- 7 MHz
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
		
		mode =>	ula_mode,
		clk14 => 	clk_14,
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
		clk 		=> clk_28,
		clk_sdr		=> clk_84,

		-- bank 0 ROM
		--a0			=> rom_a_bus,
		--cs0_n		=> not rom_cs,
		--oe0_n		=> not rom_cs,
		--we0_n		=> '1',
		--din0		=> "11111111",
		--dout0		=> rom_do_bus,

		-- bank 1 Video RAM
		a1 			=> "00" & video_ram_a,
		cs1_n		=> not video_ram_cs,
		oe1_n		=> not video_ram_oe,
		we1_n		=> not video_ram_we,
		din1		=> video_ram_di,
		dout1		=> video_ram_do,

		-- bank 2 Upper RAM
		a2			=> "0" & cpu_a_bus(14 downto 0),
		cs2_n		=> not ram_cs,
		oe2_n		=> cpu_rd_n,
		we2_n		=> cpu_wr_n,
		din2		=> ram_di_bus,
		dout2		=> ram_do_bus,
		rfsh2		=> not cpu_rfsh_n,

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
		CLK			=> clk_14,
		RESET		=> areset,
		ROWS 		=> kb_rows,
		COLS 		=> kb_cols,
		F 			=> kb_f,
		PS2_CLK 	=> PS2_CLK,
		PS2_DAT 	=> PS2_DAT
	);

-- ROM
U5: entity work.rom 
	port map(
		address		=> rom_a_bus (12 downto 0),
		clock 		=> clk_28,
		rden		=> rom_cs,
		q 			=> rom_do_bus
	);

-- VGA converter
U7 : entity work.scan_convert
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
		CLK			=> clk_7,
		CLK_x2		=> clk_14
	);

-- RGB converter
U8 : entity work.rgb_builder
	port map (
		mode => '0',
		clk => clk_28,
		reset => reset,
		r => vga_red(0),
		g => vga_green(0),
		b => vga_blue(0),
		i => vga_red(1) or vga_green(1) or vga_blue(1),
		red => vga_red_out,
		green => vga_green_out,
		blue => vga_blue_out,
		rgbulaplus => "00000000"
	);

-- TODO: DAC / mix
-- TODO: ADC (tape in)

-------------------------------------------------------------
areset <= not KEYS(3);					-- global reset
reset <= areset or not locked;			-- hot reset
cpu_reset_n <= not(reset);-- and not(kb_f_bus(4));	-- CPU reset
ula_mode <= '0';

-- TODO: do reset (oneshot ?)

ram_cs <= '1' when (cpu_a_bus(15) = '1' and cpu_mreq_n = '0' and (cpu_rd_n = '0' or cpu_wr_n = '0')) else '0';
ula_cs <= '1' when (cpu_a_bus(0) = '0' and cpu_iorq_n = '0' and (ula_mode = '0' or cpu_m1_n = '0')) else '0';
vram_cs <= '1' when (cpu_a_bus(15 downto 14) = "01" and cpu_mreq_n = '0') else '0';
port255_cs <= '1' when (cpu_iorq_n = '0' and cpu_a_bus(7 downto 0) = "11111111" and cpu_rd_n = '0' and (ula_mode = '0' or cpu_m1_n = '1')) else '0';
rom_cs <= '1' when (cpu_a_bus(15 downto 14) = "00" and cpu_mreq_n = '0' and cpu_rd_n = '0') else '0';
ulaplus_addr_cs <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus(0) = '1' and cpu_a_bus(2) = '0' and cpu_a_bus(7 downto 6) = "00" and cpu_a_bus(15 downto 14) = "10") else '0'; -- port BF3Bh
ulaplus_data_cs <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus(0) = '1' and cpu_a_bus(2) = '0' and cpu_a_bus(7 downto 6) = "00" and cpu_a_bus(15 downto 14) = "11") else '0'; -- port FF3Bh

ram_di_bus <= cpu_do_bus;
ula_di_bus <= cpu_do_bus;
rom_a_bus <= cpu_a_bus(13 downto 0);

process (rom_cs, ula_cs, vram_cs, port255_cs, ram_cs, rom_do_bus, ula_do_bus, ram_do_bus)
begin
	if (rom_cs = '1') then 
		cpu_di_bus <= rom_do_bus;
	elsif (ula_cs = '1' or vram_cs = '1' or port255_cs = '1' or ulaplus_data_cs = '1' or ulaplus_addr_cs = '1') then
		cpu_di_bus <= ula_do_bus;
	elsif (ram_cs = '1') then
		cpu_di_bus <= ram_do_bus;
	else 
		cpu_di_bus <= "11111111";
	end if;
end process;

-- VGA output
VGA_R <= vga_red_out(2 downto 0) & "00";
VGA_G <= vga_green_out(2 downto 0) & "000";
VGA_B <= vga_blue_out(2 downto 0) & "00";
VGA_HS <= vga_hsync;
VGA_VS <= vga_vsync;

-- TODO
UART_TXD <= 'Z';
UART_RXD <= 'Z';
BUZZER <= ula_spk;
SDRAM_CKE <= '1'; -- pullup
SDRAM_CS_N <= '0'; -- pulldown
DCLK <= '0';
ASDO <= '0';
NCSO <= '1';
SD_SI <= '0';
SD_CLK <= '0';
SD_CS_N <= '1';
DAC_OUT_L <= '0';
DAC_OUT_R <= '0';

end zx_wxeda_arch;