--ps2-keyboard
--divided into three separate pages
--first page is for debounce
--second page is for interface, changing a little so it output on the screen
 
--debounce
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
ENTITY debounce IS
  GENERIC(
    counter_size  :  INTEGER := 19); --counter size (19 bits gives 10.5ms with 50MHz clock)
  PORT(
    clk     : IN  STD_LOGIC;  --input clock
    button  : IN  STD_LOGIC;  --input signal to be debounced
    result  : OUT STD_LOGIC); --debounced signal
END debounce;
ARCHITECTURE logic OF debounce IS
  SIGNAL flipflops   : STD_LOGIC_VECTOR(1 DOWNTO 0); --input flip flops
  SIGNAL counter_set : STD_LOGIC;                    --sync reset to zero
  SIGNAL counter_out : STD_LOGIC_VECTOR(counter_size DOWNTO 0) := (OTHERS => '0'); --counter output
BEGIN
  counter_set <= flipflops(0) xor flipflops(1);   --determine when to start/reset counter
 
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT and clk = '1') THEN
      flipflops(0) <= button;
      flipflops(1) <= flipflops(0);
      If(counter_set = '1') THEN                  --reset counter because input is changing
        counter_out <= (OTHERS => '0');
      ELSIF(counter_out(counter_size) = '0') THEN --stable input time is not yet met
        counter_out <= counter_out   or  1;
      ELSE                                        --stable input time is met
        result <= flipflops(1);
      END IF;   
    END IF;
  END PROCESS;
END logic;
 
 
 
--interface 
LIBRARY ieee;
USE ieee.std_logic_1164.all;
ENTITY ps2_keyboard IS
  GENERIC(
    clk_freq              : INTEGER := 50_000_000; --system clock frequency in Hz
    debounce_counter_size : INTEGER := 8);         --set such that (2^size)/clk_freq = 5us (size = 8 for 50MHz)
  PORT(
    clk          : IN  STD_LOGIC;                     --system clock
    ps2_clk      : IN  STD_LOGIC;                     --clock signal from PS/2 keyboard
    ps2_data     : IN  STD_LOGIC;                     --data signal from PS/2 keyboard
    ps2_code_new : OUT STD_LOGIC;                     --flag that new PS/2 code is available on ps2_code bus
                                                      --(ps2_code     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --code received from PS/2
                                                      --ps2_keyboard;)—change it into something showing on the screen
    a, b, c, d, e, f, g : OUT STD_LOGIC);
   END ps2_keyboard;
ARCHITECTURE logic OF ps2_keyboard IS
  SIGNAL sync_ffs     : STD_LOGIC_VECTOR(1 DOWNTO 0);       --synchronizer flip-flops for PS/2 signals
  SIGNAL ps2_clk_int  : STD_LOGIC;                          --debounced clock signal from PS/2 keyboard
  SIGNAL ps2_data_int : STD_LOGIC;                          --debounced data signal from PS/2 keyboard
  SIGNAL ps2_word     : STD_LOGIC_VECTOR(10 DOWNTO 0);      --stores the ps2 data word
  SIGNAL error        : STD_LOGIC;                          --validate parity, start, and stop bits
  SIGNAL count_idle   : INTEGER RANGE 0 TO clk_freq/18_000; --counter to determine PS/2 is idle
  SIGNAL ps2_code: STD_LOGIC_VECTOR(7 DOWNTO 0); --code received from PS/2

  COMPONENT debounce IS
    GENERIC(
      counter_size : INTEGER); --debounce period (in seconds) = 2^counter_size/(clk freq in Hz)
    PORT(
      clk    : IN  STD_LOGIC;  --input clock
      button : IN  STD_LOGIC;  --input signal to be debounced
      result : OUT STD_LOGIC); --debounced signal
  END COMPONENT;
