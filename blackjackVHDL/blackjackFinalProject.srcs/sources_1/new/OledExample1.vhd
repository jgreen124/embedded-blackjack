----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
-- 
-- Create Date:    11:50:03 10/24/2011 
-- Module Name:    OledExample - Behavioral 
-- Project Name: 	 PmodOLED Demo
-- Tool versions:  ISE 13.2
-- Description: Demo for the PmodOLED.  First displays the alphabet for ~4 seconds and then
--				Clears the display, waits for a ~1 second and then displays "This is Digilent's
--				PmodOLED"
--
-- Revision: 1.2
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------



--HAVE RESET SWITCH CONTROL WHETHER PLAYER CARDS/MONEY ARE DISPLAYED OR IF DEALER CARDS
--ARE DISPLAYED

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity OledEx1 is
    Port ( CLK 	: in  STD_LOGIC; --System CLK
         RST 	: in	STD_LOGIC; --Synchronous Reset
         EN		: in  STD_LOGIC; --Example block enable pin
         CS  	: out STD_LOGIC; --SPI Chip Select
         SDO		: out STD_LOGIC; --SPI Data out
         SCLK	: out STD_LOGIC; --SPI Clock
         DC		: out STD_LOGIC; --Data/Command Controller
         FIN  	: out STD_LOGIC;

         --signals that I am adding
         newDataIn : in std_logic_vector(47 downto 0);
         switchDisplay : in std_logic_vector(3 downto 0));--This will be changed to represent the data coming in
end OledEx1;

