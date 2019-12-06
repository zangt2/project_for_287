
library IEEE;
use ieee.STD_LOGIC_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
entity clock_enable_debouncing_button is
port(
 clk: in std_logic; -- input clock on FPGA 100Mhz
                           -- Change counter threshold accordingly
 button: in std_logic;
 slow_clk_enable: out std_logic
);
end clock_enable_debouncing_button;
architecture Behavioral of clock_enable_debouncing_button is
signal counter: std_logic_vector(27 downto 0):=(others => '0');
begin
process(clk,button)
begin
 if(button='0') then 
  counter <= (others => '0');
 elsif(rising_edge(clk)) then
  counter <= counter + x"0000001"; 
  if(counter>=x"003D08F") then -- reduce this number for simulation
   counter <=  (others => '0');
  end if;
 end if;
end process;
 slow_clk_enable <= '1' when counter=x"003D08F" else '0';



entity calculator is
 port(
 which_operator_+_SW03   : in STD_LOGIC;
 which_operator_-_SW02   : in STD_LOGIC;
 which_operator_*_SW01   : in STD_LOGIC;
 which_operator_/_SW00   : in STD_LOGIC;
 
 NUMBER_A_SWITCH17       : in STD_LOGIC;
 NUMBER_A_SWITCH16       : in STD_LOGIC;
 NUMBER_A_SWITCH15       : in STD_LOGIC;
 NUMBER_A_SWITCH14       : in STD_LOGIC;
 NUMBER_A_SWITCH13       : in STD_LOGIC;
 NUMBER_A_SWITCH12       : in STD_LOGIC;
 NUMBER_A_SWITCH11       : in STD_LOGIC;
 NUMBER_B_SWITCH10       : in STD_LOGIC;
 NUMBER_B_SWITCH09       : in STD_LOGIC;
 NUMBER_B_SWITCH08       : in STD_LOGIC;
 NUMBER_B_SWITCH07       : in STD_LOGIC;
 NUMBER_B_SWITCH06       : in STD_LOGIC;
 NUMBER_B_SWITCH05       : in STD_LOGIC;
 NUMBER_B_SWITCH04       : in STD_LOGIC;

 
 which_system_ten        : in STD_LOGIC;
 which_system_eig        : in STD_LOGIC;
 which_system_fou        : in STD_LOGIC;
 which_system_two        : in STD_LOGIC;
 
 
 a1,b1,c1,d1,e1,f1,g1    : out STD_LOGIC;
 a2,b2,c2,d2,e2,f2,g2    : out STD_LOGIC;
 );
end calculator;

architecture Behavioral of calculator is
	component clock_enable_debouncing_button is
		port (clk             : in std_logic; 
            which_system_ten: in std_logic;
             slow_clk_enable: out std_logic);
   end component;
	component clock_enable_debouncing_button is
		port (clk             : in std_logic; 
            which_system_eig: in std_logic;
             slow_clk_enable: out std_logic);
   end component;
	component clock_enable_debouncing_button is
		port (clk             : in std_logic; 
            which_system_fou: in std_logic;
             slow_clk_enable: out std_logic);
   end component;
	component clock_enable_debouncing_button is
		port (clk             : in std_logic; 
            which_system_two: in std_logic;
             slow_clk_enable: out std_logic);
   end component;
begin 
if  which_operator_+_SW03 = '1' then
	(if which_operator_+_SW03= '1' then
		a1 <=
		b1 <=
		c1 <=
		d1 <=
		e1 <=
		f1 <=
		g1 <=
		a2 <=
		b2 <=
		c2 <=
		d2 <=
		e2 <=
		f2 <=
		g2 <=
		
	)



	