BEGIN
  --synchronizer flip-flops
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN  --rising edge of system clock
      sync_ffs(0) <= ps2_clk;           --synchronize PS/2 clock signal
      sync_ffs(1) <= ps2_data;          --synchronize PS/2 data signal
    END IF;
  END PROCESS;
  --debounce PS2 input signals
  debounce_ps2_clk: debounce
    GENERIC MAP(counter_size => debounce_counter_size)
    PORT MAP(clk => clk, button => sync_ffs(0), result => ps2_clk_int);
  debounce_ps2_data: debounce
    GENERIC MAP(counter_size => debounce_counter_size)
    PORT MAP(clk => clk, button => sync_ffs(1), result => ps2_data_int);
  --input PS2 data
  PROCESS(ps2_clk_int)
  BEGIN
    IF(ps2_clk_int'EVENT AND ps2_clk_int = '0') THEN    --falling edge of PS2 clock
      ps2_word <= ps2_data_int & ps2_word(10 DOWNTO 1);   --shift in PS2 data bit
    END IF;
  END PROCESS;
   
  --verify that parity, start, and stop bits are all correct
  error <= NOT (NOT ps2_word(0) AND ps2_word(10) AND (ps2_word(9) XOR ps2_word(8) XOR
        ps2_word(7) XOR ps2_word(6) XOR ps2_word(5) XOR ps2_word(4) XOR ps2_word(3) XOR
        ps2_word(2) XOR ps2_word(1))); 
  --determine if PS2 port is idle (i.e. last transaction is finished) and output result
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN           --rising edge of system clock
   
      IF(ps2_clk_int = '0') THEN                 --low PS2 clock, PS/2 is active
        count_idle <= 0;                           --reset idle counter
      ELSIF(count_idle /= clk_freq/18_000) THEN  --PS2 clock has been high less than a half clock period (<55us)
          count_idle <= count_idle   or  1;            --continue counting
      END IF;
     
      IF(count_idle = clk_freq/18_000 AND error = '0') THEN  --idle threshold reached and no errors detected
        ps2_code_new <= '1';                                   --set flag that new PS/2 code is available
        ps2_code <= ps2_word(8 DOWNTO 1);                      --output new PS/2 code
      ELSE                                                   --PS/2 port active or error detected
        ps2_code_new <= '0';                                   --set flag that PS/2 transaction is in progress
      END IF;
     
    END IF;
  END PROCESS;
  
	a<= ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(4) and ps2_code(4) and ps2_code(3)
	and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(2)  or ps2_code(5) and ps2_code(3)
	and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(3) and ps2_code(2)  or ps2_code(6)
	and ps2_code(2)  or ps2_code(6) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(4)
	and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(1) and ps2_code(0)
	or ps2_code(5) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(4)
	and ps2_code(2)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(1) and ps2_code(0)
	or ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(5) and ps2_code(0)  or ps2_code(5)
	and ps2_code(4) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(0)  or ps2_code(5)
	and ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(3)
	and ps2_code(2)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2) and ps2_code(0)
	or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(2)  or ps2_code(0)
	or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(1) and ps2_code(0)  or ps2_code(6)
	and ps2_code(5) and ps2_code(4) and ps2_code(2)  or ps2_code(6) and ps2_code(5) and ps2_code(4)
	and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(3)  or ps2_code(1)
  or ps2_code(6) and ps2_code(5) and ps2_code(4);
	b<= ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(4) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(2)  or ps2_code(6) and ps2_code(2)  or ps2_code(6) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(4) and ps2_code(3) and ps2_code(2)  or ps2_code(5) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(1)  or ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(5) and ps2_code(1)  or ps2_code(5) and ps2_code(3) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(3) and ps2_code(2)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(3) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4);
	c<= ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(4) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(2)  or ps2_code(6) and ps2_code(2)  or ps2_code(4) and ps2_code(3) and ps2_code(2)  or ps2_code(4) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(2)  or ps2_code(5) and ps2_code(4) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(1)  or ps2_code(5) and ps2_code(1)  or ps2_code(5) and ps2_code(3) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(3) and ps2_code(2)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2)  or ps2_code(6) and ps2_code(5) and ps2_code(3) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4);
	d<= ps2_code(4) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(2)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(2)  or ps2_code(6) and ps2_code(2)  or ps2_code(4) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(2)  or ps2_code(6) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(5) and ps2_code(0)  or ps2_code(5) and ps2_code(3) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4);
	e<= ps2_code(5) and ps2_code(2)  or ps2_code(5) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(3) and ps2_code(2)  or ps2_code(5) and ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(2)  or ps2_code(6) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(2)  or ps2_code(6) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(4) and ps2_code(3) and ps2_code(2)  or ps2_code(5) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(2)  or ps2_code(5) and ps2_code(4) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(1)  or ps2_code(6) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(5) and ps2_code(1)  or ps2_code(5) and ps2_code(0)  or ps2_code(5) and ps2_code(3) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4);
	f<= ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(2)  or ps2_code(5) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(3) and ps2_code(2)  or ps2_code(5) and ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(2)  or ps2_code(6) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(2)  or ps2_code(6) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(4) and ps2_code(3) and ps2_code(2)  or ps2_code(4) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(2)  or ps2_code(5) and ps2_code(4) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(1)  or ps2_code(6) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(1)  or ps2_code(5) and ps2_code(0)  or ps2_code(5) and ps2_code(3) and ps2_code(1)  or ps2_code(5)  or ps2_code(4) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2)  or ps2_code(6) and ps2_code(5) and ps2_code(4);
	g<= ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(4) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(2)  or ps2_code(5) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(4) and ps2_code(3) and ps2_code(2)  or ps2_code(4) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(5) and ps2_code(4) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(1)  or ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(5) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(1)  or ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(2) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(3) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(1) and ps2_code(0)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(2)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(1)  or ps2_code(6) and ps2_code(5) and ps2_code(4) and ps2_code(3) and ps2_code(1);

END logic;