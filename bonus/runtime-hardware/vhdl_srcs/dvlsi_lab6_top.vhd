library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dvlsi_lab6_top is
  port (
        DDR_cas_n         : inout STD_LOGIC;
        DDR_cke           : inout STD_LOGIC;
        DDR_ck_n          : inout STD_LOGIC;
        DDR_ck_p          : inout STD_LOGIC;
        DDR_cs_n          : inout STD_LOGIC;
        DDR_reset_n       : inout STD_LOGIC;
        DDR_odt           : inout STD_LOGIC;
        DDR_ras_n         : inout STD_LOGIC;
        DDR_we_n          : inout STD_LOGIC;
        DDR_ba            : inout STD_LOGIC_VECTOR( 2 downto 0);
        DDR_addr          : inout STD_LOGIC_VECTOR(14 downto 0);
        DDR_dm            : inout STD_LOGIC_VECTOR( 3 downto 0);
        DDR_dq            : inout STD_LOGIC_VECTOR(31 downto 0);
        DDR_dqs_n         : inout STD_LOGIC_VECTOR( 3 downto 0);
        DDR_dqs_p         : inout STD_LOGIC_VECTOR( 3 downto 0);
        FIXED_IO_mio      : inout STD_LOGIC_VECTOR(53 downto 0);
        FIXED_IO_ddr_vrn  : inout STD_LOGIC;
        FIXED_IO_ddr_vrp  : inout STD_LOGIC;
        FIXED_IO_ps_srstb : inout STD_LOGIC;
        FIXED_IO_ps_clk   : inout STD_LOGIC;
        FIXED_IO_ps_porb  : inout STD_LOGIC
       );
end entity;

architecture arch of dvlsi_lab6_top is

  component design_1_wrapper is
    port (
          DDR_cas_n         : inout STD_LOGIC;
          DDR_cke           : inout STD_LOGIC;
          DDR_ck_n          : inout STD_LOGIC;
          DDR_ck_p          : inout STD_LOGIC;
          DDR_cs_n          : inout STD_LOGIC;
          DDR_reset_n       : inout STD_LOGIC;
          DDR_odt           : inout STD_LOGIC;
          DDR_ras_n         : inout STD_LOGIC;
          DDR_we_n          : inout STD_LOGIC;
          DDR_ba            : inout STD_LOGIC_VECTOR( 2 downto 0);
          DDR_addr          : inout STD_LOGIC_VECTOR(14 downto 0);
          DDR_dm            : inout STD_LOGIC_VECTOR( 3 downto 0);
          DDR_dq            : inout STD_LOGIC_VECTOR(31 downto 0);
          DDR_dqs_n         : inout STD_LOGIC_VECTOR( 3 downto 0);
          DDR_dqs_p         : inout STD_LOGIC_VECTOR( 3 downto 0);
          FIXED_IO_mio      : inout STD_LOGIC_VECTOR(53 downto 0);
          FIXED_IO_ddr_vrn  : inout STD_LOGIC;
          FIXED_IO_ddr_vrp  : inout STD_LOGIC;
          FIXED_IO_ps_srstb : inout STD_LOGIC;
          FIXED_IO_ps_clk   : inout STD_LOGIC;
          FIXED_IO_ps_porb  : inout STD_LOGIC;

          ACLK                                : out STD_LOGIC;
          ARESETN                             : out STD_LOGIC_VECTOR(0 to 0);

          M_AXIS_TO_ACCELERATOR_tdata         : out STD_LOGIC_VECTOR(7 downto 0);
          M_AXIS_TO_ACCELERATOR_tkeep         : out STD_LOGIC_VECTOR(0 to 0);
          M_AXIS_TO_ACCELERATOR_tlast         : out STD_LOGIC;
          M_AXIS_TO_ACCELERATOR_tready        : in  STD_LOGIC;
          M_AXIS_TO_ACCELERATOR_tvalid        : out STD_LOGIC;

          S_AXIS_S2MM_FROM_ACCELERATOR_tdata  : in  STD_LOGIC_VECTOR(31 downto 0);
          S_AXIS_S2MM_FROM_ACCELERATOR_tkeep  : in  STD_LOGIC_VECTOR(3 downto 0);
          S_AXIS_S2MM_FROM_ACCELERATOR_tlast  : in  STD_LOGIC;
          S_AXIS_S2MM_FROM_ACCELERATOR_tready : out STD_LOGIC;
          S_AXIS_S2MM_FROM_ACCELERATOR_tvalid : in  STD_LOGIC;

          debayer_cfg                         : out STD_LOGIC_VECTOR(16 downto 0)
         );
  end component design_1_wrapper;

  signal aclk    : std_logic;
  signal aresetn : std_logic_vector(0 to 0);

  signal tmp_tdata  : std_logic_vector(7 downto 0);
  signal tmp_tkeep  : std_logic_vector(0 downto 0);
  signal tmp_tlast  : std_logic;
  signal tmp_tready : std_logic;
  signal tmp_tvalid : std_logic;

  signal s2mm_tready : std_logic;

  signal deb_R, deb_G, deb_B : std_logic_vector(7 downto 0);
  signal deb_valid_out        : std_logic;
  signal deb_img_done         : std_logic;
  signal first_pixel          : std_logic := '1';

  signal debayer_cfg_raw   : std_logic_vector(16 downto 0);
  signal debayer_cfg_sync1 : std_logic_vector(16 downto 0) := (others => '0');
  signal debayer_cfg_sync2 : std_logic_vector(16 downto 0) := (others => '0');

  signal cfg_dim       : std_logic_vector(15 downto 0);
  signal cfg_vld       : std_logic;
  signal cfg_valid_dim : std_logic;
  signal tmp_accept    : std_logic;

