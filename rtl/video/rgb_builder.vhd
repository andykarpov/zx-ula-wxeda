library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity rgb_builder is
port (
	mode		: in std_logic; -- 0 - ULA, 1 - ULA plus
	-- clocks
	clk 		: in std_logic; -- 28 MHz
	-- reset
	reset		: in std_logic;
	-- input signals
	r 			: in std_logic;
	g 			: in std_logic;
	b 			: in std_logic;
	i 			: in std_logic;
	rgbulaplus	: in std_logic_vector(7 downto 0);
	red 		: out std_logic_vector(2 downto 0);
	green 		: out std_logic_vector(2 downto 0);
	blue 		: out std_logic_vector(2 downto 0)
);

end rgb_builder;

architecture rtl of rgb_builder is

signal ir : std_logic_vector(1 downto 0);
signal ig : std_logic_vector(1 downto 0);
signal ib : std_logic_vector(1 downto 0);

begin

ir <= i & r;
ig <= i & g;
ib <= i & b;

process (clk, ir, mode, rgbulaplus)
begin 
	if mode = '0' then
		case (ir) is
			when "00" => red <= "000";
			when "01" => red <= "101";
			when "10" => red <= "000";
			when "11" => red <= "111";
		end case;
	else 
		red <= rgbulaplus(4 downto 2);
	end if;
end process;

process (clk, ig, mode, rgbulaplus)
begin 
	if mode = '0' then
		case (ig) is
			when "00" => green <= "000";
			when "01" => green <= "101";
			when "10" => green <= "000";
			when "11" => green <= "111";
		end case;
	else 
		green <= rgbulaplus(7 downto 5);
	end if;
end process;

process (clk, ib, mode, rgbulaplus)
begin 
	if mode = '0' then
		case (ib) is
			when "00" => blue <= "000";
			when "01" => blue <= "101";
			when "10" => blue <= "000";
			when "11" => blue <= "111";
		end case;
	else 
		blue <= rgbulaplus(1 downto 0) & rgbulaplus(1);
	end if;
end process;


end rtl;