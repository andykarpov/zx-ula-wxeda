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

		ula_r : in std_logic;
		ula_g : in std_logic;
		ula_b : in std_logic;
		ula_i : in std_logic;
		ula_c : in std_logic;
		ula_hs : in std_logic;
		ula_vs : in std_logic;

		vga_r : out std_logic_vector(7 downto 0);
		vga_g : out std_logic_vector(7 downto 0);
		vga_b : out std_logic_vector(7 downto 0);
		vga_hs : out std_logic;
		vga_vs : out std_logic
	);
end;

architecture rtl of video is

signal vga_red		:	std_logic_vector(1 downto 0);
signal vga_green	:	std_logic_vector(1 downto 0);
signal vga_blue		:	std_logic_vector(1 downto 0);
signal vga_red_out	: std_logic_vector(2 downto 0);
signal vga_green_out : std_logic_vector(2 downto 0);
signal vga_blue_out  : std_logic_vector(2 downto 0);
signal vga_hsync	:	std_logic;
signal vga_vsync	:	std_logic;
signal vga_sblank	:	std_logic;

begin

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
		I_VIDEO		=> (ula_i and ula_r) & ula_r & (ula_i and ula_g) & ula_g & (ula_i and ula_b) & ula_b,
		I_HSYNC		=> ula_hs,
		I_VSYNC		=> ula_vs,
		O_VIDEO(5 downto 4)	=> vga_red,
		O_VIDEO(3 downto 2)	=> vga_green,
		O_VIDEO(1 downto 0)	=> vga_blue,
		O_HSYNC		=> vga_hs,
		O_VSYNC		=> vga_vs,
		O_CMPBLK_N	=> vga_sblank,
		CLK			=> clk_7,
		CLK_x2		=> clk_14
	);

-- RGB converter
U6 : entity work.rgb_builder
	port map (
		mode => '0',
		clk => clk_28,
		reset => reset,
		r => vga_red(0) and vga_sblank,
		g => vga_green(0) and vga_sblank,
		b => vga_blue(0) and vga_sblank,
		i => (vga_red(1) or vga_green(1) or vga_blue(1)) and vga_sblank,
		red => vga_red_out,
		green => vga_green_out,
		blue => vga_blue_out,
		rgbulaplus => "00000000"
	);

	-- VGA output
vga_r <= vga_red_out(2 downto 0) 	& "00000";
vga_g <= vga_green_out(2 downto 0) & "00000";
vga_b <= vga_blue_out(2 downto 0) 	& "00000";

end architecture rtl;