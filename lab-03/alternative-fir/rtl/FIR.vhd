library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_filter is
    generic (
        DATA_WIDTH : integer := 8;
        Y_WIDTH    : integer := 14
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        valid_in  : in  std_logic;
        x         : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        y         : out std_logic_vector(Y_WIDTH-1 downto 0);
        valid_out : out std_logic
    );
end fir_filter;

architecture Structural of fir_filter is

    signal rom_address  : std_logic_vector(2 downto 0);
    signal ram_address  : std_logic_vector(2 downto 0);

    signal coeff_s      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal ram_out_s    : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sample_mac_s : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal mac_en_s       : std_logic;
    signal mac_init_s     : std_logic;
    signal sample_load_s  : std_logic;
    signal use_direct_x_s : std_logic;
    signal valid_out_s    : std_logic;

begin

    sample_mac_s <= x when use_direct_x_s = '1' else ram_out_s;

    U_ROM : entity work.mlab_rom
        generic map (
            coeff_width => DATA_WIDTH
        )
        port map (
            addr    => rom_address,
            rom_out => coeff_s
        );

    U_RAM : entity work.fir_sample_ram
        generic map (
            data_width => DATA_WIDTH
        )
        port map (
            clk         => clk,
            rst         => rst,
            sample_load => sample_load_s,
            sample_in   => x,
            addr        => ram_address,
            ram_out     => ram_out_s
        );

    U_MAC : entity work.mac_fir
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ACC_WIDTH  => Y_WIDTH
        )
        port map (
            clk       => clk,
            rst       => rst,
            mac_en    => mac_en_s,
            mac_init  => mac_init_s,
            coeff_in  => coeff_s,
            sample_in => sample_mac_s,
            y_out     => y
        );

    U_CU : entity work.fir_cu
        port map (
            clk          => clk,
            rst          => rst,
            valid_in     => valid_in,
            rom_address  => rom_address,
            ram_address  => ram_address,
            mac_en       => mac_en_s,
            mac_init     => mac_init_s,
            sample_load  => sample_load_s,
            use_direct_x => use_direct_x_s,
            valid_out    => valid_out_s
        );

    valid_out <= valid_out_s;

end Structural;
