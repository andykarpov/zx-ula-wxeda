library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity audio is
port (
		clk_dac: in std_logic;
		clk_adc : in std_logic; 
		clk_ula : in std_logic;
		clk_psg : in std_logic;
		reset: in std_logic;
        enable: in std_logic := '0';

		ula_spk : in std_logic;
		ula_mic : in std_logic;
		ula_ear : out std_logic;

		AY_BDIR : in std_logic;
		AY_CS : in std_logic;
		AY_BC : in std_logic;
		AY_DI : in std_logic_vector(7 downto 0);
		AY_DO : out std_logic_vector(7 downto 0);

		ADC_DAT : in std_logic;
		ADC_CLK : out std_logic;
		ADC_CS_N : out std_logic;

		out_buzzer : out std_logic;
		out_dac : out std_logic_vector(7 downto 0);
		out_l : out std_logic;
		out_r : out std_logic

	);
end;

architecture rtl of audio is

signal linein 		: std_logic_vector(7 downto 0);
signal line8in		: std_logic_vector(7 downto 0);
signal tapein		: std_logic;
signal ad_clk_out 	: std_logic;

signal ay_out_a 		: std_logic_vector(7 downto 0);
signal ay_out_b 		: std_logic_vector(7 downto 0);
signal ay_out_c 		: std_logic_vector(7 downto 0);

signal audio_l		: std_logic_vector(15 downto 0);
signal audio_r		: std_logic_vector(15 downto 0);
signal audio_b		: std_logic_vector(15 downto 0);

signal dac_s_l		: std_logic_vector(15 downto 0);
signal dac_s_r		: std_logic_vector(15 downto 0);
signal dac_s_b		: std_logic_vector(15 downto 0);

begin

u_AY8910 : entity work.ay8910
port map(
   CLK            => clk_adc,
   ENA            => clk_psg,
   RESET          => reset,
   BDIR           => AY_BDIR,
   CS             => AY_CS,
   BC             => AY_BC,
   DI             => AY_DI,
   DO             => AY_DO,
   OUT_A          => ay_out_a,
   OUT_B          => ay_out_b,
   OUT_C          => ay_out_c);

-- Delta-Sigma L
U8: entity work.dac
port map (
    CLK   		=> clk_dac,
    RESET 		=> reset,
    DAC_DATA	=> audio_l,
    DAC_OUT   	=> out_l);

-- Delta-Sigma R
U9: entity work.dac
port map (
    CLK   		=> clk_dac,
    RESET 		=> reset,
    DAC_DATA	=> audio_r,
    DAC_OUT   	=> out_r);

ADC : entity work.tlc549 
generic map (
	frequency => 28
)
port map (
	clk => clk_adc,
    reset => reset,
	adc_data => ADC_DAT,
	adc_clk => ADC_CLK,
	adc_cs_n => ADC_CS_N,
	data_out => linein,
    clk_out => ad_clk_out
);

-- Audio
audio_l <= 	  ("0000" & ula_spk & "00000000000") + 
				  ("0000" & ula_mic & "00000000000") + 
				   ("000000" & tapein  & "000000000") + 
				   ("0000" & ay_out_a & "0000") +
				   ("00000" & ay_out_b & "000");

audio_r <=    ("0000" & ula_spk & "00000000000") + 
				  ("0000" & ula_mic & "00000000000") + 
				  ("000000" & tapein  & "000000000") +
				   ("0000" & ay_out_c & "0000") +
				   ("00000" & ay_out_b & "000");

ula_ear <= tapein when enable = '1' else '0';
out_buzzer <= '1';
line8in <= linein(7 downto 0) when enable = '1' else "00000000";
out_dac <= linein;

-- adc to tapein conversion
process (clk_ula, tapein, line8in)
variable HYST: integer := 4;
variable LEVEL: integer := 128;
begin
	if rising_edge(clk_ula) then 
        if (tapein = '1' and line8in < LEVEL - HYST) then 
            tapein <= '0';
        elsif (tapein = '0' and line8in > LEVEL + HYST) then 
            tapein <= '1';
        end if;
	end if;    
end process;

end architecture rtl;