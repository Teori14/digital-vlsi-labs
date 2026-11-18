library ieee;
use ieee.std_logic_1164.all;
entity full_adder_sync is
    port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        a    : in  std_logic;
        b    : in  std_logic;
        cin  : in  std_logic;
        s    : out std_logic;
        cout : out std_logic
    );
end full_adder_sync;
architecture behavioral of full_adder_sync is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                s    <= '0';
                cout <= '0';
            else
                s    <= a xor b xor cin;
                cout <= (a and b) or (a and cin) or (b and cin);
            end if;
        end if;
    end process;
end behavioral;
