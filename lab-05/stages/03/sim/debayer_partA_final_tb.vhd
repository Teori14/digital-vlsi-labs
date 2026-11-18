library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use std.env.all;

entity debayer_partA_final_tb is
    generic (
        N           : integer := 4;
        INPUT_FILE  : string  := "input_pixels.txt";
        OUTPUT_FILE : string  := "dut_rgb.txt"
    );
end debayer_partA_final_tb;

architecture sim of debayer_partA_final_tb is

    signal clk            : std_logic := '0';
    signal rst_n          : std_logic := '0';
    signal pixel          : std_logic_vector(7 downto 0) := (others => '0');
    signal valid_in       : std_logic := '0';
    signal new_image      : std_logic := '0';
    signal R              : std_logic_vector(7 downto 0);
    signal G              : std_logic_vector(7 downto 0);
    signal B              : std_logic_vector(7 downto 0);
    signal valid_out      : std_logic;
    signal image_finished : std_logic;

    file infile  : text open read_mode is INPUT_FILE;
    file outfile : text open write_mode is OUTPUT_FILE;

begin

    uut: entity work.debayer_partA_final
        generic map (
            N => N
        )
        port map (
            clk            => clk,
            rst_n          => rst_n,
            pixel          => pixel,
            valid_in       => valid_in,
            new_image      => new_image,
            R              => R,
            G              => G,
            B              => B,
            valid_out      => valid_out,
            image_finished => image_finished
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

    stimulus_process: process
        variable l          : line;
        variable pix_int    : integer;
        variable good       : boolean;
        variable pixel_cnt  : integer := 0;
    begin
        rst_n <= '0';
        valid_in <= '0';
        new_image <= '0';
        pixel <= (others => '0');

        wait for 20 ns;
        rst_n <= '1';
        wait until falling_edge(clk);

        while not endfile(infile) loop
            readline(infile, l);

            loop
                read(l, pix_int, good);
                exit when not good;

                assert (pix_int >= 0) and (pix_int <= 255)
                    report "Input pixel out of 8-bit range"
                    severity failure;

                pixel <= std_logic_vector(to_unsigned(pix_int, 8));
                valid_in <= '1';

                if pixel_cnt = 0 then
                    new_image <= '1';
                else
                    new_image <= '0';
                end if;

                pixel_cnt := pixel_cnt + 1;

                wait until rising_edge(clk);
                wait until falling_edge(clk);
            end loop;
        end loop;

        valid_in <= '0';
        new_image <= '0';
        pixel <= (others => '0');

        assert pixel_cnt = N * N
            report "Input file does not contain exactly N*N pixels"
            severity failure;

        wait until rising_edge(clk) and image_finished = '1';
        wait for 20 ns;

        report "Simulation finished successfully" severity note;
        std.env.finish;
        wait;
    end process;

    writer_process: process(clk)
        variable lout      : line;
        variable out_count : integer := 0;
    begin
        if rising_edge(clk) then
            if valid_out = '1' then
                write(lout, to_integer(unsigned(R)));
                write(lout, string'(" "));
                write(lout, to_integer(unsigned(G)));
                write(lout, string'(" "));
                write(lout, to_integer(unsigned(B)));
                writeline(outfile, lout);

                out_count := out_count + 1;

                assert out_count <= N * N
                    report "Produced more than N*N outputs"
                    severity failure;

                if image_finished = '1' then
                    assert out_count = N * N
                        report "image_finished asserted before N*N outputs"
                        severity failure;
                end if;
            end if;
        end if;
    end process;

end sim;
