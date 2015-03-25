library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity clock is
port (
		clk: in std_logic;
		reset: in std_logic;

		locked: out std_logic;
		clk_ula : out std_logic;
		clk_mem : out std_logic;
		clk_sdram : out std_logic;
		clk_audio: out std_logic;
		clk_kbd : out std_logic;
		clk_video: out std_logic;
		clk_loader: out std_logic;
		clk_adc : out std_logic
	);
end;

architecture rtl of clock is

signal clk_84 		: 	std_logic;
signal clk_28 		: 	std_logic;
signal clk_14 		: 	std_logic;
signal clk_7 		: 	std_logic;
signal clk_24 		:  std_logic;

signal ena_14mhz	: std_logic;
signal ena_7mhz		: std_logic;
signal ena_3_5mhz	: std_logic;
signal ena_1_75mhz	: std_logic;
signal ena_0_4375mhz	: std_logic;
signal ena_cnt		: std_logic_vector(5 downto 0);

begin

-- Clocks
-- todo: incapsulate into clock unit (inc ena_*)
U0: entity work.altpll1
	port map (
		areset		=> reset,
		inclk0		=> clk,		--  48.0 MHz
		locked		=> locked,
		c0			=> clk_84, 	-- 84 MHz
		c1			=> clk_28, 	-- 28 MHz
		c2			=> clk_14, 	-- 14 MHz
		c3			=> clk_7,	-- 7 MHz
		c4			=> clk_24 	-- 24 MHz 
	);

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
clk_video <= clk_7;
clk_adc <= clk_24;

end architecture rtl;