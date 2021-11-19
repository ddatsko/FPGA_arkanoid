library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;




entity arkanoid is 
	generic (
		RESET_ACTIVE : std_logic := '1');
		
	port (
		display_enabled 	: in std_logic;
		row 					: in std_logic_vector(31 downto 0);
		col 					: in std_logic_vector(31 downto 0);
		
		red 					: out std_logic_vector(7 downto 0);
		green 				: out std_logic_vector(7 downto 0);
		blue 					: out std_logic_vector(7 downto 0);
		
		led_r 				: out std_logic_vector(9 downto 0);
		
		clock 				: in std_logic;
		reset 				: in std_logic);
		
end arkanoid;


architecture behav of arkanoid is

signal object_y : integer := 10;
signal object_x : integer := 10;
	
begin
	red <= "01111111" when display_enabled = '1' else "00000000";
	green <= "11111111" when (conv_integer(col) < object_x + 10 and
									 conv_integer(col) > object_x - 10) and
									 conv_integer(row) > object_y - 10 and
									 conv_integer(row) < object_y + 10 and
									 (display_enabled = '1') else "00000000";
									 
	blue <= "11111111" when display_enabled = '1' else "00000000";
	
	move_object : process(clock) is
		variable counter : integer := 0;
		variable moving_left : boolean := false;
		variable moving_up 	: boolean := false;
		
	begin
		if (rising_edge(clock)) then
			counter := counter + 1;
			if (counter > 200000) then
				counter := 0;
				
				if (moving_left) then
					if (object_x <= 10) then
						moving_left := false;
					else
						object_x <= object_x - 1;
					end if;
				else
					if (object_x >= 790) then
						moving_left := true;
					else
						object_x <= object_x + 1;
					end if;
				end if;
				
				
				if (moving_up) then
					if (object_y <= 10) then
						moving_up := false;
					else
						object_y <= object_y - 1;
					end if;
				else
					if (object_y >= 590) then
						moving_up := true;
					else
						object_y <= object_y + 1;
					end if;
				end if;
				
				
				
			end if;
		end if;
	end process;
	

end behav;
	
		
	
		