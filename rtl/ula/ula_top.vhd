library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;    

entity ula_top is                   
	port(
    
    -- 14 MHz master clock
    clk14 : in std_logic;
    reset : in std_logic; -- to reset the ULA to normal color mode.
	 
	 -- CPU interfacing
    a : in std_logic_vector(15 downto 0); -- Address bus from CPU (not all lines are used)
    din : in std_logic_vector(7 downto 0); -- Input data bus from CPU
	dout : out std_logic_vector(7 downto 0); -- Output data bus to CPU
    mreq_n : in std_logic; 	-- MREQ from CPU
    iorq_n : in std_logic; 	-- IORQ from CPU
    rd_n : in std_logic; 	-- RD from CPU
    wr_n : in std_logic; 	-- WR from CPU
	rfsh_n : in std_logic;	-- RFSH from CPU
	clkcpu : out std_logic;	-- CLK to CPU
	msk_int_n : out std_logic; -- Vertical retrace interrupt, to CPU

	-- VRAM interfacing
    va : out std_logic_vector(13 downto 0);		-- Address bus to VRAM (16K)
	vramdout : in std_logic_vector(7 downto 0); -- Data from VRAM to ULA/CPU
	vramdin : out std_logic_vector(7 downto 0); -- Data from CPU to VRAM
    vramoe : out std_logic; -- 
    vramcs : out std_logic; -- Control signals for VRAM
    vramwe : out std_logic; --

	-- ULA I/O
    ear : in std_logic; 	-- tape in ?
    mic : out std_logic;	-- tape out ?
    spk : out std_logic;	-- speaker
	kbrows : out std_logic_vector(7 downto 0); -- Keyboard rows
    kbcolumns : in std_logic_vector(4 downto 0); -- Keyboard columns
	
	-- Video output
    r : out std_logic; -- RED TTL signal
    g : out std_logic; -- GREEN TTL signal
    b : out std_logic; -- BLUE TTL signal
    i : out std_logic; -- Bright TTL signal
    csync : out std_logic; -- composite sync
    hsync : out std_logic; -- composite sync
    vsync : out std_logic; -- composite sync
    rgbulaplus : out std_logic_vector(7 downto 0); -- 8-bit RGB value for current pixel, ULA+
    ulaplus_enabled : out std_logic  -- =1 if ULAPlus enabled. To help selecting the right outputs to the RGB DAC
);
end ula_top;

architecture rtl of ula_top is 

component ula is                   
	port(
    
    -- 14 MHz master clock
    clk14 : in std_logic;
    reset : in std_logic; -- to reset the ULA to normal color mode.
	 
	 -- CPU interfacing
    a : in std_logic_vector(15 downto 0); -- Address bus from CPU (not all lines are used)
    din : in std_logic_vector(7 downto 0); -- Input data bus from CPU
	dout : out std_logic_vector(7 downto 0); -- Output data bus to CPU
    mreq_n : in std_logic; 	-- MREQ from CPU
    iorq_n : in std_logic; 	-- IORQ from CPU
    rd_n : in std_logic; 	-- RD from CPU
    wr_n : in std_logic; 	-- WR from CPU
	rfsh_n : in std_logic;	-- RFSH from CPU
	clkcpu : out std_logic;	-- CLK to CPU
	msk_int_n : out std_logic; -- Vertical retrace interrupt, to CPU

	-- VRAM interfacing
    va : out std_logic_vector(13 downto 0);		-- Address bus to VRAM (16K)
	vramdout : in std_logic_vector(7 downto 0); -- Data from VRAM to ULA/CPU
	vramdin : out std_logic_vector(7 downto 0); -- Data from CPU to VRAM
    vramoe : out std_logic; -- 
    vramcs : out std_logic; -- Control signals for VRAM
    vramwe : out std_logic; --

	-- ULA I/O
    ear : in std_logic; 	-- tape out
    mic : out std_logic;	-- tape in
    spk : out std_logic;	-- speaker
	kbrows : out std_logic_vector(7 downto 0); -- Keyboard rows
    kbcolumns : in std_logic_vector(4 downto 0); -- Keyboard columns
	
	-- Video output
    r : out std_logic; -- RED TTL signal
    g : out std_logic; -- GREEN TTL signal
    b : out std_logic; -- BLUE TTL signal
    i : out std_logic; -- Bright TTL signal
    csync : out std_logic; -- composite sync
    hsync : out std_logic; -- composite sync
    vsync : out std_logic; -- composite sync
    rgbulaplus : out std_logic_vector(7 downto 0); -- 8-bit RGB value for current pixel, ULA+
    ulaplus_enabled : out std_logic  -- =1 if ULAPlus enabled. To help selecting the right outputs to the RGB DAC

);
end component;

begin

ins_ula: ula 
port map (
	clk14 => clk14,
    reset => reset,
    a => a,
    din => din,
	dout => dout,
    mreq_n => mreq_n,
    iorq_n => iorq_n,
    rd_n => rd_n,
    wr_n => wr_n,
	rfsh_n => rfsh_n, 
	clkcpu => clkcpu,
	msk_int_n => msk_int_n,
    va => va,
	vramdout => vramdout,
	vramdin => vramdin,
    vramoe => vramoe,
    vramcs => vramcs,
    vramwe => vramwe,
    ear => ear,
    mic => mic,
    spk => spk,
	kbrows => kbrows,
    kbcolumns => kbcolumns,
    r => r,
    g => g,
    b => b,
    i => i,
    csync => csync,
    hsync => hsync,
    vsync => vsync,
    rgbulaplus => rgbulaplus,
    ulaplus_enabled => ulaplus_enabled
);

end rtl;