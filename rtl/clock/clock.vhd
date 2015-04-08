library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity clock is
port (
		clk_56 	: in std_logic;
		reset 	: in std_logic;

		clk_28 	: out std_logic;
		clk_14 	: out std_logic;
		clk_7 	: out std_logic;
		clk_3_5 : out std_logic;
		clk_1_75: out std_logic;
		clk_0_4375: out std_logic;

		ena_14  : out std_logic;
		ena_7 	: out std_logic;
		ena_3_5 : out std_logic;
		ena_1_75: out std_logic;
		ena_0_4375: out std_logic
	);
end;

architecture rtl of clock is

signal cnt			: std_logic_vector(6 downto 0);

begin

-- clk divider
process (clk_56, reset)
begin
	if (reset = '1') then 
		cnt <= (others => '0');
	elsif clk_56'event and clk_56='0' then
		cnt <= cnt + 1;
	end if;
end process;

clk_28 			<= cnt(0);
clk_14 			<= cnt(1);
clk_7  			<= cnt(2);
clk_3_5 		<= cnt(3);
clk_1_75 		<= cnt(4);
clk_0_4375	 	<= cnt(6);

ena_14 			<= cnt(1) and cnt(0);
ena_7 			<= cnt(2) and cnt(1) and cnt(0);
ena_3_5 		<= cnt(3) and cnt(2) and cnt(1) and cnt(0);
ena_1_75 		<= cnt(4) and cnt(3) and cnt(2) and cnt(1) and cnt(0);
ena_0_4375 		<= cnt(6) and cnt(5) and cnt(4) and cnt(3) and cnt(2) and cnt(1) and cnt(0);

end architecture rtl;