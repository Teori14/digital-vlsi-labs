library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_cu is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        valid_in     : in  std_logic;
        rom_address  : out std_logic_vector(2 downto 0);
        ram_address  : out std_logic_vector(2 downto 0);
        mac_en       : out std_logic;
        mac_init     : out std_logic;
        sample_load  : out std_logic;
        use_direct_x : out std_logic;
        valid_out    : out std_logic
    );
end fir_cu;

architecture Behavioral of fir_cu is
    signal busy          : std_logic := '0';
    signal count         : unsigned(2 downto 0) := (others => '0');
    signal valid_out_reg : std_logic := '0';
begin

    rom_address <= "000" when busy = '0' else std_logic_vector(count);
    ram_address <= "000" when busy = '0' else std_logic_vector(count);

    mac_en       <= '1' when (busy = '1') or (busy = '0' and valid_in = '1') else '0';
    mac_init     <= '1' when (busy = '0' and valid_in = '1') else '0';
    sample_load  <= '1' when (busy = '0' and valid_in = '1') else '0';
    use_direct_x <= '1' when (busy = '0' and valid_in = '1') else '0';
    valid_out    <= valid_out_reg;

    process(clk, rst)
    begin
        if rst = '1' then
            busy          <= '0';
            count         <= (others => '0');
            valid_out_reg <= '0';
        elsif rising_edge(clk) then
            valid_out_reg <= '0';

            if busy = '0' then
                if valid_in = '1' then
                    busy  <= '1';
                    count <= "001";
                else
                    count <= (others => '0');
                end if;
            else
                if count = "111" then
                    valid_out_reg <= '1';
                    busy          <= '0';
                    count         <= (others => '0');
                else
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
