library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity multiplier_4bit_systolic_tb is
end entity;
architecture tb of multiplier_4bit_systolic_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal a   : std_logic_vector(3 downto 0) := (others => '0');
    signal b   : std_logic_vector(3 downto 0) := (others => '0');
    signal p   : std_logic_vector(7 downto 0);
    type pipe_t is array (0 to 9) of std_logic_vector(7 downto 0);
begin
    uut : entity work.multiplier_4bit_systolic
        port map (
            clk => clk,
            rst => rst,
            a   => a,
            b   => b,
            p   => p
        );
    clk <= not clk after 5 ns;  -- 10 ns clock period
    stimulus : process
        variable exp_pipe : pipe_t := (others => (others => '0'));
        variable new_prod : unsigned(7 downto 0);
        variable cycles   : integer := 0;
    begin
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        rst <= '0';
        for ia in 0 to 15 loop
            for ib in 0 to 15 loop
                wait until falling_edge(clk);
                a <= std_logic_vector(to_unsigned(ia, 4));
                b <= std_logic_vector(to_unsigned(ib, 4));
                new_prod := to_unsigned(ia * ib, 8);
                wait until rising_edge(clk);
                -- shift expected pipeline
                exp_pipe(9) := exp_pipe(8);
                exp_pipe(8) := exp_pipe(7);
                exp_pipe(7) := exp_pipe(6);
                exp_pipe(6) := exp_pipe(5);
                exp_pipe(5) := exp_pipe(4);
                exp_pipe(4) := exp_pipe(3);
                exp_pipe(3) := exp_pipe(2);
                exp_pipe(2) := exp_pipe(1);
                exp_pipe(1) := exp_pipe(0);
                exp_pipe(0) := std_logic_vector(new_prod);
                wait for 1 ns;
                cycles := cycles + 1;
                if cycles >= 10 then
                    assert p = exp_pipe(9)
                        report "Mismatch in multiplier output"
                        severity error;
                end if;
            end loop;
        end loop;
        -- flush pipeline
        for k in 1 to 9 loop
            wait until falling_edge(clk);
            a <= (others => '0');
            b <= (others => '0');
            wait until rising_edge(clk);
            exp_pipe(9) := exp_pipe(8);
            exp_pipe(8) := exp_pipe(7);
            exp_pipe(7) := exp_pipe(6);
            exp_pipe(6) := exp_pipe(5);
            exp_pipe(5) := exp_pipe(4);
            exp_pipe(4) := exp_pipe(3);
            exp_pipe(3) := exp_pipe(2);
            exp_pipe(2) := exp_pipe(1);
            exp_pipe(1) := exp_pipe(0);
            exp_pipe(0) := (others => '0');
            wait for 1 ns;
            assert p = exp_pipe(9)
                report "Mismatch during pipeline flush"
                severity error;
        end loop;
        report "Simulation completed successfully";
        wait;
    end process;
end architecture;
