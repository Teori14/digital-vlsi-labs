library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_cu is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        valid_in    : in  std_logic;
        rom_address : out std_logic_vector(2 downto 0);
        ram_address : out std_logic_vector(2 downto 0);
        mac_en      : out std_logic;
        mac_init    : out std_logic;
        valid_out   : out std_logic
    );
end fir_cu;

architecture Behavioral of fir_cu is

    type state_type is (IDLE, RUN);
    signal state : state_type := IDLE;
    signal count : unsigned(2 downto 0) := (others => '0');

begin

    -- combinational outputs
    rom_address <= std_logic_vector(count) when state = RUN else "000";
    ram_address <= std_logic_vector(count) when state = RUN else "000";

    mac_en    <= '1' when state = RUN else '0';
    mac_init  <= '1' when (state = RUN and count = "000") else '0';
    valid_out <= '1' when (state = RUN and count = "111") else '0';

    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            count <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    count <= (others => '0');
                    if valid_in = '1' then
                        state <= RUN;
                    end if;

                when RUN =>
                    if count = "111" then
                        state <= IDLE;
                        count <= (others => '0');
                    else
                        count <= count + 1;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
