----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/08/2024 07:19:37 PM
-- Design Name: 
-- Module Name: clock_div - Behavioral
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div is
    port (
        clk : in std_logic;
        enable  : out std_logic
    );
end clock_div;

architecture clock_div_arch of clock_div is
    signal count : std_logic_vector (26 downto 0) := (others => '0');
begin



    process(clk)
    begin
        if rising_edge(clk) then
            if (unsigned(count) < 1084) then
                count <= std_logic_vector( unsigned(count) + 1 );
                enable <= '0';
            else
                count <= (others => '0');
                enable <= '1';
            end if;
        end if;
    end process;

end clock_div_arch;