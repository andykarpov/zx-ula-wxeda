library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity video is
port (
		reset : in std_logic;
		clk_7 : in std_logic;
		clk_14: in std_logic;
		clk_28: in std_logic;

		-- inputs from ULA
		ula_r : in std_logic;
		ula_g : in std_logic;
		ula_b : in std_logic;
		ula_i : in std_logic;
		ula_c : in std_logic;
		ula_hs : in std_logic;
		ula_vs : in std_logic;
		ulaplus_rgb: in std_logic_vector(7 downto 0);
		ulaplus_enabled : in std_logic;

		-- output to VGA
		vga_r : out std_logic_vector(7 downto 0);
		vga_g : out std_logic_vector(7 downto 0);
		vga_b : out std_logic_vector(7 downto 0);
		vga_hs : out std_logic;
		vga_vs : out std_logic
	);
end;

architecture rtl of video is

signal ula_red		: std_logic_vector(2 downto 0);
signal ula_green 	: std_logic_vector(2 downto 0);
signal ula_blue  	: std_logic_vector(2 downto 0);

signal vga_red	: std_logic_vector(2 downto 0);
signal vga_green : std_logic_vector(2 downto 0);
signal vga_blue  : std_logic_vector(2 downto 0);

signal vga_hsync	:	std_logic;
signal vga_vsync	:	std_logic;
signal vga_sblank	:	std_logic;

begin

-- RGB converter (switch between ula/ulaplus, outputs 3-bit per color)
U6 : entity work.rgb_builder
	port map (
		mode => ulaplus_enabled,
		clk => clk_28,
		reset => reset,
		-- inputs
		r => ula_r,
		g => ula_g,
		b => ula_b,
		i => ula_i,
		rgbulaplus => ulaplus_rgb,
		-- outputs
		red => ula_red,
		green => ula_green,
		blue => ula_blue
	);


-- VGA converter
U5 : entity work.scan_convert
	generic map (
		-- mark active area of input video
		cstart      	=>  38,  -- composite sync start
		clength     	=> 352,  -- composite sync length
		-- output video timing
		hA		=>  24,	-- h front porch
		hB		=>  32,	-- h sync
		hC		=>  40,	-- h back porch
		hD		=> 352,	-- visible video
	--	vA		=>   0,	-- v front porch (not used)
		vB		=>   2,	-- v sync
		vC		=>  10,	-- v back porch
		vD		=> 284,	-- visible video
		hpad		=>   0,	-- create H black border
		vpad		=>   0	-- create V black border
	)
	port map (
		-- clock
		CLK			=> clk_7,
		CLK_x2		=> clk_14,
		-- inputs
		I_VIDEO		=> ula_red(2 downto 0) & ula_green(2 downto 0) & ula_blue(2 downto 0),
		I_HSYNC		=> ula_hs,
		I_VSYNC		=> ula_vs,
		-- outputs
		O_VIDEO(8 downto 6)	=> vga_red,
		O_VIDEO(5 downto 3)	=> vga_green,
		O_VIDEO(2 downto 0)	=> vga_blue,
		O_HSYNC		=> vga_hs,
		O_VSYNC		=> vga_vs,
		O_CMPBLK_N	=> vga_sblank
	);

-- VGA output
vga_r <= vga_red(2 downto 0) & "00000" when vga_sblank='1' else "00000000"; 
vga_g <= vga_green(2 downto 0) & "00000" when vga_sblank='1' else "00000000";
vga_b <= vga_blue(2 downto 0) & "00000" when vga_sblank='1' else "00000000";

end architecture rtl;