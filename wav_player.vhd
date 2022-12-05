----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/01/2022 02:40:59 PM
-- Design Name: 
-- Module Name: wav_player - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wav_player is
	Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
		   --//*************IO for player***************//
           play : in STD_LOGIC;
           L_H : in STD_LOGIC;
		   
		   --//*************IO for SD card***************//
           MISO : in STD_LOGIC;
           MOSI : out STD_LOGIC;
           SCLK : out STD_LOGIC;
           CS : out STD_LOGIC;
		   --//*************IO for dac***************//
		   --MISO_dac : in STD_LOGIC;
           MOSI_dac : out STD_LOGIC;
           SCLK_dac : out STD_LOGIC;
           SYNC_dac : out STD_LOGIC
		   
		   --//*************IO for debug***************//
		   --debug : out STD_LOGIC_VECTOR(15 downto 0)
		   );
end wav_player;

architecture Behavioral of wav_player is
component SD_controller port ( clk : in STD_LOGIC;
    reset : in STD_LOGIC;
    play : in STD_LOGIC;
	pause: in STD_LOGIC;
    L_H : in STD_LOGIC;
    --DO : out STD_LOGIC;
    MISO : in STD_LOGIC;
    MOSI : out STD_LOGIC;
    SCLK : out STD_LOGIC;
    CS : out STD_LOGIC;
	data_get : out STD_LOGIC_VECTOR(15 downto 0);
    data_valid: out STD_LOGIC);
end component;

component clk_generator2 port( 
	clk : in STD_LOGIC;
    clk_768K : out STD_LOGIC;
    clk_5M : out STD_LOGIC);
end component;

component RAM1024_16 port ( clka : in std_logic;
	clkb : in std_logic;
	ena : in std_logic;
	enb : in std_logic;
	wea : in std_logic;
	addra : in std_logic_vector(8 downto 0);
	addrb : in std_logic_vector(8 downto 0);
	dia : in std_logic_vector(15 downto 0);
	dob : out std_logic_vector(15 downto 0));
end component;

component ila_0 port(
    clk: in STD_LOGIC;
    probe0: in STD_LOGIC_VECTOR(15 downto 0);
    probe1: in STD_LOGIC_VECTOR(0 downto 0);
    probe2: in STD_LOGIC_VECTOR(0 downto 0);
    probe3: in STD_LOGIC_VECTOR(15 downto 0);
    probe4: in STD_LOGIC_VECTOR(0 downto 0)
);
end component;

component data_converter port ( 
	data_in : in STD_LOGIC_VECTOR (15 downto 0);
    data_out : out STD_LOGIC_VECTOR (15 downto 0));
end component;

component SPI_master GENERIC(
    DATA_WIDTH  : INTEGER := 8;
    SPI_MODE    : INTEGER RANGE 0 TO 3 := 0;
    SLAVES      : INTEGER := 1;     -- the amount of peripherals connected by SPI
    CLK_FREQ    : INTEGER := 100e6; -- frequency of the system clock
    SLAVE_FREQ  : INTEGER := 64); -- frequency of the slave device
  PORT(
    clk   : IN STD_LOGIC;                                   -- system clock (100 MHz)
    reset_N  : IN STD_LOGIC;
    MISO  : IN STD_LOGIC;                                   -- master in, slave out
    Tx_reg: IN STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    byte_refresh : IN STD_LOGIC;
    enable: IN STD_LOGIC;                                   -- enable the SCLK
    SCLK  : OUT STD_LOGIC;                                  -- serial clock
    SS    : OUT STD_LOGIC;                                  -- slave select (active low)
    Rx_reg: OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);    -- receiver register
    MOSI  : OUT STD_LOGIC);   
end component;

--//**********************************signals for components************************//
signal clk5m, clk768k, SD_play, SD_pause, SD_pause_next, data_valid, RAM_wea, RAM_wea_next, RAM_enb, RAM_enb_next, RAM_ena, RAM_ena_next: STD_LOGIC;
signal RAM_addra, RAM_addra_next, RAM_addrb, RAM_addrb_next: STD_LOGIC_VECTOR(8 downto 0);
signal data_get, RAM_in, RAM_out, RAM_in_buffer, RAM_in_buffer_next, RAM_out_buffer, RAM_out_buffer_next : STD_LOGIC_VECTOR(15 downto 0);
signal DC_in, DC_out: STD_LOGIC_VECTOR(15 downto 0);

signal SPI_en, SPI_byte_refresh, SPI_byte_refresh_next, SPI_MISO, SPI_MOSI, SPI_SS, SPI_SCLK, SPI_reset : STD_LOGIC;
signal SPI_Tx : STD_LOGIC_VECTOR(15 downto 0);

--//**********************************inner signals************************//
type state_type is (idle, load1, detecting1, load2, detecting2);
signal state, state_next: state_type;
signal cnt17, cnt17_next: STD_LOGIC_VECTOR(4 downto 0);

--signal debug_state: STD_LOGIC_VECTOR(15 downto 0);
--signal flag_load_debug, flag_play_debug, WEA_debug: STD_LOGIC_VECTOR(0 downto 0);
--signal addr_debug: STD_LOGIC_VECTOR(15 downto 0);


begin
inst1: component SD_controller port map(
	clk=>clk,
	reset=>reset,
	play=>SD_play,
	pause=>SD_pause,
	L_H=>L_H,
	MISO=>MISO,
	MOSI=>MOSI,
	SCLK=>SCLK,
	CS=>CS,
	data_get=>data_get,
	data_valid=>data_valid
);

inst2: component clk_generator2 port map(
	clk=>clk,
	clk_768K=>clk768k,
	clk_5M=>clk5m
);

