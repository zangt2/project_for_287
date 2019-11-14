library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Simple8Bit is
	port(
		databus			: inout 	std_logic_vector(7 downto 0);
		addr				: out		std_logic_vector(5 downto 0);
		n_out_enable	: out		std_logic;
		n_write_enable	: out		std_logic;
		n_rst				: in		std_logic;
		clk				: in		std_logic
	);
	
	-- Input with a shared databus used for input and output 
	
	
	
architecture behavior of Simple8Bit is
	signal 	accumulator				: std_logic_vector(8 downto 0);
	alias 	carry 					is accumulator(8);
	alias		result 					is accumulator(7 downto 0);
	alias		opcode 					is databus (7 downto 6);
	
	signal	addr_register			: std_logic_vector(5 downto 0)
	signal	program_counter		: std_logic_vector(5 downto 0);
	signal	states					: std_logic_vector(2 downto 0);
	
	type 		cpu_state 				is (FETCH, WRITE_TO, ALU_ADD, ALU_NOR, BRANCH_NOT_TAKEN);
	signal 	curr_state				: cpu_state;
	
	type 		state_encoding_type 	is array (curr_state) of std_logic_vector(2 downto 0);
	constant	state_encoding			: state_encoding_type := (FETCH <= "000", WRITE_TO <= "001", ALU_ADD <= "010", ALU_NOR <= "011", BRANCH_NOT_TAKEN <= "100");

	begin
	
	process (clk,n_rst)
		begin
			if not n_rst then	
				addr_register <= (others => '0');
				states <= "000";
				cpu_state <= FETCH;
				accumulator <= (others => '0');
				program_counter <= (others => '0');
			
			elsif rising_edge(clk) then
				
				if cpu_state = FETCH then
					program_counter <= addr_register + 1;
					addr_register <= databus(5 downto 0);
				else
					addr_register <= program_counter;
				end if;
				
				case cpu_state is 
					when ALU_ADD =>
						accumulator <= ('0' & result) + ('0' & databus);
					when ALU_NOR =>
						accumulator <= result nor databus;
					when BRANCH_NOT_TAKEN =>
						carry <= '0';
				end case;
				
				if cpu_state /= FETCH then
					cpu_state <= FETCH;
				elsif opcode ?= "11" and carry then
					cpu_state <= BRANCH_NOT_TAKEN;
				else 
					states <= "0" & not opcode;
					case opcode is
						when "00" 		=> cpu_state <= ALU_NOR;
						when "01" 		=> cpu_state <= ALU_AND;
						when "10" 		=> cpu_state <= WRITE_TO;
						when "11" 		=> cpu_state <= FETCH;
						when others 	=> null;
					end case;
				end if;
			end if;
		end process
		
	addr <= addr_register;
	databus <= result when (cpu_state = WRITE_TO) else (others => 'Z');
	
	n_out_enable <= '1' when (clk = '1' or cpu_state = WRITE_TO or n_rst = '0' or cpu_state = BRANCH_NOT_TAKEN) else '0';
	
	n_write_enable <= '1' when (clk = '1' or cpu_state /= WRITE_TO or n_rst = '0') else '0';

end;	
				
					
				
	
	
	