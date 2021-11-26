LIBRARY ieee;
USE ieee.std_logic_1164.all;


entity ps2_controller is
	generic (
		RESET_ACTIVE : std_logic := '0';
		CLK_TICKS_BEFORE_RESET : integer := 5000 -- 100 us
		);

	port (
		keycode 			: out std_logic_vector(7 downto 0) := "00000000";
		data_received 	: out std_logic;
		ps2_data			: in std_logic;
		ps2_clk			: inout std_logic; -- The driver need to have an ability to pull this to low
		reset 			: in std_logic;
		clk 				: in std_logic);
end ps2_controller;
		
		
architecture behav of ps2_controller is
	type ps2_state_t is (PS2_IDLE, PS2_DATA_RECV, PS2_PARITY, PS2_STOP);
	signal recv_buf : std_logic_vector(7 downto 0);

begin

	ps2_read : process(ps2_clk, reset, clk) is
		variable ps2_state 					: ps2_state_t := PS2_IDLE;
		variable clock_ticks_passed 		: integer := 0;
		variable byte_reading 				: integer := 0;
		variable parity 						: std_logic;
		variable parity_valid				: boolean := false;
	begin
		
		if (reset = RESET_ACTIVE) then
			keycode <= (others => '0');
			data_received <= '0';
		elsif (rising_edge(clk)) then
			clock_ticks_passed := clock_ticks_passed + 1;
			if (clock_ticks_passed >= CLK_TICKS_BEFORE_RESET and ps2_state /= PS2_IDLE) then
				-- If a lot of time passed since the last clock pulse and no pulse was decected anymore - reset the controller
				keycode <= (others => '0');
				data_received <= '0';
				ps2_state := PS2_IDLE;
			end if;
			
		elsif (falling_edge(ps2_clk)) then
			clock_ticks_passed := 0;
			case ps2_state is 
				
				when PS2_IDLE =>
					byte_reading := 0;
					ps2_state := PS2_DATA_RECV;
					data_received <= '0';
					parity := '0';
				
				
				when PS2_DATA_RECV =>
					recv_buf(byte_reading) <= ps2_data;
					parity := parity xor ps2_data;
					byte_reading := byte_reading + 1;
					if (byte_reading = 8) then
						ps2_state := ps2_PARITY;
					end if;
					
				when PS2_PARITY =>
					parity := parity xor ps2_data;
					if (parity /= '0') then
						parity_valid := false;
					else
						parity_valid := true;
					end if;
					ps2_state := PS2_STOP;
				
				when PS2_STOP =>
					if (ps2_data = '1') then
						keycode <= recv_buf;
						data_received <= '1';
					end if;
					ps2_state := PS2_IDLE;
			end case;
		end if;
	end process;
end behav;
					
					
					
				
					
					
					
					