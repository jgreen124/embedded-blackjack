----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/04/2024 01:39:38 PM
-- Design Name: 
-- Module Name: blackjackGameTB - Behavioral
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

entity blackjackGameTB is
    --  Port ( );
end blackjackGameTB;

architecture Behavioral of blackjackGameTB is

    signal clk, rst, cs, cs1, sdin, sdin1, sclk, sclk1, dc, dc1, res, res1, vbat, vbat1, vdd, vdd1, changeDisplay, resetBtn : std_logic := '0';
    signal buttonPressed : std_logic_vector(3 downto 0) := (others => '0');
    signal seed : std_logic_vector(2 downto 0) := (others => '0');
    signal JE : std_logic_vector(7 downto 0) := (others => '0');

    component blackjackGameWithoutKeypad is
        Port ( CLK : in std_logic;
             RST : in std_logic;


             --OLED Signals
             CS,CS1  	: out STD_LOGIC;
             SDIN,SDIN1	: out STD_LOGIC;
             SCLK,SCLK1	: out STD_LOGIC;
             DC, DC1		: out STD_LOGIC;
             RES,RES1	: out STD_LOGIC;
             VBAT, VBAT1	: out STD_LOGIC;
             VDD,VDD1	: out STD_LOGIC;
             changeDisplay : in std_logic;

             --button signals
             --JA : inout std_logic_vector(7 downto 0);
             buttonPressed : in std_logic_vector(3 downto 0) := (others => '0');
             resetBtn : in std_logic := '0';
             seed : in std_logic_vector(2 downto 0) := (others => '0');

             --extra LEDS
             je : out std_logic_vector(7 downto 0)
            );
    end component blackjackGameWithoutKeypad;

begin

    clk_proc : process begin
        clk <= '1';
        wait for 4 ns;
        clk <= '0';
        wait for 4 ns;
    end process;

    changeInput_Proc : process begin
        wait for 16 ns;
        if buttonPressed = "1111" then
            buttonPressed <= "0000";
        else
            buttonPressed <= std_logic_vector(unsigned(buttonPressed) + 1);
        end if;
    end process;

    switchDisplayProc : process begin
        changeDisplay <= '0';
        wait for 500 us;
        changeDisplay <= '1';
        wait for 500 us;
    end process;

    DUT : blackjackGameWithoutKeypad port map(
            clk => clk,
            rst => rst,
            CS => cs,
            cs1 => cs1,
            SDIN => sdin,
            sdin1 => sdin1,
            sclk => sclk,
            sclk1 => sclk1,
            dc => dc,
            dc1 => dc1,
            res => res,
            res1 => res1,
            vbat => vbat,
            vbat1 => vbat1,
            vdd => vdd,
            vdd1 => vdd1,
            changeDisplay => changeDisplay,
            buttonPressed => buttonPressed,
            resetBtn => resetBtn,
            seed => seed,
            je => je

        );
end Behavioral;
