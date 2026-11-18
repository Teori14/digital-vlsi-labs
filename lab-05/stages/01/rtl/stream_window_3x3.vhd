library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stream_window_3x3 is
    generic (
        N : integer := 4
    );
    port (
        clk              : in  std_logic;
        rst_n            : in  std_logic;
        valid_in         : in  std_logic;
        new_image        : in  std_logic;
        pixel_in         : in  std_logic_vector(7 downto 0);

        p00, p01, p02    : out std_logic_vector(7 downto 0);
        p10, p11, p12    : out std_logic_vector(7 downto 0);
        p20, p21, p22    : out std_logic_vector(7 downto 0);

        center_row_even  : out std_logic;
        center_col_even  : out std_logic;
        window_valid     : out std_logic
    );
end stream_window_3x3;

architecture rtl of stream_window_3x3 is

    type line_t is array (0 to N-1) of std_logic_vector(7 downto 0);

    signal line1 : line_t := (others => (others => '0'));
    signal line2 : line_t := (others => (others => '0'));

    signal top0, top1, top2 : std_logic_vector(7 downto 0) := (others => '0');
    signal mid0, mid1, mid2 : std_logic_vector(7 downto 0) := (others => '0');
    signal bot0, bot1, bot2 : std_logic_vector(7 downto 0) := (others => '0');

    signal row_reg : integer range 0 to N-1 := 0;
    signal col_reg : integer range 0 to N-1 := 0;

    signal center_row_even_reg : std_logic := '1';
    signal center_col_even_reg : std_logic := '1';
    signal window_valid_reg    : std_logic := '0';

begin

    process(clk, rst_n)
        variable row_curr : integer range 0 to N-1;
        variable col_curr : integer range 0 to N-1;
        variable prev1_v  : std_logic_vector(7 downto 0);
        variable prev2_v  : std_logic_vector(7 downto 0);
    begin
        if rst_n = '0' then
            for i in 0 to N-1 loop
                line1(i) <= (others => '0');
                line2(i) <= (others => '0');
            end loop;

            top0 <= (others => '0');
            top1 <= (others => '0');
            top2 <= (others => '0');
            mid0 <= (others => '0');
            mid1 <= (others => '0');
            mid2 <= (others => '0');
            bot0 <= (others => '0');
            bot1 <= (others => '0');
            bot2 <= (others => '0');

            row_reg <= 0;
            col_reg <= 0;

            center_row_even_reg <= '1';
            center_col_even_reg <= '1';
            window_valid_reg    <= '0';

        elsif rising_edge(clk) then

            if new_image = '1' then
                for i in 0 to N-1 loop
                    line1(i) <= (others => '0');
                    line2(i) <= (others => '0');
                end loop;

                top0 <= (others => '0');
                top1 <= (others => '0');
                top2 <= (others => '0');
                mid0 <= (others => '0');
                mid1 <= (others => '0');
                mid2 <= (others => '0');
                bot0 <= (others => '0');
                bot1 <= (others => '0');
                bot2 <= (others => '0');

                row_reg <= 0;
                col_reg <= 0;
            end if;

            if valid_in = '1' then

                if new_image = '1' then
                    row_curr := 0;
                    col_curr := 0;
                else
                    row_curr := row_reg;
                    col_curr := col_reg;
                end if;

                prev1_v := line1(col_curr);
                prev2_v := line2(col_curr);

                -- Insert left padding at the start of every row
                if col_curr = 0 then
                    top0 <= (others => '0');
                    top1 <= (others => '0');
                    top2 <= prev2_v;

                    mid0 <= (others => '0');
                    mid1 <= (others => '0');
                    mid2 <= prev1_v;

                    bot0 <= (others => '0');
                    bot1 <= (others => '0');
                    bot2 <= pixel_in;
                else
                    top0 <= top1;
                    top1 <= top2;
                    top2 <= prev2_v;

                    mid0 <= mid1;
                    mid1 <= mid2;
                    mid2 <= prev1_v;

                    bot0 <= bot1;
                    bot1 <= bot2;
                    bot2 <= pixel_in;
                end if;

                line2(col_curr) <= line1(col_curr);
                line1(col_curr) <= pixel_in;

                if (row_curr > 0) and (col_curr > 0) then
                    window_valid_reg <= '1';
                else
                    window_valid_reg <= '0';
                end if;

                if row_curr = 0 then
                    center_row_even_reg <= '1';
                elsif ((row_curr - 1) mod 2) = 0 then
                    center_row_even_reg <= '1';
                else
                    center_row_even_reg <= '0';
                end if;

                if col_curr = 0 then
                    center_col_even_reg <= '1';
                elsif ((col_curr - 1) mod 2) = 0 then
                    center_col_even_reg <= '1';
                else
                    center_col_even_reg <= '0';
                end if;

                if col_curr = N-1 then
                    col_reg <= 0;

                    if row_curr = N-1 then
                        row_reg <= 0;
                    else
                        row_reg <= row_curr + 1;
                    end if;
                else
                    col_reg <= col_curr + 1;
                    row_reg <= row_curr;
                end if;

            else
                window_valid_reg <= '0';
            end if;
        end if;
    end process;

    p00 <= top0;
    p01 <= top1;
    p02 <= top2;

    p10 <= mid0;
    p11 <= mid1;
    p12 <= mid2;

    p20 <= bot0;
    p21 <= bot1;
    p22 <= bot2;

    center_row_even <= center_row_even_reg;
    center_col_even <= center_col_even_reg;
    window_valid    <= window_valid_reg;

end rtl;
