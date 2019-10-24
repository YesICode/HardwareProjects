library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity pulsing_leds is
	generic(
		N: integer := 10);
	port(
		clk, reset: in std_logic;
		en: in std_logic;
		pwm_period: in std_logic_vector(9 downto 0);
		pulse_length: in std_logic_vector(9 downto 0);
		
		q: out std_logic_vector(N-1 downto 0)
	);
end pulsing_leds;

architecture pulsing_arch of pulsing_leds is

	signal counter_reg, counter_next: unsigned(N-1 downto 0);
	signal r_reg, r_next: unsigned(N-1 downto 0);
	signal period,pulse: unsigned(N-1 downto 0);
	signal pulse_tick, period_tick: std_logic;
	
begin
	--register
	process(clk, reset)
	begin
		if(reset = '1') then
			counter_reg <= (others => '0');
			r_reg <= (others => '0');
		elsif(rising_edge(clk))then
			if(en = '1') then
				counter_reg <= counter_next;
				r_reg <= r_next;
			end if;
		end if;
	end process;
	
	--next-state logic
	period <= unsigned(pwm_period);
	pulse <= unsigned(pulse_length);
	
	counter_next <= 	(others => '0') when (counter_reg = period) else counter_reg + 1;
	
	period_tick <= '1' when (counter_reg = period) else '0';
	
	pulse_tick <= '1' when ((counter_reg = pulse) or (counter_reg = period)) else '0';
	
	r_next <= 	(others => '1') when ((period_tick = '1') and (pulse_tick = '1')) else
					(others => '0') when ((period_tick = '0') and (pulse_tick = '1')) else
					r_reg;
	
	--output logic
	q <= std_logic_vector(r_reg);
	
end pulsing_arch;
	


