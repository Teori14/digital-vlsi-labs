library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_debayer_core is
end tb_debayer_core;

architecture sim of tb_debayer_core is

    signal p00, p01, p02 : std_logic_vector(7 downto 0);
    signal p10, p11, p12 : std_logic_vector(7 downto 0);
    signal p20, p21, p22 : std_logic_vector(7 downto 0);

    signal row_even      : std_logic;
    signal col_even      : std_logic;

    signal r_out         : std_logic_vector(7 downto 0);
    signal g_out         : std_logic_vector(7 downto 0);
    signal b_out         : std_logic_vector(7 downto 0);

begin

    uut: entity work.debayer_core
        port map (
            p00 => p00, p01 => p01, p02 => p02,
            p10 => p10, p11 => p11, p12 => p12,
            p20 => p20, p21 => p21, p22 => p22,
            row_even => row_even,
            col_even => col_even,
            r_out => r_out,
            g_out => g_out,
            b_out => b_out
        );

    stim_proc: process
    begin
        ----------------------------------------------------------------
        -- CASE 1: Blue pixel
        -- Expected:
        -- B = 100
        -- G = (60 + 20 + 40 + 80)/4 = 50
        -- R = (10 + 30 + 50 + 70)/4 = 40
        ----------------------------------------------------------------
        p00 <= x"0A";  -- 10
        p01 <= x"3C";  -- 60
        p02 <= x"1E";  -- 30
        p10 <= x"14";  -- 20
        p11 <= x"64";  -- 100
        p12 <= x"28";  -- 40
        p20 <= x"32";  -- 50
        p21 <= x"50";  -- 80
        p22 <= x"46";  -- 70

        row_even <= '1';
        col_even <= '0';

        wait for 10 ns;

        assert r_out = x"28" report "CASE 1: wrong R" severity error;
        assert g_out = x"32" report "CASE 1: wrong G" severity error;
        assert b_out = x"64" report "CASE 1: wrong B" severity error;

        ----------------------------------------------------------------
        -- CASE 2: Red pixel
        -- Expected:
        -- R = 120
        -- G = (20 + 40 + 60 + 80)/4 = 50
        -- B = (10 + 30 + 50 + 70)/4 = 40
        ----------------------------------------------------------------
        p00 <= x"0A";  -- 10
        p01 <= x"14";  -- 20
        p02 <= x"1E";  -- 30
        p10 <= x"28";  -- 40
        p11 <= x"78";  -- 120
        p12 <= x"3C";  -- 60
        p20 <= x"32";  -- 50
        p21 <= x"50";  -- 80
        p22 <= x"46";  -- 70

        row_even <= '0';
        col_even <= '1';

        wait for 10 ns;

        assert r_out = x"78" report "CASE 2: wrong R" severity error;
        assert g_out = x"32" report "CASE 2: wrong G" severity error;
        assert b_out = x"28" report "CASE 2: wrong B" severity error;

        ----------------------------------------------------------------
        -- CASE 3: Green pixel (first G case)
        -- Expected:
        -- G = 90
        -- R = (40 + 80)/2 = 60
        -- B = (20 + 60)/2 = 40
        ----------------------------------------------------------------
        p00 <= x"00";
        p01 <= x"28";  -- 40
        p02 <= x"00";
        p10 <= x"14";  -- 20
        p11 <= x"5A";  -- 90
        p12 <= x"3C";  -- 60
        p20 <= x"00";
        p21 <= x"50";  -- 80
        p22 <= x"00";

        row_even <= '1';
        col_even <= '1';

        wait for 10 ns;

        assert r_out = x"3C" report "CASE 3: wrong R" severity error;
        assert g_out = x"5A" report "CASE 3: wrong G" severity error;
        assert b_out = x"28" report "CASE 3: wrong B" severity error;

        ----------------------------------------------------------------
        -- CASE 4: Green pixel (second G case)
        -- Expected:
        -- G = 90
        -- R = (20 + 60)/2 = 40
        -- B = (16 + 80)/2 = 48
        ----------------------------------------------------------------
        p00 <= x"00";
        p01 <= x"10";  -- 16
        p02 <= x"00";
        p10 <= x"14";  -- 20
        p11 <= x"5A";  -- 90
        p12 <= x"3C";  -- 60
        p20 <= x"00";
        p21 <= x"50";  -- 80
        p22 <= x"00";

        row_even <= '0';
        col_even <= '0';

        wait for 10 ns;

        assert r_out = x"28" report "CASE 4: wrong R" severity error;
        assert g_out = x"5A" report "CASE 4: wrong G" severity error;
        assert b_out = x"30" report "CASE 4: wrong B" severity error;

        report "All debayer_core tests passed." severity note;
        wait;
    end process;

end sim;
