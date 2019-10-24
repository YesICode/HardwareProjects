library ieee;
use ieee.std_logic_1164.all;


entity falling_edge_detector is
	port(
		clk: in std_logic;
		reset: in std_logic; 
		input: in std_logic;
		
		fall: out std_logic
	);
end falling_edge_detector;

architecture gate_level_arch of falling_edge_detector is
	signal d0, q0, d1, q1, d2, q2: std_logic;	
begin
	
	--register
	process(clk, reset)
	begin
		if(reset = '1') then
			q0 <= '0';
			q1 <= '0';
			q2 <= '0';
		elsif(rising_edge(clk))then
				q0 <= d0;
				q1 <= d1;
				q2 <= d2;
		end if;
	end process;
	
	--next-state logic
	d0 <= input;
	d1 <= q0;
	d2 <= q1;
		
	--output logic
	fall <= ((not q1) and q2);
end gate_level_arch;
	

