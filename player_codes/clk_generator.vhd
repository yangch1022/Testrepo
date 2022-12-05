----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/21/2022 07:46:18 PM
-- Design Name: 
-- Module Name: clk_generator - Behavioral
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

entity clk_generator is
    Port ( clk : in STD_LOGIC;
           clk_400K : out STD_LOGIC;
           clk_5M : out STD_LOGIC);
end clk_generator;

architecture Behavioral of clk_generator is
constant period_400k: natural:=124;--124
constant period_5M: natural:=3;--9

signal cnt_400K, cnt_400K_next: STD_LOGIC_VECTOR(6 downto 0):=(others=>'0');
signal cnt_5M, cnt_5M_next: STD_LOGIC_VECTOR(4 downto 0):=(others=>'0');

signal clk400K, clk400K_next: STD_LOGIC:='0';
signal clk5M, clk5M_next: STD_LOGIC:='0';
begin
process(clk)
begin
	if rising_edge(clk) then
		cnt_400K<=cnt_400K_next;
		cnt_5M<=cnt_5M_next;
		clk400K<=clk400K_next;
		clk5M<=clk5M_next;
	end if;
end process;

cnt_400K_next<=(others=>'0') when cnt_400K=period_400k else
			   cnt_400K+1;
cnt_5M_next<=(others=>'0') when cnt_5M=period_5M else
			 cnt_5M+1;
			 
clk400K_next<=not(clk400K) when cnt_400K=period_400k else
			  clk400K;
clk5M_next<=not(clk5M) when cnt_5M=period_5M else
			  clk5M;

clk_400K<=clk400K;
clk_5M<=clk5M;

end Behavioral;