inst3: component RAM1024_16 port map(
	clka=>clk5m,
	clkb=>clk768k,
	ena=>RAM_ena,
	enb=>RAM_enb,
	wea=>RAM_wea,
	addra=>RAM_addra,
	addrb=>RAM_addrb,
	dia=>RAM_in,
	dob=>RAM_out
);

--inst4: component ila_0 port map(
--    clk=>clk,
--    probe0=>debug_state,
--    probe1=>flag_load_debug,
--    probe2=>flag_play_debug,
--    probe3=>addr_debug,
--    probe4=>WEA_debug
--);

inst5: component SPI_master GENERIC map(
    DATA_WIDTH  => 16,
    SPI_MODE    => 3,
    SLAVES      => 1,
    CLK_FREQ    => 100e6,
    SLAVE_FREQ  => 141)
  port map(
    clk => clk,
    reset_N  => SPI_reset,
    MISO => SPI_MISO,
    Tx_reg => SPI_Tx,
    byte_refresh => SPI_byte_refresh,
    enable => SPI_en,
    SCLK  => SPI_SCLK,
    SS => SPI_SS,
    MOSI  => SPI_MOSI);   

inst6: component data_converter port map(
    data_in => DC_in,
    data_out => DC_out
);


process(clk5m, reset)
begin
	if rising_edge(clk5m) then
		if reset='1' then
			RAM_addra<=(others=>'0');
			RAM_in_buffer<=(others=>'0');
			RAM_wea<='0';
			SD_pause<='1';
			RAM_ena<='0';
		else
			RAM_addra<=RAM_addra_next;
			RAM_in_buffer<=RAM_in_buffer_next;
			RAM_wea<=RAM_wea_next;
			SD_pause<=SD_pause_next;
			RAM_ena<=RAM_ena_next;
		end if;
	end if;
end process;

process(clk768k, reset)
begin
	if rising_edge(clk768k) then
		if reset='1' then
			RAM_addrb<=(others=>'0');
			RAM_enb<='0';
			state<=idle;
			cnt17<=(others=>'0');
			RAM_out_buffer<=(others=>'0');
			SPI_byte_refresh<='0';
		else
			state<=state_next;
			RAM_addrb<=RAM_addrb_next;
			RAM_enb<=RAM_enb_next;
			cnt17<=cnt17_next;
			RAM_out_buffer<=RAM_out_buffer_next;
			SPI_byte_refresh<=SPI_byte_refresh_next;
		end if;
	end if;
end process;


process(state, data_valid, RAM_addra, RAM_addrb)
begin
	case state is
		when idle=>
			SD_pause_next<='0';
			SD_play<='0';
		when load1=>
			SD_play<='1';
			SD_pause_next<='1';
		when detecting1=>
			SD_play<='1';
			if RAM_addrb=510 then
			    SD_pause_next<='0';
			else
			    SD_pause_next<='1';
			end if;
		when load2=>
			SD_play<='1';
		    SD_pause_next<='1';
		when detecting2=>
			SD_play<='1';
			if RAM_addrb=254 then
			    SD_pause_next<='0';
			else
			    SD_pause_next<='1';
			end if;
	end case;
end process;


process(state, play, RAM_addra, RAM_addrb)
begin
	case state is
		when idle=>
			if play='1' then
				state_next<=load1;
			else
				state_next<=idle;
			end if;
		when load1=>
			if RAM_addra=256 then
				state_next<=detecting1;
			else
				state_next<=load1;
			end if;
		when detecting1=>
			if RAM_addrb=510 then
				state_next<=load2;
			else
				state_next<=detecting1;
			end if;
		when load2=>
			if RAM_addra=0 then
				state_next<=detecting2;
			else
				state_next<=load2;
			end if;
		when detecting2=>
			if play='1' then
			    if RAM_addrb=254 then
				    state_next<=load1;
			    else
				    state_next<=detecting2;
			    end if;
			else
			    state_next<=idle;
			end if;
	end case;
end process;


RAM_in_buffer_next<=data_get;
RAM_in<=RAM_in_buffer;
cnt17_next<=(others=>'0') when state=idle or cnt17=16 else
            cnt17+1;
RAM_ena_next<='1' when data_valid='1' else
              '0';
RAM_wea_next<='1' when data_valid='1' else
              '0';
RAM_addra_next<=(others=>'0') when state=idle else 
                RAM_addra+1 when data_valid='1' else
                RAM_addra;
                
                
RAM_addrb_next<=(others=>'0') when state=idle else
                RAM_addrb+1 when cnt17=16 else
                RAM_addrb;
RAM_enb_next<='1' when cnt17=16 else
              '0';                 
RAM_out_buffer_next<=(others=>'0') when state=idle else
                     RAM_out when cnt17=16 else
                     RAM_out_buffer;
                     
SPI_byte_refresh_next<='0' when state=idle else
                       '1' when cnt17=16 else
                       '0';
SPI_en<='0' when state=idle else
        '1';
SPI_reset<=not(reset);        
SPI_Tx<=(others=>'0') when state=idle else
        DC_out;

DC_in <= RAM_out_buffer;

MOSI_dac<=SPI_MOSI;
SYNC_dac<=SPI_SS;
SCLK_dac<=SPI_SCLK;


--debug<=RAM_out_buffer;

--WEA_debug(0)<=SPI_SCLK;
--flag_play_debug(0)<=SPI_MOSI;
--flag_load_debug(0)<=SPI_SS;
--addr_debug<=RAM_out_buffer;
--debug_state<=RAM_in_buffer;

end Behavioral;
