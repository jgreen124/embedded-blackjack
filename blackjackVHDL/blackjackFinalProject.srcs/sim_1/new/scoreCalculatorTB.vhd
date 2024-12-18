----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/03/2024 11:42:19 PM
-- Design Name: 
-- Module Name: scoreCalculatorTB - Behavioral
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

entity scoreCalculatorTB is
    --  Port ( );
end scoreCalculatorTB;

architecture Behavioral of scoreCalculatorTB is

    --testbench signals
    signal tb_clk :  std_logic := '0';
    signal tb_dealerCards :  std_logic_vector(79 downto 0) := (others => '0');
    signal tb_playerCards :  std_logic_vector(79 downto 0) := (others => '0');
    signal tb_dealerScore, tb_playerScore :  std_logic_vector(7 downto 0) := (others => '0');


    --component to be tested
    component scoreCalculator is
        Port (
            clk : in std_logic;
            dealerCards : in std_logic_vector(79 downto 0);
            playerCards : in std_logic_vector(79 downto 0);
            dealerScore, playerScore : out std_logic_vector(7 downto 0)
        );
    end component scoreCalculator;

begin
    changeInput : process begin
        tb_playerCards(79 downto 72) <= x"32";
        tb_playerCards(63 downto 56) <= x"33";
        tb_playerCards(47 downto 40) <= x"34";
        tb_playerCards(31 downto 24) <= x"35";
        tb_playerCards(15 downto 8) <= x"36";
        tb_dealerCards(79 downto 72) <= x"41";
        tb_dealerCards(63 downto 56) <= x"4B";
        tb_dealerCards(47 downto 40) <= x"51";
        tb_dealerCards(31 downto 24) <= x"4A";
        tb_dealerCards(15 downto 8) <= x"54";
        wait for 16 ns;
        tb_dealerCards(79 downto 72) <= x"32";
        tb_dealerCards(63 downto 56) <= x"51";
        tb_dealerCards(47 downto 40) <= x"34";
        tb_dealerCards(31 downto 24) <= x"35";
        tb_dealerCards(15 downto 8) <= x"36";
        tb_playerCards(79 downto 72) <= x"41";
        tb_playerCards(63 downto 56) <= x"33";
        tb_playerCards(47 downto 40) <= x"4B";
        tb_playerCards(31 downto 24) <= x"4A";
        tb_playerCards(15 downto 8) <= x"54";
        wait for 16 ns;
    end process;

    clockgen : process begin
        tb_clk <= '1';
        wait for 4 ns;
        tb_clk <= '0';
        wait for 4 ns;
    end process;


    DUT : scoreCalculator port map(
            clk => tb_clk,
            dealerCards => tb_dealerCards,
            playerCards => tb_playerCards,
            dealerScore => tb_dealerScore,
            playerScore => tb_playerScore
        );
end Behavioral;
