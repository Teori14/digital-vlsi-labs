library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_position_counters is
end tb_position_counters;

architecture sim of tb_position_counters is

    constant N : integer := 4;

    signal clk       : std_logic := '0';
    signal rst_n     : std_logic := '0';
    signal valid_in  : std_logic := '0';
    signal new_image : std_logic := '0';

    signal row_cnt   : std_logic_vector(15 downto 0);
    signal col_cnt   : std_logic_vector(15 downto 0);
    signal row_even  : std_logic;
    signal col_even  : std_logic;

begin

    uut: entity work.position_counters
        generic map (
            N => N
        )
        port map (
            clk       => clk,
            rst_n     => rst_n,
            valid_in  => valid_in,
            new_image => new_image,
            row_cnt   => row_cnt,
            col_cnt   => col_cnt,
            row_even  => row_even,
            col_even  => col_even
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
        wait for 20 ns;

        rst_n <= '1';
        wait for 10 ns;

        -- start of new image
        new_image <= '1';
        valid_in  <= '1';
        wait for 10 ns;

        new_image <= '0';

        -- Send the rest of a 4x4 image = total 16 valid pixels
        wait for 150 ns;

        -- stop valid
        valid_in <= '0';
        wait for 20 ns;

        report "position_counters test finished" severity note;
        wait;
    end process;

end sim;
