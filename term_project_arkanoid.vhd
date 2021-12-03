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
		PLATFORM_HEIGHT 	    : integer := 10;
		BALL_LENGTH			    : integer := 6;
		ONE_MOVE_CLOCK_TICKS  : integer := 100000;
		ROWS_NUM 				 : integer := 5; -- 5
		BRICK_WIDTH			 	 : integer := 50; --50
		BRICKS_IN_A_ROW 		 : integer := 16; -- 16
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

type bricks_arr is array(0 to ROWS_NUM - 1) of bit_vector(0 to BRICKS_IN_A_ROW - 1);
type color_t is array(1 to 3) of std_logic_vector(7 downto 0);

-- objects positions
signal ball_x : integer := SCREEN_WIDTH / 2;
signal ball_y : integer := SCREEN_HEIGHT / 2;
signal platform_x : integer := SCREEN_WIDTH / 2 - PLATFORM_WIDTH / 2 + 1;
signal bricks : bricks_arr := (others => (others => '1'));

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




	red <= "00000000" when reset = RESET_ACTIVE or col > SCREEN_WIDTH or row > SCREEN_HEIGHT else
			 BALL_COLOR(1) 			when row > ball_y and row < ball_y + BALL_LENGTH and col > ball_x and col < ball_x + BALL_LENGTH else
			 PLATFORM_COLOR(1) 		when row > PLATFORM_Y and row < PLATFORM_Y + PLATFORM_HEIGHT and col > platform_x and col < platform_x + plaTFORM_WIDTH else
			 BRICK_COLOR(1) 			when row > PADDING_TOP and row < (PADDING_TOP + ROWS_NUM * BRICK_HEIGHT) and not ((conv_integer(row) - PADDING_TOP) mod BRICK_HEIGHT = 0 or (conv_integer(row) - PADDING_TOP) mod BRICK_HEIGHT = BRICK_HEIGHT - 1 or 
						(conv_integer(col) mod BRICK_WIDTH = 0 or conv_integer(col) mod BRICK_WIDTH = BRICK_WIDTH - 1)) and 
						bricks((conv_integer(row) - PADDING_TOP) / BRICK_HEIGHT)(conv_integer(col) / BRICK_WIDTH) = '1' else
			 BACKGROUND_COLOR(1);
			 
	green <= "00000000" when reset = RESET_ACTIVE or col > SCREEN_WIDTH or row > SCREEN_HEIGHT else
			 BALL_COLOR(2) 			when row > ball_y and row < ball_y + BALL_LENGTH and col > ball_x and col < ball_x + BALL_LENGTH else
			 PLATFORM_COLOR(2) 		when row > PLATFORM_Y and row < PLATFORM_Y + PLATFORM_HEIGHT and col > platform_x and col < platform_x + plaTFORM_WIDTH else
			 BRICK_COLOR(2) 			when row > PADDING_TOP and row < (PADDING_TOP + ROWS_NUM * BRICK_HEIGHT) and not ((conv_integer(row) - PADDING_TOP) mod BRICK_HEIGHT = 0 or (conv_integer(row) - PADDING_TOP) mod BRICK_HEIGHT = BRICK_HEIGHT - 1 or 
						(conv_integer(col) mod BRICK_WIDTH = 0 or conv_integer(col) mod BRICK_WIDTH = BRICK_WIDTH - 1)) and 
						bricks((conv_integer(row) - PADDING_TOP) / BRICK_HEIGHT)(conv_integer(col) / BRICK_WIDTH) = '1' else
			 BACKGROUND_COLOR(2);

			 
	blue <= "00000000" when reset = RESET_ACTIVE or col > SCREEN_WIDTH or row > SCREEN_HEIGHT else
			 BALL_COLOR(3) 			when row > ball_y and row < ball_y + BALL_LENGTH and col > ball_x and col < ball_x + BALL_LENGTH else
			 PLATFORM_COLOR(3) 		when row > PLATFORM_Y and row < PLATFORM_Y + PLATFORM_HEIGHT and col > platform_x and col < platform_x + plaTFORM_WIDTH else
			 BRICK_COLOR(3) 			when row > PADDING_TOP and row < (PADDING_TOP + ROWS_NUM * BRICK_HEIGHT) and not ((conv_integer(row) - PADDING_TOP) mod BRICK_HEIGHT = 0 or (conv_integer(row) - PADDING_TOP) mod BRICK_HEIGHT = BRICK_HEIGHT - 1 or 
						(conv_integer(col) mod BRICK_WIDTH = 0 or conv_integer(col) mod BRICK_WIDTH = BRICK_WIDTH - 1)) and 
						bricks((conv_integer(row) - PADDING_TOP) / BRICK_HEIGHT)(conv_integer(col) / BRICK_WIDTH) = '1' else
			 BACKGROUND_COLOR(3);
	

	
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

	type movement_t is record
		d_x : integer;
		d_y : integer;
	end record;
	
	type angles_array_t is array(0 to 7) of movement_t;
	
	type two_d_index is record
		row : integer;
		col : integer;
	end record;
	
	-- Constant for calculating different move angles of the ball
	constant move_angles_up : angles_array_t := ((d_x => -939, d_y => -342),
	(d_x => -766, d_y => -642),
	(d_x => -500, d_y => -866),
	(d_x => -173, d_y => -984),
	(d_x => 173, d_y => -984),
	(d_x => 499, d_y => -866),
	(d_x => 766, d_y => -642),
	(d_x => 939, d_y => -342));


	constant move_angles_down : angles_array_t := ((d_x => -939, d_y => 342),
	(d_x => -766, d_y => 642),
	(d_x => -500, d_y => 866),
	(d_x => -173, d_y => 984),
	(d_x => 173, d_y => 984),
	(d_x => 499, d_y => 866),
	(d_x => 766, d_y => 642),
	(d_x => 939, d_y => 342));

	variable ball_x_real : integer := SCREEN_WIDTH / 2 * 1000;
	variable ball_y_real : integer := SCREEN_HEIGHT / 2 * 1000;
	variable new_ball_x, new_ball_y : integer;
	variable ball_moving_down : boolean := true;
	variable ball_movement_angle : integer range 1 to 8 := 3;
	variable intersecting_brick : two_d_index;

