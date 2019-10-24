library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vending_machine is
	port(
		clk: in std_logic;
		reset: in std_logic;
		sw:  in std_logic_vector(7 downto 0);
		key2, key1, key0: in std_logic;
		
		bin3, bin1, bin0: out std_logic_vector(3 downto 0);
		products: out std_logic_vector(7 downto 0);
		lamps: out std_logic_vector(1 downto 0)
	);
end vending_machine;

architecture arch of vending_machine is
	constant CENT_90: unsigned := 	"1011010";
	constant CENT_50: unsigned := 	"0110010";
	constant CENT_40: unsigned := 	"0101000";
	constant CENT_30: unsigned := 	"0011110";
	constant CENT_20: unsigned := 	"0010100";
	constant CENT_10: unsigned := 	"0001010";
	
	type state_type is (ready, insert_coins, buy_product, check, error, done);
	signal state_reg, state_next: state_type;
	
	signal money_reg, money_next, coin, price: unsigned(6 downto 0);
	signal p0_reg, p1_reg, p2_reg, p3_reg, p4_reg, p5_reg, p6_reg, p7_reg: unsigned(2 downto 0);
	signal p0_next, p1_next, p2_next, p3_next, p4_next, p5_next, p6_next, p7_next: unsigned(2 downto 0);
	signal current_pr_reg, current_pr_next: std_logic_vector(2 downto 0);

	signal error_reg, error_next: std_logic_vector(1 downto 0);
	
	signal bcd1, bcd0: std_logic_vector(3 downto 0);

	signal non_valid_sw, product_sold_out, too_expensive_choice: std_logic;
	signal zero_money, refill: std_logic;
	signal sw7, sw6, sw5, sw4, sw3, sw2, sw1, sw0: std_logic;

	signal p0_ok, p1_ok, p2_ok, p3_ok, p4_ok, p5_ok, p6_ok, p7_ok: std_logic;
	
	signal pay_tick, buy_tick , b2b_start: std_logic;
	
