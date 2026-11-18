library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fir_cu is
end tb_fir_cu;

architecture Behavioral of tb_fir_cu is

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal valid_in    : std_logic := '0';
    signal rom_address : std_logic_vector(2 downto 0);
    signal ram_address : std_logic_vector(2 downto 0);
    signal mac_en      : std_logic;
    signal mac_init    : std_logic;
    signal valid_out   : std_logic;

begin

    uut: entity work.fir_cu
        port map (
            clk         => clk,
            rst         => rst,
            valid_in    => valid_in,
            rom_address => rom_address,
            ram_address => ram_address,
            mac_en      => mac_en,
            mac_init    => mac_init,
            valid_out   => valid_out
        );

    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    stim_proc : process
    begin
        -- reset
        rst <= '1';
        wait for 12 ns;
        rst <= '0';
        wait for 1 ns;

        assert mac_en = '0' and mac_init = '0' and valid_out = '0'
            report "CU reset/idle error"
            severity error;

        -- pulse valid_in
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';
        wait for 1 ns;

        -- active cycle 0
        assert mac_en = '1'
            report "CU error: mac_en should be 1 at cycle 0"
            severity error;
        assert mac_init = '1'
            report "CU error: mac_init should be 1 at cycle 0"
            severity error;
        assert valid_out = '0'
            report "CU error: valid_out should be 0 at cycle 0"
            severity error;
        assert rom_address = "000" and ram_address = "000"
            report "CU error: address should be 0 at cycle 0"
            severity error;

        -- cycle 1
        wait until rising_edge(clk);
        wait for 1 ns;
        assert mac_en = '1' and mac_init = '0' and valid_out = '0'
            report "CU error at cycle 1"
            severity error;
        assert rom_address = "001" and ram_address = "001"
            report "CU address error at cycle 1"
            severity error;

        -- cycle 2
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_address = "010" and ram_address = "010"
            report "CU address error at cycle 2"
            severity error;

        -- cycle 3
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_address = "011" and ram_address = "011"
            report "CU address error at cycle 3"
            severity error;

        -- cycle 4
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_address = "100" and ram_address = "100"
            report "CU address error at cycle 4"
            severity error;

        -- cycle 5
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_address = "101" and ram_address = "101"
            report "CU address error at cycle 5"
            severity error;

        -- cycle 6
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_address = "110" and ram_address = "110"
            report "CU address error at cycle 6"
            severity error;

        -- cycle 7
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_address = "111" and ram_address = "111"
            report "CU address error at cycle 7"
            severity error;
        assert valid_out = '1'
            report "CU error: valid_out should be 1 at cycle 7"
            severity error;

        -- back to idle
        wait until rising_edge(clk);
        wait for 1 ns;
        assert mac_en = '0' and mac_init = '0' and valid_out = '0'
            report "CU error: should return to IDLE"
            severity error;

        report "CU TB finished successfully" severity note;
        wait;
    end process;

end Behavioral;
