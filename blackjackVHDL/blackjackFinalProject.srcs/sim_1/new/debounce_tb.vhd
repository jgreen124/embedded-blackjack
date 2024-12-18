--
-- filename:    blinker_tb.vhd
-- written by:  steve dinicolantonio
-- description: testbench for blinker.vhd
-- notes:       
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity debounce_tb is
end debounce_tb;

architecture testbench of debounce_tb is

    signal tb_in : std_logic := '0';
    signal tb_clk : std_logic := '0';
    signal tb_en  : std_logic := '0';

    
component debounce is
    Port ( in0 : in STD_LOGIC;
           out0 : out STD_LOGIC := '0';
           clk : in STD_LOGIC);
end component debounce;
    

begin

--------------------------------------------------------------------------------
-- procs
--------------------------------------------------------------------------------

    -- simulate a 125 Mhz clock
    clk_gen_proc: process
    begin
    
        wait for 4 ns;
        tb_clk <= '1';
        
        wait for 4 ns;
        tb_clk <= '0';
    
    end process clk_gen_proc;
    
    button_press : process
    begin
        wait for 10ms;
        tb_in <= '1';
        wait for 50ms;
        tb_in <= '0';
        wait for 10ms;
        tb_in <='1';
        wait for 10ms;
        tb_in <= '0';
        wait for 10ms;
        tb_in <= '1';
        wait for 10ms;
        tb_in <= '0';
    end process button_press;
        
    
    dut : debounce port map (
    in0 => tb_in,
    out0 => tb_en,
    clk => tb_clk
    );   



    
end testbench; 