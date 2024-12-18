----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/29/2024 11:16:06 PM
-- Design Name: 
-- Module Name: blackjackGame - Behavioral
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

--figure out double down logic
--add second oled for information on game
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity blackjackGame is
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
         JA : inout std_logic_vector(7 downto 0);
         resetBtn : in std_logic;
         seed : in std_logic_vector(2 downto 0);

         --extra LEDS
         je : out std_logic_vector(7 downto 0)
        );
end blackjackGame;

architecture Behavioral of blackjackGame is
    --signals to detect button press
    signal buttonPressed : std_logic_Vector(3 downto 0) := (others => '0');


    --blackjack game timing signals
    signal clk_en : std_logic; --acts as clock enable, port mapped to clock_div

    --signals for OLED
    signal dataToOLED : std_logic_vector(215 downto 0); --same size as cardDataIn for PmodOLEDCtrl component
    signal dataToOLED1 : std_logic_vector(47 downto 0);
    signal toggleDisplay1 : std_logic_vector(3 downto 0) := "0000";
    signal oledReset : std_logic; --won't need to be used
    signal asciiMoney : std_logic_vector(23 downto 0);
    signal toggleDisplay : std_logic;

    --reset signal    
    signal resetDebounced : std_logic;


    --signals for Psuedo Random Number Generation
    signal lfsr : std_logic_vector(17 downto 0) := (others => '0'); --set to any nonzero number for seed and use as number to index deck
    signal feedback : std_logic := '0';
    signal PRN : std_logic_vector(7 downto 0) := (others => '0');

    component clock_div is
        port (
            clk : in std_logic;
            enable  : out std_logic
        );
    end component clock_div;

    --component PRNArrays is
    --port (
    --    seed : in std_logic_vector(2 downto 0);
    --    clk : in std_logic;
    --    index : in std_logic_vector(17 downto 0);
    --    output : out std_logic_vector(7 downto 0)
    --);
    --end component;
    component debounce is
        port (
            in0 : in std_logic;
            clk : in std_logic;
            out0 : out std_logic
        );
    end component debounce;
    component  PmodOLEDCtrl is
        Port (
            CLK 	: in  STD_LOGIC;
            RST 	: in  STD_LOGIC;

            CS  	: out STD_LOGIC;
            SDIN	: out STD_LOGIC;
            SCLK	: out STD_LOGIC;
            DC		: out STD_LOGIC;
            RES	: out STD_LOGIC;
            VBAT	: out STD_LOGIC;
            VDD	: out STD_LOGIC;

            --signals that I am adding
            --changeInput : in std_logic -- flipping switch changes data sent to display;
            cardDataIn : in std_logic_vector(215 downto 0); --will change as more card data comes in
            toggleDisplay : in std_logic
        );
    end component PmodOLEDCtrl;
    component binaryToASCIIConverter is
        port (
            clk : in std_logic;
            binaryIn : in std_logic_vector(7 downto 0);
            asciiOut : out std_logic_vector(23 downto 0));
    end component binaryToASCIIConverter;

    component keypadDecoder is
        port (
            clk : in std_logic;
            Row : in std_logic_vector(3 downto 0);
            Col : out std_logic_vector(3 downto 0);
            DecodeOut : out std_logic_vector(3 downto 0)
        );
    end component keypadDecoder;

    component scoreCalculator is
        port (
            clk : in std_logic;
            dealerCards : in std_logic_vector(79 downto 0);
            playerCards : in std_logic_vector(79 downto 0);
            dealerScore, playerScore : out std_logic_vector(7 downto 0)
        );
    end component scoreCalculator;

    component pmodOledCTRL1 is
        Port (
            CLK 	: in  STD_LOGIC;
            RST 	: in  STD_LOGIC;

            CS1  	: out STD_LOGIC;
            SDIN1	: out STD_LOGIC;
            SCLK1	: out STD_LOGIC;
            DC1		: out STD_LOGIC;
            RES1	: out STD_LOGIC;
            VBAT1	: out STD_LOGIC;
            VDD1	: out STD_LOGIC;

            --signals that I am adding
            --changeInput : in std_logic -- flipping switch changes data sent to display;
            cardDataIn : in std_logic_vector(47 downto 0); --will change as more card data comes in
            toggleDisplay : in std_logic_vector(3 downto 0)
        );
    end component;


    --state type declaration
    type state is (  playerBid,
                   deal0,
                   deal1,
                   deal2,
                   deal3,
                   playerAction,
                   doubleDown,
                   dealerAction,
                   findWinner,
                   waitState,
                   reset
                  ); --define states here

    signal PS : state;
    signal AS : state;

    --deck and player/dealer hand declarations, cardIndex declaration
    type cardDeck is array (0 to 51) of std_logic_vector(15 downto 0); --a brute force way of storing cards, first 8 bits are rank, next 8 bits are suit
    signal deck : cardDeck := (x"3243", x"3343", x"3443", x"3543", x"3643", x"3743", x"3843", x"3943", x"5443", x"4A43", x"5143", x"4B43", x"4143",x"3248", x"3348",
                                                                     x"3448", x"3548", x"3648", x"3748", x"3848", x"3948", x"5448", x"4A48", x"5148", x"4B48", x"4148",x"3253", x"3353", x"3453", x"3553", x"3653", x"3753", x"3853", x"3953",
                                                                     x"5453", x"4A53", x"5153", x"4B53", x"4153",x"3244", x"3344", x"3444", x"3544", x"3644", x"3744", x"3844", x"3944", x"5444", x"4A44", x"5144", x"4B44", x"4144");
    type cardHand is array(0 to 4) of std_logic_vector(15 downto 0);--I am going to gamble that no one who uses this will successfully get to 6 cards
    signal playerHand, dealerHand : cardHand := (x"2020", x"2020", x"2020", x"2020", x"2020"); --x"2020" will be used to represent an unoccupied slot since this makes clearing the oled easier later
    signal cardHandIndex : std_logic_vector(3 downto 0) := "0010"; --start at 3    
    --money for player declaration
    signal playerMoney : std_logic_vector(7 downto 0) := "10000000";--start player with 128, cap at 256   
    signal asciiConv : std_logic_vector(23 downto 0);

    --signals to count scores, the ASCII signals are for the OLED
    signal dealerCards, playerCards : std_logic_vector(79 downto 0);
    signal playerScore, dealerScore : std_logic_vector(7 downto 0);
    signal playerScoreASCII, dealerScoreASCII : std_logic_vector(23 downto 0);
    --this signal stores the players bid
    signal playerBet : std_logic_vector(3 downto 0);
    signal playerBetASCII : std_logic_Vector(23 downto 0);
    signal playerBetConv: std_logic_vector(7 downto 0);

    signal winCounter : std_logic_vector(2 downto 0) := "000"; --counts consecutive wins
