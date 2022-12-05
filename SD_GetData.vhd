----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2022 08:50:58 PM
-- Design Name: 
-- Module Name: SD_GetData - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SD_GetData is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           data_in : in STD_LOGIC;
           data_out : out STD_LOGIC_VECTOR (15 downto 0));
end SD_GetData;

architecture Behavioral of SD_GetData is
signal byte, byte_next: STD_LOGIC_VECTOR(15 downto 0);
begin

process(clk,reset)
begin
	if falling_edge(clk) then
		if reset='1' then
			byte<=(others=>'1');
		else
			byte<=byte_next;
		end if;
	end if;
end process;

process(clk)
begin
	byte_next(0)<=data_in;
	for i in 15 downto 1 loop
		byte_next(i)<=byte(i-1);
	end loop;
end process;

data_out<=byte;

end Behavioral;
