library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity tb_mlab_rom is
end tb_mlab_rom;
architecture Behavioral of tb_mlab_rom is
    constant coeff_width : integer := 8;
    signal clk     : std_logic := '0';
    signal en      : std_logic := '0';
    signal addr    : std_logic_vector(2 downto 0) := (others => '0');
    signal rom_out : std_logic_vector(coeff_width-1 downto 0);
begin
    -- Instantiate DUT
    uut: entity work.mlab_rom
        generic map (
            coeff_width => coeff_width
        )
        port map (
            clk     => clk,
            en      => en,
            addr    => addr,
            rom_out => rom_out
        );
    -- Clock generation: period = 10 ns
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;
    -- Stimulus
    stim_proc: process
    begin
        -- Initialize the test signals.
        en   <= '0';
        addr <= "000";
        wait for 12 ns;
        -- Enable ROM and test all addresses
        en <= '1';
        addr <= "000";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_out = "00001000"
            report "ERROR at addr=000, expected 8"
            severity error;
        addr <= "001";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_out = "00000111"
            report "ERROR at addr=001, expected 7"
            severity error;
        addr <= "010";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_out = "00000110"
            report "ERROR at addr=010, expected 6"
            severity error;
        addr <= "011";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_out = "00000101"
            report "ERROR at addr=011, expected 5"
            severity error;
        addr <= "100";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_out = "00000100"
            report "ERROR at addr=100, expected 4"
            severity error;
        addr <= "101";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_out = "00000011"
            report "ERROR at addr=101, expected 3"
            severity error;
        addr <= "110";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_out = "00000010"
            report "ERROR at addr=110, expected 2"
            severity error;
        addr <= "111";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_out = "00000001"
            report "ERROR at addr=111, expected 1"
            severity error;
        -- test enable = 0 : output should hold previous value
        en <= '0';
        addr <= "000";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert rom_out = "00000001"
            report "ERROR: rom_out changed while en=0"
            severity error;
        report "ROM test completed successfully." severity note;
        wait;
    end process;
end Behavioral;
