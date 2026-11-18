library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debayer_partA_final is
    port (
        clk            : in  std_logic;
        rst_n          : in  std_logic;

        -- Runtime configuration.
        -- image_dim must be one of: 64, 128, 256, 512, 1024.
        image_dim      : in  std_logic_vector(15 downto 0);
        image_dim_vld  : in  std_logic;

        pixel          : in  std_logic_vector(7 downto 0);
        valid_in       : in  std_logic;
        new_image      : in  std_logic;

        R              : out std_logic_vector(7 downto 0);
        G              : out std_logic_vector(7 downto 0);
        B              : out std_logic_vector(7 downto 0);
        valid_out      : out std_logic;
        image_finished : out std_logic
    );
end debayer_partA_final;

architecture rtl of debayer_partA_final is

    constant MAX_N      : integer := 1024;
    constant MAX_PIXELS : integer := MAX_N * MAX_N;

    type row_buffer_t is array (0 to MAX_N-1) of std_logic_vector(7 downto 0);
    signal fifo1, fifo2 : row_buffer_t := (others => (others => '0'));
    signal wr_ptr       : integer range 0 to MAX_N-1 := 0;

    attribute ram_style : string;
    attribute ram_style of fifo1 : signal is "block";
    attribute ram_style of fifo2 : signal is "block";

    signal active_dim    : integer range 0 to MAX_N := 0;
    signal active_pixels : integer range 0 to MAX_PIXELS := 0;
    signal configured    : std_logic := '0';

    signal p22, p21, p20 : std_logic_vector(7 downto 0) := (others => '0');
    signal p12, p11, p10 : std_logic_vector(7 downto 0) := (others => '0');
    signal p02, p01, p00 : std_logic_vector(7 downto 0) := (others => '0');

    signal mux_p00, mux_p01, mux_p02 : std_logic_vector(7 downto 0);
    signal mux_p10, mux_p11, mux_p12 : std_logic_vector(7 downto 0);
    signal mux_p20, mux_p21, mux_p22 : std_logic_vector(7 downto 0);

    signal in_count    : integer range 0 to MAX_PIXELS := 0;
    signal out_count   : integer range 0 to MAX_PIXELS := 0;
    signal shift_count : integer range 0 to MAX_PIXELS + MAX_N + 5 := 0;
    signal out_row     : integer range 0 to MAX_N-1 := 0;
    signal out_col     : integer range 0 to MAX_N-1 := 0;

    signal flushing      : std_logic;
    signal shift_en      : std_logic;
    signal pixel_in_mux  : std_logic_vector(7 downto 0);

    signal row_even, col_even : std_logic;
    signal core_valid_in      : std_logic;
    signal core_last_in       : std_logic;

    procedure clear_window(
        signal sp22, sp21, sp20 : out std_logic_vector(7 downto 0);
        signal sp12, sp11, sp10 : out std_logic_vector(7 downto 0);
        signal sp02, sp01, sp00 : out std_logic_vector(7 downto 0)
    ) is
    begin
        sp22 <= (others => '0'); sp21 <= (others => '0'); sp20 <= (others => '0');
        sp12 <= (others => '0'); sp11 <= (others => '0'); sp10 <= (others => '0');
        sp02 <= (others => '0'); sp01 <= (others => '0'); sp00 <= (others => '0');
    end procedure;

