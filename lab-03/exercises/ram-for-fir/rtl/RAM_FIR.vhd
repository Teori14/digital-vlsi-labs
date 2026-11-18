library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_sample_ram is
    generic (
        data_width : integer := 8
    );
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        en           : in  std_logic;
        sample_valid : in  std_logic;
        sample_in    : in  std_logic_vector(data_width-1 downto 0);
        addr         : in  std_logic_vector(2 downto 0);
        data_out     : out std_logic_vector(data_width-1 downto 0)
    );
end fir_sample_ram;

architecture Behavioral of fir_sample_ram is
    type ram_type is array (0 to 7) of std_logic_vector(data_width-1 downto 0);
    signal ram   : ram_type := (others => (others => '0'));
    signal rdata : std_logic_vector(data_width-1 downto 0) := (others => '0');
begin

    rdata <= ram(to_integer(unsigned(addr)));

    process(clk, rst)
    begin
        if rst = '1' then
            ram      <= (others => (others => '0'));
            data_out <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then

                if sample_valid = '1' then
                    ram(7) <= ram(6);
                    ram(6) <= ram(5);
                    ram(5) <= ram(4);
                    ram(4) <= ram(3);
                    ram(3) <= ram(2);
                    ram(2) <= ram(1);
                    ram(1) <= ram(0);
                    ram(0) <= sample_in;
                end if;

                data_out <= rdata;
            end if;
        end if;
    end process;

end Behavioral;
