library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mac_fir is
end tb_mac_fir;

architecture Behavioral of tb_mac_fir is

    constant DATA_WIDTH : integer := 8;
    constant ACC_WIDTH  : integer := 19;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal mac_en    : std_logic := '0';
    signal mac_init  : std_logic := '0';
    signal coeff_in  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal sample_in : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal y_out     : std_logic_vector(ACC_WIDTH-1 downto 0);

begin

    uut: entity work.mac_fir
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ACC_WIDTH  => ACC_WIDTH
        )
        port map (
            clk       => clk,
            rst       => rst,
            mac_en    => mac_en,
            mac_init  => mac_init,
            coeff_in  => coeff_in,
            sample_in => sample_in,
            y_out     => y_out
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
        wait for 2 ns;

        assert unsigned(y_out) = 0
            report "MAC reset error"
            severity error;

        -- First operation: initialize with 8 * 10 = 80.
        mac_en    <= '1';
        mac_init  <= '1';
        coeff_in  <= std_logic_vector(to_unsigned(8, DATA_WIDTH));
        sample_in <= std_logic_vector(to_unsigned(10, DATA_WIDTH));

        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(y_out) = 80
            report "MAC error after first product"
            severity error;

        -- Second operation: add 7 * 5 = 35, giving 115.
        mac_init  <= '0';
        coeff_in  <= std_logic_vector(to_unsigned(7, DATA_WIDTH));
        sample_in <= std_logic_vector(to_unsigned(5, DATA_WIDTH));

        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(y_out) = 115
            report "MAC accumulation error at step 2"
            severity error;

        -- Third operation: add 6 * 2 = 12, giving 127.
        coeff_in  <= std_logic_vector(to_unsigned(6, DATA_WIDTH));
        sample_in <= std_logic_vector(to_unsigned(2, DATA_WIDTH));

        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(y_out) = 127
            report "MAC accumulation error at step 3"
            severity error;

        -- Idle: hold the accumulated result.
        mac_en    <= '0';
        coeff_in  <= std_logic_vector(to_unsigned(20, DATA_WIDTH));
        sample_in <= std_logic_vector(to_unsigned(20, DATA_WIDTH));

        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(y_out) = 127
            report "MAC hold error while mac_en=0"
            severity error;

        -- Initialize again: 3 * 4 = 12.
        mac_en    <= '1';
        mac_init  <= '1';
        coeff_in  <= std_logic_vector(to_unsigned(3, DATA_WIDTH));
        sample_in <= std_logic_vector(to_unsigned(4, DATA_WIDTH));

        wait until rising_edge(clk);
        wait for 1 ns;
        assert unsigned(y_out) = 12
            report "MAC re-init error"
            severity error;

        report "MAC TB finished successfully" severity note;
        wait;
    end process;

end Behavioral;
