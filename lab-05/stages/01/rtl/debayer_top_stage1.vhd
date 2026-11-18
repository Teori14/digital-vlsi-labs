library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debayer_top_stage1 is
    generic (
        N : integer := 4
    );
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        valid_in  : in  std_logic;
        new_image : in  std_logic;

        -- Receive a 3x3 pixel neighborhood from the testbench.
        p00, p01, p02 : in  std_logic_vector(7 downto 0);
        p10, p11, p12 : in  std_logic_vector(7 downto 0);
        p20, p21, p22 : in  std_logic_vector(7 downto 0);

        r_out     : out std_logic_vector(7 downto 0);
        g_out     : out std_logic_vector(7 downto 0);
        b_out     : out std_logic_vector(7 downto 0);

        row_cnt   : out std_logic_vector(15 downto 0);
        col_cnt   : out std_logic_vector(15 downto 0);
        row_even  : out std_logic;
        col_even  : out std_logic;

        valid_out : out std_logic
    );
end debayer_top_stage1;

architecture rtl of debayer_top_stage1 is

    signal row_even_s : std_logic;
    signal col_even_s : std_logic;

begin

    u_pos: entity work.position_counters
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
            row_even  => row_even_s,
            col_even  => col_even_s
        );

    u_core: entity work.debayer_core
        port map (
            p00 => p00, p01 => p01, p02 => p02,
            p10 => p10, p11 => p11, p12 => p12,
            p20 => p20, p21 => p21, p22 => p22,
            row_even => row_even_s,
            col_even => col_even_s,
            r_out => r_out,
            g_out => g_out,
            b_out => b_out
        );

    row_even  <= row_even_s;
    col_even  <= col_even_s;
    valid_out <= valid_in;

end rtl;
