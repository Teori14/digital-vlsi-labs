library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debayer_top_stage1_tb is
end debayer_top_stage1_tb;

architecture sim of debayer_top_stage1_tb is

    constant N : integer := 4;

    signal clk       : std_logic := '0';
    signal rst_n     : std_logic := '0';
    signal valid_in  : std_logic := '0';
    signal new_image : std_logic := '0';

    signal p00, p01, p02 : std_logic_vector(7 downto 0);
    signal p10, p11, p12 : std_logic_vector(7 downto 0);
    signal p20, p21, p22 : std_logic_vector(7 downto 0);

    signal r_out     : std_logic_vector(7 downto 0);
    signal g_out     : std_logic_vector(7 downto 0);
    signal b_out     : std_logic_vector(7 downto 0);

    signal row_cnt   : std_logic_vector(15 downto 0);
    signal col_cnt   : std_logic_vector(15 downto 0);
    signal row_even  : std_logic;
    signal col_even  : std_logic;
    signal valid_out : std_logic;

begin

    uut: entity work.debayer_top_stage1
        generic map (
            N => N
        )
        port map (
            clk       => clk,
            rst_n     => rst_n,
            valid_in  => valid_in,
            new_image => new_image,

            p00 => p00, p01 => p01, p02 => p02,
            p10 => p10, p11 => p11, p12 => p12,
            p20 => p20, p21 => p21, p22 => p22,

            r_out => r_out,
            g_out => g_out,
            b_out => b_out,

            row_cnt => row_cnt,
            col_cnt => col_cnt,
            row_even => row_even,
            col_even => col_even,

            valid_out => valid_out
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
        -- reset
        rst_n <= '0';
        valid_in <= '0';
        new_image <= '0';

        -- Provide a 3x3 neighborhood for each pixel.
        p00 <= x"0A";
        p01 <= x"14";
        p02 <= x"1E";
        p10 <= x"28";
        p11 <= x"78";
        p12 <= x"3C";
        p20 <= x"32";
        p21 <= x"50";
        p22 <= x"46";

        wait for 20 ns;
        rst_n <= '1';
        wait for 10 ns;

        -- Clock the next input.
        new_image <= '1';
        valid_in  <= '1';
        wait for 10 ns;

        new_image <= '0';

        -- Check valid output pixels.
        wait for 150 ns;

        valid_in <= '0';
        wait for 20 ns;

        report "debayer_top_stage1_tb finished" severity note;
        wait;
    end process;

end sim;