begin
	if (reset = RESET_ACTIVE) then
		ball_x <= SCREEN_WIDTH / 2;
		ball_y <= SCREEN_HEIGHT / 2;
		ball_x_real := SCREEN_WIDTH / 2 * 1000;
		ball_y_real := SCREEN_HEIGHT / 2 * 1000;
		
		
		ball_movement_angle := 3;
		ball_moving_down := true;
		bricks <= (others => (others => '1'));
		
--		for i in bricks'range loop
--			for j in bricks(i)'range loop
--				bricks(i)(j) <= '1';
--			end loop;
--		end loop;

	elsif (rising_edge(move_clock)) then
		-- firstly, move the platform
		if (buttons_pressed(2) = '1' and buttons_pressed(0) = '0' and platform_x > 0) then
			-- A is pressed, so move the platform to the left
			platform_x <= platform_x - 1;
		elsif (buttons_pressed(0) = '1' and buttons_pressed(2) = '0' and platform_x + PLATFORM_WIDTH < SCREEN_WIDTH - 1) then
			-- D is pressed, so move the platform to the right
			platform_x <= platform_x + 1;
		end if;

		-- Then, move the ball to its movement direction
		if (ball_moving_down) then
			ball_x_real := ball_x_real + move_angles_down(ball_movement_angle).d_x;
			ball_y_real := ball_y_real + move_angles_down(ball_movement_angle).d_y;
		else
			ball_x_real := ball_x_real + move_angles_up(ball_movement_angle).d_x;
			ball_y_real := ball_y_real + move_angles_up(ball_movement_angle).d_y;
		end if;

		-- Find the new position of the ball one the screen
		new_ball_x := ball_x_real / 1000;
		new_ball_y := ball_y_real / 1000;

		-- Process collision with the left wall
		if (new_ball_x < 1) then
			new_ball_x := -new_ball_x + 1;
			ball_movement_angle := 7 - ball_movement_angle;
		end if;

		-- Process collosion with the right wall
		if (new_ball_x + BALL_LENGTH > SCREEN_WIDTH) then
			new_ball_x := SCREEN_WIDTH - (new_ball_x + BALL_LENGTH - SCREEN_WIDTH);
			ball_movement_angle := 7 - ball_movement_angle;
		end if;

		-- Process collision with the top wall
		if (new_ball_y < 1) then
			new_ball_y := -new_ball_y + 1;
			ball_moving_down := true;
		end if;

		-- Process collision with the bottom wall
		if (new_ball_y + BALL_LENGTH > SCREEN_HEIGHT) then
			-- The ball is lost. Put it back to the center of the screen
			ball_x_real := SCREEN_WIDTH / 2 * 1000;
			ball_y_real := SCREEN_HEIGHT / 2 * 1000;
			new_ball_x := SCREEN_WIDTH / 2;
			new_ball_y := SCREEN_HEIGHT / 2;
			ball_movement_angle := 3;
		end if;

		-- Process collision with the platform
		if (new_ball_y + BALL_LENGTH >= PLATFORM_Y and new_ball_y < PLATFORM_Y + PLATFORM_HEIGHT and ball_moving_down) then
		-- Ball is at least at the same height as the platform is
			if (ball_x <= platform_x + PLATFORM_WIDTH and ball_x + BALL_LENGTH > platform_x) then
				-- Ball touches the platform
				ball_moving_down := false;
				-- Change ball movement angle depending on the side of the platform that was hit
				ball_movement_angle := (new_ball_x + BALL_LENGTH - platform_x + 2) * 8 / (PLATFORM_WIDTH + BALL_LENGTH);
			end if;
		end if;

		
		-- Process collision with bricks
		-- TODO: implement this without copy pasting the code
		
		-- Process ball moving up
		if (ball_moving_down = false and new_ball_y >= PADDING_TOP + BRICK_HEIGHT and new_ball_y <= PADDING_TOP + (BRICK_HEIGHT * ROWS_NUM)) then
			if ((new_ball_y - PADDING_TOP) mod BRICK_HEIGHT = 0) then
				if (bricks((new_ball_y - PADDING_TOP) / BRICK_HEIGHT - 1)(new_ball_x / BRICK_WIDTH) = '1') then
					bricks((new_ball_y - PADDING_TOP) / BRICK_HEIGHT - 1)(new_ball_x / BRICK_WIDTH) <= '0';
					ball_moving_down := true;
				elsif (bricks((new_ball_y - PADDING_TOP) / BRICK_HEIGHT - 1)((new_ball_x + BALL_LENGTH) / BRICK_WIDTH) = '1') then
					bricks((new_ball_y - PADDING_TOP) / BRICK_HEIGHT - 1)((new_ball_x + BALL_LENGTH) / BRICK_WIDTH) <= '0';
					ball_moving_down := true;
				end if;
			end if;
			
		-- Process ball moving down
		elsif (ball_moving_down and new_ball_y + BALL_LENGTH >= PADDING_TOP + 1 and new_ball_y + BALL_LENGTH <= PADDING_TOP + (BRICK_HEIGHT * (ROWS_NUM - 1)) + 1) then
			if ((new_ball_y - PADDING_TOP) mod BRICK_HEIGHT = 1) then
				if (bricks((new_ball_y + BALL_LENGTH - PADDING_TOP) / BRICK_HEIGHT)(new_ball_x / BRICK_WIDTH) = '1') then
					bricks((new_ball_y + BALL_LENGTH - PADDING_TOP) / BRICK_HEIGHT)(new_ball_x / BRICK_WIDTH) <= '0';
					ball_moving_down := false;
				end if;
				if (bricks((new_ball_y + BALL_LENGTH - PADDING_TOP) / BRICK_HEIGHT)((new_ball_x + BALL_LENGTH) / BRICK_WIDTH) = '1') then
					bricks((new_ball_y + BALL_LENGTH - PADDING_TOP) / BRICK_HEIGHT)((new_ball_x + BALL_LENGTH) / BRICK_WIDTH) <= '0';
					ball_moving_down := false;
				end if;
			end if;
		end if;
		
		-- Process ball moving right
		if (ball_movement_angle >= 4 and (new_ball_x + BALL_LENGTH) mod BRICK_WIDTH = 0) then
				if (new_ball_y > PADDING_TOP and new_ball_y <= PADDING_TOP + BRICK_HEIGHT * ROWS_NUM) then
					if (bricks((new_ball_y - PADDING_TOP) / BRICK_HEIGHT)((new_ball_x + BALL_LENGTH) / BRICK_WIDTH) = '1') then
						bricks((new_ball_y - PADDING_TOP) / BRICK_HEIGHT)((new_ball_x + BALL_LENGTH) / BRICK_WIDTH) <= '0';
						
						-- Chagne movement direction if it has not been changed before
						if ball_movement_angle >= 4 then
							ball_movement_angle := 7 - ball_movement_angle;
						end if;
					end if;
				end if;
					
				if ((new_ball_y + BALL_LENGTH) > PADDING_TOP and (new_ball_y + BALL_LENGTH) <= PADDING_TOP + BRICK_HEIGHT * ROWS_NUM) then
					if (bricks((new_ball_y + BALL_LENGTH - PADDING_TOP) / BRICK_HEIGHT)((new_ball_x + BALL_LENGTH) / BRICK_WIDTH) = '1') then
						bricks((new_ball_y + BALL_LENGTH - PADDING_TOP) / BRICK_HEIGHT)((new_ball_x + BALL_LENGTH) / BRICK_WIDTH) <= '0';
						
						-- Chagne movement direction if it has not been changed before
						if ball_movement_angle >= 4 then
							ball_movement_angle := 7 - ball_movement_angle;
						end if;
					end if;
				end if;
			
		-- Process ball moving left
		elsif (ball_movement_angle <= 3 and new_ball_x mod BRICK_WIDTH = BRICK_WIDTH - 1) then
				if (new_ball_y > PADDING_TOP and new_ball_y <= PADDING_TOP + BRICK_HEIGHT * ROWS_NUM) then
					if (bricks((new_ball_y - PADDING_TOP) / BRICK_HEIGHT)(new_ball_x / BRICK_WIDTH) = '1') then
						bricks((new_ball_y - PADDING_TOP) / BRICK_HEIGHT)(new_ball_x / BRICK_WIDTH) <= '0';
						
						-- Chagne movement direction if it has not been changed before
						if ball_movement_angle <= 3 then
							ball_movement_angle := 7 - ball_movement_angle;
						end if;
					end if;
				end if;
					
				if ((new_ball_y + BALL_LENGTH) > PADDING_TOP and new_ball_y <= PADDING_TOP + BRICK_HEIGHT * ROWS_NUM) then
					if (bricks((new_ball_y + BALL_LENGTH - PADDING_TOP) / BRICK_HEIGHT)(new_ball_x / BRICK_WIDTH) = '1') then
						bricks((new_ball_y + BALL_LENGTH - PADDING_TOP) / BRICK_HEIGHT)(new_ball_x / BRICK_WIDTH) <= '0';
						
						-- Chagne movement direction if it has not been changed before
						if ball_movement_angle <= 3 then
							ball_movement_angle := 7 - ball_movement_angle;
						end if;
					end if;
				end if;
		end if;


		ball_x <= new_ball_x;
		ball_y <= new_ball_y;

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
	
		
	
		
