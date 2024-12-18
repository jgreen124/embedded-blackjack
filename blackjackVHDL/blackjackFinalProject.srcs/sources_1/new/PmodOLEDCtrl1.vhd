----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
-- 
-- Create Date:    14:35:33 10/10/2011 
-- Module Name:    PmodOLEDCtrl - Behavioral 
-- Project Name:   PmodOLED Demo
-- Tool versions:  ISE 13.2
-- Description:    Top level controller that controls the PmodOLED blocks
--
-- Revision: 1.1
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.std_logic_arith.all;

entity PmodOLEDCtrl1 is
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
end PmodOLEDCtrl1;

architecture Behavioral of PmodOLEDCtrl1 is

    component OledInit is
        Port ( CLK 	: in  STD_LOGIC;
             RST 	: in	STD_LOGIC;
             EN		: in  STD_LOGIC;
             CS  	: out STD_LOGIC;
             SDO	: out STD_LOGIC;
             SCLK	: out STD_LOGIC;
             DC		: out STD_LOGIC;
             RES	: out STD_LOGIC;
             VBAT	: out STD_LOGIC;
             VDD	: out STD_LOGIC;
             FIN  : out STD_LOGIC);
    end component;

    component OledEx1 is
        Port ( CLK 	: in  STD_LOGIC;
             RST 	: in	STD_LOGIC;
             EN		: in  STD_LOGIC;
             CS  	: out STD_LOGIC;
             SDO		: out STD_LOGIC;
             SCLK	: out STD_LOGIC;
             DC		: out STD_LOGIC;
             FIN  : out STD_LOGIC;
             --signals that I am adding
             newDataIn : in std_logic_vector(47 downto 0);
             switchDisplay : in std_logic_vector(3 downto 0));
    end component;

    type states is (Idle,
                    OledInitialize,
                    OledExample,
                    Done);

    signal current_state 	: states := Idle;

    signal init_en				: STD_LOGIC := '0';
    signal init_done			: STD_LOGIC;
    signal init_cs				: STD_LOGIC;
    signal init_sdo			: STD_LOGIC;
    signal init_sclk			: STD_LOGIC;
    signal init_dc				: STD_LOGIC;

    signal example_en			: STD_LOGIC := '0';
    signal example_cs			: STD_LOGIC;
    signal example_sdo		: STD_LOGIC;
    signal example_sclk		: STD_LOGIC;
    signal example_dc			: STD_LOGIC;
    signal example_done		: STD_LOGIC;


    --signals that I am creating
    signal newDataToOled : std_logic_vector(47 downto 0);
    signal switchDisplay : std_logic_vector(3 downto 0);

begin

    Init: OledInit port map(CLK, RST, init_en, init_cs, init_sdo, init_sclk, init_dc, RES1, VBAT1, VDD1, init_done);
    Example: OledEx1 Port map(CLK, RST, example_en, example_cs, example_sdo, example_sclk, example_dc, example_done, newDataToOled, switchDisplay);

    --MUXes to indicate which outputs are routed out depending on which block is enabled
    CS1 <= init_cs when (current_state = OledInitialize) else
             example_cs;
    SDIN1 <= init_sdo when (current_state = OledInitialize) else
             example_sdo;
    SCLK1 <= init_sclk when (current_state = OledInitialize) else
             example_sclk;
    DC1 <= init_dc when (current_state = OledInitialize) else
             example_dc;
    --END output MUXes

    --MUXes that enable blocks when in the proper states
    init_en <= '1' when (current_state = OledInitialize) else
                  '0';
    example_en <= '1' when (current_state = OledExample) else
                  '0';
    --END enable MUXes

    changeData : process(clk)
    begin
        if(rising_edge(clk)) then
            newDataToOled <= cardDataIn(47 downto 0);
            switchDisplay <= toggleDisplay;
        end if;
    end process;


    process(CLK)
    begin
        if(rising_edge(CLK)) then
            if(RST = '1') then
                current_state <= Idle;
            else
                case(current_state) is
                    when Idle =>
                        current_state <= OledInitialize;
                    --Go through the initialization sequence
                    when OledInitialize =>
                        if(init_done = '1') then
                            current_state <= OledExample;
                        end if;
                    --Do example and Do nothing when finished
                    when OledExample =>
                        if(example_done = '1') then
                            current_state <= Done;
                        end if;
                    --Do Nothing
                    when Done =>
                        current_state <= Done;
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;


end Behavioral;
