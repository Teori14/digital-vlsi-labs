library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debayer_full_stage2 is
    generic (
        N : integer := 4
    );
    port (
        clk             : in  std_logic;
        rst_n           : in  std_logic;
        valid_in        : in  std_logic;
        new_image       : in  std_logic;
        pixel_in        : in  std_logic_vector(7 downto 0);

        r_out           : out std_logic_vector(7 downto 0);
        g_out           : out std_logic_vector(7 downto 0);
        b_out           : out std_logic_vector(7 downto 0);
        valid_out       : out std_logic;
        image_finished  : out std_logic;

        out_row_dbg     : out std_logic_vector(15 downto 0);
        out_col_dbg     : out std_logic_vector(15 downto 0);

        p00_dbg         : out std_logic_vector(7 downto 0);
        p01_dbg         : out std_logic_vector(7 downto 0);
        p02_dbg         : out std_logic_vector(7 downto 0);
        p10_dbg         : out std_logic_vector(7 downto 0);
        p11_dbg         : out std_logic_vector(7 downto 0);
        p12_dbg         : out std_logic_vector(7 downto 0);
        p20_dbg         : out std_logic_vector(7 downto 0);
        p21_dbg         : out std_logic_vector(7 downto 0);
        p22_dbg         : out std_logic_vector(7 downto 0);

        row_even_dbg    : out std_logic;
        col_even_dbg    : out std_logic
    );
end debayer_full_stage2;

architecture rtl of debayer_full_stage2 is

    type frame_row_t is array (0 to N-1) of std_logic_vector(7 downto 0);
    type frame_t     is array (0 to N-1) of frame_row_t;

    type state_t is (IDLE, CAPTURE, OUTPUT);

    signal frame_mem  : frame_t := (others => (others => (others => '0')));
    signal state_reg  : state_t := IDLE;

    signal in_row_reg  : integer range 0 to N-1 := 0;
    signal in_col_reg  : integer range 0 to N-1 := 0;
    signal out_row_reg : integer range 0 to N-1 := 0;
    signal out_col_reg : integer range 0 to N-1 := 0;

    signal p00_s, p01_s, p02_s : std_logic_vector(7 downto 0);
    signal p10_s, p11_s, p12_s : std_logic_vector(7 downto 0);
    signal p20_s, p21_s, p22_s : std_logic_vector(7 downto 0);

    signal row_even_s : std_logic;
    signal col_even_s : std_logic;

begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            for r in 0 to N-1 loop
                for c in 0 to N-1 loop
                    frame_mem(r)(c) <= (others => '0');
                end loop;
            end loop;

            state_reg   <= IDLE;
            in_row_reg  <= 0;
            in_col_reg  <= 0;
            out_row_reg <= 0;
            out_col_reg <= 0;

        elsif rising_edge(clk) then

            if (new_image = '1') and (valid_in = '1') then
                for r in 0 to N-1 loop
                    for c in 0 to N-1 loop
                        frame_mem(r)(c) <= (others => '0');
                    end loop;
                end loop;

                frame_mem(0)(0) <= pixel_in;

                out_row_reg <= 0;
                out_col_reg <= 0;

                if N = 1 then
                    state_reg  <= OUTPUT;
                    in_row_reg <= 0;
                    in_col_reg <= 0;
                else
                    state_reg  <= CAPTURE;
                    in_row_reg <= 0;
                    in_col_reg <= 1;
                end if;

            else
                case state_reg is

                    when IDLE =>
                        null;

                    when CAPTURE =>
                        if valid_in = '1' then
                            frame_mem(in_row_reg)(in_col_reg) <= pixel_in;

                            if (in_row_reg = N-1) and (in_col_reg = N-1) then
                                out_row_reg <= 0;
                                out_col_reg <= 0;
                                state_reg   <= OUTPUT;
                            else
                                if in_col_reg = N-1 then
                                    in_col_reg <= 0;
                                    in_row_reg <= in_row_reg + 1;
                                else
                                    in_col_reg <= in_col_reg + 1;
                                end if;
                            end if;
                        end if;

                    when OUTPUT =>
                        if (out_row_reg = N-1) and (out_col_reg = N-1) then
                            state_reg <= IDLE;
                        else
                            if out_col_reg = N-1 then
                                out_col_reg <= 0;
                                out_row_reg <= out_row_reg + 1;
                            else
                                out_col_reg <= out_col_reg + 1;
                            end if;
                        end if;

                end case;
            end if;
        end if;
    end process;

    p00_s <= (others => '0') when ((out_row_reg = 0) or (out_col_reg = 0))
             else frame_mem(out_row_reg - 1)(out_col_reg - 1);

    p01_s <= (others => '0') when (out_row_reg = 0)
             else frame_mem(out_row_reg - 1)(out_col_reg);

    p02_s <= (others => '0') when ((out_row_reg = 0) or (out_col_reg = N-1))
             else frame_mem(out_row_reg - 1)(out_col_reg + 1);

    p10_s <= (others => '0') when (out_col_reg = 0)
             else frame_mem(out_row_reg)(out_col_reg - 1);

    p11_s <= frame_mem(out_row_reg)(out_col_reg);

    p12_s <= (others => '0') when (out_col_reg = N-1)
             else frame_mem(out_row_reg)(out_col_reg + 1);

    p20_s <= (others => '0') when ((out_row_reg = N-1) or (out_col_reg = 0))
             else frame_mem(out_row_reg + 1)(out_col_reg - 1);

    p21_s <= (others => '0') when (out_row_reg = N-1)
             else frame_mem(out_row_reg + 1)(out_col_reg);

    p22_s <= (others => '0') when ((out_row_reg = N-1) or (out_col_reg = N-1))
             else frame_mem(out_row_reg + 1)(out_col_reg + 1);

    row_even_s <= '1' when ((out_row_reg mod 2) = 0) else '0';
    col_even_s <= '1' when ((out_col_reg mod 2) = 0) else '0';

    u_core: entity work.debayer_core
        port map (
            p00 => p00_s, p01 => p01_s, p02 => p02_s,
            p10 => p10_s, p11 => p11_s, p12 => p12_s,
            p20 => p20_s, p21 => p21_s, p22 => p22_s,
            row_even => row_even_s,
            col_even => col_even_s,
            r_out => r_out,
            g_out => g_out,
            b_out => b_out
        );

    valid_out      <= '1' when (state_reg = OUTPUT) else '0';
    image_finished <= '1' when ((state_reg = OUTPUT) and (out_row_reg = N-1) and (out_col_reg = N-1)) else '0';

    out_row_dbg <= std_logic_vector(to_unsigned(out_row_reg, 16));
    out_col_dbg <= std_logic_vector(to_unsigned(out_col_reg, 16));

    p00_dbg <= p00_s;
    p01_dbg <= p01_s;
    p02_dbg <= p02_s;
    p10_dbg <= p10_s;
    p11_dbg <= p11_s;
    p12_dbg <= p12_s;
    p20_dbg <= p20_s;
    p21_dbg <= p21_s;
    p22_dbg <= p22_s;

    row_even_dbg <= row_even_s;
    col_even_dbg <= col_even_s;

end rtl;
