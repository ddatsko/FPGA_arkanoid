LIBRARY ieee;
USE ieee.std_logic_1164.all;


entity ps2_controller is
	generic (
		RESET_ACTIVE 	: std_logic := '0'
		);

	port (
		keycode 			: out std_logic_vector(7 downto 0) := "00000000";
		data_received 	: out std_logic := '0';
		ps2_data			: in std_logic;
		ps2_clk			: inout std_logic; -- The driver need to have an ability to pull this to low
		reset 			: in std_logic;
		clk 				: in std_logic;
		led_r				: out std_logic_vector(9 downto 0) -- For debug only
		);
end ps2_controller;
		
		
architecture behav of ps2_controller is
	constant CLK_TICKS_IDLE : integer := 2750; -- 55 us

	type ps2_state_t is (PS2_IDLE, PS2_DATA_RECV, PS2_PARITY, PS2_STOP);
	signal recv_buf : std_logic_vector(10 downto 0);
	signal ps2_clk_sync, ps2_dat_sync : std_logic;
	signal ps2_clk_deb, ps2_dat_deb   : std_logic;
	
	component debounce is
    generic (
      counter_size : integer --debounce period (in seconds) = 2^counter_size/(clk freq in Hz)
	 );
    port(
      clk    : in  std_logic;  --input clock
      button : in  std_logic;  --input signal to be debounced
      result : out std_logic	 --debounced signal
		); 
	end component;

begin

	led_r <= recv_buf(9 downto 0);

	sync_signals : process(clk) is
	begin
		if rising_edge(clk) then
			ps2_clk_sync <= ps2_clk;
			ps2_dat_sync <= ps2_data;
		end if;
	end process;
	
	ps2_clk_debouncer : debounce generic map(8) port map(clk, ps2_clk_sync, ps2_clk_deb);
	ps2_dat_debouncer : debounce generic map(8) port map(clk, ps2_dat_sync, ps2_dat_deb);
	
	ps2_read_signal : process (ps2_clk_deb) is 
	begin
		if falling_edge(ps2_clk_deb) then
			recv_buf <= ps2_dat_deb & recv_buf(10 downto 1);
		end if;
	end process;
	
   idle_state_waiter : process (clk, reset) is
		variable counter : integer := 0;
	begin
--		if (reset = RESET_ACTIVE) then
--			counter := 0;
		if rising_edge(clk) then
		
			if ps2_clk_deb = '0' then
				counter := 0;
			elsif (counter /= CLK_TICKS_IDLE) then
				counter := counter + 1;
			end if;
			
			if counter = CLK_TICKS_IDLE then
				if (recv_buf(0) = '0' and
					 recv_buf(10) = '1' and 
					 (recv_buf(1) xor recv_buf(2) xor recv_buf(3) xor recv_buf(4) xor recv_buf(5) xor
										  recv_buf(6) xor recv_buf(7) xor recv_buf(8) xor recv_buf(9)) = '1') 
				then
					keycode <= recv_buf(8 downto 1);
					data_received <= '1';
				else 
					data_received <= '0';
				end if;
			else
				data_received <= '0';
			end if;
					
		end if;
	end process;
end behav;
		