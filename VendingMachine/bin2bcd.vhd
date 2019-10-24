library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Converts a hexadecimal number into a decimal number
entity bin2bcd is
	port(
		clk: in std_logic;
		reset: in std_logic;
		start: in std_logic;
		bin:  in std_logic_vector(7 downto 0);
	
		ready: out std_logic;
		bcd1, bcd0: out std_logic_vector(3 downto 0)
	);
end bin2bcd;

architecture arch of bin2bcd is
	
	type state_type is (idle, op, done);
	signal state_reg, state_next: state_type;
	signal p2s_reg, p2s_next: std_logic_vector(7 downto 0);
	signal n_reg, n_next: unsigned(3 downto 0);
	signal bcd1_reg, bcd1_next, bcd1_tmp: unsigned(3 downto 0);
	signal bcd0_reg, bcd0_next, bcd0_tmp: unsigned(3 downto 0);
	
begin
	--state and data registers
	process(clk, reset)
	begin
		if (reset = '1') then
			state_reg <= idle;
			p2s_reg <= (others => '0');
			n_reg <= (others => '0');
			bcd1_reg <= (others => '0');
			bcd0_reg <= (others => '0');
		elsif (rising_edge(clk)) then
			state_reg <= state_next;
			p2s_reg <= p2s_next;
			n_reg <= n_next;
			bcd1_reg <= bcd1_next;
			bcd0_reg <= bcd0_next;
		end if;
	end process;
	
	--fsmd next-state logic / data path operations
	process(state_reg, start, p2s_reg, n_reg, n_next, bin,
				bcd1_reg, bcd0_reg, bcd1_tmp, bcd0_tmp)
	begin
		state_next <= state_reg;
		ready <= '0';
		p2s_next <= p2s_reg;
		bcd1_next <= bcd1_reg;
		bcd0_next <= bcd0_reg;
		n_next <= n_reg;
		
		case state_reg is
			when idle =>
				ready <= '1';
				if (start = '1') then
					state_next <= op;
					bcd1_next <= (others => '0');
					bcd0_next <= (others => '0');
					n_next <= "1000"; --index
					p2s_next <= bin; --input shift register
					state_next <= op;
				end if;
			when op =>
				--shift in binary bit
				p2s_next <= p2s_reg(6 downto 0) & '0';
				--shift two bcd digits
				bcd0_next <= bcd0_tmp(2 downto 0) & p2s_reg(7);
				bcd1_next <= bcd1_tmp(2 downto 0) & bcd0_tmp(3);
				n_next <= n_reg - 1;
				if(n_next = 0) then
					state_next <= done;
				end if;
			when done =>
				state_next <= idle;
			end case;
	end process;
	
	--data path function units
	--two bcd adjustment circuits
	bcd0_tmp <= (bcd0_reg + 3) when (bcd0_reg > 4) else bcd0_reg;
	bcd1_tmp <= (bcd1_reg + 3) when (bcd1_reg > 4) else bcd1_reg;
	
	--output
	bcd0 <= std_logic_vector(bcd0_reg);
	bcd1 <= std_logic_vector(bcd1_reg);
	
end arch;





