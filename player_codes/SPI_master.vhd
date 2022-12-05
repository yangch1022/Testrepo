LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;

ENTITY SPI_master IS
  GENERIC(
    DATA_WIDTH  : INTEGER := 8;
    SPI_MODE    : INTEGER RANGE 0 TO 3 := 0;
    SLAVES      : INTEGER := 1;     -- the amount of peripherals connected by SPI
    CLK_FREQ    : INTEGER := 100e6; -- frequency of the system clock
    SLAVE_FREQ  : INTEGER := 25e6); -- frequency of the slave device
  PORT(
    clk   : IN STD_LOGIC;                                   -- system clock (100 MHz)
    reset_N  : IN STD_LOGIC;
    MISO  : IN STD_LOGIC;                                   -- master in, slave out
    Tx_reg: IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    byte_refresh: IN STD_LOGIC;
    enable: IN STD_LOGIC;                                   -- enable the SCLK
    SCLK  : OUT STD_LOGIC;                                  -- serial clock
    SS    : OUT STD_LOGIC;                                  -- slave select (active low)
    Rx_reg: OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);    -- receiver register
    MOSI  : OUT STD_LOGIC);                                 -- master out, slave in
END ENTITY;

ARCHITECTURE behavioral OF SPI_master IS

  TYPE STATE IS (idle, transfer, waiting);

  -- constant declarations
  -- the number to count to before flipping SCLK
  CONSTANT SERIAL_CNT : INTEGER := SLAVE_FREQ; 

  -- signal declarations

  -- control signals
  -- clock polarity
  SIGNAL CPOL       : STD_LOGIC;
  -- clock phase
  SIGNAL CPHA       : STD_LOGIC;

  SIGNAL clk_cnt    : INTEGER RANGE 0 TO SERIAL_CNT := 0;
  -- send MSB first
  SIGNAL curr_bit   : UNSIGNED(INTEGER(LOG2(REAL(DATA_WIDTH)))-1 DOWNTO 0) := (OTHERS => '1');
  SIGNAL curr_bit2   : UNSIGNED(INTEGER(LOG2(REAL(DATA_WIDTH)))-1 DOWNTO 0) := (OTHERS => '1');
  SIGNAL SCLK_sig    : STD_LOGIC := '0';

  SIGNAL curr_state, next_state : STATE := idle;
  SIGNAL SS_sig : STD_LOGIC := '1';
  --SIGNAL byte_finish : STD_LOGIC;
BEGIN
  -- assign default values

  -- assign clock polarity and phase according to selected SPI mode
  CPOL <= '0' WHEN (SPI_MODE = 0) OR (SPI_MODE = 1) ELSE '1';
  CPHA <= '0' WHEN (SPI_MODE = 0) OR (SPI_MODE = 2) ELSE '1';
  SS_sig <= '0' WHEN curr_state = transfer else
            '1';
  SCLK <= (SCLK_sig) WHEN curr_state = transfer else
          (CPOL);
  SS <= SS_sig;
  MOSI <= Tx_reg(TO_INTEGER(curr_bit2)) WHEN curr_state = transfer else
          '0';
  -- generate SCLK
  gen_sclk: PROCESS(clk, reset_N)
  BEGIN
    IF RISING_EDGE(clk) THEN
            IF (clk_cnt = SERIAL_CNT) THEN
              clk_cnt <= 0;
              SCLK_sig <= NOT SCLK_sig;
            ELSE
              clk_cnt <= clk_cnt + 1;
              SCLK_sig <= SCLK_sig;
            END IF;
    END IF;
  END PROCESS gen_sclk;

  -- update the FSM state on rising edge of system clock (clk)
  update_state: PROCESS(SCLK_sig, reset_N)
  BEGIN
    IF (reset_N = '0') THEN
      curr_state <= idle;
    ELSIF RISING_EDGE(SCLK_sig) THEN
      curr_state <= next_state;
    END IF;
  END PROCESS update_state;

  -- state transitions
  state_transition: PROCESS(curr_state, enable, byte_refresh, curr_bit2)
  BEGIN
    CASE curr_state IS
      WHEN idle =>
        IF (enable = '1') THEN
          next_state <= transfer;
        ELSE
          next_state <= idle;
        END IF;
      WHEN waiting =>
        IF enable = '0' THEN
          next_state <= idle;
        ELSE
          IF byte_refresh = '1' THEN
            next_state <= transfer;
          ELSE
            next_state <= waiting;
          END IF;
        END IF;
      WHEN transfer =>
        IF curr_bit2 = 0 THEN
          next_state <= waiting;
        ELSE
          next_state <= transfer;
        END IF;
        
    END CASE;
  END PROCESS state_transition;

  -- update the bit to send on MOSI and store MISO in Rx_reg
  update_curr_bit: PROCESS(SCLK_sig)
  BEGIN
    IF (reset_N = '0') THEN
      Rx_reg <= (OTHERS => '0');
    ELSIF FALLING_EDGE(SCLK_sig) THEN
      curr_bit <= curr_bit - 1;
      Rx_reg(TO_INTEGER(curr_bit)) <= MISO;
    END IF;
  END PROCESS update_curr_bit;

    -- cnt2 definition
  cnt2_transition: PROCESS(curr_state, reset_N, SCLK_sig)
  BEGIN
    IF (reset_N = '0') THEN
      curr_bit2<=(others=> '1');
    ELSIF RISING_EDGE(SCLK_sig) THEN
      CASE curr_state IS
        WHEN idle =>
          curr_bit2<=(others=> '1');
          --SS_sig<='1';
        WHEN transfer =>
          curr_bit2<=curr_bit2-1;
          --SS_sig<='0';
        WHEN waiting =>
          curr_bit2<=(others=> '1');
          --SS_sig<='1';
      END CASE;
    END IF;
  END PROCESS cnt2_transition;

  -- transfer data on MOSI
  --transfer_data: PROCESS(SCLK_sig)
  --BEGIN
    --MOSI <= '0';
    --IF RISING_EDGE(SCLK_sig) THEN
      --MOSI <= Tx_reg(TO_INTEGER(curr_bit2));
    --END IF;
  --END PROCESS transfer_data;

  -- byte finish flag
  --flag_byte_finish: PROCESS(SCLK_sig, curr_bit2)
  --BEGIN
    --IF RISING_EDGE(SCLK_sig) THEN
      --IF curr_bit2 = 0 THEN
        --byte_finish<='1';
      --ELSE
        --byte_finish<='0';
      --END IF;
    --END IF;
  --END PROCESS flag_byte_finish;
END behavioral;
