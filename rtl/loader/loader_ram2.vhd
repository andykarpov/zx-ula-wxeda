-- Generic RTL expression of Dual port RAM with one read and one write port, unregistered output.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity loader_ram2 is
	generic
		(
			AddrBits : integer := 8;
			DataWidth : integer :=16
		);
	port (
		clock : in std_logic;
		data1 : in std_logic_vector(DataWidth-1 downto 0);
		data2 : in std_logic_vector(DataWidth-1 downto 0);
		address1 : in std_logic_vector(AddrBits-1 downto 0);
		address2 : in std_logic_vector(AddrBits-1 downto 0);
		wren1 : in std_logic;
		wren2 : in std_logic;
		q1 : out std_logic_vector(DataWidth-1 downto 0);
		q2 : out std_logic_vector(DataWidth-1 downto 0)
	);
end loader_ram2;

architecture RTL of loader_ram2 is

type ram_type is array(natural range ((2**AddrBits)-1) downto 0) of std_logic_vector(DataWidth-1 downto 0);
shared variable ram : ram_type;

begin

process (clock)
begin
	if (clock'event and clock = '1') then
		if wren1='1' then
			ram(to_integer(unsigned(address1))) := data1;
		end if;
		if wren2='1' then
			ram(to_integer(unsigned(address2))) := data2;
		end if;
	end if;
end process;

process (clock, address1, address2)
begin
	q1 <= ram(to_integer(unsigned(address1)));
	q2 <= ram(to_integer(unsigned(address2)));
end process;

end rtl;

