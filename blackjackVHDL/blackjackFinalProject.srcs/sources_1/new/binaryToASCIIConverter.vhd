----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/29/2024 11:42:49 PM
-- Design Name: 
-- Module Name: binaryToASCIIConverter - Behavioral
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

entity binaryToASCIIConverter is
    Port (
        clk : in std_logic;
        binaryIn : in std_logic_vector(7 downto 0);
        asciiOut : out std_logic_vector(23 downto 0)
    );

end binaryToASCIIConverter;

architecture Behavioral of binaryToASCIIConverter is
    -- Internal signal to hold the integer value of the input vector
    signal intValue: integer range 0 to 255;
    signal asciiHundreds, asciiTens,asciiOnes : std_logic_vector(7 downto 0);
begin
    process(binaryIn)
        variable hundreds: integer;
        variable tens: integer;
        variable ones: integer;
    begin
        -- Convert the 8-bit vector to an integer
        intValue <= to_integer(unsigned(binaryIn));


        hundreds := intValue / 100;
        tens := (intValue mod 100) / 10;
        ones := intValue mod 10;

        if hundreds = 0 then
            asciiHundreds <= X"20";  -- Space for hundreds if less than 100
        else
            asciiHundreds <= std_logic_vector(to_unsigned(48 + hundreds, 8));
        end if;

        if hundreds = 0 and tens = 0 then
            asciiTens <= X"20";  -- Space for tens if less than 10
        else
            asciiTens <= std_logic_vector(to_unsigned(48 + tens, 8));
        end if;

        asciiOnes <= std_logic_vector(to_unsigned(48 + ones, 8));
    end process;

    process(clk) begin
        asciiOut <= asciihundreds & asciitens & asciiones;
    end process;
end Behavioral;
