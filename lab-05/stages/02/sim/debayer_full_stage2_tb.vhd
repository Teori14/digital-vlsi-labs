library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debayer_full_stage2_tb is
end debayer_full_stage2_tb;

architecture sim of debayer_full_stage2_tb is

    constant N : integer := 4;

    signal clk             : std_logic := '0';
    signal rst_n           : std_logic := '0';
    signal valid_in        : std_logic := '0';
    signal new_image       : std_logic := '0';
    signal pixel_in        : std_logic_vector(7 downto 0) := (others => '0');

    signal r_out           : std_logic_vector(7 downto 0);
    signal g_out           : std_logic_vector(7 downto 0);
    signal b_out           : std_logic_vector(7 downto 0);
    signal valid_out       : std_logic;
    signal image_finished  : std_logic;

    signal out_row_dbg     : std_logic_vector(15 downto 0);
    signal out_col_dbg     : std_logic_vector(15 downto 0);

    signal p00_dbg         : std_logic_vector(7 downto 0);
    signal p01_dbg         : std_logic_vector(7 downto 0);
    signal p02_dbg         : std_logic_vector(7 downto 0);
    signal p10_dbg         : std_logic_vector(7 downto 0);
    signal p11_dbg         : std_logic_vector(7 downto 0);
    signal p12_dbg         : std_logic_vector(7 downto 0);
    signal p20_dbg         : std_logic_vector(7 downto 0);
    signal p21_dbg         : std_logic_vector(7 downto 0);
    signal p22_dbg         : std_logic_vector(7 downto 0);

    signal row_even_dbg    : std_logic;
    signal col_even_dbg    : std_logic;

begin

    uut: entity work.debayer_full_stage2
        generic map (
            N => N
        )
        port map (
            clk             => clk,
            rst_n           => rst_n,
            valid_in        => valid_in,
            new_image       => new_image,
            pixel_in        => pixel_in,

            r_out           => r_out,
            g_out           => g_out,
            b_out           => b_out,
            valid_out       => valid_out,
            image_finished  => image_finished,

            out_row_dbg     => out_row_dbg,
            out_col_dbg     => out_col_dbg,

            p00_dbg         => p00_dbg,
            p01_dbg         => p01_dbg,
            p02_dbg         => p02_dbg,
            p10_dbg         => p10_dbg,
            p11_dbg         => p11_dbg,
            p12_dbg         => p12_dbg,
            p20_dbg         => p20_dbg,
            p21_dbg         => p21_dbg,
            p22_dbg         => p22_dbg,

            row_even_dbg    => row_even_dbg,
            col_even_dbg    => col_even_dbg
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
        wait for 220 ns;

        report "debayer_full_stage2_tb finished" severity note;
        wait;
    end process;

    check_proc: process(clk)
        variable valid_count : integer := 0;
    begin
        if rising_edge(clk) then
            if valid_out = '1' then
                valid_count := valid_count + 1;

                if valid_count < 16 then
                    assert image_finished = '0' report "image_finished asserted too early" severity error;
                else
                    assert image_finished = '1' report "image_finished missing on last output" severity error;
                end if;

                case valid_count is
                    when 1 =>
                        assert r_out = x"02" report "Output 1 wrong R" severity error;
                        assert g_out = x"01" report "Output 1 wrong G" severity error;
                        assert b_out = x"01" report "Output 1 wrong B" severity error;

                    when 2 =>
                        assert r_out = x"03" report "Output 2 wrong R" severity error;
                        assert g_out = x"02" report "Output 2 wrong G" severity error;
                        assert b_out = x"02" report "Output 2 wrong B" severity error;

                    when 3 =>
                        assert r_out = x"03" report "Output 3 wrong R" severity error;
                        assert g_out = x"03" report "Output 3 wrong G" severity error;
                        assert b_out = x"03" report "Output 3 wrong B" severity error;

                    when 4 =>
                        assert r_out = x"01" report "Output 4 wrong R" severity error;
                        assert g_out = x"02" report "Output 4 wrong G" severity error;
                        assert b_out = x"04" report "Output 4 wrong B" severity error;

                    when 5 =>
                        assert r_out = x"05" report "Output 5 wrong R" severity error;
                        assert g_out = x"04" report "Output 5 wrong G" severity error;
                        assert b_out = x"03" report "Output 5 wrong B" severity error;

                    when 6 =>
                        assert r_out = x"06" report "Output 6 wrong R" severity error;
                        assert g_out = x"06" report "Output 6 wrong G" severity error;
                        assert b_out = x"06" report "Output 6 wrong B" severity error;

                    when 7 =>
                        assert r_out = x"07" report "Output 7 wrong R" severity error;
                        assert g_out = x"07" report "Output 7 wrong G" severity error;
                        assert b_out = x"07" report "Output 7 wrong B" severity error;

                    when 8 =>
                        assert r_out = x"03" report "Output 8 wrong R" severity error;
                        assert g_out = x"08" report "Output 8 wrong G" severity error;
                        assert b_out = x"08" report "Output 8 wrong B" severity error;

                    when 9 =>
                        assert r_out = x"09" report "Output 9 wrong R" severity error;
                        assert g_out = x"09" report "Output 9 wrong G" severity error;
                        assert b_out = x"05" report "Output 9 wrong B" severity error;

                    when 10 =>
                        assert r_out = x"0A" report "Output 10 wrong R" severity error;
                        assert g_out = x"0A" report "Output 10 wrong G" severity error;
                        assert b_out = x"0A" report "Output 10 wrong B" severity error;

                    when 11 =>
                        assert r_out = x"0B" report "Output 11 wrong R" severity error;
                        assert g_out = x"0B" report "Output 11 wrong G" severity error;
                        assert b_out = x"0B" report "Output 11 wrong B" severity error;

                    when 12 =>
                        assert r_out = x"05" report "Output 12 wrong R" severity error;
                        assert g_out = x"08" report "Output 12 wrong G" severity error;
                        assert b_out = x"0C" report "Output 12 wrong B" severity error;

                    when 13 =>
                        assert r_out = x"0D" report "Output 13 wrong R" severity error;
                        assert g_out = x"05" report "Output 13 wrong G" severity error;
                        assert b_out = x"02" report "Output 13 wrong B" severity error;

                    when 14 =>
                        assert r_out = x"0E" report "Output 14 wrong R" severity error;
                        assert g_out = x"0E" report "Output 14 wrong G" severity error;
                        assert b_out = x"05" report "Output 14 wrong B" severity error;

                    when 15 =>
                        assert r_out = x"0F" report "Output 15 wrong R" severity error;
                        assert g_out = x"0A" report "Output 15 wrong G" severity error;
                        assert b_out = x"05" report "Output 15 wrong B" severity error;

                    when 16 =>
                        assert r_out = x"07" report "Output 16 wrong R" severity error;
                        assert g_out = x"10" report "Output 16 wrong G" severity error;
                        assert b_out = x"06" report "Output 16 wrong B" severity error;

                    when others =>
                        assert false report "More than 16 valid outputs detected" severity error;
                end case;
            end if;
        end if;
    end process;

end sim;
