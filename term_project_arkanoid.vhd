library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity arkanoid is 
	generic (
		RESET_ACTIVE 		    : std_logic := '0';
		SCREEN_WIDTH 		    : integer := 800;
		SCREEN_HEIGHT 		    : integer := 600;
		PLATFORM_WIDTH		    : integer := 100;
		PLATFORM_HEIGHT 	    : integer := 20;
		BALL_LENGTH			    : integer := 6;
		ONE_MOVE_CLOCK_TICKS  : integer := 400000;
		ROWS_NUM 				 : integer := 5;
		BRICK_WIDTH			 	 : integer := 50;
		BRICKS_IN_A_ROW 		 : integer := 16;
		BRICK_HEIGHT 			 : integer := 20;
		PADDING_TOP				 : integer := 20;
		PLATFORM_Y				 : integer := 550);
		
	port (
		clock 				    : in std_logic;
		reset 				    : in std_logic;
		display_enabled 		 : in std_logic;
		row 					    : in std_logic_vector(31 downto 0);
		col 					    : in std_logic_vector(31 downto 0);
		
		ps2_keycode 		    : in std_logic_vector(7 downto 0);
		ps2_key_received 	    : in std_logic;
		
		red 					    : out std_logic_vector(7 downto 0);
		green 				    : out std_logic_vector(7 downto 0);
		blue 					    : out std_logic_vector(7 downto 0);
		
		led_r 				    : out std_logic_vector(9 downto 0) -- For debug
);
		
end arkanoid;

architecture behav of arkanoid is

type key_pressed_t is (KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT, KEY_NONE);
type color_row is array(1 to SCREEN_WIDTH) of std_logic_vector(7 downto 0);

type bricks_arr is array(1 to ROWS_NUM) of bit_vector(1 to BRICKS_IN_A_ROW);
type color_t is array(1 to 3) of std_logic_vector(7 downto 0);

-- objects positions
signal ball_x : integer := SCREEN_WIDTH / 2;
signal ball_y : integer := SCREEN_HEIGHT / 2;
signal platform_x : integer := SCREEN_WIDTH / 2 - PLATFORM_WIDTH / 2 + 1;
signal bricks : bricks_arr;

--Signals for storing the next row to be drawn
signal row_red : color_row;
signal row_green : color_row; 
signal row_blue : color_row; 

signal buttons_pressed  : std_logic_vector(3 downto 0) := "0000"; -- one bit per button (WASD)

signal move_clock : std_logic := '1'; -- AUX clock for moving the shapes on the screen

constant PLATFORM_COLOR : color_t := ("00111111", "00111111", "00111111");
constant BALL_COLOR : color_t := ("00111111", "00000000", "00000000");
constant BRICK_COLOR : color_t := ("00000111", "00000011", "01111111");
constant BACKGROUND_COLOR : color_t := ("00000000", "00000000", "00000111");

function max(n1: integer; n2: integer) return integer is
begin
	if (n1 > n2) then
		return n1;
	else
		return n2;
	end if;
end function;

function min(n1: integer; n2: integer) return integer is
begin
	if (n1 < n2) then
		return n1;
	else
		return n2;
	end if;
end function;


begin
   red <= row_red(conv_integer(col)) when col <= SCREEN_WIDTH and display_enabled = '1' else "00000000";
   green <= row_green(conv_integer(col)) when col <= SCREEN_WIDTH and display_enabled = '1' else "00000000";
   blue <= row_blue(conv_integer(col)) when col <= SCREEN_WIDTH and display_enabled = '1' else "00000000";

	
	screen_output_generator : process (clock, reset) is
		variable last_row_generated : integer := -1;
	begin
		
		if (reset = RESET_ACTIVE) then
			row_red <= (others => "00000000");
			row_green <= (others => "00000000");
			row_blue <= (others => "00000000");
		
		-- Need not regenerate the row if the current one is already generated or blanking time and the next one is already generated
		elsif (not ((last_row_generated = conv_integer(row)) or (last_row_generated = conv_integer(row) + 1 and conv_integer(col) > SCREEN_WIDTH))) then
			-- Regenerate each color for the next row during blanking time
			last_row_generated := conv_integer(row) + 1;
