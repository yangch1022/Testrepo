----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2022 09:05:11 PM
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SD_init is
	Port (   
	clk : in STD_LOGIC;
    reset: in STD_LOGIC;
	initialized: out STD_LOGIC;
    MISO : in STD_LOGIC;
    MOSI : out STD_LOGIC;
    CS : out STD_LOGIC;
    SCLK : out STD_LOGIC);
end SD_init;

architecture Behavioral of SD_init is
--//***********************component*******************//
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

--//***********************IO for component*******************//
signal clk400k, clk5m: STD_LOGIC;
signal send_en: STD_LOGIC;
signal cmd: STD_LOGIC_VECTOR(47 downto 0);
constant cmd0: STD_LOGIC_VECTOR(47 downto 0):=x"400000000095";
constant cmd8: STD_LOGIC_VECTOR(47 downto 0):=x"48000001AA86";
constant cmd55: STD_LOGIC_VECTOR(47 downto 0):=x"7700000000FF";
constant acmd41: STD_LOGIC_VECTOR(47 downto 0):=x"6940000000FF";
signal byte_get: STD_LOGIC_VECTOR(15 downto 0);

--//***********************Signals in controller*******************//
type state_type is (send_clk, init1, response1, wait_clk1, init2, response2, wait_clk2, init3, response3, wait_clk3, init4, response4, wait_clk4, finished);
signal state, state_next: state_type;
signal cnt74, cnt74_next: STD_LOGIC_VECTOR(6 downto 0);
constant clk_num: natural:=100;
signal sclk_out: STD_LOGIC;

begin

inst1: component clk_generator port map(
	clk=>clk,
	clk_400K=>clk400k,
	clk_5M=>clk5m
);
inst2: component SD_cmd port map(
	clk=>clk5m,
	reset=>reset,
	send=>send_en,
	cmd_in=>cmd,
	cmd_out=>MOSI
);
inst3: component SD_GetData port map(
	clk=>clk5m,
	reset=>reset,
	data_in=>MISO,
	data_out=>byte_get
);
process(clk5m,reset)
begin
	if rising_edge(clk5m) then
		if reset='1' then
			state<=send_clk;
		else
			state<=state_next;
		end if;
	end if;
end process;

process(clk400k,reset)
begin
	if rising_edge(clk400k) then
		if reset='1' then
			cnt74<=(others=>'0');
		else
			cnt74<=cnt74_next;
		end if;
	end if;
end process;


process(state, clk5m)
begin
	case state is
		when send_clk=>
			sclk_out<=clk400k;
			cnt74_next<=cnt74+1;
			CS<='1';
			send_en<='0';
			cmd<=(others=>'1');
		when init1=>
			sclk_out<=clk5m;
			cnt74_next<=(others=>'0');
			CS<='1';
			send_en<='1';
			cmd<=cmd0;
		when response1=>
			sclk_out<=clk5m;
			cnt74_next<=(others=>'0');
			CS<='0';
			send_en<='0';
			cmd<=(others=>'1');
		when wait_clk1=>
			sclk_out<=clk5m;
			cnt74_next<=cnt74+1;
			CS<='0';
			send_en<='0';
			cmd<=(others=>'1');
			
    		
		when init2=>
			sclk_out<=clk5m;
			cnt74_next<=(others=>'0');
			CS<='1';
			send_en<='1';
			cmd<=cmd8;
		when response2=>
			sclk_out<=clk5m;
			cnt74_next<=(others=>'0');
			CS<='0';
			send_en<='0';
			cmd<=(others=>'1');
		when wait_clk2=>
			sclk_out<=clk5m;
			cnt74_next<=cnt74+1;
			CS<='0';
			send_en<='0';
			cmd<=(others=>'1');
			
		when init3=>
			sclk_out<=clk5m;
			cnt74_next<=(others=>'0');
			CS<='1';
			send_en<='1';
			cmd<=cmd55;
		when response3=>
			sclk_out<=clk5m;
			cnt74_next<=(others=>'0');
			CS<='0';
			send_en<='0';
			cmd<=(others=>'1');
		when wait_clk3=>
			sclk_out<=clk5m;
			cnt74_next<=cnt74+1;
			CS<='0';
			send_en<='0';
			cmd<=(others=>'1');
			
		when init4=>
			sclk_out<=clk5m;
			cnt74_next<=(others=>'0');
			CS<='1';
			send_en<='1';
			cmd<=acmd41;
		when response4=>
			sclk_out<=clk5m;
			cnt74_next<=(others=>'0');
			CS<='0';
			send_en<='0';
			cmd<=(others=>'1');
		when wait_clk4=>
			sclk_out<=clk5m;
			cnt74_next<=cnt74+1;
			CS<='0';
			send_en<='0';
			cmd<=(others=>'1');
		when finished=>
			sclk_out<=clk5m;
			cnt74_next<=cnt74+1;
			CS<='0';
			send_en<='0';
			cmd<=(others=>'1');
		
	end case;
end process;


process(cnt74, byte_get)
begin
	case state is
        when send_clk=>
			if cnt74=clk_num then
				state_next<=init1;
			else
				state_next<=send_clk;
			end if;
		when init1=>
			state_next<=response1;
		when response1=>
			if byte_get=x"FF01" then
				state_next<=wait_clk1;
			else
				state_next<=response1;
			end if;
		when wait_clk1=>
			if cnt74="0000010" then
				state_next<=init2;
			else
				state_next<=wait_clk1;
			end if;
		when init2=>
			state_next<=response2;
		when response2=>
			if byte_get=x"01AA" then
				state_next<=wait_clk2;
			else
				state_next<=response2;
			end if;
		when wait_clk2=>
			if cnt74="0000010" then
				state_next<=init3;
			else
				state_next<=wait_clk2;
			end if;
		when init3=>
			state_next<=response3;
		when response3=>
			if byte_get=x"FF01" then
				state_next<=wait_clk3;
			else
				state_next<=response3;
			end if;
		when wait_clk3=>
			if cnt74="0000010" then
				state_next<=init4;
			else
				state_next<=wait_clk3;
			end if;
		when init4=>
			state_next<=response4;
		when response4=>
			if byte_get=x"FF01" then
				state_next<=wait_clk4;
			elsif byte_get=x"FF00" then
				state_next<=finished;
			else
				state_next<=response4;
			end if;
		when wait_clk4=>
			if cnt74="0000010" then
				state_next<=init3;
			else
				state_next<=wait_clk4;
			end if;
		when finished=>
		    state_next<=finished;
	end case;
end process;

initialized<='1' when state=finished else
             '0';
SCLK<=not(sclk_out);



end Behavioral;
