----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/05/2022 02:31:46 PM
-- Design Name: 
-- Module Name: data_converter - Behavioral
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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity data_converter is
    Port ( data_in : in STD_LOGIC_VECTOR (15 downto 0);
           data_out : out STD_LOGIC_VECTOR (15 downto 0));
end data_converter;

architecture Behavioral of data_converter is
begin

process(data_in)
variable temp: integer range 0 to 65535;
begin
    temp := (to_integer(signed(data_in(7 downto 0) & data_in(15 downto 8)))+32768);
    data_out <= "00" & std_logic_vector(to_unsigned(integer(temp*255/65536), 8)) & "000000";
end process;



end Behavioral;
