library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.ALL;

-- CTRL_CNT  0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36

-- ADC_CS_n -------------|_________________________________________________|-----------------------------------------------
--                              1     2     3     4     5     6     7     8    ... 17uS pause for sampling
-- ADC_CLK  ___________________|-|___|-|___|-|___|-|___|-|___|-|___|-|___|-|_______________________________________________

-- ADC_DATA                 D7    D6    D5    D4    D3    D2    D1    D0  
--                          5     7     9     11    13    15    17    19
-- DATA_OUT  z  z  z  z  z  z  z  z  z  z  z  z  z  z  z  z  z  z  z  OUT z  z  z  z  z  z  z  z  z  z  z  z  z  z  z  z  z

entity tlc549 is 
generic (
	frequency : integer := 24; -- input freq (in MHz)
	sample_cycles : integer := 28 -- total count of 1mhz cycles to sample data
);
port (
		clk 		: in std_logic;
		reset 		: in std_logic;

		adc_data 	: in std_logic;
		adc_cs_n 	: out std_logic := '1';
		adc_clk  	: out std_logic := '0';

		clk_out		: out std_logic;
		data_out 	: out std_logic_vector(7 downto 0) := "00000000"
	);
end tlc549;

architecture rtl of tlc549 is 

signal clk_1m : std_logic := '0';
signal ad_data_shift : std_logic_vector(7 downto 0) := "00000000"; 
signal adc_clk_out : std_logic := '0';
signal adc_cs_n_out : std_logic := '1';

begin 

-- 2 mhz clock from input clock (default to 24 mhz)
process (clk, reset)
variable cnt : integer range 0 to frequency := 0;
variable half : integer := frequency/2;
variable full : integer := frequency;
begin
	
	if (reset = '1') then 

		clk_1m <= '0';
		cnt := 0;

	elsif rising_edge(clk) then 

		cnt := cnt + 1;

		if (cnt <= half) then
			clk_1m <= '1';
		else 
			clk_1m <= '0';
		end if;

		-- reset counter on frequency cycles
		if (cnt = full) then
			cnt := 0;
		end if;

	end if;

end process;

clk_out <= clk_1m;
adc_clk <= adc_clk_out;
adc_cs_n <= adc_cs_n_out;

-- AD signal generation for sampling / reading
process (clk_1m, reset)
variable cnt : integer range 0 to sample_cycles := 0;
begin
	if (reset = '1') then
		
		cnt := 0;
		adc_clk_out <= '0';
		adc_cs_n_out <= '1';

	elsif rising_edge(clk_1m) then
		
		cnt := cnt + 1;
        adc_cs_n_out <= '1';
        adc_clk_out <= '0';
        
		-- ad cs_n
		if (cnt >= 4 and cnt <= 20) then 
			adc_cs_n_out <= '0';
		end if;

		-- ad clk
		if (cnt = 6 or cnt = 8 or cnt = 10 or cnt = 12 or cnt = 14 or cnt = 16 or cnt = 18 or cnt = 20) then 
			adc_clk_out <= '1';
		end if;

		-- reset counter 
		if (cnt = sample_cycles) then
			cnt := 0;
		end if;

	end if;
end process;

-- sampling data from adc
process (adc_clk_out, reset)
begin
	if (reset = '1') then
		ad_data_shift <= "00000000";
	elsif rising_edge(adc_clk_out) then
		ad_data_shift <= ad_data_shift(6 downto 0) & adc_data;
	end if;
end process;

-- reading data from adc
process (adc_cs_n_out)
begin
	if rising_edge(adc_cs_n_out) then
		data_out <= ad_data_shift;
	end if;	
end process;

end rtl;