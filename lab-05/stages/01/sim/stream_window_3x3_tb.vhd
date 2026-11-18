library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stream_window_3x3_tb is
end stream_window_3x3_tb;

architecture sim of stream_window_3x3_tb is

    constant N : integer := 4;

    signal clk             : std_logic := '0';
    signal rst_n           : std_logic := '0';
    signal valid_in        : std_logic := '0';
    signal new_image       : std_logic := '0';
    signal pixel_in        : std_logic_vector(7 downto 0) := (others => '0');

    signal p00, p01, p02   : std_logic_vector(7 downto 0);
    signal p10, p11, p12   : std_logic_vector(7 downto 0);
    signal p20, p21, p22   : std_logic_vector(7 downto 0);

    signal center_row_even : std_logic;
    signal center_col_even : std_logic;
    signal window_valid    : std_logic;

begin

    uut: entity work.stream_window_3x3
        generic map (
            N => N
        )
        port map (
            clk             => clk,
            rst_n           => rst_n,
            valid_in        => valid_in,
            new_image       => new_image,
            pixel_in        => pixel_in,

            p00 => p00, p01 => p01, p02 => p02,
            p10 => p10, p11 => p11, p12 => p12,
            p20 => p20, p21 => p21, p22 => p22,

            center_row_even => center_row_even,
            center_col_even => center_col_even,
            window_valid    => window_valid
        );

    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    stim_proc: process
    begin
        rst_n <= '0';
        valid_in <= '0';
        new_image <= '0';
        pixel_in <= x"00";
        wait for 20 ns;

        rst_n <= '1';
        wait for 10 ns;

        valid_in <= '1';
        new_image <= '1';
        pixel_in <= x"01";
        wait for 10 ns;

        new_image <= '0';
        pixel_in <= x"02";
        wait for 10 ns;

        pixel_in <= x"03";
        wait for 10 ns;

        pixel_in <= x"04";
        wait for 10 ns;

        pixel_in <= x"05";
        wait for 10 ns;

        pixel_in <= x"06";
        wait for 10 ns;

        pixel_in <= x"07";
        wait for 10 ns;

        pixel_in <= x"08";
        wait for 10 ns;

        pixel_in <= x"09";
        wait for 10 ns;

        pixel_in <= x"0A";
        wait for 10 ns;

        pixel_in <= x"0B";
        wait for 10 ns;

        pixel_in <= x"0C";
        wait for 10 ns;

        pixel_in <= x"0D";
        wait for 10 ns;

        pixel_in <= x"0E";
        wait for 10 ns;

        pixel_in <= x"0F";
        wait for 10 ns;

        pixel_in <= x"10";
        wait for 10 ns;

        valid_in <= '0';
        pixel_in <= x"00";
        wait for 30 ns;

        report "stream_window_3x3_tb finished" severity note;
        wait;
    end process;

end sim;
