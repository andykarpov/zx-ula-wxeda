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
    process (clk_out)
    variable cnt : integer range 0 to 1000000 := 0;
    variable cnt2 : integer range 0 to 2 := 0;
    begin
        if rising_edge(clk_out) then
            cnt := cnt + 1;

            if (cnt = 5 or cnt = 6 or cnt = 8 or cnt = 10 or cnt = 12 or cnt = 14 or cnt = 16 or cnt = 18 or cnt = 20) then
                if (cnt2 = 0) then
                    adc_data <= '1';
                else 
                    adc_data <= '0';
                end if;
            else 
                adc_data <= 'Z';
            end if;

            if (cnt = 32) then
                cnt := 0;
                cnt2 := cnt2 + 1;
                if (cnt2 = 2) then
                    cnt2 := 0;
                end if;
            end if;

        end if;
    end process;

end;