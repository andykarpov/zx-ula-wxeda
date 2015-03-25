library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity memory is
port (
	-- clocks
	clk 		: in std_logic; -- 28 MHz
	clk_sdr		: in std_logic; -- 84 MHz

	-- bank 0 ROM
	a0 			: in std_logic_vector(13 downto 0);
	cs0_n		: in std_logic;
	oe0_n		: in std_logic;
	dout0		: out std_logic_vector(7 downto 0);

	-- bank 1 Video RAM
	a1 			: in std_logic_vector(15 downto 0);
	cs1_n		: in std_logic;
	oe1_n		: in std_logic;
	we1_n		: in std_logic;
	din1		: in std_logic_vector(7 downto 0);
	dout1		: out std_logic_vector(7 downto 0);

	-- bank 2 Upper RAM
	a2			: in std_logic_vector(24 downto 0);
	cs2_n		: in std_logic;
	oe2_n		: in std_logic;
	we2_n		: in std_logic;
	din2		: in std_logic_vector(7 downto 0);
	dout2		: out std_logic_vector(7 downto 0);
	rfsh2		: in std_logic;

	-- SDRAM signals
	CK			: out std_logic;
	RAS_n		: out std_logic;
	CAS_n		: out std_logic;
	WE_n		: out std_logic;
	DQML		: out std_logic;
	DQMH		: out std_logic;
	BA			: out std_logic_vector(1 downto 0);
	MA			: out std_logic_vector(12 downto 0);
	DQ			: inout std_logic_vector(15 downto 0)
);

end memory;

architecture rtl of memory is

signal sdr_ram_a 	: std_logic_vector(24 downto 0);
signal sdr_ram_di 	: std_logic_vector(7 downto 0);
signal sdr_ram_do 	: std_logic_vector(7 downto 0);
signal sdr_ram_wr	: std_logic;
signal sdr_ram_rd	: std_logic;
signal sdr_ram_rfsh : std_logic;

signal video_ram_a 	: std_logic_vector(15 downto 0);
signal video_ram_do : std_logic_vector(7 downto 0);
signal video_ram_di : std_logic_vector(7 downto 0);
signal video_ram_we : std_logic;
signal video_ram_oe : std_logic;
signal video_ram_cs : std_logic;

begin

-- Test ROM
--U_ROM: entity work.rom 
--	port map(
--		address		=> a0 (12 downto 0),
--		clock 		=> clk,
--		rden		=> not cs0_n,
--		q 			=> dout0
--	);

-- Video memory
U_VID: entity work.videoram
port map (
	clock_a		=> clk,
	address_a	=> video_ram_a(13 downto 0), -- write
	data_a		=> video_ram_di, -- write
	q_a			=> open, -- write
	wren_a		=> video_ram_we and video_ram_cs and not video_ram_oe, -- write

	clock_b		=> clk,
	address_b	=> video_ram_a(13 downto 0), -- read
	data_b		=> "11111111", -- read
	q_b			=> video_ram_do, -- read
	wren_b		=> '0');

video_ram_a <= a1;
video_ram_cs <= (not cs1_n and (not we1_n or not oe1_n));
video_ram_oe <= not oe1_n;
video_ram_we <= not we1_n;
video_ram_di <= din1;
dout1 <= video_ram_do;

-- SDRAM Controller
U_SDR: entity work.sdram
port map (
	CLK			=> clk_sdr,

	A			=> sdr_ram_a,
	DI			=> sdr_ram_di,
	DO			=> sdr_ram_do,
	WR			=> sdr_ram_wr,
	RD			=> sdr_ram_rd,
	RFSH		=> sdr_ram_rfsh,

	RFSHREQ		=> open,
	IDLE		=> open,

	CK			=> CK,
	RAS_n		=> RAS_n,
	CAS_n		=> CAS_n,
	WE_n		=> WE_n,
	DQML		=> DQML,
	DQMH		=> DQMH,
	BA			=> BA,
	MA			=> MA,
	DQ			=> DQ);

-- share address / data / signals between rom and ram
sdr_ram_a <= "10000100000" & a0 when cs0_n='0' else a2 when cs2_n='0' and (oe2_n='0' or we2_n='0') else (others => '0');
sdr_ram_rd <= '1' when cs0_n='0' or (cs2_n='0' and oe2_n='0' and we2_n='1') else '0';
sdr_ram_wr <= '1' when cs2_n='0' and we2_n='0' and cs0_n='1' else '0';
sdr_ram_di <= din2;
dout0 <= sdr_ram_do;-- when cs0_n='0' and oe0_n='0' else "11111111";
dout2 <= sdr_ram_do;-- when cs2_n='0' and oe2_n='0' else "11111111";
sdr_ram_rfsh <= rfsh2;

--sdr_ram_a <= a2;
--sdr_ram_rd <= not oe2_n;
--sdr_ram_wr <= not we2_n;
--sdr_ram_di <= din2;
--sdr_ram_rfsh <= rfsh2;
--dout2 <= sdr_ram_do;

end rtl;