----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/01/2022 03:16:12 PM
-- Design Name: 
-- Module Name: clk_generator2 - Behavioral
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

entity clk_generator2 is
    Port ( clk : in STD_LOGIC;
           clk_768K : out STD_LOGIC;
           clk_5M : out STD_LOGIC);
end clk_generator2;

architecture Behavioral of clk_generator2 is
constant period_768k: natural:=141;--141s
constant period_5M: natural:=3;--9

signal cnt_768K, cnt_768K_next: STD_LOGIC_VECTOR(7 downto 0):=(others=>'0');
signal cnt_5M, cnt_5M_next: STD_LOGIC_VECTOR(4 downto 0):=(others=>'0');

signal clk768K, clk768K_next: STD_LOGIC:='0';
signal clk5M, clk5M_next: STD_LOGIC:='0';
begin
process(clk)
begin
	if rising_edge(clk) then
		cnt_768K<=cnt_768K_next;
		cnt_5M<=cnt_5M_next;
		clk768K<=clk768K_next;
		clk5M<=clk5M_next;
	end if;
end process;

cnt_768K_next<=(others=>'0') when cnt_768K=period_768k else
			   cnt_768K+1;
cnt_5M_next<=(others=>'0') when cnt_5M=period_5M else
			 cnt_5M+1;
			 
clk768K_next<=not(clk768K) when cnt_768K=period_768k else
			  clk768K;
clk5M_next<=not(clk5M) when cnt_5M=period_5M else
			  clk5M;

clk_768K<=clk768K;
clk_5M<=clk5M;

end Behavioral;