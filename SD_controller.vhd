----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/28/2022 08:16:43 PM
-- Design Name: 
-- Module Name: SD_controller - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SD_controller is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
		   pause : in STD_LOGIC;
           play : in STD_LOGIC;
           L_H : in STD_LOGIC;
           --DO : out STD_LOGIC;
           MISO : in STD_LOGIC;
           MOSI : out STD_LOGIC;
           SCLK : out STD_LOGIC;
           CS : out STD_LOGIC;
		   data_get : out STD_LOGIC_VECTOR(15 downto 0);
		   data_valid: out STD_LOGIC);
end SD_controller;

architecture Behavioral of SD_controller is
component clk_generator port( 
	clk : in STD_LOGIC;
    clk_400K : out STD_LOGIC;
    clk_5M : out STD_LOGIC);
end component;

component SD_cmd Port ( 
	clk : in STD_LOGIC;
	reset : in STD_LOGIC;
	send : in STD_LOGIC;
	cmd_in : in STD_LOGIC_VECTOR (47 downto 0);
	cmd_out : out STD_LOGIC;
	ready : out STD_LOGIC);
end component;

component SD_GetData Port ( 
	clk : in STD_LOGIC;
    reset : in STD_LOGIC;
    data_in : in STD_LOGIC;
    data_out : out STD_LOGIC_VECTOR (15 downto 0));
end component;

component SD_init Port (   
	clk : in STD_LOGIC;
    reset: in STD_LOGIC;
	initialized: out STD_LOGIC;
    MISO : in STD_LOGIC;
    MOSI : out STD_LOGIC;
    CS : out STD_LOGIC;
    SCLK : out STD_LOGIC);
end component;

--component ila_0 port(
--    clk: in STD_LOGIC;
--    probe0: in STD_LOGIC_VECTOR(2 downto 0);
--    probe1: in STD_LOGIC_VECTOR(0 downto 0);
--    probe2: in STD_LOGIC_VECTOR(0 downto 0);
--    probe3: in STD_LOGIC_VECTOR(15 downto 0);
--    probe4: in STD_LOGIC_VECTOR(0 downto 0)
--);
--end component;
--//************************signal for component*************************//
signal clk5m, send_en, SCLK_temp, CS_temp, SCLK_init, CS_init, MOSI_com, MOSI_temp, MOSI_init, ifinitialized: STD_LOGIC;
signal cmd_reg, cmd_next: STD_LOGIC_VECTOR(47 downto 0);
signal byte_get : STD_LOGIC_VECTOR(15 downto 0);


--//************************inner signal*************************//
type state_type is (waiting, idle, send_cmd, response, get_header, get_data, wait_clk);
signal state, state_next: state_type;
signal byte_valid: STD_LOGIC;
signal cnt16, cnt16_next: STD_LOGIC_VECTOR(3 downto 0);
signal cnt512, cnt512_next: STD_LOGIC_VECTOR(9 downto 0);
constant sector:natural:=257;
constant sec_high:natural:=159;
constant sec_low:natural:=159;
signal sec_num_next,sec_num: STD_LOGIC_VECTOR(9 downto 0);

signal data_flag, read_flag: STD_LOGIC;

constant addre_low: STD_LOGIC_VECTOR(47 downto 0):= x"510000A080FF";
constant addre_high: STD_LOGIC_VECTOR(47 downto 0):= x"510000A120FF";

--signal debug: STD_LOGIC_VECTOR(2 downto 0);
--signal cnt_debug: STD_LOGIC_VECTOR(15 downto 0);
--signal MOSI_debug, MISO_debug: STD_LOGIC_VECTOR(0 downto 0);
--signal clk_debug, byte_valid_debug: STD_LOGIC_VECTOR(0 downto 0);
begin
inst1: component clk_generator port map(
	clk=>clk,
	clk_5M=>clk5m
);
inst2: component SD_cmd port map(
	clk=>clk5m,
	reset=>reset,
	send=>send_en,
	cmd_in=>cmd_reg,
	cmd_out=>MOSI_com
);
inst3: component SD_GetData port map(
	clk=>clk5m,
	reset=>reset,
	data_in=>MISO,
	data_out=>byte_get	
);
inst4: component SD_init port map(
	clk=>clk,
	reset=>reset,
	initialized=>ifinitialized,
	MISO=>MISO,
	MOSI=>MOSI_init,
	CS=>CS_init,
	SCLK=>SCLK_init
);
--inst5: component ila_0 port map(
--    clk=>clk,
--    probe0=>debug,
--    probe1=>MOSI_debug,
--    probe2=>MISO_debug,
--    probe3=>cnt_debug,
--    probe4=>byte_valid_debug
--);


process(clk5m, reset)
begin
	if rising_edge(clk5m) then
		if reset='1' then
			state<=waiting;
			cnt16<=(others=>'0');
			cnt512<=(others=>'0');
			cmd_reg<=(others=>'1');
			sec_num<=(others=>'0');
		else
			state<=state_next;
			cnt16<=cnt16_next;
			cnt512<=cnt512_next;
			cmd_reg<=cmd_next;
			sec_num<=sec_num_next;
		end if;
	end if;
end process;

