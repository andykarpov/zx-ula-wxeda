-------------------------------------------------------------------[06.05.2013]
-- UART Controller for FT232R
-------------------------------------------------------------------------------
-- Engineer: 	MVV
-- Description: 
--
-- Versions:
-- V1.0		05.05.2013	Initial release.
-- V1.1		06.05.2013
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity uart is
	generic (
		divisor		: integer := 243 );	-- divisor = 28MHz / 115200 Baud = 243
	port (
		CLK			: in  std_logic;
		RESET		: in  std_logic;
		WR			: in  std_logic;
		RD			: in  std_logic;
		DI			: in  std_logic_vector(7 downto 0);
		DO			: out std_logic_vector(7 downto 0);
		TXBUSY		: out std_logic;
		RXAVAIL		: out std_logic;
		RXERROR		: out std_logic;
		RXD			: in  std_logic;
		TXD			: out std_logic );
end uart;

architecture rtl of uart is
	constant halfbit : integer := divisor / 2; 

	signal tx_count		: integer range 0 to divisor;
	signal tx_shift_reg	: std_logic_vector(10 downto 0);
	signal tx_busy		: std_logic := '0';
	
	signal rx_buffer	: std_logic_vector(7 downto 0);
	signal rx_bit_count	: integer range 0 to 10;
	signal rx_count		: integer range 0 to divisor;
	signal rx_avail		: std_logic;
	signal rx_error		: std_logic;
	signal rx_shift_reg	: std_logic_vector(7 downto 0);
	signal rx_bit		: std_logic;

begin

process(CLK, RESET) is
begin
	if RESET = '1' then
		tx_shift_reg <= (others => '1');
		tx_count <= 0;
		tx_busy <= '0';
		rx_buffer <= (others => '0');
		rx_bit_count <= 0;
		rx_count <= 0;
		rx_error <= '0';
		rx_avail <= '0';
     elsif CLK'event and CLK = '1' then
-- Transmitter		
		if tx_busy = '0' then
			if WR = '1' then
				tx_shift_reg	<= "01" & DI & '0';	-- STOP, MSB...LSB, START
				tx_busy 		<= '1';
				tx_count 		<= divisor;
			end if;
		else
			if tx_count = 0 then
				if tx_shift_reg = "11111111101" then
					tx_busy <= '0';
				else
					tx_shift_reg <= '1' & tx_shift_reg(10 downto 1);
				end if;
				tx_count <= divisor;
			else
				tx_count <= tx_count - 1;
			end if;
		end if;
		
-- Receiver	 
		if RD = '1' then 
			rx_error <= '0';
			rx_avail <= '0';
		end if;

		if rx_count /= 0 then 
			rx_count <= rx_count - 1;
        else
			if rx_bit_count = 0 then		-- wait for startbit
				if rx_bit = '0' then		-- FOUND
					rx_count <= halfbit;
					rx_bit_count <= rx_bit_count + 1;                                               
				end if;
			elsif rx_bit_count = 1 then		-- sample mid of startbit
				if rx_bit = '0' then		-- OK
					rx_count <= divisor;
					rx_bit_count <= rx_bit_count + 1;
					rx_shift_reg <= "00000000";
				else						-- ERROR
					rx_error <= '1';
					rx_bit_count <= 0;
				end if;
			elsif rx_bit_count = 10 then	-- stopbit
				if rx_bit = '1' then		-- OK
					rx_count <= 0;
					rx_bit_count <= 0;
					rx_buffer <= rx_shift_reg;
					rx_avail <= '1';
				else						-- ERROR
					rx_count <= divisor;
					rx_bit_count <= 0;
					rx_error <= '1';
				end if;
			else
				rx_shift_reg(6 downto 0) <= rx_shift_reg(7 downto 1);
				rx_shift_reg(7)	<= rx_bit;
				rx_count <= divisor;
				rx_bit_count <= rx_bit_count + 1;
			end if;
        end if;
     end if;
end process;

-- Sync incoming RXD (anti metastable)
syncproc: process (RESET, CLK) is
begin
	if RESET = '1' then
		rx_bit <= '1';
	elsif CLK'event and CLK = '0' then
		rx_bit <= RXD;
	end if;
end process;

RXERROR <= rx_error;
RXAVAIL <= rx_avail;
TXBUSY	<= tx_busy;
TXD		<= tx_shift_reg(0);
DO		<= rx_buffer;
end rtl;