architecture Behavioral of OledEx1 is

    --SPI Controller Component
    COMPONENT SpiCtrl
        PORT(
            CLK : IN  std_logic;
            RST : IN  std_logic;
            SPI_EN : IN  std_logic;
            SPI_DATA : IN  std_logic_vector(7 downto 0);
            CS : OUT  std_logic;
            SDO : OUT  std_logic;
            SCLK : OUT  std_logic;
            SPI_FIN : OUT  std_logic
        );
    END COMPONENT;

    --Delay Controller Component
    COMPONENT Delay
        PORT(
            CLK : IN  std_logic;
            RST : IN  std_logic;
            DELAY_MS : IN  std_logic_vector(11 downto 0);
            DELAY_EN : IN  std_logic;
            DELAY_FIN : OUT  std_logic
        );
    END COMPONENT;

    --Character Library, Latency = 1
    COMPONENT charLib
        PORT (
            clka : IN STD_LOGIC; --Attach System Clock to it
            addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0); --First 8 bits is the ASCII value of the character the last 3 bits are the parts of the char
            douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) --Data byte out
        );
    END COMPONENT;

    --States for state machine
    type states is (Idle,
                    ClearDC,
                    SetPage,
                    PageNum,
                    LeftColumn1,
                    LeftColumn2,
                    SetDC,
                    Alphabet,
                    Wait1,
                    ClearScreen,
                    Wait2,
                    DigilentScreen,
                    UpdateScreen,
                    SendChar1,
                    SendChar2,
                    SendChar3,
                    SendChar4,
                    SendChar5,
                    SendChar6,
                    SendChar7,
                    SendChar8,
                    ReadMem,
                    ReadMem2,
                    Done,
                    Transition1,
                    Transition2,
                    Transition3,
                    Transition4,
                    Transition5,

                    --my created states
                    playerScreen,
                    wait3
                   );
    type OledMem is array(0 to 3, 0 to 15) of STD_LOGIC_VECTOR(7 downto 0);

    --Variable that contains what the screen will be after the next UpdateScreen state
    signal presentScreen : OledMem;
    signal current_screen : OledMem;
    --Constant that contains the screen filled with the Alphabet and numbers
    constant blackjackStart : OledMem :=((
(X"57",X"65",X"6C",X"63",X"6F",X"6D",X"65",X"20",X"74",X"6F",X"20",X"62",X"6C",X"61",X"63",X"6B"),
                                          (X"6A",X"61",X"63",X"6B",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                          (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                          (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20")));
    --Constant that fills the screen with blank (spaces) entries
    constant clear_screen : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                          (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                          (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                          (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
    --Constant that holds "This is Digilent's PmodOLED"
    constant warningScreen : OledMem:= (
        (X"46",X"6C",X"69",X"70",X"20",X"74",X"68",X"65",X"20",X"66",X"69",X"72",X"73",X"74",X"20",X"20"),
        (X"73",X"77",X"69",X"74",X"63",X"68",X"20",X"74",X"6F",X"20",X"66",X"6C",X"69",X"70",X"20",X"20"),
        (X"62",X"65",X"74",X"77",X"65",X"65",X"6E",X"20",X"79",X"6F",X"75",X"72",X"73",X"20",X"20",X"20"),
        (X"61",X"6E",X"64",X"20",X"64",X"65",X"61",X"6C",X"65",X"72",X"20",X"68",X"61",X"6E",X"64",X"20")
    );

    signal placeBidScreen : OledMem := (
        (X"50",X"72",X"65",X"73",X"73",X"20",X"61",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"63",X"68",X"61",X"72",X"61",X"63",X"74",X"65",X"72",X"20",X"74",X"6F",X"20",X"20",X"20",X"20"),
        (X"70",X"6C",X"61",X"63",X"65",X"20",X"61",X"20",X"62",X"69",X"64",X"20",X"20",X"20",X"20",X"20"),
        (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20")
    );

    signal bidReceivedScreen : oledMem := (
        (X"50",X"6C",X"61",X"79",X"65",X"72",X"20",X"42",X"69",X"64",X"3A",X"20",X"5F",X"5F",X"20",X"20"),
        (X"50",X"72",X"65",X"73",X"73",X"20",X"30",X"20",X"74",X"6F",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"63",X"6F",X"6E",X"74",X"69",X"6E",X"75",X"65",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20")
    );

    signal playerActions : oledMem := (
        (X"63",X"61",X"72",X"64",X"73",X"20",X"64",X"65",X"61",X"6C",X"74",X"20",X"20",X"20",X"20",X"20"),
        (X"41",X"3D",X"68",X"69",X"74",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"42",X"3D",X"53",X"74",X"61",X"6E",X"64",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"43",X"3D",X"44",X"6F",X"75",X"62",X"6C",X"65",X"20",X"44",X"6F",X"77",X"6E",X"20",X"20",X"20")
    );

    signal zeroToContinue : oledMem := (
        (X"61",X"63",X"74",X"69",X"6F",X"6E",X"20",X"72",X"65",X"63",X"65",X"69",X"76",X"65",X"64",X"20"),
        (X"70",X"72",X"65",X"73",X"73",X"20",X"30",X"20",X"74",X"6F",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"63",X"6F",X"6E",X"74",X"69",X"6E",X"75",X"65",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20")
    );

    signal playerBustScreen : oledMem := (
        (X"42",X"75",X"73",X"74",X"65",X"64",X"21",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"50",X"72",X"65",X"73",X"73",X"20",X"46",X"20",X"74",X"6F",X"20",X"70",X"61",X"79",X"20",X"20"),
        (X"72",X"65",X"73",X"70",X"65",X"63",X"74",X"73",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20")
    );

    signal dealerBustScreen : oledMem := (
        (X"54",X"68",X"65",X"20",X"64",X"65",X"61",X"6C",X"65",X"72",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"62",X"75",X"73",X"74",X"73",X"2E",X"20",X"50",X"72",X"65",X"73",X"73",X"20",X"46",X"20",X"20"),
        (X"74",X"6F",X"20",X"63",X"6F",X"6C",X"6C",X"65",X"63",X"74",X"20",X"79",X"6F",X"75",X"72",X"20"),
        (X"79",X"6F",X"75",X"72",X"20",X"77",X"69",X"6E",X"6E",X"69",X"6E",X"67",X"73",X"20",X"20",X"20")
    );

    signal standScreen : oledMem := (
        (X"59",X"6F",X"75",X"20",X"73",X"74",X"61",X"6E",X"64",X"2E",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"50",X"72",X"65",X"73",X"73",X"20",X"30",X"20",X"74",X"6F",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"73",X"74",X"61",X"72",X"74",X"20",X"74",X"68",X"65",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"64",X"65",X"61",X"6C",X"65",X"72",X"27",X"73",X"20",X"74",X"75",X"72",X"6E",X"20",X"20",X"20")
    );

    signal YouWin : oledMem := (
        (X"44",X"65",X"61",X"6C",X"65",X"72",X"20",X"68",X"61",X"73",X"20",X"5F",X"5F",X"20",X"20",X"20"),
        (X"59",X"6F",X"75",X"20",X"68",X"61",X"76",X"65",X"20",X"5F",X"5F",X"20",X"20",X"20",X"20",X"20"),
        (X"59",X"6F",X"75",X"20",X"77",X"69",X"6E",X"2E",X"20",X"50",X"72",X"65",X"73",X"73",X"20",X"20"),
        (X"46",X"20",X"74",X"6F",X"20",X"63",X"6F",X"6C",X"6C",X"65",X"63",X"74",X"20",X"20",X"20",X"20")
    );

    signal YouLose : oledMem := (
        (X"44",X"65",X"61",X"6C",X"65",X"72",X"20",X"68",X"61",X"73",X"20",X"5F",X"5F",X"20",X"20",X"20"),
        (X"59",X"6F",X"75",X"20",X"68",X"61",X"76",X"65",X"20",X"5F",X"5F",X"20",X"20",X"20",X"20",X"20"),
        (X"59",X"6F",X"75",X"20",X"6C",X"6F",X"73",X"65",X"2E",X"20",X"50",X"72",X"65",X"73",X"73",X"20"),
        (X"46",X"20",X"74",X"6F",X"20",X"67",X"6F",X"20",X"61",X"67",X"61",X"69",X"6E",X"20",X"20",X"20")
    );

    signal resetScreen : oledMem := (
        (X"70",X"72",X"65",X"73",X"73",X"20",X"30",X"20",X"74",X"6F",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"73",X"74",X"61",X"72",X"74",X"20",X"74",X"68",X"65",X"20",X"6E",X"65",X"78",X"74",X"20",X"20"),
        (X"68",X"61",X"6E",X"64",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
        (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20")
    );

    signal tieScreen : oledMem := (
        (X"79",X"6F",X"75",X"20",X"61",X"6E",X"64",X"20",X"64",X"65",X"61",X"6C",X"65",X"72",X"20",X"20"),
        (X"68",X"61",X"76",X"65",X"20",X"5F",X"5F",X"2E",X"20",X"59",X"6F",X"75",X"20",X"20",X"20",X"20"),
        (X"73",X"6F",X"72",X"74",X"20",X"6F",X"66",X"20",X"77",X"69",X"6E",X"2E",X"20",X"20",X"20",X"20"),
        (X"50",X"72",X"65",X"73",X"73",X"20",X"46",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20")
    );

    signal doubleDown : oledMem := (
        (x"59", x"6F", x"75", x"20", x"64", x"6F", x"75", x"62", x"6C", x"65", x"20", x"64", x"6F", x"77", x"6E", x"0A"),
        (x"50", x"72", x"65", x"73", x"73", x"20", x"30", x"20", x"74", x"6F", x"20", x"0A", x"63", x"6F", x"6E", x"74"),
        (x"69", x"6E", x"75", x"65", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00"),
        (x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00", x"00")
    );



    --Current overall state of the state machine
    signal current_state : states := Idle;
    --State to go to after the SPI transmission is finished
    signal after_state : states;
    --State to go to after the set page sequence
    signal after_page_state : states;
    --State to go to after sending the character sequence
    signal after_char_state : states;
    --State to go to after the UpdateScreen is finished
    signal after_update_state : states;

    --Contains the value to be outputted to DC
    signal temp_dc : STD_LOGIC := '0';

    --Variables used in the Delay Controller Block
    signal temp_delay_ms : STD_LOGIC_VECTOR (11 downto 0); --amount of ms to delay
    signal temp_delay_en : STD_LOGIC := '0'; --Enable signal for the delay block
    signal temp_delay_fin : STD_LOGIC; --Finish signal for the delay block

    --Variables used in the SPI controller block
    signal temp_spi_en : STD_LOGIC := '0'; --Enable signal for the SPI block
    signal temp_spi_data : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); --Data to be sent out on SPI
    signal temp_spi_fin : STD_LOGIC; --Finish signal for the SPI block

    signal temp_char : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); --Contains ASCII value for character
    signal temp_addr : STD_LOGIC_VECTOR (10 downto 0) := (others => '0'); --Contains address to BYTE needed in memory
    signal temp_dout : STD_LOGIC_VECTOR (7 downto 0); --Contains byte outputted from memory
    signal temp_page : STD_LOGIC_VECTOR (1 downto 0) := (others => '0'); --Current page
    signal temp_index : integer range 0 to 15 := 0; --Current character on page

begin


    updateScreens: process(clk) begin
        if(rising_edge(clk)) then
            case switchDisplay is
                when "0000" => presentScreen <= placeBidScreen;
                when "0001" => presentScreen <= bidReceivedScreen;
                    bidReceivedScreen(0,12) <= newDataIn(15 downto 8);
                    bidReceivedScreen(0,13) <= newDataIn(7 downto 0);
                when "0010" => presentScreen <= playerActions;
                when "0011" => presentScreen <= zeroToContinue;
                when "0100" => presentScreen <= playerBustScreen;
                when "0101" => presentScreen <= dealerBustScreen;
                when "0110" => presentScreen <= standScreen;
                when "0111" => presentScreen <= resetScreen;
                when "1000" => presentScreen <= youWin;
                    youWin(0,11) <= newDataIn(31 downto 24);
                    youWin(0,12) <=  newDataIn(23 downto 16);
                    youWin(1,9) <= newDataIn(47 downto 40);
                    youWin(1,10) <= newDataIn(39 downto 32);
                when "1001" => presentScreen <= youLose;
                    youLose(0,11) <= newDataIn(31 downto 24);
                    youLose(0,12) <=  newDataIn(23 downto 16);
                    youLose(1,9) <= newDataIn(47 downto 40);
                    youLose(1,10) <= newDataIn(39 downto 32);
                when "1010" => presentScreen <= tieScreen;
--                    tieScreen(0,11) <= newDataIn(31 downto 24);
--                    tieScreen(0,12) <=  newDataIn(23 downto 16);
                    tieScreen(1,5) <= newDataIn(47 downto 40);
                    tieScreen(1,6) <= newDataIn(39 downto 32);
                when "1011" => presentScreen <= doubleDown;
                when others =>
            end case;
        end if;
    end process;

    DC <= temp_dc;
    --Example finish flag only high when in done state
    FIN <= '1' when (current_state = Done) else
           '0';
    --Instantiate SPI Block
    SPI_COMP: SpiCtrl PORT MAP (
            CLK => CLK,
            RST => RST,
            SPI_EN => temp_spi_en,
            SPI_DATA => temp_spi_data,
            CS => CS,
            SDO => SDO,
            SCLK => SCLK,
            SPI_FIN => temp_spi_fin
        );
    --Instantiate Delay Block
    DELAY_COMP: Delay PORT MAP (
            CLK => CLK,
            RST => RST,
            DELAY_MS => temp_delay_ms,
            DELAY_EN => temp_delay_en,
            DELAY_FIN => temp_delay_fin
        );
    --Instantiate Memory Block
    CHAR_LIB_COMP : charLib
        PORT MAP (
            clka => CLK,
            addra => temp_addr,
            douta => temp_dout
        );
    process (CLK)
    begin
        if(rising_edge(CLK)) then
            case(current_state) is
                --Idle until EN pulled high than intialize Page to 0 and go to state Alphabet afterwards
                when Idle =>
                    if(EN = '1') then
                        current_state <= ClearDC;
                        after_page_state <= Alphabet;
                        temp_page <= "00";
                    end if;
                --Set current_screen to constant alphabet_screen and update the screen.  Go to state Wait1 afterwards
                when Alphabet =>
                    current_screen <= blackjackStart;
                    current_state <= UpdateScreen;
                    after_update_state <= Wait1;
                --Wait 4ms and go to ClearScreen
                when Wait1 =>
                    temp_delay_ms <= "111110100000"; --4000
                    after_state <= ClearScreen;
                    current_state <= Transition3; --Transition3 = The delay transition states
                --set current_screen to constant clear_screen and update the screen. Go to state Wait2 afterwards
                when ClearScreen =>
                    current_screen <= clear_screen;
                    after_update_state <= Wait2;
                    current_state <= UpdateScreen;
                --Wait 1ms and go to DigilentScreen
                when Wait2 =>
                    temp_delay_ms <= "001111101000"; --1000
                    after_state <= DigilentScreen;
                    current_state <= Transition3; --Transition3 = The delay transition states
                --Set currentScreen to constant digilent_screen and update the screen. Go to state Done afterwards
                when DigilentScreen =>
                    temp_delay_ms <= "111111111111";
                    current_screen <= warningScreen;
                    after_update_state <= wait3;
                    current_state <= UpdateScreen;
                when Wait3 =>
                    temp_delay_ms <= "111111111111"; --1000
                    after_state <= playerScreen;
                    current_state <= Transition3; --Transition3 = The delay transition states
                when playerScreen =>
                    current_screen <= presentScreen;
                    after_update_state <= playerScreen;
                    current_state <= UpdateScreen;
                when Done			=>
                    if(EN = '0') then
                        current_state <= Idle;
                    end if;

                --UpdateScreen State
                --1. Gets ASCII value from current_screen at the current page and the current spot of the page
                --2. If on the last character of the page transition update the page number, if on the last page(3)
                --			then the updateScreen go to "after_update_state" after 
                when UpdateScreen =>
                    temp_char <= current_screen(CONV_INTEGER(temp_page),temp_index);
                    if(temp_index = 15) then
                        temp_index <= 0;
                        temp_page <= temp_page + 1;
                        after_char_state <= ClearDC;
                        if(temp_page = "11") then
                            after_page_state <= after_update_state;
                        else
                            after_page_state <= UpdateScreen;
                        end if;
                    else
                        temp_index <= temp_index + 1;
                        after_char_state <= UpdateScreen;
                    end if;
                    current_state <= SendChar1;

                --Update Page states
                --1. Sets DC to command mode
                --2. Sends the SetPage Command
                --3. Sends the Page to be set to
                --4. Sets the start pixel to the left column
                --5. Sets DC to data mode
                when ClearDC =>
                    temp_dc <= '0';
                    current_state <= SetPage;
                when SetPage =>
                    temp_spi_data <= "00100010";
                    after_state <= PageNum;
                    current_state <= Transition1;
                when PageNum =>
                    temp_spi_data <= "000000" & temp_page;
                    after_state <= LeftColumn1;
                    current_state <= Transition1;
                when LeftColumn1 =>
                    temp_spi_data <= "00000000";
                    after_state <= LeftColumn2;
                    current_state <= Transition1;
                when LeftColumn2 =>
                    temp_spi_data <= "00010000";
                    after_state <= SetDC;
                    current_state <= Transition1;
                when SetDC =>
                    temp_dc <= '1';
                    current_state <= after_page_state;
                --End Update Page States

                --Send Character States
                --1. Sets the Address to ASCII value of char with the counter appended to the end
                --2. Waits a clock for the data to get ready by going to ReadMem and ReadMem2 states
                --3. Send the byte of data given by the block Ram
                --4. Repeat 7 more times for the rest of the character bytes
                when SendChar1 =>
                    temp_addr <= temp_char & "000";
                    after_state <= SendChar2;
                    current_state <= ReadMem;
                when SendChar2 =>
                    temp_addr <= temp_char & "001";
                    after_state <= SendChar3;
                    current_state <= ReadMem;
                when SendChar3 =>
                    temp_addr <= temp_char & "010";
                    after_state <= SendChar4;
                    current_state <= ReadMem;
                when SendChar4 =>
                    temp_addr <= temp_char & "011";
                    after_state <= SendChar5;
                    current_state <= ReadMem;
                when SendChar5 =>
                    temp_addr <= temp_char & "100";
                    after_state <= SendChar6;
                    current_state <= ReadMem;
                when SendChar6 =>
                    temp_addr <= temp_char & "101";
                    after_state <= SendChar7;
                    current_state <= ReadMem;
                when SendChar7 =>
                    temp_addr <= temp_char & "110";
                    after_state <= SendChar8;
                    current_state <= ReadMem;
                when SendChar8 =>
                    temp_addr <= temp_char & "111";
                    after_state <= after_char_state;
                    current_state <= ReadMem;
                when ReadMem =>
                    current_state <= ReadMem2;
                when ReadMem2 =>
                    temp_spi_data <= temp_dout;
                    current_state <= Transition1;
                --End Send Character States

                --SPI transitions
                --1. Set SPI_EN to 1
                --2. Waits for SpiCtrl to finish
                --3. Goes to clear state (Transition5)
                when Transition1 =>
                    temp_spi_en <= '1';
                    current_state <= Transition2;
                when Transition2 =>
                    if(temp_spi_fin = '1') then
                        current_state <= Transition5;
                    end if;

                --Delay Transitions
                --1. Set DELAY_EN to 1
                --2. Waits for Delay to finish
                --3. Goes to Clear state (Transition5)
                when Transition3 =>
                    temp_delay_en <= '1';
                    current_state <= Transition4;
                when Transition4 =>
                    if(temp_delay_fin = '1') then
                        current_state <= Transition5;
                    end if;

                --Clear transition
                --1. Sets both DELAY_EN and SPI_EN to 0
                --2. Go to after state
                when Transition5 =>
                    temp_spi_en <= '0';
                    temp_delay_en <= '0';
                    current_state <= after_state;
                --END SPI transitions
                --END Delay Transitions
                --END Clear transition

                when others 		=>
                    current_state <= Idle;
            end case;
        end if;
    end process;

end Behavioral;