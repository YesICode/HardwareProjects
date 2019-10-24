--PulseWidthModulator

--The Top-Entity here is PWM. 
--The rising edges of the KEYs are detected by the four instances of the rising_edge_detector and sent to the circuit.
--The adress_counter_unit controls the logic of the adress selection. 
--This happens via evaluation of the mode in which the machine currently is (programming- vs. execution mode), 
--of the cycle duration of the PWM and of the number of iterations.
--The currently active adress is being transferred to the memory unit one_port_ram_unit 
--and to the adress_display_unit (controls the Hex3-display).
--The memory unit one_port_ram_unit transfers the PWM-value, which has been saved under the currently active
--adress to the bin_to_sseg_unit3-1 (control the Hex2-0 displays).


library ieee;
use ieee.std_logic_1164.all;

--top-entity
entity PWM is
	port(
	   clk: in std_logic;
		sw:  in std_logic_vector(9 downto 0);
		key:  in std_logic_vector(3 downto 0);
		
		hex3, hex2, hex1, hex0: out std_logic_vector(6 downto 0);
		ledr: out std_logic_vector(9 downto 0);
		ledg: out std_logic_vector(0 downto 0)
	);
end PWM;

architecture arch of PWM is

	signal key0, key1, key2, key3: std_logic;
	signal key0_rise, key1_rise, key2_rise, key3_rise: std_logic;
	signal pr: std_logic;
	signal pwm_period, repetition_number, pulse_length, pulsing: std_logic_vector(9 downto 0); 
	
	signal adr: std_logic_vector(3 downto 0); --current adress

begin
	key0 <= (not key(0));
	key1 <= (not key(1));
	key2 <= (not key(2));
	key3 <= (not key(3));
	
	--instantiate rising_edge_detectors for the keys
	rising_edge_unit0: entity work.rising_edge_detector(arch)
		port map(clk => clk, reset => '0', en => '1', input => key0, rise => key0_rise);
		
	rising_edge_unit1: entity work.rising_edge_detector(arch)
		port map(clk => clk, reset => '0', en => '1', input => key1, rise => key1_rise);
		
	rising_edge_unit2: entity work.rising_edge_detector(arch)
		port map(clk => clk, reset => '0', en => '1', input => key2, rise => key2_rise);
		
	rising_edge_unit3: entity work.rising_edge_detector(arch)
		port map(clk => clk, reset => '0', en => '1', input => key3, rise => key3_rise);

	--current adress holder and counter
	adress_counter_unit: entity work.adress_counter(mod_m_arch)
		port map(clk => clk, reset => '0', en => '1', 
		key0 => key0_rise, key1 => key1_rise, key3 => key3_rise, sw_switch => sw, 
		adress => adr, pr_modus => pr, pwm_period => pwm_period);
		
	--show the modus (programming vs. executing)	
	ledg(0) <= not pr;
		
	--M4K to hold the data
	one_port_ram_unit: entity work.one_port_ram(beh_arch2)
		port map(clk => clk, we => (key2_rise and pr), addr => adr,
		d => sw, q => pulse_length);
	
	pulsing_leds_display_unit: entity work.pulsing_leds(pulsing_arch)
		port map(clk => clk, reset => '0', en => '1', pwm_period => pwm_period, pulse_length => pulse_length, q => pulsing);
		
	ledr <= pwm_period when (pr = '1') else pulsing;
	
	adress_display_unit: entity work.bin_to_sseg(arch)
		port map(bin => adr, sseg => hex3);	
	
	bin_to_sseg_unit3: entity work.bin_to_sseg(arch)
		port map(bin => ("00" & pulse_length(9 downto 8)), sseg => hex2);
		
	bin_to_sseg_unit2: entity work.bin_to_sseg(arch)
		port map(bin => pulse_length(7 downto 4), sseg => hex1);
		
	bin_to_sseg_unit1: entity work.bin_to_sseg(arch)
		port map(bin => pulse_length(3 downto 0), sseg => hex0);
	
end arch;




