library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity seven_seg_driver is
	 
  generic (
	 RESET_ACTIVE : std_logic := '0'
	 );

  port (
    clock  : in std_logic;
    reset  : in std_logic;
    number : in integer;
    hex    : out std_logic_vector(27 downto 0)
	 );
end seven_seg_driver;

architecture behav of seven_seg_driver is

  type lut is array (natural range <>) of std_logic_vector(6 downto 0); -- type: unconstrained array of 7-bit words

  -- constant - look-up table contains the 7-segment codes for numbers 0 to 7
  constant MY_LUT : lut := (	"1000000", "1111001", "0100100", "0110000", "0011001",
										"0010010", "0000010", "1111000", "0000000", "0010000");
									 
begin
	hex(6 downto 0) <= MY_LUT(number mod 10) when reset /= RESET_ACTIVE else "1111111";
	hex(13 downto 7) <= MY_LUT((number / 10) mod 10)  when reset /= RESET_ACTIVE else "1111111";
	hex(20 downto 14) <= MY_LUT((number / 100) mod 10) when reset /= RESET_ACTIVE else "1111111";
	hex(27 downto 21) <= MY_LUT((number / 1000) mod 10) when reset /= RESET_ACTIVE else "1111111";

end architecture;