begin

    --concatenate data so components can be mapped to these signals
    dataToOled <= playerHand(0) & playerHand(1) & playerHand(2) & playerHand(3) & playerHand(4) & playerScoreASCII(15 downto 0) & asciiMoney & dealerHand(0) & dealerHand(1) & dealerHand(2) & dealerHand(3) & dealerHand(4) & dealerScoreASCII(15 downto 0);
    dataToOled1 <= playerScoreASCII(15 downto 0) & dealerScoreASCII(15 downto 0) & playerBetASCII(15 downto 0);
    dealerCards <= dealerHand(0) & dealerHand(1) & dealerHand(2) & dealerHand(3) & dealerHand(4);
    playerCards <= playerHand(0) & playerHand(1) & playerHand(2) & playerHand(3) & playerHand(4);
    playerBetConv <= "0000" & playerBet;

    --check if OLED should be displaying player or card data

    showConsWins : process(clk)
    begin
        case winCounter is
            when "000" => JE <= "00000001";
            when "001" => JE <= "00000011";
            when "010" => JE <= "00000111";
            when "011" => JE <= "00001111";
            when "100" => JE <= "00011111";
            when "101" => JE <= "00111111";
            when "110" => JE <= "01111111";
            when "111" => JE <= "11111111";
        end case;
    end process;

    updateDisplay : process(clk)
    begin
        if(rising_edge(clk)) then
            toggleDisplay <= changeDisplay;
        end if;
    end process;



    --This FSM is the game
    stateProc : process(clk)
    begin
        if(rising_edge(clk)) then
            if(clk_en = '1' and unsigned(PRN)<52) then
                if (resetDebounced = '1') then --a reset isn't really necessary here since the FSM has a reset state that serves as a catch-all for anything not explicitely defined
                    PS <= reset;
                end if;
                case ps is --case statement for player/dealer actions
                    when playerBid => --press button on keypad to place bid, transition afterwards to waitState, and then deal0
                        toggleDisplay1 <= "0000";
                        if(buttonPressed = "0000") then
                            PS <= playerBid;
                        else
                            playerMoney <= std_logic_vector(unsigned(playerMoney) - unsigned(buttonPressed));
                            playerBet <= std_logic_vector(unsigned(buttonPressed));
                            --toggleDisplay1 <= "0001";
                            PS <= waitState;
                            AS <= deal0;
                        end if;
                    when deal0 => --deals first player card
                        playerHand(0) <= deck(to_integer(unsigned(PRN)));
                        PS <= deal1;

                    when deal1 => --deals second player card
                        playerHand(1) <= deck(to_integer(unsigned(PRN)));
                        PS <= deal2;

                    when deal2 => --deals first dealer card
                        dealerHand(0) <= deck(to_integer(unsigned(PRN)));
                        PS <= playerAction;

                    --                when deal3 =>
                    --                    dealerHand(1) <= deck(to_integer(unsigned(lfsr)));
                    --                    cardHandIndex <= "0010";
                    --                    PS <= dealerAction;

                    when playerAction => --check for condition or for what button is pressed and perform appropriate actions
                        toggleDisplay1 <= "0010";
                        if(unsigned(playerScore) > 21) then --player has busted, switch to waitState and findWinner;
                            PS <= waitState;
                            AS <= findWinner;
                            --add player bust screen here
                            toggleDisplay1 <= "0100";
                        elsif((unsigned(cardHandIndex) = 5) or (unsigned(playerScore) = 21)) then --If player has 21 then just move on, I am also capping the number of cards drawn to 5 for the player and dealer, so if five cards are drawn without error, transition to dealers turn
                            PS <= waitState;
                            AS <= dealerAction;
                            dealerHand(1) <= deck(to_integer(unsigned(PRN))); --deal second card to dealer after player stands
                            cardHandIndex <= "0001"; --reset card index so dealer cards are drawn correctly. waitState will add 1 to cardIndex before any card is drawn so reset to 1 and let wait add so that cardIndex is 2
                        elsif(buttonPressed = "1010") then --hit and then transition to wait, and then back to playerAction
                            PS <= waitState;
                            AS <= playerAction;
                            playerHand(to_integer(unsigned(cardHandIndex))) <= deck(to_integer(unsigned(PRN))); --assign next card to player
                        elsif (buttonPressed = "1011") then --stand, end player turn and transition to dealer's turn
                            PS <= waitState;
                            AS <= dealerAction;
                            dealerHand(1) <= deck(to_integer(unsigned(PRN))); --deal second card to dealer after player stands
                            toggleDisplay1 <= "0110";
                            cardHandIndex <= "0001"; --reset card index so dealer cards are drawn correctly. waitState will add 1 to cardIndex before any card is drawn so reset to 1 and let wait add so that cardIndex is 2
                        elsif (buttonPressed = "1100" and (unsigned(playerBet)<unsigned(playerMoney)) and cardHandIndex = "0010") then --double down
                            PS <= waitState;
                            AS <= dealerAction;
                            playerHand(to_integer(unsigned(cardhandIndex))) <= deck(to_integer(unsigned(PRN)));
                            cardHandIndex <= "0001";
                            dealerHand(1) <= deck(to_integer(unsigned(PRN)));
                            toggleDisplay1 <= "1011";
                        --                    elsif ((buttonPressed = "1100") and (unsigned(playerBet) > unsigned(playerMoney)) and (unsigned(cardHandIndex) = "0010")) then --double down, draw one card and transition, only available if player hasn't drawn a card
                        --                        PS <= waitState;
                        --                        AS <= doubleDown;
                        --                        playerMoney <= std_logic_vector(unsigned(playerMoney) - unsigned(playerBet));
                        --                        playerHand(2) <= deck(to_integer(unsigned(lfsr))); --give one card to player
                        else
                            PS <= playerAction;
                        end if;
                    --                when doubleDown => --transitions to dealerAction and corrects the playerBet to reflect the double down
                    --                        PS <= waitState;
                    --                        AS <= dealerAction; 
                    --                        playerBet <= std_logic_vector(unsigned(playerBet) + unsigned(playerBet));
                    --                        dealerHand(1) <= deck(to_integer(unsigned(lfsr))); --deal second card to dealer after player stands
                    --                        cardHandIndex <= "0010"; --reset card index so dealer cards are drawn correctly 
                    when dealerAction => --samething as playerAction here, but easier since its formulaic. Just need to find a way to slow down the process, maybe by asking player to place a bid
                        if(unsigned(dealerScore) <17 or unsigned(dealerScore) = 17 ) then
                            PS <= waitState;
                            AS <= dealerAction;
                            dealerHand(to_integer(unsigned(cardHandIndex))) <= deck(to_integer(unsigned(PRN)));
                        elsif(unsigned(cardHandINdex) = 5) then
                            PS <= waitState;
                            AS <= findWinner;
                        else
                            PS <= waitState;
                            AS <= findWinner;
                        end if;
                    when findWinner =>
                        toggleDisplay1 <= "0111";
                        if(unsigned(playerScore) > 21) then
                            --update top display with information, saying that the player has busted
                            PS <= waitState;
                            AS <= reset;
                            winCounter <= (others => '0');
                        --toggleDisplay1 <= "0100";
                        elsif(unsigned(dealerScore) > 21) then
                            --update top display saying the dealer has busted
                            playerMoney <= std_logic_vector(unsigned(playerMoney) + unsigned(playerBet) + unsigned(playerBet));
                            PS <= waitState;
                            AS <= reset;
                            winCounter <= std_logic_vector(unsigned(winCounter) + 1);
                        --toggleDisplay1 <= "0101";
                        elsif(unsigned(dealerScore) > unsigned(playerScore)) then
                            PS <= waitState;
                            AS <= reset;
                            winCounter <= (others => '0');
                        --toggleDisplay1 <= "1001";
                        elsif(unsigned(playerScore) > unsigned(dealerScore)) then
                            playerMoney <= std_logic_Vector(unsigned(playerMoney) + unsigned(playerBet) + unsigned(playerBet));
                            PS <= waitState;
                            AS <= reset;
                            winCounter <= std_logic_vector(unsigned(winCounter) + 1);
                        elsif(unsigned(playerScore) = unsigned(dealerScore)) then
                            playerMoney <= std_logic_vector(unsigned(playerMoney) + unsigned(playerBet));
                            --toggleDisplay1 <= "1000";
                            PS <= waitState;
                            AS <= reset;
                        else
                            PS <= waitState;
                        end if;

                    when waitState =>
                        case AS is
                            when deal0 =>
                                if(buttonPressed = "0000") then
                                    PS <= AS;
                                    toggleDisplay1 <= "0010";
                                else
                                    PS <= waitState;
                                    toggleDisplay1 <= "0001";
                                end if;
                            when playerAction =>
                                if(buttonPressed = "0000") then
                                    PS <= AS;
                                    if (AS = playerAction) then
                                        cardHandIndex <= std_Logic_vector(unsigned(cardHandIndex) + 1);
                                    else
                                        cardHandIndex <= "0010";
                                    end if;
                                else
                                    PS <= waitState;
                                    toggleDisplay1 <= "0011";
                                end if;
                            --                    when deal3 =>
                            --                        if(buttonPressed = "1111") then
                            --                              PS <= AS;
                            --                        else
                            --                            PS <= waitState;
                            --                        end if;
                            --                    when doubleDown =>
                            --                        if(buttonPressed) = "0000" then
                            --                            PS <= AS;
                            --                        else
                            --                            PS <= waitState;
                            --                        end if;
                            when dealerAction =>
                                if(buttonPressed = "0000") then
                                    PS <= AS;
                                    toggleDisplay1 <= "0110";
                                    if (AS = dealerAction) then
                                        cardHandIndex <= std_Logic_vector(unsigned(cardHandIndex) + 1);
                                    else
                                        cardHandIndex <= "0010";
                                    end if;
                                else
                                    PS <= waitState;
                                end if;
                            when findWinner =>
                                if(buttonPressed = "1111") then
                                    PS <= AS;
                                else
                                    PS <= waitState;
                                    if(unsigned(playerScore) > 21) then
                                        toggleDisplay1 <= "0100";
                                    elsif(unsigned(dealerScore) > 21) then
                                        toggleDisplay1 <= "0101";
                                    elsif(unsigned(dealerScore) > unsigned(playerScore)) then
                                        toggleDisplay1 <= "1001";
                                    elsif(unsigned(playerScore) > unsigned(dealerScore)) then
                                        toggleDisplay1 <= "1000";
                                    elsif(unsigned(playerScore) = unsigned(dealerScore)) then
                                        toggleDisplay1 <= "1010";

                                    end if;
                                end if;
                            when reset =>
                                if (buttonPressed = "0000") then
                                    PS <= AS;
                                else
                                    PS <= waitState;
                                end if;
                            when others => PS <= reset;
                        end case;

                    when reset =>
                        --reset player bet
                        playerBet <= (others => '0');

                        --reset player and dealer hands
                        playerHand <= (others => x"2020");
                        dealerHand <= (others => x"2020");

                        --reset card index
                        cardHandIndex <= "0010";


                        --go to wait state
                        PS <= playerBid;
                        AS <=playerBid;
                    when others =>
                end case;
            end if;
        end if;
    end process;

    --Psuedo Random Number Generation Process lfsr, feedback, randomnum
    RandomNumProc : process(clk)
    begin
        --feedback <= lfsr(7) xor lfsr(5);
        if(rising_edge(clk)) then
            --            
            if(unsigned(PRN) > 99999) then
                PRN <= (others => '0');
            else
                PRN <= std_logic_vector(unsigned(PRN) + unsigned(seed) + unsigned(playerScore) + unsigned(dealerScore) + unsigned(playerMoney) + 1);
            end if;
        end if;
    end process;



    --Port mappings
    clock_en : clock_div port map(
            clk => clk,
            enable => clk_en
        );

    OLED : PmodOLEDCtrl port map(
            CLK => clk,
            RST => oledReset, --not a necessary signal since I won't need to reset
            CS => CS,
            SDIN => SDIN,
            SCLK => SCLK,
            DC => DC,
            RES => RES,
            VBAT => VBAT,
            VDD => VDD,
            cardDataIn => dataToOled,
            toggleDisplay => toggleDisplay
        );

    OLED1 : PmodOLEDCtrl1 port map(
            CLK => clk,
            RST => oledReset, --not a necessary signal since I won't need to reset
            CS1 => CS1,
            SDIN1 => SDIN1,
            SCLK1 => SCLK1,
            DC1 => DC1,
            RES1 => RES1,
            VBAT1 => VBAT1,
            VDD1 => VDD1,
            cardDataIn => dataToOled1,
            toggleDisplay => toggleDisplay1
        );

    moneyInToASCII : binaryToASCIIConverter port map(
            clk => clk,
            binaryIn => playerMoney,
            asciiOut => asciiMoney
        );

    playerScoreInToASCII : binaryToASCIIConverter port map(
            clk => clk,
            binaryIn => playerScore,
            asciiOut => playerScoreASCII
        );

    dealerScoreInToASCII : binaryToASCIIConverter port map(
            clk => clk,
            binaryIn => dealerScore,
            asciiOut => dealerScoreASCII
        );

    playerAmountBet : binaryToASCIIConverter port map(
            clk => clk,
            binaryIn => playerBetConv,
            asciiOut => playerBetASCII
        );
    keypad : keypadDecoder port map(
            clk => clk,
            Row => JA(7 downto 4),
            Col => JA(3 downto 0),
            DecodeOut => buttonPressed
        );

    scores : scoreCalculator port map(
            clk => clk,
            dealerCards => dealerCards,
            playerCards => playerCards,
            playerScore => playerScore,
            dealerScore => dealerScore
        );

    resetProc : debounce port map(
            in0 => resetBtn,
            clk => clk,
            out0 => resetDebounced
        );

        --PRNFetch : PRNArrays port map(
        --    seed => seed,
        --    clk => clk,
        --    index => lfsr,
        --    output => PRN
        --);

end Behavioral;
