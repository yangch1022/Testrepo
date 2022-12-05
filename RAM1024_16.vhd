----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/01/2022 02:36:52 PM
-- Design Name: 
-- Module Name: RAM1024_16 - Behavioral
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

entity RAM1024_16 is
    Port ( clka : in std_logic;
			clkb : in std_logic;
			ena : in std_logic;
			enb : in std_logic;
			wea : in std_logic;
			addra : in std_logic_vector(8 downto 0);
			addrb : in std_logic_vector(8 downto 0);
			dia : in std_logic_vector(15 downto 0);
			dob : out std_logic_vector(15 downto 0));
end RAM1024_16;

architecture Behavioral of RAM1024_16 is

    type ram_type is array (511 downto 0) of std_logic_vector(15 downto 0);
	shared variable RAM : ram_type;
begin
process(clka)
begin
	if falling_edge(clka) then
		if ena = '1' then
			if wea = '1' then
				RAM(conv_integer(addra)) := dia;
			end if;
		end if;
	end if;
end process;

process(clkb)
	begin
		if falling_edge(clkb) then
			if enb = '1' then
				dob <= RAM(conv_integer(addrb));
			end if;
		end if;
	end process;
	
end Behavioral;