process(state, play, L_H, cnt16, cnt512, sec_num, cmd_reg)
begin
	case state is
		when waiting=>
			cnt16_next<=(others=>'0');
			cnt512_next<=(others=>'0');
			cmd_next<=(others=>'1');
			byte_valid<='0';
			data_flag<='0';
			read_flag<='0';
			SCLK_temp<=SCLK_init;
			CS_temp<=CS_init;
			MOSI_temp<=MOSI_init;
			send_en<='0';
			sec_num_next<=(others=>'0');
		when idle=>
			cnt16_next<=(others=>'0');
			cnt512_next<=(others=>'0');
			if play='1' then
				if L_H='1' then
			        cmd_next<=addre_high;
			        sec_num_next<=std_logic_vector(to_unsigned(sec_high,10));
				else
			        cmd_next<=addre_low;
			        sec_num_next<=std_logic_vector(to_unsigned(sec_low,10));
				end if;
			else
			    cmd_next<=(others=>'1');
			    sec_num_next<=sec_num;
			end if;
			byte_valid<='0';
			data_flag<='0';
			read_flag<='0';
			SCLK_temp<=not(clk5m);
			CS_temp<='0';
			MOSI_temp<=MOSI_com;
			send_en<='0';
		when send_cmd=>
			cnt16_next<=(others=>'0');
			cnt512_next<=(others=>'0');
			cmd_next<=cmd_reg+ x"000000000100";
			sec_num_next<=sec_num-1;
			byte_valid<='0';
			data_flag<='0';
			read_flag<='0';
			SCLK_temp<=not(clk5m);
			CS_temp<='1';
			MOSI_temp<=MOSI_com;
			send_en<='1';
		when response=>
			cnt16_next<=(others=>'0');
			cnt512_next<=(others=>'0');
			cmd_next<=cmd_reg;
			sec_num_next<=sec_num;
			byte_valid<='0';
			data_flag<='0';
			read_flag<='0';
			SCLK_temp<=not(clk5m);
			CS_temp<='0';
			MOSI_temp<=MOSI_com;
			send_en<='0';
		when get_header=>
			cnt16_next<=(others=>'0');
			cnt512_next<=(others=>'0');
			cmd_next<=cmd_reg;
			sec_num_next<=sec_num;
			byte_valid<='0';
			data_flag<='0';
			read_flag<='0';
			SCLK_temp<=not(clk5m);
			CS_temp<='0';
			MOSI_temp<=MOSI_com;
			send_en<='0';
		when get_data=>
			cnt16_next<=cnt16+1;
			if cnt16="1111" then
				cnt512_next<=cnt512+1;
				if cnt512<256 then
				    byte_valid<='1';
			    else
			        byte_valid<='0';
			    end if;
			else
				cnt512_next<=cnt512;
				byte_valid<='0';
			end if;
			
			data_flag<='1';
			cmd_next<=cmd_reg;
			sec_num_next<=sec_num;
			if sec_num=x"000" then
				read_flag<='0';
			else
				read_flag<='1';
			end if;
			SCLK_temp<=not(clk5m);
			CS_temp<='0';
			MOSI_temp<=MOSI_com;
			send_en<='0';
		when wait_clk=>
			if cnt16="1111" then
				cnt16_next<=cnt16;
			else
				cnt16_next<=cnt16+1;
			end if;
			cnt512_next<=(others=>'0');
			cmd_next<=cmd_reg;
			sec_num_next<=sec_num;
			byte_valid<='0';
			data_flag<='0';
			read_flag<='0';
			SCLK_temp<=not(clk5m);
			CS_temp<='0';
			MOSI_temp<=MOSI_com;
			send_en<='0';
	end case;
end process;


process(ifinitialized, play, byte_get, cnt512, read_flag, cnt16, pause, sec_num)
begin
	case state is
		when waiting=>
			if ifinitialized='1' then
				state_next<=idle;
			else
				state_next<=waiting;
			end if;
		when idle=>
			if play='1' then
				state_next<=send_cmd;
			else
				state_next<=idle;
			end if;
		when send_cmd=>
			state_next<=response;
	    when response=>
			if byte_get=x"FF00" then
				state_next<=get_header;
			elsif byte_get=x"FF05" then
			    state_next<=idle;
			else
				state_next<=response;
			end if;
		when get_header=>
			if byte_get=x"FFFE" then
				state_next<=get_data;
			else
				state_next<=get_header;
			end if;
		when get_data=>
			if cnt512=sector then
				if read_flag='1' then
					state_next<=wait_clk;
				elsif read_flag='0' then
					state_next<=idle;
				end if;
			else
				state_next<=get_data;
			end if;
		when wait_clk=>
			if cnt16="1111" then
			    if sec_num=0 then
			        state_next<=idle;
			    elsif pause='0' then
				    state_next<=send_cmd;
				else
				    state_next<=wait_clk;
				end if;
			else
				state_next<=wait_clk;
			end if;
	end case;
end process;
MOSI<=MOSI_temp;
CS<=CS_temp;
SCLK<=SCLK_temp;
data_get<=byte_get;
data_valid<=byte_valid;

--MOSI_debug(0)<=MOSI_temp;
--MISO_debug(0)<=MISO;
--clk_debug(0)<=read_flag;
--byte_valid_debug(0)<=byte_valid;
--cnt_debug<=cmd_reg(23 downto 8);
--debug<="000" when state=waiting else
--       "001" when state=idle else
--       "010" when state=send_cmd else
--       "011" when state=get_header else
--       "100" when state=response else
--       "101" when state=get_data else
--       "110" when state=wait_clk else
--       "111";


end Behavioral;
