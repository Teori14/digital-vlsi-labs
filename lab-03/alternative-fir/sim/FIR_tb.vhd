library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fir_filter is
end tb_fir_filter;

architecture Behavioral of tb_fir_filter is

    constant DATA_WIDTH : integer := 8;
    constant Y_WIDTH    : integer := 14;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal valid_in  : std_logic := '0';
    signal x         : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal y         : std_logic_vector(Y_WIDTH-1 downto 0);
    signal valid_out : std_logic;

begin

    uut : entity work.fir_filter
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            Y_WIDTH    => Y_WIDTH
        )
        port map (
            clk       => clk,
            rst       => rst,
            valid_in  => valid_in,
            x         => x,
            y         => y,
            valid_out => valid_out
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
        ----------------------------------------------------------------
        -- RESET CHECK
        ----------------------------------------------------------------
        rst <= '1';
        wait for 12 ns;
        wait for 1 ns;

        assert valid_out = '0'
            report "valid_out should be 0 during reset"
            severity error;

        assert to_integer(unsigned(y)) = 0
            report "y should be 0 during reset"
            severity error;

        rst <= '0';
        wait for 10 ns;

        ----------------------------------------------------------------
        -- TEST 1: IMPULSE RESPONSE
        ----------------------------------------------------------------

        -- x=1 -> expected y=8
        x <= std_logic_vector(to_unsigned(1, DATA_WIDTH));
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';

        for i in 1 to 7 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;

        assert valid_out = '1' report "valid_out missing for impulse 1" severity error;
        assert to_integer(unsigned(y)) = 8 report "wrong output: expected 8" severity error;

        -- x=0 -> expected y=7
        x <= std_logic_vector(to_unsigned(0, DATA_WIDTH));
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';

        for i in 1 to 7 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;

        assert valid_out = '1' report "valid_out missing for impulse 2" severity error;
        assert to_integer(unsigned(y)) = 7 report "wrong output: expected 7" severity error;

        -- x=0 -> expected y=6
        x <= std_logic_vector(to_unsigned(0, DATA_WIDTH));
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';

        for i in 1 to 7 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;

        assert valid_out = '1' report "valid_out missing for impulse 3" severity error;
        assert to_integer(unsigned(y)) = 6 report "wrong output: expected 6" severity error;

        ----------------------------------------------------------------
        -- TEST 2: SIMPLE KNOWN VALUES
        ----------------------------------------------------------------
        rst <= '1';
        wait for 8 ns;
        rst <= '0';
        wait for 10 ns;

        -- x=10 -> y=80
        x <= std_logic_vector(to_unsigned(10, DATA_WIDTH));
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';

        for i in 1 to 7 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;

        assert valid_out = '1' report "valid_out missing for x=10" severity error;
        assert to_integer(unsigned(y)) = 80 report "wrong output: expected 80" severity error;

        -- x=20 -> y=8*20 + 7*10 = 230
        x <= std_logic_vector(to_unsigned(20, DATA_WIDTH));
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';

        for i in 1 to 7 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;

        assert valid_out = '1' report "valid_out missing for x=20" severity error;
        assert to_integer(unsigned(y)) = 230 report "wrong output: expected 230" severity error;

        -- x=30 -> y=8*30 + 7*20 + 6*10 = 440
        x <= std_logic_vector(to_unsigned(30, DATA_WIDTH));
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';

        for i in 1 to 7 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;

        assert valid_out = '1' report "valid_out missing for x=30" severity error;
        assert to_integer(unsigned(y)) = 440 report "wrong output: expected 440" severity error;

        -- x=40 -> y=8*40 + 7*30 + 6*20 + 5*10 = 700
        x <= std_logic_vector(to_unsigned(40, DATA_WIDTH));
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';

        for i in 1 to 7 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;

        assert valid_out = '1' report "valid_out missing for x=40" severity error;
        assert to_integer(unsigned(y)) = 700 report "wrong output: expected 700" severity error;

        ----------------------------------------------------------------
        -- TEST 3: MAX VALUES
        ----------------------------------------------------------------
        rst <= '1';
        wait for 8 ns;
        rst <= '0';
        wait for 10 ns;

        -- 1st 255 -> 2040
        x <= std_logic_vector(to_unsigned(255, DATA_WIDTH));
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';
        for i in 1 to 7 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;
        assert valid_out = '1' report "valid_out missing max1" severity error;
        assert to_integer(unsigned(y)) = 2040 report "wrong output: expected 2040" severity error;

        -- 2nd 255 -> 3825
        x <= std_logic_vector(to_unsigned(255, DATA_WIDTH));
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';
        for i in 1 to 7 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;
        assert valid_out = '1' report "valid_out missing max2" severity error;
        assert to_integer(unsigned(y)) = 3825 report "wrong output: expected 3825" severity error;

        -- 3rd 255 -> 5355
        x <= std_logic_vector(to_unsigned(255, DATA_WIDTH));
        valid_in <= '1';
        wait until rising_edge(clk);
        valid_in <= '0';
        for i in 1 to 7 loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns;
        assert valid_out = '1' report "valid_out missing max3" severity error;
        assert to_integer(unsigned(y)) = 5355 report "wrong output: expected 5355" severity error;

        report "tb_fir_filter completed successfully" severity note;
        wait;
    end process;

end Behavioral;
