--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
	  port(
		i_L     : in  STD_LOGIC;
          i_R     : in  STD_LOGIC;
          i_reset : in  STD_LOGIC;
          i_clk   : in  STD_LOGIC;
          o_LightR     : out  STD_LOGIC_VECTOR(2 downto 0);
          o_LightL     : out  STD_LOGIC_VECTOR(2 downto 0)
	  );
	end component thunderbird_fsm ;
	-- test I/O signals
	
    --in--
    signal w_L :  std_logic := '0';
    signal w_R : std_logic := '0';
    signal w_Reset :  std_logic := '0';
    signal w_clk :  std_logic := '0';
    --out--
    signal w_LightR : std_logic_vector(2 downto 0) := "000";
    signal w_lightL : std_logic_vector(2 downto 0) := "000";

	-- constants
	constant k_clk_period : time := 10 ns;
	
begin
	-- PORT MAPS ----------------------------------------
	uut: thunderbird_fsm port map (
              i_L => w_L,
              i_R => w_R,
              i_reset => w_Reset,
              i_clk => w_clk,
              o_LightR => w_LightR,
              o_LightL => w_LightL
            );
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_proc : process
        begin
            w_clk <= '0';
            wait for k_clk_period/4;
            w_clk <= '1';
            wait for k_clk_period/4;
        end process;
	-----------------------------------------------------
	--we have the clock moving faster so it is easier to see the changes in the waveform.
	--first we test the turning lights by setting a desired output after the set time and checking it
	-- then we test the lights again turning the signal off midway
	--then we test the emergency light, and also test it when turning left or right.
	-- the reset is also tested during turns and emergency.
	--this should cover all serious scenarios
	-- Test Plan Process --------------------------------
	sim_proc: process
        begin
            -- sequential timing        
            w_reset <= '1';
            wait for k_clk_period*1;
              assert w_LightL = "000" report "bad reset left" severity error;
              assert w_LightR = "000" report "bad reset right" severity error;
            w_reset <= '0';
            wait for k_clk_period*1;
            
            -- left normal
            w_L <= '1'; wait for k_clk_period;
              assert w_LightL = "010" report "bad start left" severity error;
            w_L <= '0';
            w_L <= '1'; wait for k_clk_period * 3;
              assert w_LightL = "111" report "bad cycle left" severity error;
            w_L <= '0';  
            -- Right normal
            w_R <= '1'; wait for k_clk_period;
              assert w_LightR = "010" report "bad start right" severity error;
            w_R <='0';
            w_R <= '1'; wait for k_clk_period * 3;
              assert w_LightR = "111" report "bad cycle right" severity error;
            w_R <='0'; 
             
            --Left remove switch midway
            w_L <= '1'; wait for k_clk_period*0.5;
            w_L <= '0'; wait for k_clk_period*0.5;
              assert w_LightL = "010" report "bad start left" severity error;
            --Right remove switch midway
            w_R <= '1'; wait for k_clk_period*0.5;
            w_R <= '0'; wait for k_clk_period*0.5;
              assert w_LightR = "010" report "bad start right" severity error;
              
            --Emergency normal 
            w_R <= '1'; w_L <= '1'; wait for k_clk_period;
              assert w_LightR = "111" report "right not on" severity error;
              assert w_LightL = "111" report "left not on" severity error;
            w_L <= '0';
            w_R <='0';
              
            w_R <= '1'; wait for k_clk_period;
            w_L <= '1'; wait for k_clk_period;
              assert w_LightR = "111" report "right not on" severity error;
              assert w_LightL = "111" report "left not on" severity error;
            w_L <= '0';
            w_R <='0';
            
            w_L <= '1'; wait for k_clk_period;
            w_R <= '1'; wait for k_clk_period;
              assert w_LightR = "111" report "right not on" severity error;
              assert w_LightL = "111" report "left not on" severity error;
            w_L <= '0';
            w_R <='0';  
            --reset
            w_L <= '1'; wait for k_clk_period;
            w_reset <= '1';
             wait for k_clk_period*1;
             assert w_LightL = "000" report "bad reset left" severity error;
             assert w_LightR = "000" report "bad reset right" severity error;
            w_reset <= '0';
            w_L <= '0';
            
            
            w_L <= '1'; w_R <= '1'; wait for k_clk_period;
            w_reset <= '1';
              wait for k_clk_period*1;
              assert w_LightL = "000" report "bad reset left" severity error;
              assert w_LightR = "000" report "bad reset right" severity error;
            w_reset <= '0';
            w_L <= '0';
            w_R <='0';
            wait;
        end process;
	-----------------------------------------------------	
	
end test_bench;
