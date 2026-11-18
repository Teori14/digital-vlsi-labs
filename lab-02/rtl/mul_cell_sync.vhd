library ieee;
use ieee.std_logic_1164.all;
entity mul_cell_sync is
    port (
        clk : in std_logic;
        rst : in std_logic;
        ai  : in std_logic;
        bi  : in std_logic;
        si  : in std_logic;
        ci  : in std_logic;
        ao  : out std_logic;
        bo  : out std_logic;
        so  : out std_logic;
        co  : out std_logic
    );
end entity;
architecture structural of mul_cell_sync is
    signal ab   : std_logic;
    signal a_d1 : std_logic;
begin
    ab <= ai and bi;
    -- synchronous full adder from question 1
    fa_i : entity work.full_adder_sync
        port map (
            clk  => clk,
            rst  => rst,
            a    => ab,
            b    => si,
            cin  => ci,
            s    => so,
            cout => co
        );
    -- b propagates right by 1 cycle
    -- a propagates down by 2 cycles total
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                a_d1 <= '0';
                ao   <= '0';
                bo   <= '0';
            else
                a_d1 <= ai;
                ao   <= a_d1;
                bo   <= bi;
            end if;
        end if;
    end process;
end architecture;