begin
	--instantiate a bin2bcd converter
	bin2bcd_unit: entity work.bin2bcd (arch)
	port map
			(clk => clk, reset => reset, start => b2b_start,
			bin => std_logic_vector("0" & money_next) , ready => open,
			bcd1 => bcd1, bcd0 => bcd0);


	--state and data registers
	process(clk, reset)
	begin
		if (reset = '1') then
			state_reg <= ready;
			money_reg <= (others => '0');
			p0_reg <= "101";
			p1_reg <= "101";
			p2_reg <= "101";
			p3_reg <= "101";
			p4_reg <= "101";
			p5_reg <= "101";
			p6_reg <= "101";
			p7_reg <= "101";
			current_pr_reg <= (others => '0');
			
			error_reg <= (others => '0');
			
		elsif (rising_edge(clk)) then
			state_reg <= state_next;
			money_reg <= money_next;
			p0_reg <= p0_next;
			p1_reg <= p1_next;
			p2_reg <= p2_next;
			p3_reg <= p3_next;
			p4_reg <= p4_next;
			p5_reg <= p5_next;
			p6_reg <= p6_next;
			p7_reg <= p7_next;
			current_pr_reg <= current_pr_next;
			
			error_reg <= error_next;
			
		end if;
	end process;
	
	--fsm next-state logic
	process(state_reg, money_reg, money_next, error_reg,
				p0_reg, p1_reg, p2_reg, p3_reg, p4_reg, p5_reg, p6_reg, p7_reg,
				sw, key2, key1, key0,
				product_sold_out, too_expensive_choice, bcd1, bcd0)
				
	begin
		state_next <= state_reg;
		error_next <= error_reg;
		
	  
		non_valid_sw <= '0';
	  
	
		zero_money <= '0';
		refill <= '0';
	
		coin <= (others => '0');
		
		sw7 <= '0';
		sw6 <= '0';
		sw5 <= '0';
		sw4 <= '0';
		sw3 <= '0';
		sw2 <= '0';
		sw1 <= '0';
		sw0 <= '0';
				
		pay_tick  <= '0';
		buy_tick <= '0';
		
		b2b_start <= '0';
		
		case state_reg is
			
			--READY
			when ready =>

					refill <= '1';
					state_next <= done;
		
				
			--INSERT COINS	
			when insert_coins =>
				
				if(key0 = '1') then
					pay_tick <= '1';
					if (sw(2 downto 0) = "001") then 
							coin <= "0001010"; --10 cent 
					elsif(sw(2 downto 0) = "010") then  
							coin <= "0010100"; --20 cent
					elsif(sw(2 downto 0) = "100") then  
							coin <= "0110010"; --50 cent
					end if;
					
					b2b_start <= '1';
					
				elsif (key1 = '1') then
						state_next <= buy_product;
						
				elsif (key2 = '1') then
					state_next <= done;
						
				elsif(money_reg > CENT_90) then
					state_next <= error;
					error_next <= "00";
				end if;
				
				
			--BUY PRODUCT
			when buy_product =>
			
				if(key1 = '1') then
					buy_tick <= '1';
					if (sw = "00000001") then 
							sw0 <= '1';	
							state_next <= check;
					elsif(sw = "00000010") then  
							sw1 <= '1';
							state_next <= check;
					elsif (sw = "00000100") then 
							sw2 <= '1';
							state_next <= check;
					elsif (sw = "00001000") then 
							sw3 <= '1';	
							state_next <= check;
					elsif (sw = "00010000") then 
							sw4 <= '1';	
							state_next <= check;
					elsif (sw = "00100000") then
							sw5 <= '1';
							state_next <= check;
					elsif (sw = "01000000") then 
							sw6 <= '1';
							state_next <= check;
					elsif (sw = "10000000") then
							sw7 <= '1';
							state_next <= check;
							
					else -- zero or >1 sw on
					      non_valid_sw <= '1';
							error_next <= 	"01";
							state_next <= error;	
					end if;
					
					b2b_start <= '1';	
					
				elsif(key0 = '1' or key2 = '1') then
					state_next <= done;
				end if;
			
			
			--CHECK
			when check =>	
				
				if (product_sold_out = '1') then
				      error_next <= "11";
						state_next <= error;
							
				elsif (too_expensive_choice = '1') then
						state_next <= error;
						error_next <= "10";
							
				else
					state_next <= buy_product;
				end if;	

				
			--ERROR
			when error =>

				if (key0 = '1') then
					state_next <= done;
				end if;
				

			--DONE
			when done =>
				zero_money <= '1';
				b2b_start <= '1';	
				state_next <= insert_coins;
		
			end case;
	end process;
	
	--data path function units
	p0_ok <=	'1' when	((sw0 = '1') and (money_reg >= price)) else '0';
	p1_ok <=	'1' when	((sw1 = '1') and (money_reg >= price)) else '0';
	p2_ok <=	'1' when	((sw2 = '1') and (money_reg >= price)) else '0';
	p3_ok <=	'1' when	((sw3 = '1') and (money_reg >= price)) else '0';
	p4_ok <=	'1' when	((sw4 = '1') and (money_reg >= price)) else '0';
	p5_ok <=	'1' when ((sw5 = '1') and (money_reg >= price)) else '0';
	p6_ok <=	'1' when ((sw6 = '1') and (money_reg >= price)) else '0';
	p7_ok <=	'1' when	((sw7 = '1') and (money_reg >= price)) else '0';
	
						
	money_next <= (others => '0') when (zero_money = '1') else
						money_reg + coin when (pay_tick = '1') else
						money_reg - price when (buy_tick = '1' 
														and (not (non_valid_sw = '1'))
														and (not (product_sold_out = '1'))
														and (not (too_expensive_choice = '1'))
														and (money_reg >= price)) else
						money_reg;
						
						
	p0_next <= 	"101" when (refill = '1') else
					p0_reg - 1 when (p0_ok = '1') else
					p0_reg;
	p1_next <= 	"101" when (refill = '1') else
					p1_reg - 1 when (p1_ok = '1') else
					p1_reg;
	p2_next <= 	"101" when (refill = '1') else
					p2_reg - 1 when (p2_ok = '1') else
					p2_reg;
	p3_next <= 	"101" when (refill = '1') else
					p3_reg - 1 when (p3_ok = '1')  else
					p3_reg;
	p4_next <= 	"101" when (refill = '1') else
					p4_reg - 1 when (p4_ok = '1')  else
					p4_reg;
	p5_next <= 	"101" when (refill = '1') else
					p5_reg - 1 when (p5_ok = '1') else
					p5_reg;
	p6_next <= 	"101" when (refill = '1') else
					p6_reg - 1 when (p6_ok = '1') else
					p6_reg;
	p7_next <= 	"101" when (refill = '1') else
					p7_reg - 1 when (p7_ok = '1') else
					p7_reg;
					

	current_pr_next <= 	"000" when (sw0 = '1' or state_reg = done) else
								"001" when sw1 = '1' else
								"010" when sw2 = '1' else
								"011" when sw3 = '1' else
								"100" when sw4 = '1' else
								"101" when sw5 = '1' else
								"110" when sw6 = '1' else
								"111" when sw7 = '1' else
								current_pr_reg;
								
	price <= 	CENT_50 when (current_pr_next = "111") else 									-- 50 cent 
					CENT_40 when (current_pr_next = "110" or current_pr_next = "101") else 		-- 40 cent
					CENT_30 when (current_pr_next = "100" or current_pr_next = "011") else 		-- 30 cent
					CENT_10 when (current_pr_next = "000") else									-- 10 cent
					CENT_20;	--(current_pr_next = "010" or current_pr_next = "001")			-- 20 cent	
								
	product_sold_out <= '1' when ((current_pr_next = "000" and p0_reg = 0)
											or (current_pr_next = "001" and p1_reg = 0)
											or (current_pr_next = "010" and p2_reg = 0)
											or (current_pr_next = "011" and p3_reg = 0)
											or (current_pr_next = "100" and p4_reg = 0)
											or (current_pr_next = "101" and p5_reg = 0)
											or (current_pr_next = "110" and p6_reg = 0)
											or (current_pr_next = "111" and p7_reg = 0)) else '0';
											
										
	too_expensive_choice <= '1' when(((current_pr_next = "000")
											or (current_pr_next = "001")
											or (current_pr_next = "010")
											or (current_pr_next = "011")
											or (current_pr_next = "100")
											or (current_pr_next = "101")
											or (current_pr_next = "110")
											or (current_pr_next = "111")) and (money_reg < price)) else '0';
																	
					
	--output
	WITH state_reg SELECT
		bin3 <= "1100" WHEN insert_coins, 									--show C     
              "1110" WHEN error,  											--show E
              ("0" & current_pr_reg) WHEN OTHERS;   						--show product number

	WITH state_reg SELECT
		bin1 <= "1100" WHEN error, 											--show C     
					bcd1 WHEN OTHERS;  										--show amount of money
					
	WITH state_reg SELECT
		bin0 <= ("00" & error_next) WHEN error, 							--show error number     
				  bcd0 WHEN OTHERS;  										--show amount of money
   

	lamps(0) <= '1' when (state_reg = insert_coins 	and (not(sw(2 downto 0) = "001"
															or sw(2 downto 0) = "010"
															or sw(2 downto 0) = "100"))) 
					else'0';

								

	lamps(1) <= '1'when (state_reg = buy_product and (not 	  (sw = "00000001"
																or sw = "00000010"
																or sw = "00000100"
																or sw = "00001000"
																or sw = "00010000"
																or sw = "00100000"
																or sw = "01000000"
																or sw = "10000000"))) 
					else'0';
					
	
	products(0) <= '0' when ((p0_reg = 0) or (money_reg < CENT_10)) else '1';
	products(1) <= '0' when ((p1_reg = 0) or (money_reg < CENT_20)) else '1';
	products(2) <= '0' when ((p2_reg = 0) or (money_reg < CENT_20)) else '1';
	products(3) <= '0' when ((p3_reg = 0) or (money_reg < CENT_30)) else '1';
	products(4) <= '0' when ((p4_reg = 0) or (money_reg < CENT_30)) else '1';
	products(5) <= '0' when ((p5_reg = 0) or (money_reg < CENT_40)) else '1';
	products(6) <= '0' when ((p6_reg = 0) or (money_reg < CENT_40)) else '1';
	products(7) <= '0' when ((p7_reg = 0) or (money_reg < CENT_50)) else '1';

	
end arch;





