library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity adress_counter is
	generic(
		N: integer := 4);
	port(
		clk, reset: in std_logic;
		en: in std_logic;
		key0, key1, key3: in std_logic;
		sw_switch: in std_logic_vector(9 downto 0);

		adress: out std_logic_vector(N-1 downto 0);
		pwm_period: out std_logic_vector(9 downto 0); 
		pr_modus: out std_logic
	);
end adress_counter;

architecture mod_m_arch of adress_counter is
	
	signal 	modus_reg, modus_next: std_logic;
	signal 	period_reg, period_next, 
				period_count_reg, period_count_next: unsigned(9 downto 0);
	signal	repetition_reg, repetition_next,
				repetition_count_reg, repetition_count_next: unsigned(15 downto 0);
	signal 	adr_program_reg, adr_program_next, 
				adr_execute_reg, adr_execute_next: unsigned(N-1 downto 0);
	
	signal 	wrap_up, pr: std_logic;
	
begin
	--register
	process(clk, reset)
	begin
		if(reset = '1') then
			modus_reg <= '0';
			
			period_reg <= (others => '0');
			repetition_reg <= (others => '0');
			
			period_count_reg <= (others => '0');
			repetition_count_reg <= (others => '0');
			
			adr_program_reg <= (others => '0');
			adr_execute_reg <= (others => '0');
		elsif(rising_edge(clk))then
			if(en = '1') then
				modus_reg <= modus_next;
				
				period_reg <= period_next;
				repetition_reg <= repetition_next;
				
				period_count_reg <= period_count_next;
				repetition_count_reg <= repetition_count_next;
				
				adr_program_reg <= adr_program_next;
				adr_execute_reg <= adr_execute_next;		
			end if;
		end if;
	end process;
	
	--next-state logic
	--modus
	pr <= modus_reg;
	modus_next <= (not modus_reg) when (key0 = '1') else modus_reg;
	
	--pwm-period and repetition 
	period_next <= unsigned(sw_switch) when ((key3 = '1') and (pr = '1')) else period_reg;
	--concatanation of 6 zeros to account for multiplication of repetition number with 64 
	repetition_next <= unsigned(sw_switch & "000000") when  ((key3 = '1') and (pr = '0')) else 
							repetition_reg;
	
	period_count_next <= (others => '0') when (period_count_reg = period_reg) else
								period_count_reg + 1;
								
	repetition_count_next <= (others => '0') when (repetition_count_reg = repetition_reg) else 
									repetition_count_reg + 1 when (period_count_reg = period_reg) else
									repetition_count_reg;
										
	wrap_up <= '1' when ((repetition_count_reg = repetition_reg) and (repetition_reg /= "000000000000000")) else '0';
						
	adr_program_next <= adr_program_reg + 1 when (pr = '1' and key1 = '1') else adr_program_reg;	
	adr_execute_next <= adr_execute_reg + 1 when (pr = '0' and wrap_up = '1') else adr_execute_reg;
	
	--output logic: the current adress, pwm period and modus
	adress <= std_logic_vector(adr_program_reg) when (pr = '1') else std_logic_vector(adr_execute_reg);
	pwm_period <= std_logic_vector(period_reg);
	pr_modus <= pr;
	
end mod_m_arch;
	


