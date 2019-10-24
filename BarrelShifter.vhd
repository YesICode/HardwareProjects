--Barrel_Shifter


--The TOP-LEVEL ENTITY of the program is barrel_shifter.
--In order to determine direction and distance of the shift, the barrel_shifter uses the functionality of the entity range_director. 
--The range_director calculates the direction and the range of the rotation using the input from the 
--sliding switches SW8 and SW9 and pressed keys KEY0 to KEY3. 
--Afterwards it sends two signals to the barrel_shifter:   
--1) One 1-bit signal "dir" (1 - in case of the shift to the left and 0 - in case of the shift to the right).
--2) One 4-bit signal "dis", which carries the information about the rotation width.
--The barrel_shifter rotates the input from the sliding switches SW7 to SW0 simultanously to the left and to the right 
--and it sets the signal "output" dependent on the value of the internal signal "direction" with one of the results. 
--The barrel_shifter transfers the result of the rotation to the LEDG- and to the hexadecimal-display (but only in case, in which just one of the keys has been pressed).
--Three instances of the entity bin_to_sseg translate the 4-bit signals of the input/output and of the rotation width into a hexadecimal display.



library ieee;
use ieee.std_logic_1164.all;

--TOP LEVEL ENTITY
--Rotates the input to the right or to the left. 
entity barrel_shifter is
	port(
		key: in std_logic_vector(3 downto 0);
		sw: in std_logic_vector(9 downto 0);
		
		hex3, hex2, hex1, hex0: out std_logic_vector(6 downto 0);
		ledr: out std_logic_vector (7 downto 0);
		ledg: out std_logic_vector (7 downto 0)

	);
end barrel_shifter;


architecture arch of barrel_shifter is	
	signal direction: std_logic;
	signal distance: std_logic_vector(3 downto 0);
	
	signal input, s0_R, s0_L, s1_R, s1_L, output_R, output_L, output: std_logic_vector(7 downto 0);
	
begin

	-- show input using red LEDs
	ledr <= sw(7 downto 0);
	
	--instance a range director
	r_dir: entity work.range_director(arch)
		port map(keys => key, r => sw(9 downto 8), dir => direction, dist => distance);
	
	
	--instatiate THREE instances of 7-seg LED-decoders
	
	--instance for 4 MSBs of the output of the barrel shifter
	sseg_unit_1: entity work.bin_to_sseg(arch)
		port map(bin => output(7 downto 4), sseg => hex3);
	
	--instance for 4 LSBs of the output of the barrel shifter
	sseg_unit_0: entity work.bin_to_sseg(arch)
		port map(bin => output(3 downto 0), sseg => hex2);
		
	--hex1 displays either a minus in the case of left shift or nothing in case of the right shift
	hex1 <= "0111111" when (direction = '1') else "1111111";
	
	--instance for displaing the range of shifting
	sseg_unit_2: entity work.bin_to_sseg(arch)
		port map(bin => distance, sseg => hex0);

		
	input <= sw(7 downto 0);	
	
	--Rotate to the RIGHT:
	--stage 0, shift 0 or 1 bit
	s0_R <= input(0) & input(7 downto 1) when (distance(0) = '1') else 
			input;
	
	--stage 1, shift 0 or 2 bits
	s1_R <= s0_R(1 downto 0) & s0_R(7 downto 2) when (distance(1) = '1') else
			s0_R;
			
	--stage 2, shift 0 or 4 bits
	output_R <= s1_R(3 downto 0) & s1_R(7 downto 4) when (distance(2) = '1') else
				s1_R;
	
	--Rotate to the LEFT:
	--stage 0, shift 0 or 1 bit
	s0_L <=  input(6 downto 0) & input(7) when (distance(0) = '1') else 
			input;
	
	--stage 1, shift 0 or 2 bits
	s1_L <= s0_L(5 downto 0) & s0_L(7 downto 6) when (distance(1) = '1') else
			s0_L;
			
	--stage 2, shift 0 or 4 bits
	output_L <= s1_L(3 downto 0) & s1_L(7 downto 4) when (distance(2) = '1') else
				s1_L;
	
   --Choose the rotated value (to the right or to the left) dependent on the direction signal:	
	output <= output_R when (direction = '0') else output_L;

	-- show output using green LEDs:
	ledg <= output when (key(0) = '0' or key(1) = '0' or key(2) = '0' or key(3) = '0') else "00000000";	

	
end arch;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Calculates the direction (to the right or to the left) and the range of the shift
entity range_director is
	port(
		keys: in std_logic_vector(3 downto 0);
		r: in std_logic_vector(1 downto 0);
		dir: out std_logic;
		dist: out std_logic_vector (3 downto 0)

	);
end range_director;	
	
architecture arch of range_director is
	signal temp, inc_temp: std_logic_vector(3 downto 0);
begin
	
	--sets both signals dir and dist depending on the key pressed
	process (keys,r, temp, inc_temp)
	begin
		temp <= "00" & r;
		inc_temp <= std_logic_vector(unsigned(temp) + 4 );
		
		--CASE STATEMENT
		case keys is
			--key0 pressed
			when "1110" =>
				dir <= '0';
				dist <= inc_temp;
			--key1 pressed	
			when "1101" =>
				dir <= '0';
				dist <= temp;
			--key2 pressed
			when "1011" =>
				dir <= '1';
				dist <= temp;
			--key3 pressed
			when "0111" =>
				dir <= '1';
				dist <= inc_temp;
			--no key or > 1 key pressed	
			when others =>
				dir <= '0';
				dist <= "0000";
		end case;
	end process;

end arch;
	


library ieee;
use ieee.std_logic_1164.all;

--Displays a 4-bit signal as a hexadecimal number
entity bin_to_sseg is
	port(
		bin: in std_logic_vector(3 downto 0);
		sseg: out std_logic_vector(6 downto 0)
	);
end bin_to_sseg;

architecture arch of bin_to_sseg is
begin
	with bin select
	
		sseg 	<= 	"1000000" when "0000", --0
						"1111001" when "0001", --1
						"0100100" when "0010", --2
						"0110000" when "0011", --3
						"0011001" when "0100", --4
						"0010010" when "0101", --5
						"0000010" when "0110", --6
						"1111000" when "0111", --7
						"0000000" when "1000", --8
						"0010000" when "1001", --9
						"0001000" when "1010", --A
						"0000011" when "1011", --B
						"1000110" when "1100", --C
						"0100001" when "1101", --D
						"0000110" when "1110", --E
						"0001110" when others; --F
						

end arch;
	


