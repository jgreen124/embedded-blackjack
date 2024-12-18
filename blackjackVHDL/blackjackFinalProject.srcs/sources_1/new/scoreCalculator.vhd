----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/01/2024 03:36:00 PM
-- Design Name: 
-- Module Name: scoreCalculator - Behavioral
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

entity scoreCalculator is
    Port (
        clk : in std_logic;
        dealerCards : in std_logic_vector(79 downto 0);
        playerCards : in std_logic_vector(79 downto 0);
        dealerScore, playerScore : out std_logic_vector(7 downto 0)
    );
end scoreCalculator;


architecture Behavioral of scoreCalculator is
    signal DVal1, Dval2, Dval3, Dval4, Dval5, Pval1, Pval2, Pval3, Pval4, Pval5 : std_logic_vector(7 downto 0) := (others => '0');
    signal playerScoreInter, dealerScoreInter : std_logic_vector(7 downto 0);
begin

    calculateDealerScoreCard1 : process(clk) begin
        if(dealerCards(79 downto 72) = x"20") then --card is blank
            Dval1 <= "00000000";
        elsif(dealerCards(79 downto 72) = x"41") then --Ace
            Dval1 <= "00001011";    --14
        elsif(dealerCards(79 downto 72) = x"4B") then --King
            Dval1 <= "00001010"; --13
        elsif(dealerCards(79 downto 72) = x"51") then --Queen
            Dval1 <= "00001010";--12
        elsif(dealerCards(79 downto 72) = x"4A") then
            Dval1 <= "00001010";
        elsif(dealerCards(79 downto 72) = x"54") then --Ten
            Dval1 <= "00001010";
        else                                          --Everything else
            Dval1 <= std_logic_vector(unsigned(dealerCards(79 downto 72)) - 48);
        end if;
    end process;

    calculateDealerScoreCard2 : process(clk) begin
        if(dealerCards(63 downto 56) = x"20") then --card is blank
            Dval2 <= "00000000";
        elsif(dealerCards(63 downto 56) = x"41") then --Ace
            Dval2 <= "00001011";    --14
        elsif(dealerCards(63 downto 56) = x"4B") then --King
            Dval2 <= "00001010"; --13
        elsif(dealerCards(63 downto 56) = x"51") then --Queen
            Dval2 <= "00001010";--12
        elsif(dealerCards(63 downto 56) = x"4A") then
            Dval2 <= "00001010";
        elsif(dealerCards(63 downto 56) = x"54") then --Ten
            Dval2 <= "00001010";
        else                                          --Everything else
            Dval2 <= std_logic_vector(unsigned(dealerCards(63 downto 56)) - 48);
        end if;
    end process;

    calculateDealerScoreCard3 : process(clk) begin
        if(dealerCards(47 downto 40) = x"20") then --card is blank
            Dval3 <= "00000000";
        elsif(dealerCards(47 downto 40) = x"41") then --Ace
            Dval3 <= "00001011";    --14
        elsif(dealerCards(47 downto 40) = x"4B") then --King
            Dval3 <= "00001010"; --13
        elsif(dealerCards(47 downto 40) = x"51") then --Queen
            Dval3 <= "00001010";--12
        elsif(dealerCards(47 downto 40) = x"4A") then
            Dval3 <= "00001010";
        elsif(dealerCards(47 downto 40) = x"54") then --Ten
            Dval3 <= "00001010";
        else                                          --Everything else
            Dval3 <= std_logic_vector(unsigned(dealerCards(47 downto 40)) - 48);
        end if;
    end process;

    calculateDealerScoreCard4 : process(clk) begin
        if(dealerCards(31 downto 24) = x"20") then --card is blank
            Dval4 <= "00000000";
        elsif(dealerCards(31 downto 24) = x"41") then --Ace
            Dval4 <= "00001011";    --14
        elsif(dealerCards(31 downto 24) = x"4B") then --King
            Dval4 <= "00001010"; --13
        elsif(dealerCards(31 downto 24) = x"51") then --Queen
            Dval4 <= "00001010";--12
        elsif(dealerCards(31 downto 24) = x"4A") then
            Dval4 <= "00001010";
        elsif(dealerCards(31 downto 24) = x"54") then --Ten
            Dval4 <= "00001010";
        else                                          --Everything else
            Dval4 <= std_logic_vector(unsigned(dealerCards(31 downto 24)) - 48);
        end if;
    end process;

    calculateDealerScoreCard5 : process(clk) begin
        if(dealerCards(15 downto 8) = x"20") then --card is blank
            Dval5 <= "00000000";
        elsif(dealerCards(15 downto 8) = x"41") then --Ace
            Dval5 <= "00001011";    --14
        elsif(dealerCards(15 downto 8) = x"4B") then --King
            Dval5 <= "00001010"; --13
        elsif(dealerCards(15 downto 8) = x"51") then --Queen
            Dval5 <= "00001010";--12
        elsif(dealerCards(15 downto 8) = x"4A") then
            Dval5 <= "00001010";
        elsif(dealerCards(15 downto 8) = x"54") then --Ten
            Dval5 <= "00001010";
        else                                          --Everything else
            Dval5 <= std_logic_vector(unsigned(dealerCards(15 downto 8)) - 48);
        end if;
    end process;

    calculatePlayerScoreCard1 : process(clk) begin
        if(playerCards(79 downto 72) = x"20") then --card is blank
            Pval1 <= "00000000";
        elsif(playerCards(79 downto 72) = x"41") then --Ace
            Pval1 <= "00001011";    --14
        elsif(playerCards(79 downto 72) = x"4B") then --King
            Pval1 <= "00001010"; --13
        elsif(playerCards(79 downto 72) = x"51") then --Queen
            Pval1 <= "00001010";--12
        elsif(playerCards(79 downto 72) = x"4A") then
            Pval1 <= "00001010";
        elsif(playerCards(79 downto 72) = x"54") then --Ten
            Pval1 <= "00001010";
        else                                          --Everything else
            Pval1 <= std_logic_vector(unsigned(playerCards(79 downto 72)) - 48);
        end if;
    end process;

    calculatePlayerScoreCard2 : process(clk) begin
        if(playerCards(63 downto 56) = x"20") then --card is blank
            Pval2 <= "00000000";
        elsif(playerCards(63 downto 56) = x"41") then --Ace
            Pval2 <= "00001011";    --14
        elsif(playerCards(63 downto 56) = x"4B") then --King
            Pval2 <= "00001010"; --13
        elsif(playerCards(63 downto 56) = x"51") then --Queen
            Pval2 <= "00001010";--12
        elsif(playerCards(63 downto 56) = x"4A") then
            Pval2 <= "00001010";
        elsif(playerCards(63 downto 56) = x"54") then --Ten
            Pval2 <= "00001010";
        else                                          --Everything else
            Pval2 <= std_logic_vector(unsigned(playerCards(63 downto 56)) - 48);
        end if;
    end process;

    calculatePlayerScoreCard3 : process(clk) begin
        if(playerCards(47 downto 40) = x"20") then --card is blank
            Pval3 <= "00000000";
        elsif(playerCards(47 downto 40) = x"41") then --Ace
            Pval3 <= "00001011";    --14
        elsif(playerCards(47 downto 40) = x"4B") then --King
            Pval3 <= "00001010"; --13
        elsif(playerCards(47 downto 40) = x"51") then --Queen
            Pval3 <= "00001010";--12
        elsif(playerCards(47 downto 40) = x"4A") then
            Pval3 <= "00001010";
        elsif(playerCards(47 downto 40) = x"54") then --Ten
            Pval3 <= "00001010";
        else                                          --Everything else
            Pval3 <= std_logic_vector(unsigned(playerCards(47 downto 40)) - 48);
        end if;
    end process;

    calculatePlayerScoreCard4 : process(clk) begin
        if(playerCards(31 downto 24) = x"20") then --card is blank
            Pval4 <= "00000000";
        elsif(playerCards(31 downto 24) = x"41") then --Ace
            Pval4 <= "00001011";    --14
        elsif(playerCards(31 downto 24) = x"4B") then --King
            Pval4 <= "00001010"; --13
        elsif(playerCards(31 downto 24) = x"51") then --Queen
            Pval4 <= "00001010";--12
        elsif(playerCards(31 downto 24) = x"4A") then
            Pval4 <= "00001010";
        elsif(playerCards(31 downto 24) = x"54") then --Ten
            Pval4 <= "00001010";
        else                                          --Everything else
            Pval4 <= std_logic_vector(unsigned(playerCards(31 downto 24)) - 48);
        end if;
    end process;

    calculatePlayerScoreCard5 : process(clk) begin
        if(playerCards(15 downto 8) = x"20") then --card is blank
            Pval5 <= "00000000";
        elsif(playerCards(15 downto 8) = x"41") then --Ace
            Pval5 <= "00001011";    --14
        elsif(playerCards(15 downto 8) = x"4B") then --King
            Pval5 <= "00001010"; --13
        elsif(playerCards(15 downto 8) = x"51") then --Queen
            Pval5 <= "00001010";--12
        elsif(playerCards(15 downto 8) = x"4A") then
            Pval5 <= "00001010";
        elsif(playerCards(15 downto 8) = x"54") then --Ten
            Pval5 <= "00001010";
        else                                          --Everything else
            Pval5 <= std_logic_vector(unsigned(playerCards(15 downto 8)) - 48);
        end if;
    end process;

    calculateScores : process(clk) begin
        playerScoreInter <= std_logic_vector(unsigned(Pval1) + unsigned(Pval2) + unsigned(Pval3) + unsigned(Pval4) + unsigned(Pval5));
        dealerScoreInter <= std_logic_vector(unsigned(Dval1) + unsigned(Dval2) + unsigned(Dval3) + unsigned(Dval4) + unsigned(Dval5));

        if((unsigned(Pval1) = 11 or unsigned(Pval2) = 11 or unsigned(Pval3) = 11 or unsigned(Pval4) = 11 or unsigned(Pval5) = 11) and unsigned(playerScoreInter)>21) then
            playerScore <= std_logic_vector(unsigned(playerScoreInter) - 10);
        else
            playerScore <= playerScoreInter;
        end if;

        if((unsigned(Dval1) = 11 or unsigned(Dval2) = 11 or unsigned(Dval3) = 11 or unsigned(Dval4) = 11 or unsigned(Dval5) = 11) and unsigned(DealerScoreInter)>21) then
            dealerScore <= std_logic_vector(unsigned(DealerScoreInter) - 10);
        else
            dealerScore <= dealerScoreInter;
        end if;
    end process;


end Behavioral;
