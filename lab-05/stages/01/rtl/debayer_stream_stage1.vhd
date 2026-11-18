library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debayer_stream_stage1 is
    generic (
        N : integer := 4
    );
    port (
        clk             : in  std_logic;
        rst_n           : in  std_logic;
        valid_in        : in  std_logic;
        new_image       : in  std_logic;
        pixel_in        : in  std_logic_vector(7 downto 0);

        r_out           : out std_logic_vector(7 downto 0);
        g_out           : out std_logic_vector(7 downto 0);
        b_out           : out std_logic_vector(7 downto 0);
        valid_out       : out std_logic;

        p00_dbg         : out std_logic_vector(7 downto 0);
        p01_dbg         : out std_logic_vector(7 downto 0);
        p02_dbg         : out std_logic_vector(7 downto 0);
        p10_dbg         : out std_logic_vector(7 downto 0);
        p11_dbg         : out std_logic_vector(7 downto 0);
        p12_dbg         : out std_logic_vector(7 downto 0);
        p20_dbg         : out std_logic_vector(7 downto 0);
        p21_dbg         : out std_logic_vector(7 downto 0);
        p22_dbg         : out std_logic_vector(7 downto 0);

        center_row_even : out std_logic;
        center_col_even : out std_logic
    );
end debayer_stream_stage1;

architecture rtl of debayer_stream_stage1 is

    signal p00_s, p01_s, p02_s : std_logic_vector(7 downto 0);
    signal p10_s, p11_s, p12_s : std_logic_vector(7 downto 0);
    signal p20_s, p21_s, p22_s : std_logic_vector(7 downto 0);

    signal center_row_even_s   : std_logic;
    signal center_col_even_s   : std_logic;
    signal window_valid_s      : std_logic;

begin

    u_window: entity work.stream_window_3x3
        generic map (
            N => N
        )
        port map (
            clk             => clk,
            rst_n           => rst_n,
            valid_in        => valid_in,
            new_image       => new_image,
            pixel_in        => pixel_in,

            p00 => p00_s, p01 => p01_s, p02 => p02_s,
            p10 => p10_s, p11 => p11_s, p12 => p12_s,
            p20 => p20_s, p21 => p21_s, p22 => p22_s,

            center_row_even => center_row_even_s,
            center_col_even => center_col_even_s,
            window_valid    => window_valid_s
        );

    u_core: entity work.debayer_core
        port map (
            p00 => p00_s, p01 => p01_s, p02 => p02_s,
            p10 => p10_s, p11 => p11_s, p12 => p12_s,
            p20 => p20_s, p21 => p21_s, p22 => p22_s,
            row_even => center_row_even_s,
            col_even => center_col_even_s,
            r_out => r_out,
            g_out => g_out,
            b_out => b_out
        );

    valid_out       <= window_valid_s;

    p00_dbg         <= p00_s;
    p01_dbg         <= p01_s;
    p02_dbg         <= p02_s;
    p10_dbg         <= p10_s;
    p11_dbg         <= p11_s;
    p12_dbg         <= p12_s;
    p20_dbg         <= p20_s;
    p21_dbg         <= p21_s;
    p22_dbg         <= p22_s;

    center_row_even <= center_row_even_s;
    center_col_even <= center_col_even_s;

end rtl;