begin

    flushing <= '1' when (configured = '1') and
                         (active_pixels > 0) and
                         (in_count = active_pixels) and
                         (out_count < active_pixels)
                else '0';

    shift_en <= '1' when (configured = '1') and
                         ((valid_in = '1') or (flushing = '1'))
                else '0';

    pixel_in_mux <= pixel when valid_in = '1' else (others => '0');

    process(clk, rst_n)
        variable dim_i : integer;
    begin
        if rst_n = '0' then
            active_dim    <= 0;
            active_pixels <= 0;
            configured    <= '0';

            in_count    <= 0;
            out_count   <= 0;
            shift_count <= 0;
            wr_ptr      <= 0;
            out_row     <= 0;
            out_col     <= 0;
            clear_window(p22, p21, p20, p12, p11, p10, p02, p01, p00);

        elsif rising_edge(clk) then

            -- Configuration phase. Software writes image_dim before starting DMA.
            -- new_image is high while the accelerator is idle and waiting for the first pixel.
            if (image_dim_vld = '1') and (new_image = '1') and (valid_in = '0') then
                dim_i := to_integer(unsigned(image_dim));

                case dim_i is
                    when 64 =>
                        active_dim    <= 64;
                        active_pixels <= 4096;
                        configured    <= '1';
                    when 128 =>
                        active_dim    <= 128;
                        active_pixels <= 16384;
                        configured    <= '1';
                    when 256 =>
                        active_dim    <= 256;
                        active_pixels <= 65536;
                        configured    <= '1';
                    when 512 =>
                        active_dim    <= 512;
                        active_pixels <= 262144;
                        configured    <= '1';
                    when 1024 =>
                        active_dim    <= 1024;
                        active_pixels <= 1048576;
                        configured    <= '1';
                    when others =>
                        active_dim    <= 0;
                        active_pixels <= 0;
                        configured    <= '0';
                end case;

                in_count    <= 0;
                out_count   <= 0;
                shift_count <= 0;
                wr_ptr      <= 0;
                out_row     <= 0;
                out_col     <= 0;
                clear_window(p22, p21, p20, p12, p11, p10, p02, p01, p00);

            elsif (configured = '1') then

                if (new_image = '1') and (valid_in = '1') then
                    in_count    <= 1;
                    out_count   <= 0;
                    shift_count <= 1;
                    wr_ptr      <= 1;
                    out_row     <= 0;
                    out_col     <= 0;

                    p22 <= pixel; p21 <= (others => '0'); p20 <= (others => '0');
                    p12 <= (others => '0'); p11 <= (others => '0'); p10 <= (others => '0');
                    p02 <= (others => '0'); p01 <= (others => '0'); p00 <= (others => '0');

                    fifo1(0) <= pixel;
                    fifo2(0) <= (others => '0');

                else
                    if (valid_in = '1') and (in_count < active_pixels) then
                        in_count <= in_count + 1;
                    end if;

                    if shift_en = '1' then
                        if shift_count < active_pixels + active_dim + 4 then
                            shift_count <= shift_count + 1;
                        end if;

                        if (shift_count >= active_dim + 2) and (out_count < active_pixels) then
                            if out_count < active_pixels - 1 then
                                if out_col = active_dim - 1 then
                                    out_col <= 0;
                                    out_row <= out_row + 1;
                                else
                                    out_col <= out_col + 1;
                                end if;
                            end if;

                            out_count <= out_count + 1;
                        end if;

                        p22 <= pixel_in_mux;
                        p21 <= p22;
                        p20 <= p21;

                        p12 <= fifo1(wr_ptr);
                        p11 <= p12;
                        p10 <= p11;

                        p02 <= fifo2(wr_ptr);
                        p01 <= p02;
                        p00 <= p01;

                        fifo1(wr_ptr) <= pixel_in_mux;
                        fifo2(wr_ptr) <= fifo1(wr_ptr);

                        if wr_ptr = active_dim - 1 then
                            wr_ptr <= 0;
                        else
                            wr_ptr <= wr_ptr + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    row_even <= '1' when (out_row mod 2 = 0) else '0';
    col_even <= '1' when (out_col mod 2 = 0) else '0';

    mux_p00 <= (others => '0') when (out_row = 0) or (out_col = 0) else p00;
    mux_p01 <= (others => '0') when (out_row = 0)                  else p01;
    mux_p02 <= (others => '0') when (out_row = 0) or (out_col = active_dim - 1) else p02;

    mux_p10 <= (others => '0') when (out_col = 0) else p10;
    mux_p11 <= p11;
    mux_p12 <= (others => '0') when (out_col = active_dim - 1) else p12;

    mux_p20 <= (others => '0') when (out_row = active_dim - 1) or (out_col = 0) else p20;
    mux_p21 <= (others => '0') when (out_row = active_dim - 1) else p21;
    mux_p22 <= (others => '0') when (out_row = active_dim - 1) or (out_col = active_dim - 1) else p22;

    core_valid_in <= '1' when (configured = '1') and
                              (shift_en = '1') and
                              (shift_count >= active_dim + 2) and
                              (out_count < active_pixels)
                     else '0';

    core_last_in <= '1' when (core_valid_in = '1') and
                             (out_count = active_pixels - 1)
                    else '0';

    u_core: entity work.debayer_core
        port map (
            clk       => clk,
            rst_n     => rst_n,
            valid_in  => core_valid_in,
            last_in   => core_last_in,
            p00       => mux_p00, p01 => mux_p01, p02 => mux_p02,
            p10       => mux_p10, p11 => mux_p11, p12 => mux_p12,
            p20       => mux_p20, p21 => mux_p21, p22 => mux_p22,
            row_even  => row_even,
            col_even  => col_even,
            r_out     => R,
            g_out     => G,
            b_out     => B,
            valid_out => valid_out,
            last_out  => image_finished
        );

end rtl;
