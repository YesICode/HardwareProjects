--VendingMachine as an Example of a Finite State Machine

--The top entity here is VM. 
--VM receives the key-signals from four instances of the falling_edge_detector.
--The signals are then transmitted to the vending_machine, which can be in one of the six states:
--1) READY, in which the product register can be filled. 
--It changes into the state DONE, in order to empty the money register. 
--2) INSERT_COINS, in which one can deposit money using KEY0 and one of the SW-switches. 
--By pressing KEY1 one changes into the state BUY_PRODUCT.
--In case of (money_reg > CENT_90) the machine changes into the state ERROR. 
--3) BUY_PRODUCT, in which one can buy products using KEY1 and one of the SW-switches.
--Afterwards the machine changes into the state CHECK.
--In case none or more than one SW-switches have been pressed the machine changes into the state ERROR. 
--4) CHECK, in which two signals product_sold_out and too_expensive_choice are being checked.
--If one of the signals is set, the machine changes into the state ERROR. 
--5) ERROR, from which one can change into the state DONE pressing the KEY0, so that a new transaction can take place. 
--6) DONE, in which the money register is emptied. It changes into the state INSERT_COINS.
--The vending_machine posses one instance of the bin2bcd, which gets triggered after each change of the money register.
--The three instances of bin_to_sseg in the entity VM translate the output for the three hex-displays.




library ieee;
use ieee.std_logic_1164.all;

--top level entity
entity VM is
	port(
	   clk: in std_logic;
		sw:  in std_logic_vector(7 downto 0);
		key:  in std_logic_vector(3 downto 0);
		
		hex3, hex2, hex1, hex0: out std_logic_vector(6 downto 0);
		ledg: out std_logic_vector(7 downto 0);
		ledr: out std_logic_vector(9 downto 8)
	);
end VM;

architecture arch of VM is

	signal key3, key2, key1, key0: std_logic;
	signal bin3, bin1, bin0: std_logic_vector(3 downto 0);
	
begin
	
	--instantiate four falling_edge_detectors for the keys
	falling_edge_unit3: entity work.falling_edge_detector(gate_level_arch)
		port map(clk => clk, reset => '0', input => key(3), fall => key3);

	falling_edge_unit2: entity work.falling_edge_detector(gate_level_arch)
		port map(clk => clk, reset => '0', input => key(2), fall => key2);
		
	falling_edge_unit1: entity work.falling_edge_detector(gate_level_arch)
		port map(clk => clk, reset => '0', input => key(1), fall => key1);
	
	falling_edge_unit0: entity work.falling_edge_detector(gate_level_arch)
		port map(clk => clk, reset => '0', input => key(0), fall => key0);
		
	
	vending_machine_unit: entity work.vending_machine(arch)
		port map(clk => clk, reset => key3, sw => sw, 
					key2 => key2, key1 => key1, key0 => key0,
					bin3 => bin3, bin1 => bin1, bin0 => bin0,
					products => ledg, lamps => ledr);
					
					
	bin_to_sseg_unit3: entity work.bin_to_sseg(arch)
		port map(bin => bin3, sseg => hex3);
		
	hex2 <= (others => '1');
		
	bin_to_sseg_unit1: entity work.bin_to_sseg(arch)
		port map(bin => bin1, sseg => hex1);
		
	bin_to_sseg_unit0: entity work.bin_to_sseg(arch)
		port map(bin => bin0, sseg => hex0);
	
end arch;




