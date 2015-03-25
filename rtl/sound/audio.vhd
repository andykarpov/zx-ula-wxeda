library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity audio is
port (
		clk: in std_logic;
		clk_adc : in std_logic;
		reset: in std_logic;

		ula_spk : in std_logic;
		ula_mic : in std_logic;
		ula_ear : out std_logic;

		ADC_DAT : in std_logic;
		ADC_CLK : out std_logic;
		ADC_CS_N : out std_logic;

		out_buzzer : out std_logic;
		out_l : out std_logic;
		out_r : out std_logic

	);
end;

architecture rtl of audio is

component tlc549c is 
port (
	clk24 : in std_logic;
	adc_data_in : in std_logic;
	adc_clk : out std_logic;
	adc_cs_n : out std_logic;
	adc_data : out std_logic_vector(7 downto 0)
);
end component;

signal line8in		: std_logic_vector(7 downto 0);
signal tapein		: std_logic;

signal audio_l		: std_logic_vector(11 downto 0);
signal audio_r		: std_logic_vector(11 downto 0);
signal audio_b		: std_logic_vector(11 downto 0);

signal dac_s_l		: std_logic_vector(11 downto 0);
signal dac_s_r		: std_logic_vector(11 downto 0);
signal dac_s_b		: std_logic_vector(11 downto 0);

begin

-- Delta-Sigma L
U8: entity work.dac
port map (
    CLK   		=> clk,
    RESET 		=> reset,
    DAC_DATA	=> dac_s_l,
    DAC_OUT   	=> out_l);

-- Delta-Sigma R
U9: entity work.dac
port map (
    CLK   		=> clk,
    RESET 		=> reset,
    DAC_DATA	=> dac_s_r,
    DAC_OUT   	=> out_r);

-- Delta-Sigma B
--UB: entity work.dac
--port map (
--    CLK   		=> clk,
--    RESET 		=> reset,
--    DAC_DATA	=> dac_s_b,
--    DAC_OUT   	=> out_buzzer);

ADC: tlc549c
port map (
	clk24 => clk_adc,
	adc_data_in => ADC_DAT,
	adc_clk => ADC_CLK,
	adc_cs_n => ADC_CS_N,
	adc_data => line8in
);

-- Audio
audio_l <= 	  ("0000" & ula_spk & "0000000") + ("0000" & ula_mic & "0000000");  
audio_r <=    ("0000" & ula_spk & "0000000") + ("0000" & ula_mic & "0000000");
--audio_b <=    ("0000" & ula_spk & "0000000") + ("0000" & ula_mic & "0000000");

-- Convert signed audio data (range 127 to -128) to simple unsigned value.
dac_s_l <= std_logic_vector(unsigned(audio_l + 2048));
dac_s_r <= std_logic_vector(unsigned(audio_r + 2048));
--dac_s_b <= std_logic_vector(unsigned(audio_b + 2048));

ula_ear <= tapein;
out_buzzer <= '1';

process (clk_adc)
variable HYST: integer := 4; --4;
variable LEVEL: integer := 64; -- 128
begin
	if rising_edge(clk_adc) then 
	    if (unsigned(line8in) < LEVEL+HYST) then 
	    	tapein <= '0';
	    end if;
	    if (unsigned(line8in) > LEVEL-HYST) then 
	    	tapein <= '1';
	    end if;
	end if;
end process;

end architecture rtl;