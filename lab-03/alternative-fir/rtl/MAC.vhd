library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mac_fir is
    generic (
        DATA_WIDTH : integer := 8;
        ACC_WIDTH  : integer := 14
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        mac_en    : in  std_logic;
        mac_init  : in  std_logic;
        coeff_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        sample_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        y_out     : out std_logic_vector(ACC_WIDTH-1 downto 0)
    );
end mac_fir;

architecture Behavioral of mac_fir is
    signal acc : unsigned(ACC_WIDTH-1 downto 0) := (others => '0');
begin

    process(clk, rst)
        variable prod_v : unsigned((2*DATA_WIDTH)-1 downto 0);
    begin
        if rst = '1' then
            acc <= (others => '0');
        elsif rising_edge(clk) then
            if mac_en = '1' then
                prod_v := unsigned(coeff_in) * unsigned(sample_in);

                if mac_init = '1' then
                    acc <= resize(prod_v, ACC_WIDTH);
                else
                    acc <= acc + resize(prod_v, ACC_WIDTH);
                end if;
            end if;
        end if;
    end process;

    y_out <= std_logic_vector(acc);

end Behavioral;
