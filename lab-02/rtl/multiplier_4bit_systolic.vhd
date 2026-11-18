library ieee;
use ieee.std_logic_1164.all;
entity multiplier_4bit_systolic is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        a   : in  std_logic_vector(3 downto 0);
        b   : in  std_logic_vector(3 downto 0);
        p   : out std_logic_vector(7 downto 0)
    );
end entity;
architecture structural of multiplier_4bit_systolic is
    subtype word4 is std_logic_vector(3 downto 0);
    type word4_array is array (natural range <>) of word4;
    signal ai, ao, bi, bo, si, so, ci, co : word4_array(0 to 3);
    -- top boundary delays for a(j): j cycles
    signal a1_d1               : std_logic;
    signal a2_d1, a2_d2        : std_logic;
    signal a3_d1, a3_d2, a3_d3 : std_logic;
    -- left boundary delays for b(i): 2*i cycles
    signal b1_d1, b1_d2                               : std_logic;
    signal b2_d1, b2_d2, b2_d3, b2_d4                : std_logic;
    signal b3_d1, b3_d2, b3_d3, b3_d4, b3_d5, b3_d6 : std_logic;
    -- output alignment to common latency = 10 cycles
    signal p0_d1, p0_d2, p0_d3, p0_d4, p0_d5, p0_d6, p0_d7, p0_d8, p0_d9 : std_logic;
    signal p1_d1, p1_d2, p1_d3, p1_d4, p1_d5, p1_d6, p1_d7                : std_logic;
    signal p2_d1, p2_d2, p2_d3, p2_d4, p2_d5                               : std_logic;
    signal p3_d1, p3_d2, p3_d3                                              : std_logic;
    signal p4_d1, p4_d2                                                     : std_logic;
    signal p5_d1                                                            : std_logic;
begin
    -- 4x4 cell array
    gen_rows : for i in 0 to 3 generate
        gen_cols : for j in 0 to 3 generate
            cell_ij : entity work.mul_cell_sync
                port map (
                    clk => clk,
                    rst => rst,
                    ai  => ai(i)(j),
                    bi  => bi(i)(j),
                    si  => si(i)(j),
                    ci  => ci(i)(j),
                    ao  => ao(i)(j),
                    bo  => bo(i)(j),
                    so  => so(i)(j),
                    co  => co(i)(j)
                );
        end generate;
    end generate;
    -- vertical a propagation and inter-row partial sums
    gen_ai_si : for i in 1 to 3 generate
        ai(i) <= ao(i-1);
        si(i) <= co(i-1)(3) & so(i-1)(3 downto 1);
        -- si(i) = co(i-1)(3)  so(i-1)(3)  so(i-1)(2)  so(i-1)(1)
    end generate;
    -- horizontal b propagation and carries
    gen_bi_ci : for i in 0 to 3 generate
        gen_j : for j in 1 to 3 generate
            bi(i)(j) <= bo(i)(j-1);
            ci(i)(j) <= co(i)(j-1);
        end generate;
    end generate;
    -- top boundary inputs for row 0
    ai(0)(0) <= a(0);
    ai(0)(1) <= a1_d1;
    ai(0)(2) <= a2_d2;
    ai(0)(3) <= a3_d3;
    -- left boundary inputs for column 0
    bi(0)(0) <= b(0);
    bi(1)(0) <= b1_d2;
    bi(2)(0) <= b2_d4;
    bi(3)(0) <= b3_d6;
    -- zero boundaries
    si(0) <= (others => '0');
    ci(0)(0) <= '0';
    ci(1)(0) <= '0';
    ci(2)(0) <= '0';
    ci(3)(0) <= '0';
    -- boundary delays + output alignment
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                a1_d1 <= '0';
                a2_d1 <= '0'; a2_d2 <= '0';
                a3_d1 <= '0'; a3_d2 <= '0'; a3_d3 <= '0';
                b1_d1 <= '0'; b1_d2 <= '0';
                b2_d1 <= '0'; b2_d2 <= '0'; b2_d3 <= '0'; b2_d4 <= '0';
                b3_d1 <= '0'; b3_d2 <= '0'; b3_d3 <= '0';
                b3_d4 <= '0'; b3_d5 <= '0'; b3_d6 <= '0';
                p0_d1 <= '0'; p0_d2 <= '0'; p0_d3 <= '0'; p0_d4 <= '0'; p0_d5 <= '0';
                p0_d6 <= '0'; p0_d7 <= '0'; p0_d8 <= '0'; p0_d9 <= '0';
                p1_d1 <= '0'; p1_d2 <= '0'; p1_d3 <= '0'; p1_d4 <= '0';
                p1_d5 <= '0'; p1_d6 <= '0'; p1_d7 <= '0';
                p2_d1 <= '0'; p2_d2 <= '0'; p2_d3 <= '0'; p2_d4 <= '0'; p2_d5 <= '0';
                p3_d1 <= '0'; p3_d2 <= '0'; p3_d3 <= '0';
                p4_d1 <= '0'; p4_d2 <= '0';
                p5_d1 <= '0';
            else
                -- top boundary delays for a
                a1_d1 <= a(1);
                a2_d1 <= a(2);
                a2_d2 <= a2_d1;
                a3_d1 <= a(3);
                a3_d2 <= a3_d1;
                a3_d3 <= a3_d2;
                -- left boundary delays for b
                b1_d1 <= b(1);
                b1_d2 <= b1_d1;
                b2_d1 <= b(2);
                b2_d2 <= b2_d1;
                b2_d3 <= b2_d2;
                b2_d4 <= b2_d3;
                b3_d1 <= b(3);
                b3_d2 <= b3_d1;
                b3_d3 <= b3_d2;
                b3_d4 <= b3_d3;
                b3_d5 <= b3_d4;
                b3_d6 <= b3_d5;
                -- output alignment to cycle 10
                p0_d1 <= so(0)(0);
                p0_d2 <= p0_d1;
                p0_d3 <= p0_d2;
                p0_d4 <= p0_d3;
                p0_d5 <= p0_d4;
                p0_d6 <= p0_d5;
                p0_d7 <= p0_d6;
                p0_d8 <= p0_d7;
                p0_d9 <= p0_d8;
                p1_d1 <= so(1)(0);
                p1_d2 <= p1_d1;
                p1_d3 <= p1_d2;
                p1_d4 <= p1_d3;
                p1_d5 <= p1_d4;
                p1_d6 <= p1_d5;
                p1_d7 <= p1_d6;
                p2_d1 <= so(2)(0);
                p2_d2 <= p2_d1;
                p2_d3 <= p2_d2;
                p2_d4 <= p2_d3;
                p2_d5 <= p2_d4;
                p3_d1 <= so(3)(0);
                p3_d2 <= p3_d1;
                p3_d3 <= p3_d2;
                p4_d1 <= so(3)(1);
                p4_d2 <= p4_d1;
                p5_d1 <= so(3)(2);
            end if;
        end if;
    end process;
    -- aligned final product
    p(0) <= p0_d9;
    p(1) <= p1_d7;
    p(2) <= p2_d5;
    p(3) <= p3_d3;
    p(4) <= p4_d2;
    p(5) <= p5_d1;
    p(6) <= so(3)(3);
    p(7) <= co(3)(3);
end architecture;
