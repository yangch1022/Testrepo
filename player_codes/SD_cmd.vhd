----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2022 08:35:42 PM
-- Design Name: 
-- Module Name: SD_cmd - Behavioral
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

entity SD_cmd is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           send : in STD_LOGIC;
           cmd_in : in STD_LOGIC_VECTOR (47 downto 0);
           cmd_out : out STD_LOGIC;
           ready : out STD_LOGIC);
end SD_cmd;

architecture Behavioral of SD_cmd is
type state_type is (idle,data);
signal state, state_next: state_type;

signal cnt47, cnt47_next: STD_LOGIC_VECTOR(5 downto 0);
constant cmd_wid: natural:=47;


signal cmd_reg, cmd_next: STD_LOGIC_VECTOR(47 downto 0);

begin
process(clk,reset)
begin
	if rising_edge(clk) then
		if reset='1' then
			cnt47<=std_logic_vector(to_unsigned(cmd_wid,6));
			state<=idle;
			cmd_reg<=(others=>'1');
		else
			cnt47<=cnt47_next;
			state<=state_next;
			cmd_reg<=cmd_next;
		end if;
	end if;
end process;

process(send,state,cnt47)
begin
	case state is
		when idle=>
			cnt47_next<=std_logic_vector(to_unsigned(cmd_wid,6));
			
			if send='1' then
				cmd_next<=cmd_in;
				ready<='0';
			else
				cmd_next<=(others=>'1');
				ready<='1';
			end if;
			cmd_out<='1';
		when data=>
			cnt47_next<=cnt47-1;
			ready<='0';
			cmd_next<=cmd_reg;
			cmd_out<=cmd_reg(to_integer(unsigned(cnt47)));
	end case;
end process;


process(cnt47,send,state)
begin
	case state is
		when idle=>
			if send='1' then
				state_next<=data;
			else
				state_next<=idle;
			end if;
		when data=>
			if cnt47="000000" then
				state_next<=idle;
			else
				state_next<=data;
			end if;
	end case;
end process;

end Behavioral;
