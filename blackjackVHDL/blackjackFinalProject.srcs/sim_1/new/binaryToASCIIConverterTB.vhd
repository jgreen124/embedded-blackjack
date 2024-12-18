----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/03/2024 11:32:30 PM
-- Design Name: 
-- Module Name: binaryToASCIIConverterTB - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity binaryToASCIIConverterTB is
--  Port ( );
end binaryToASCIIConverterTB;

architecture Behavioral of binaryToASCIIConverterTB is


--testbench signals
signal tb_clk : std_logic;
signal tb_binaryIn : std_logic_vector(7 downto 0) := (others => '0');
signal tb_asciiOut:  std_logic_vector(23 downto 0);


--component to be tested
component binaryToASCIIConverter is
Port(
    clk : in std_logic;
    binaryIn : in std_logic_vector(7 downto 0);
    asciiOut : out std_logic_vector(23 downto 0)
);
end component;
begin

--generate 125MHz clock
clock_gen : process begin
    tb_clk <= '1';
    wait for 4 ns;
    tb_clk <= '0';
    wait for 4 ns;
end process;

--increment input for testing
incrementInputProc : process(tb_clk)
begin
    if( tb_binaryIn = "11111111") then
        tb_binaryIn <= (others => '0');
    else
        tb_binaryIn <= std_logic_vector(unsigned(tb_binaryIn) + 1);
    end if;
end process;


--Device under testing
DUT : binaryToASCIIConverter port map(
    clk => tb_clk,
    binaryIn => tb_binaryIn,
    asciiOut => tb_asciiOut
);
end Behavioral;