--			if (last_row_generated <= PADDING_TOP or last_row_generated > PADDING_TOP + ROWS_NUM * brick_HEIGHT) then

			if (last_row_generated >= PLATFORM_Y and last_row_generated < PLATFORM_Y + PLATFORM_HEIGHT) then
				-- Show the platform
				-- TODO: remove this shitty loop. (issues)
				for i in 1 to SCREEN_WIDTH loop
					if (i < platform_x or i >= platform_x + PLATFORM_WIDTH) then
						row_red(i) <= BACKGROUND_COLOR(1);
						row_green(i) <= BACKGROUND_COLOR(2);
						row_blue(i) <= BACKGROUND_COLOR(3);
					else
						row_red(i) <= PLATFORM_COLOR(1);
						row_green(i) <= PLATFORM_COLOR(2);
						row_blue(i) <= PLATFORM_COLOR(3);
					end if;
				end loop;
				
				--row_green <= (platform_x to platform_x + PLATFORM_WIDTH - 1 => PLATFORM_COLOR(2), others => BACKGROUND_COLOR(2));
				--row_blue <= (platform_x to platform_x + PLATFORM_WIDTH - 1 => PLATFORM_COLOR(3), others => BACKGROUND_COLOR(3));
			end if;
			
			if (last_row_generated > PADDING_TOP and last_row_generated <= PADDING_TOP + ROWS_NUM * BRICK_HEIGHT) then
				if ((last_row_generated - PADDING_TOP) mod BRICK_HEIGHT = 1 or (last_row_generated - PADDING_TOP) mod BRICK_HEIGHT = BRICK_HEIGHT - 1) then
					-- Border of the brick. Draw with black color to make visual difference between bricks
					row_red <= (others => "00000000");
					row_green <= (others => "00000000");
					row_blue <= (others => "00000000");
				else
					for i in 0 to (BRICKS_IN_A_ROW - 1) loop
						row_red(i * BRICK_WIDTH + 1 to (i + 1) * BRICK_WIDTH) <= (i * BRICK_WIDTH + 1 => "00000000", i * BRICK_WIDTH + 2 to (i + 1) * BRICK_WIDTH - 1 => BRICK_COLOR(1), (i + 1) * BRICK_WIDTH => "00000000");
						row_green(i * BRICK_WIDTH + 1 to (i + 1) * BRICK_WIDTH) <= (i * BRICK_WIDTH + 1 => "00000000", i * BRICK_WIDTH + 2 to (i + 1) * BRICK_WIDTH - 1 => BRICK_COLOR(2), (i + 1) * BRICK_WIDTH => "00000000");
						row_blue(i * BRICK_WIDTH + 1 to (i + 1) * BRICK_WIDTH) <= (i * BRICK_WIDTH + 1 => "00000000", i * BRICK_WIDTH + 2 to (i + 1) * BRICK_WIDTH - 1 => BRICK_COLOR(3), (i + 1) * BRICK_WIDTH => "00000000");
					end loop;
				end if;
			end if;
			
			if (last_row_generated >= ball_x and last_row_generated < ball_x + BALL_LENGTH) then
				-- Draw the ball (on top of everything drawn before)
				row_red(max(ball_x, 1) to min(ball_x + BALL_LENGTH - 1, SCREEN_WIDTH)) <= (others => BALL_COLOR(1));
				row_green(max(ball_x, 1) to min(ball_x + BALL_LENGTH - 1, SCREEN_WIDTH)) <= (others => BALL_COLOR(2));
				row_blue(max(ball_x, 1) to min(ball_x + BALL_LENGTH - 1, SCREEN_WIDTH)) <= (others => BALL_COLOR(2));		
			end if;
		
		end if;
	end process;
	
	-- Porcess for generatinf the AUX clock
	move_clock_generator : process (clock, reset) is
		variable counter : integer range 0 to ONE_MOVE_CLOCK_TICKS := 0;
	begin
		if (reset = RESET_ACTIVE) then
			counter := 0;
		elsif (rising_edge(clock)) then
			counter := counter + 1;
			if (counter > ONE_MOVE_CLOCK_TICKS / 2) then
				move_clock <= '1';
			else
				move_clock <= '0';
			end if;
		end if;
	end process;
	
 
	-- Main process for processing movement of the shaped on the screen
	process_game : process(move_clock, reset) is
		
		-- TODO: change these to some big integers
--		variable real_ball_x : real := 0.0;
--		variable real_ball_y : real := 0.0;
	begin
		if (reset = RESET_ACTIVE) then
			ball_x <= SCREEN_WIDTH / 2;
			ball_y <= SCREEN_HEIGHT / 2;
			
		elsif (rising_edge(move_clock)) then
			-- firstly, move the platform
			if (buttons_pressed(2) = '1' and buttons_pressed(0) = '0') then
				-- A is pressed, so move the platform to the left
				platform_x <= platform_x - 1;
			elsif (buttons_pressed(0) = '1' and buttons_pressed(2) = '0') then
				-- D is pressed, so move the platform to the right
				platform_x <= platform_x + 1;
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
						end case;
							
					end if;
				end if;
			end if;
		
			prev_key_received := ps2_key_received;
		end if;
	
	end process;
end behav;
	
		
	
		
