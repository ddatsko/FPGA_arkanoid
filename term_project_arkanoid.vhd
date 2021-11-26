library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;




entity arkanoid is 
	generic (
		RESET_ACTIVE 		: std_logic := '1';
		SCREEN_WIDTH 		: integer := 800;
		SCREEN_HEIGHT 		: integer := 600;
		PLATFORM_WIDTH		: integer := 100;
		PLATFORM_HEIGHT 	: integer := 20;
		BALL_LENGTH			: integer := 6);
		
	port (
		clock 				: in std_logic;
		reset 				: in std_logic;
		display_enabled 	: in std_logic;
		row 					: in std_logic_vector(31 downto 0);
		col 					: in std_logic_vector(31 downto 0);
		
		ps2_keycode 		: in std_logic_vector(7 downto 0);
		ps2_key_received 	: in std_logic;
		
		red 					: out std_logic_vector(7 downto 0);
		green 				: out std_logic_vector(7 downto 0);
		blue 					: out std_logic_vector(7 downto 0);
		
		led_r 				: out std_logic_vector(9 downto 0) -- For debug
		
);
		
end arkanoid;


architecture behav of arkanoid is

type key_pressed_t is (KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT, KEY_NONE);

signal cur_key_pressed  : key_pressed_t := KEY_NONE; 
signal object_y 			: integer := 10;
signal object_x 			: integer := 10;

signal buttons_pressed  : std_logic_vector(3 downto 0) := "0000"; -- one bit per button (WASD)
	
begin
	-- Draw the square on the screen
	red <= "01111111" when display_enabled = '1' else "00000000";
	green <= "11111111" when (conv_integer(col) < object_x + 10 and
									 conv_integer(col) > object_x - 10) and
									 conv_integer(row) > object_y - 10 and
									 conv_integer(row) < object_y + 10 and
									 (display_enabled = '1') else "00000000";		 
	blue <= "11111111" when display_enabled = '1' else "00000000";
	
	move_object : process(clock) is
		variable counter : integer := 0;
		
	begin
		if (rising_edge(clock)) then
			counter := counter + 1;
			if (counter > 200000) then
				counter := 0;
				
				if (buttons_pressed(2) = '1') then
					if (object_x > 10) then
						object_x <= object_x - 1;
					end if;
				elsif (buttons_pressed(0) = '1') then
					if (object_x < 790) then
						object_x <= object_x + 1;
					end if;
				end if;
				
				if (buttons_pressed(3) = '1') then
					if (object_y > 10) then
						object_y <= object_y - 1;
					end if;
				elsif (buttons_pressed(1) = '1') then
					if (object_y < 590) then
						object_y <= object_y + 1;
					end if;
				end if;
				
			end if;
		end if;
	end process;
	

		
	
	
	
	read_keycode : process(clock) is
	variable release_keycode_received 	: boolean := false;
	variable prev_key_received 			: std_logic := '0';
	
	constant release_keycode 				: std_logic_vector(7 downto 0) := "11110000";
	constant extension_keycode 			: std_logic_vector(7 downto 0) := "11100000";
	constant w_keycode 						: std_logic_vector(7 downto 0) := "00011101";
	constant a_keycode 						: std_logic_vector(7 downto 0) := "00011100";
	constant s_keycode 						: std_logic_vector(7 downto 0) := "00011011";
	constant d_keycode 						: std_logic_vector(7 downto 0) := "00100011";
	
	begin
		if (rising_edge(clock)) then
			if ((prev_key_received /= ps2_key_received) and (ps2_key_received = '1')) then
				led_r(7 downto 0) <= ps2_keycode;
				
				-- Simply skip the extension keyode as we dont use it at all
				if (ps2_keycode /= extension_keycode) then
				
					-- Check if any button is released
					if (release_keycode_received) then
						release_keycode_received := false;
						case ps2_keycode is
							when w_keycode =>
								buttons_pressed(3) <= '0';
							when a_keycode =>
								buttons_pressed(2) <= '0';
							when s_keycode =>
								buttons_pressed(1) <= '0';
							when d_keycode =>
								buttons_pressed(0) <= '0';
							when release_keycode =>
								release_keycode_received := true;
							when others =>
						end case;
						
						cur_key_pressed <= KEY_NONE;
						
					else
						case ps2_keycode is
							when release_keycode =>
								release_keycode_received := true;
							
							when w_keycode =>
								buttons_pressed(3) <= '1';
								
							when a_keycode =>
								buttons_pressed(2) <= '1';
								
							when s_keycode =>
								buttons_pressed(1) <= '1';
								
							when d_keycode =>
								buttons_pressed(0) <= '1';
					
							when others =>
								cur_key_pressed <= KEY_NONE;
						end case;
							
					end if;
				end if;
			end if;
		
			prev_key_received := ps2_key_received;
		end if;
	
	end process;
end behav;
	
		
	
		