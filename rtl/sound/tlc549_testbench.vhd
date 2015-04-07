library ieee;
use ieee.std_logic_1164.all;

entity tlc549_testbench is
end tlc549_testbench;

architecture behavior of tlc549_testbench is

    component tlc549 is
        port (
            clk       : in std_logic;
            reset       : in std_logic;

            adc_data    : in std_logic;
            adc_cs_n    : out std_logic;
            adc_clk     : out std_logic;

            clk_out     : out std_logic;
            data_out    : out std_logic_vector(7 downto 0)
        );
    end component;

    signal clk24  : std_logic := '0';
    signal reset : std_logic := '0';
    
    signal adc_data : std_logic := '0';
    signal adc_cs_n : std_logic;
    signal adc_clk : std_logic;

    signal clk_out : std_logic;
    signal data_out : std_logic_vector(7 downto 0);
    signal cnt : std_logic := '0';

begin
    uut: tlc549 
    port map (
        clk => clk24,
        reset => reset,
        adc_data => adc_data,
        adc_cs_n => adc_cs_n,
        adc_clk => adc_clk,
        clk_out => clk_out,
        data_out => data_out
    );

    -- simulate reset
    reset <=
        '0' after 0 ns,
        '1' after 300 ns,
        '0' after 1000 ns;

    -- simulate clk 24 MHz
    clk24 <=  '1' after 20 ns when clk24 = '0' else
        '0' after 20 ns when clk24 = '1';

    -- simulate adc_data
    -- "11111111" / "00000000"
    adc_data <= '0' when cnt='0' and adc_cs_n='0' and adc_clk='0' else 
                '1' when cnt='1' and adc_cs_n='0' and adc_clk='0' else 
                'Z';

    process (adc_cs_n) 
    begin
        if falling_edge(adc_cs_n) then 
            if (cnt = '1') then cnt <= '0'; else cnt <= '1'; end if;
        end if;
    end process;

end;