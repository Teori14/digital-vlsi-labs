library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fir_sample_ram is
end tb_fir_sample_ram;

architecture Behavioral of tb_fir_sample_ram is

    constant data_width : integer := 8;

    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal en           : std_logic := '0';
    signal sample_valid : std_logic := '0';
    signal sample_in    : std_logic_vector(data_width-1 downto 0) := (others => '0');
    signal addr         : std_logic_vector(2 downto 0) := (others => '0');
    signal data_out     : std_logic_vector(data_width-1 downto 0);

begin

    uut: entity work.fir_sample_ram
        generic map (
            data_width => data_width
        )
        port map (
            clk          => clk,
            rst          => rst,
            en           => en,
            sample_valid => sample_valid,
            sample_in    => sample_in,
            addr         => addr,
            data_out     => data_out
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
        en  <= '0';
        wait for 12 ns;
        rst <= '0';
        en  <= '1';

        -- load sample 10
        sample_valid <= '1';
        sample_in    <= std_logic_vector(to_unsigned(10, 8));
        wait until rising_edge(clk);

        -- load sample 20
        sample_in <= std_logic_vector(to_unsigned(20, 8));
        wait until rising_edge(clk);

        -- load sample 30
        sample_in <= std_logic_vector(to_unsigned(30, 8));
        wait until rising_edge(clk);

        -- load sample 40
        sample_in <= std_logic_vector(to_unsigned(40, 8));
        wait until rising_edge(clk);

        sample_valid <= '0';

        -- now memory should contain:
        -- addr0=40, addr1=30, addr2=20, addr3=10, others=0

        addr <= "000";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(data_out) = 40 report "FIR RAM error at addr0" severity error;

        addr <= "001";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(data_out) = 30 report "FIR RAM error at addr1" severity error;

        addr <= "010";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(data_out) = 20 report "FIR RAM error at addr2" severity error;

        addr <= "011";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(data_out) = 10 report "FIR RAM error at addr3" severity error;

        addr <= "100";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(data_out) = 0 report "FIR RAM error at addr4" severity error;

        addr <= "101";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(data_out) = 0 report "FIR RAM error at addr5" severity error;

        addr <= "110";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(data_out) = 0 report "FIR RAM error at addr6" severity error;

        addr <= "111";
        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(data_out) = 0 report "FIR RAM error at addr7" severity error;

        report "FIR sample RAM TB finished successfully" severity note;
        wait;
    end process;

end Behavioral;