begin

  PROCESSING_SYSTEM_INSTANCE : design_1_wrapper
    port map (
              DDR_cas_n         => DDR_cas_n,
              DDR_cke           => DDR_cke,
              DDR_ck_n          => DDR_ck_n,
              DDR_ck_p          => DDR_ck_p,
              DDR_cs_n          => DDR_cs_n,
              DDR_reset_n       => DDR_reset_n,
              DDR_odt           => DDR_odt,
              DDR_ras_n         => DDR_ras_n,
              DDR_we_n          => DDR_we_n,
              DDR_ba            => DDR_ba,
              DDR_addr          => DDR_addr,
              DDR_dm            => DDR_dm,
              DDR_dq            => DDR_dq,
              DDR_dqs_n         => DDR_dqs_n,
              DDR_dqs_p         => DDR_dqs_p,
              FIXED_IO_mio      => FIXED_IO_mio,
              FIXED_IO_ddr_vrn  => FIXED_IO_ddr_vrn,
              FIXED_IO_ddr_vrp  => FIXED_IO_ddr_vrp,
              FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
              FIXED_IO_ps_clk   => FIXED_IO_ps_clk,
              FIXED_IO_ps_porb  => FIXED_IO_ps_porb,

              ACLK                                => aclk,
              ARESETN                             => aresetn,

              M_AXIS_TO_ACCELERATOR_tdata         => tmp_tdata,
              M_AXIS_TO_ACCELERATOR_tkeep         => tmp_tkeep,
              M_AXIS_TO_ACCELERATOR_tlast         => tmp_tlast,
              M_AXIS_TO_ACCELERATOR_tready        => tmp_tready,
              M_AXIS_TO_ACCELERATOR_tvalid        => tmp_tvalid,

              S_AXIS_S2MM_FROM_ACCELERATOR_tdata  => x"00" & deb_B & deb_G & deb_R,
              S_AXIS_S2MM_FROM_ACCELERATOR_tkeep  => "1111",
              S_AXIS_S2MM_FROM_ACCELERATOR_tlast  => deb_img_done,
              S_AXIS_S2MM_FROM_ACCELERATOR_tready => s2mm_tready,
              S_AXIS_S2MM_FROM_ACCELERATOR_tvalid => deb_valid_out,

              debayer_cfg                         => debayer_cfg_raw
             );

  -- AXI GPIO runs on the AXI-Lite clock. The value is stable before DMA starts.
  -- Two registers are enough for this lab use-case.
  process(aclk, aresetn)
  begin
    if aresetn(0) = '0' then
      debayer_cfg_sync1 <= (others => '0');
      debayer_cfg_sync2 <= (others => '0');
    elsif rising_edge(aclk) then
      debayer_cfg_sync1 <= debayer_cfg_raw;
      debayer_cfg_sync2 <= debayer_cfg_sync1;
    end if;
  end process;

  cfg_dim <= debayer_cfg_sync2(15 downto 0);
  cfg_vld <= debayer_cfg_sync2(16);

  cfg_valid_dim <= '1' when (cfg_dim = std_logic_vector(to_unsigned(64, 16))) or
                            (cfg_dim = std_logic_vector(to_unsigned(128, 16))) or
                            (cfg_dim = std_logic_vector(to_unsigned(256, 16))) or
                            (cfg_dim = std_logic_vector(to_unsigned(512, 16))) or
                            (cfg_dim = std_logic_vector(to_unsigned(1024, 16)))
                   else '0';

  process(aclk, aresetn)
  begin
    if aresetn(0) = '0' then
      first_pixel <= '1';
    elsif rising_edge(aclk) then
      if deb_img_done = '1' then
        first_pixel <= '1';
      elsif (tmp_tvalid = '1') and (tmp_tready = '1') then
        first_pixel <= '0';
      end if;
    end if;
  end process;

  u_debayer : entity work.debayer_partA_final
    port map (
      clk            => aclk,
      rst_n          => aresetn(0),
      image_dim      => cfg_dim,
      image_dim_vld  => cfg_vld,
      pixel          => tmp_tdata,
      valid_in       => tmp_accept,
      new_image      => first_pixel,
      R              => deb_R,
      G              => deb_G,
      B              => deb_B,
      valid_out      => deb_valid_out,
      image_finished => deb_img_done
    );

  -- The accelerator accepts stream input only after a valid runtime configuration.
  tmp_tready <= cfg_vld and cfg_valid_dim;
  tmp_accept <= tmp_tvalid and tmp_tready;

end architecture;
