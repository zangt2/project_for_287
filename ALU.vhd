-- VHDL file used for our in-lab presentation
library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity ALU is
   port
   (
      datain 									: in std_logic_vector(7 downto 0);
		pushbutton0, pushbutton1			: in std_logic;
      Operation 								: in std_logic_vector(2 downto 0);
      Carry_Out 								: out std_logic;
      Flag 										: out std_logic;
      Result 									: out std_logic_vector(7 downto 0)
   );
end entity ALU;

architecture Behavioral of ALU is

   signal tmp	: std_logic_vector(8 downto 0);
	signal in0	: std_logic_vector(7 downto 0);
	signal in1	: std_logic_vector(7 downto 0);
	signal tmp1	: std_logic := '0';
	signal count:  integer:=1;
	
begin
	process (pushbutton0, pushbutton1, operation, tmp)
	begin
		flag <='0';
		if pushbutton0 = '0' then
			in0 <= datain;
		end if;
		if pushbutton1 = '0' then
			in1 <= datain;
		end if;			
		case operation is
			when "000" =>
				tmp <= std_logic_vector((unsigned("0" & in0) + unsigned("0" & in1)));
				result <= tmp(7 downto 0);
				carry_Out <= tmp(8);
				flag <= tmp(8);
			when "001" =>
				if (in0 >= in1) then
					Result <= std_logic_vector(unsigned(in0) - unsigned(in1));
					Flag   <= '0';
            else
					Result <= std_logic_vector(unsigned(in1) - unsigned(in0));
					Flag   <= '1';
            end if;
			when "010" =>
				result <= in0 and in1;
				
			when "011" =>
				result <= in0 or in1;
			when "100" =>
				result <= in0 xor in1;
			when "101" =>
				result <= std_logic_vector(to_unsigned((to_integer(unsigned("0" & in0)) * to_integer(unsigned("0" & in1))),8));
				result <= tmp(7 downto 0);
				carry_out <= tmp(8);
			when "110" =>
				result <= not in1;
			when others =>
				tmp <= std_logic_vector((unsigned("0" & in0) + unsigned("0" & in1)) +1);
				result <= tmp(7 downto 0);
				flag <= tmp(8);
			end case;
		end process;
	end architecture behavioral;
			
