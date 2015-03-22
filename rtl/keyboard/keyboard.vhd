library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity keyboard is
port (
	CLK			: in std_logic;
	RESET		: in std_logic;
	ROWS		: in std_logic_vector(7 downto 0);
	COLS		: out std_logic_vector(4 downto 0);
	F 			: out std_logic_vector(12 downto 1);
	PS2_CLK		: inout std_logic;
	PS2_DAT		: inout std_logic);
end keyboard;

architecture rtl of keyboard is

-- Internal signals
type key_matrix is array (11 downto 0) of std_logic_vector(4 downto 0);
signal keys		: key_matrix;
signal keys_f	: std_logic_vector(12 downto 1);
signal row0, row1, row2, row3, row4, row5, row6, row7 : std_logic_vector(4 downto 0);
signal scan		: std_logic_vector(7 downto 0);

-- ps/2 signals
signal ps2_sc_ready : std_logic;
signal ps2_sc : std_logic_vector(9 downto 0); 
signal pressrelease_n : std_logic;
signal pressrelease :  std_logic;
signal extkey: std_logic;

begin

inst_rx : entity work.PS2Keyboard
port map (
	Clock => CLK,
	Reset => RESET,
	PS2Clock => PS2_CLK,
	PS2Data => PS2_DAT,
	CodeReady => ps2_sc_ready,
	ScanCode => ps2_sc
);

	-- Output addressed row to ULA
	row0 <= keys(0) when ROWS(0) = '0' else (others => '1');
	row1 <= keys(1) when ROWS(1) = '0' else (others => '1');
	row2 <= keys(2) when ROWS(2) = '0' else (others => '1');
	row3 <= keys(3) when ROWS(3) = '0' else (others => '1');
	row4 <= keys(4) when ROWS(4) = '0' else (others => '1');
	row5 <= keys(5) when ROWS(5) = '0' else (others => '1');
	row6 <= keys(6) when ROWS(6) = '0' else (others => '1');
	row7 <= keys(7) when ROWS(7) = '0' else (others => '1');
	COLS <= row0 and row1 and row2 and row3 and row4 and row5 and row6 and row7;
	F <= keys_f;

	pressrelease_n <= ps2_sc(8);
	pressrelease <= not ps2_sc(8);
	extkey <= ps2_sc(9);
	
	process (RESET, CLK, ps2_sc, ps2_sc_ready)
	begin
		if RESET = '1' then
			keys(0) <= (others => '1');
			keys(1) <= (others => '1');
			keys(2) <= (others => '1');
			keys(3) <= (others => '1');
			keys(4) <= (others => '1');
			keys(5) <= (others => '1');
			keys(6) <= (others => '1');
			keys(7) <= (others => '1');
			keys(8) <= (others => '0');
			keys(9) <= (others => '0');
			scan <= (others => '0');
			
		elsif CLK'event and CLK = '1' and ps2_sc_ready = '1' then
		
			if (pressrelease = '1') then
				scan <= ps2_sc(7 downto 0);
			else 
				scan <= (others => '1');
			end if;
		
			case ps2_sc(7 downto 0) is
				when X"12" => keys(0)(0) <= pressrelease_n; -- Left  shift (CAPS SHIFT)
				when X"59" => keys(0)(0) <= pressrelease_n; -- Right shift (CAPS SHIFT)
				when X"1a" => keys(0)(1) <= pressrelease_n; -- Z
				when X"22" => keys(0)(2) <= pressrelease_n; -- X
				when X"21" => keys(0)(3) <= pressrelease_n; -- C
				when X"2a" => keys(0)(4) <= pressrelease_n; -- V

				when X"1c" => keys(1)(0) <= pressrelease_n; -- A
				when X"1b" => keys(1)(1) <= pressrelease_n; -- S
				when X"23" => keys(1)(2) <= pressrelease_n; -- D
				when X"2b" => keys(1)(3) <= pressrelease_n; -- F
				when X"34" => keys(1)(4) <= pressrelease_n; -- G

				when X"15" => keys(2)(0) <= pressrelease_n; -- Q
				when X"1d" => keys(2)(1) <= pressrelease_n; -- W
				when X"24" => keys(2)(2) <= pressrelease_n; -- E
				when X"2d" => keys(2)(3) <= pressrelease_n; -- R
				when X"2c" => keys(2)(4) <= pressrelease_n; -- T

				when X"16" => keys(3)(0) <= pressrelease_n; -- 1
				when X"1e" => keys(3)(1) <= pressrelease_n; -- 2
				when X"26" => keys(3)(2) <= pressrelease_n; -- 3
				when X"25" => keys(3)(3) <= pressrelease_n; -- 4
				when X"2e" => keys(3)(4) <= pressrelease_n; -- 5

				when X"45" => keys(4)(0) <= pressrelease_n; -- 0
				when X"46" => keys(4)(1) <= pressrelease_n; -- 9
				when X"3e" => keys(4)(2) <= pressrelease_n; -- 8
				when X"3d" => keys(4)(3) <= pressrelease_n; -- 7
				when X"36" => keys(4)(4) <= pressrelease_n; -- 6

				when X"4d" => keys(5)(0) <= pressrelease_n; -- P
				when X"44" => keys(5)(1) <= pressrelease_n; -- O
				when X"43" => keys(5)(2) <= pressrelease_n; -- I
				when X"3c" => keys(5)(3) <= pressrelease_n; -- U
				when X"35" => keys(5)(4) <= pressrelease_n; -- Y

				when X"5a" => keys(6)(0) <= pressrelease_n; -- ENTER
				when X"4b" => keys(6)(1) <= pressrelease_n; -- L
				when X"42" => keys(6)(2) <= pressrelease_n; -- K
				when X"3b" => keys(6)(3) <= pressrelease_n; -- J
				when X"33" => keys(6)(4) <= pressrelease_n; -- H

				when X"29" => keys(7)(0) <= pressrelease_n; -- SPACE
								  --keys(8)(4) <= pressrelease; -- kempston fire
				when X"14" => keys(7)(1) <= pressrelease_n; -- CTRL (Symbol Shift)
				when X"3a" => keys(7)(2) <= pressrelease_n; -- M
				when X"31" => keys(7)(3) <= pressrelease_n; -- N
				when X"32" => keys(7)(4) <= pressrelease_n; -- B

				-- Cursor keys
				when X"6b" => keys(0)(0) <= pressrelease_n; -- Left (CAPS 5)
							  keys(3)(4) <= pressrelease_n;
							  --keys(8)(1) <= pressrelease; -- kempston left
				when X"72" => keys(0)(0) <= pressrelease_n; -- Down (CAPS 6)
							  keys(4)(4) <= pressrelease_n;
							  --keys(8)(2) <= pressrelease; -- kempston down
				when X"75" => keys(0)(0) <= pressrelease_n; -- Up (CAPS 7)
							  keys(4)(3) <= pressrelease_n;
							  --keys(8)(3) <= pressrelease; -- kempston up
				when X"74" => keys(0)(0) <= pressrelease_n; -- Right (CAPS 8)
							  keys(4)(2) <= pressrelease_n;
							  --keys(8)(0) <= pressrelease; -- kempston right

				-- Other special keys sent to the ULA as key combinations
				when X"66" => keys(0)(0) <= pressrelease_n; -- Backspace (CAPS 0)
							  keys(4)(0) <= pressrelease_n;
				when X"58" => keys(0)(0) <= pressrelease_n; -- Caps lock (CAPS 2)
							  keys(3)(1) <= pressrelease_n;
				when X"0d" => keys(0)(0) <= pressrelease_n; -- Tab (CAPS SPACE)
						      keys(7)(0) <= pressrelease_n;
				when X"49" => keys(7)(2) <= pressrelease_n; -- .
							  keys(7)(1) <= pressrelease_n;
				when X"4e" => keys(6)(3) <= pressrelease_n; -- -
							  keys(7)(1) <= pressrelease_n;
				when X"0e" => keys(3)(0) <= pressrelease_n; -- ` (EDIT)
							  keys(0)(0) <= pressrelease_n;
				when X"41" => keys(7)(3) <= pressrelease_n; -- ,
							  keys(7)(1) <= pressrelease_n;
				when X"4c" => keys(5)(1) <= pressrelease_n; -- ;
							  keys(7)(1) <= pressrelease_n;
				when X"52" => keys(5)(0) <= pressrelease_n; -- "
							  keys(7)(1) <= pressrelease_n;
				when X"5d" => keys(0)(1) <= pressrelease_n; -- :
							  keys(7)(1) <= pressrelease_n;
				when X"55" => keys(6)(1) <= pressrelease_n; -- =
							  keys(7)(1) <= pressrelease_n;
				when X"54" => keys(4)(2) <= pressrelease_n; -- (
							  keys(7)(1) <= pressrelease_n;
				when X"5b" => keys(4)(1) <= pressrelease_n; -- )
							  keys(7)(1) <= pressrelease_n;
				when X"4a" => keys(0)(3) <= pressrelease_n; -- ?
							  keys(7)(1) <= pressrelease_n;
				--------------------------------------------
		
				-- Soft keys
				when X"05" => keys_f(1) <= pressrelease; -- F1
				when X"06" => keys_f(2) <= pressrelease; -- F2
				when X"04" => keys_f(3) <= pressrelease; -- F3
				when X"0c" => keys_f(4) <= pressrelease; -- F4
				
				when X"03" => keys_f(5) <= pressrelease; -- F5
				when X"0b" => keys_f(6) <= pressrelease; -- F6
				when X"83" => keys_f(7) <= pressrelease; -- F7
				when X"0a" => keys_f(8) <= pressrelease; -- F8
				
				when X"01" => keys_f(9) <= pressrelease; -- F9
				when X"09" => keys_f(10) <= pressrelease; -- F10
				when X"78" => keys_f(11) <= pressrelease; -- F11
				when X"07" => keys_f(12) <= pressrelease; -- F12
				 
				-- Hardware keys
				--when X"7c" => keys(9)(2) <= pressrelease;	-- PrtScr					
				--when X"7e" => keys(9)(3) <= pressrelease;	-- Scroll Lock
				--when X"48" => keys(9)(4) <= pressrelease;	-- Pause
								
				when others => null;
			end case;
		end if;
	end process;

end architecture;
