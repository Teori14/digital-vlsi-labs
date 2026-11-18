library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mlab_rom is
    generic (
        coeff_width : integer := 8
    );
    port (
        addr    : in  std_logic_vector(2 downto 0);
        rom_out : out std_logic_vector(coeff_width-1 downto 0)
    );
end mlab_rom;

architecture Behavioral of mlab_rom is
    type rom_type is array (0 to 7) of std_logic_vector(coeff_width-1 downto 0);
    constant rom : rom_type := (
        "00001000", -- 8
        "00000111", -- 7
        "00000110", -- 6
        "00000101", -- 5
        "00000100", -- 4
        "00000011", -- 3
        "00000010", -- 2
        "00000001"  -- 1
    );
begin
    rom_out <= rom(to_integer(unsigned(addr)));
end Behavioral;
