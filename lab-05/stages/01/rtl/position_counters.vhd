library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity position_counters is
    generic (
        N : integer := 4
    );
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        valid_in  : in  std_logic;
        new_image : in  std_logic;

        row_cnt   : out std_logic_vector(15 downto 0);
        col_cnt   : out std_logic_vector(15 downto 0);
        row_even  : out std_logic;
        col_even  : out std_logic
    );
end position_counters;

architecture rtl of position_counters is
    signal row_reg : integer range 0 to N-1 := 0;
    signal col_reg : integer range 0 to N-1 := 0;
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            row_reg <= 0;
            col_reg <= 0;

        elsif rising_edge(clk) then
            if new_image = '1' then
                row_reg <= 0;
                col_reg <= 0;

            elsif valid_in = '1' then
                if col_reg = N-1 then
                    col_reg <= 0;

                    if row_reg = N-1 then
                        row_reg <= 0;
                    else
                        row_reg <= row_reg + 1;
                    end if;
                else
                    col_reg <= col_reg + 1;
                end if;
            end if;
        end if;
    end process;

    row_cnt  <= std_logic_vector(to_unsigned(row_reg, 16));
    col_cnt  <= std_logic_vector(to_unsigned(col_reg, 16));
    row_even <= '1' when (row_reg mod 2 = 0) else '0';
    col_even <= '1' when (col_reg mod 2 = 0) else '0';

end rtl;
