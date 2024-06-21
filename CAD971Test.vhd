library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CAD971Test is
	Port(
		--//////////// CLOCK //////////
		CLOCK_24 	: in std_logic;
		
		--//////////// KEY //////////
		RESET_N	: in std_logic;
		
		
		--//////////// VGA //////////
		VGA_B		: out std_logic_vector(1 downto 0);
		VGA_G		: out std_logic_vector(1 downto 0);
		VGA_HS	: out std_logic;
		VGA_R		: out std_logic_vector(1 downto 0);
		VGA_VS	: out std_logic;
		
		--//////////// KEYS //////////
		Key : in std_logic_vector(3 downto 0);
		SW : in std_logic_vector(7 downto 0);
		
		--//////////// LEDS //////////
		Leds : out std_logic_vector(7 downto 0);
		
		--////////////Segments////////
		outseg         : out bit_vector(3 downto 0); --Enable of segments to choose one
		sevensegments  : out bit_vector(7 downto 0)
	);
end CAD971Test;

--}} End of automatically maintained section

architecture CAD971Test of CAD971Test is

Component VGA_controller
	port ( CLK_24MHz		: in std_logic;
         VS					: out std_logic;
			HS					: out std_logic;
			RED				: out std_logic_vector(1 downto 0);
			GREEN				: out std_logic_vector(1 downto 0);
			BLUE				: out std_logic_vector(1 downto 0);
			RESET				: in std_logic;
			ColorIN			: in std_logic_vector(5 downto 0);
			ScanlineX		: out std_logic_vector(10 downto 0);
			ScanlineY		: out std_logic_vector(10 downto 0)
  );
end component;

Component VGA_Square2
	port ( CLK_24MHz		: in std_logic;
			CLK_200Hz		: in std_logic;
			RESET				: in std_logic;
			btns           : in std_logic_vector(3 downto 0);
			end_game       : in bit;
			score          : out integer;
			lose           : out bit;
			ColorOut			: out std_logic_vector(5 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in integer range 0 to 255;
			SQUAREHEIGHT	: in integer range 0 to 255;
			BulletWidth		: in integer range 0 to 255;
			EnemyWidth		: in integer range 0 to 255;
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			GameStart		: out std_logic;
			time_end_game	: in	std_logic;
			hit_end_game	: out std_logic;
			score_end_game : out std_logic;
			reset_flag		: out std_logic
  );
end component;

  signal ScanlineX,ScanlineY	: std_logic_vector(10 downto 0);
  signal ColorTable	: std_logic_vector(5 downto 0);
  --seven_segment...
  signal seg0: bit_vector(7 downto 0):=x"c0";
  signal seg1: bit_vector(7 downto 0):=x"c0";
  signal seg2: bit_vector(7 downto 0):=x"c0";
  signal seg3: bit_vector(7 downto 0):=x"c0";
  signal seg_selectors : BIT_VECTOR(3 downto 0) := "1110" ;
  signal output: bit_vector(7 downto 0):=x"c0";
  signal input :Integer range 0 to 100 :=0;
  signal timer_game : Integer range 0 to 100 :=0;
  signal end_game : bit :='0';
  signal score : integer;
  signal lose: bit;
  signal leds_signal : std_logic_vector(7 downto 0) := "10101010";
  signal CLK_200HZ: std_logic := '0';
  signal GameStart: std_logic := '0';
  signal time_end_game: std_logic := '0';
  signal hit_end_game: std_logic := '0';
  signal score_end_game: std_logic := '0';
  signal reset_flag: std_logic := '0';
  begin
	 --------- VGA Controller -----------
	 VGA_Control: vga_controller
			port map(
				CLK_24MHz	=> CLOCK_24,
				VS				=> VGA_VS,
				HS				=> VGA_HS,
				RED			=> VGA_R,
				GREEN			=> VGA_G,
				BLUE			=> VGA_B,
				RESET			=> not RESET_N,
				ColorIN		=> ColorTable,
				ScanlineX	=> ScanlineX,
				ScanlineY	=> ScanlineY
			);
		
		--------- Moving Square -----------
		VGA_SQ: VGA_Square2
			port map(
				CLK_24MHz		=> CLOCK_24,
				CLK_200HZ		=> CLK_200HZ,
				RESET				=> not RESET_N,
				btns	         => Key,
				end_game			=> end_game,
				score          => score,
				lose           => lose,
				ColorOut			=> ColorTable,
				SQUAREWIDTH		=> 80,
				SQUAREHEIGHT	=> 40,
				BulletWidth		=> 10,
				EnemyWidth		=> 30,
				ScanlineX		=> ScanlineX,
				ScanlineY		=> ScanlineY,
				GameStart		=> GameStart,
				time_end_game  => time_end_game,
				hit_end_game	=> hit_end_game,
				score_end_game => score_end_game,
				reset_flag		=> reset_flag
			);
	CLK_200HZ_CREATOR: process (CLOCK_24)
		variable counter: integer range 0 to 120000 :=0;
	begin
		if CLOCK_24'event and CLOCK_24 = '1' then
			counter := counter + 1;
			if(counter = 120000) then
				counter := 0;
			end if;
			if(counter < 60000) then 
				CLK_200HZ <= '0';
			else
				CLK_200HZ <= '1';
			end if;
		end if;
	
	end process;
	 --change selector to choose one of segments each time
	 process(CLOCK_24) 
	 variable counter : integer range 0 to 5000 :=0;
	 begin
		 if(rising_edge(CLOCK_24)) then 
			 counter := counter +1;
			 if (counter = 4999) then 
				 counter :=0;
			    seg_selectors <= seg_selectors(0) & seg_selectors(3 downto 1);
			 end if;
		 end if;
	 end process;
	 
	 -- Timer of game : clock is 24mhz so 1s occurs after 24000000 clock edge
	 process(CLOCK_24,RESET_N) 
	 variable counter : integer range 0 to 24000000 :=0;
	 begin
	    if RESET_N = '0' then
		 counter := 0;
		 timer_game <= 0;
		 elsif(rising_edge(CLOCK_24)) then 
			if (GameStart = '1' and reset_flag = '1') then
				 counter := counter +1;
				 if (counter = 23999999) then 
					 counter :=0;
					 if( hit_end_game = '1' or score_end_game = '1' or time_end_game = '1') then
						timer_game <= timer_game;
					 else
						 timer_game <= timer_game+1; --Add timer after 24000000 clk edge
					 end if;
				 end if;
			end if;
		 end if;
	 end process;
	 

  
	--this process handles leds. on : when game is finished else off
   process(RESET_N,CLOCK_24 )
	variable timer_leds : integer range 0 to 12000001 := 0;
	begin
	if RESET_N = '0' then
		leds <= "00000000";
		leds_signal <= "10101010";
		timer_leds := 0;
	elsif(rising_edge(CLOCK_24 )) then
	   timer_leds := timer_leds + 1;
    	if time_end_game = '1' or hit_end_game = '1' or score_end_game = '1' then
		   leds <= "11111111";
		elsif end_game = '0' and timer_leds = 12000000  then
		   leds_signal <= leds_signal(0) & leds_signal (7 downto 1);
			leds <= leds_signal;
		end if;
	end if;
	end process;
	
   outseg <= seg_selectors;
	 
	 --seg_selectors choose one segment and segx has content of each segment
	 process(seg_selectors,seg0,seg1,seg2,seg3 )
	 begin
		case seg_selectors is
			when "1110" =>
			sevenSegments <= seg0;
			when "0111" =>
			sevenSegments <= seg3;
			when "1011" =>
			sevenSegments <= seg2;
			when "1101" =>
			sevenSegments <= seg1;
			when others =>
			sevenSegments <= x"c0";
		end case;
	end process;
	
   process( RESET_N,CLOCK_24 )
	begin
	--here content of segments is "2219"
	if RESET_N = '0' then
			-- display IDs
			seg0 <= x"F9";
			seg1 <= x"F8";
		 	seg2 <= x"F9";
	    	seg3 <= x"92";
			time_end_game <= '0';
	elsif(rising_edge(CLOCK_24)) then 
	--this case shows score in 7 segment
	if (GameStart = '1' and reset_flag = '1') then
	case score is
 	when 0 => seg3 <= x"c0"; 		seg2 <= x"c0";
	when 1 => seg3 <= x"F9"; 		seg2 <= x"c0";
	when 2 => seg3 <= x"A4"; 		seg2 <= x"c0";
	when 3 => seg3 <= x"B0"; 		seg2 <= x"c0";
	when 4 => seg3 <= x"99"; 		seg2 <= x"c0";
	when 5 => seg3 <= x"92"; 		seg2 <= x"c0";
	when 6 => seg3 <= x"82";		seg2 <= x"c0";
	when 7 => seg3 <= x"F8";		seg2 <= x"c0";
	when 8 => seg3 <= x"80";		seg2 <= x"c0";
	when 9 => seg3 <= x"98";		seg2 <= x"c0";
	when 10 => seg3 <= x"c0";		seg2 <= x"F9";
	when others => seg3 <= x"c0"; seg2 <= x"c0";
  end case;
  
--	  if( timer_game >= 90)then
--	   input <= timer_game - 90; --to calculate firs digit of timer
--		seg1 <= output;
--		seg0 <= x"98";
--	 elsif( timer_game >= 80)then
--	   input <= timer_game - 80;
--		seg1 <= output;
--		seg0 <= x"80";
--	 elsif( timer_game >= 70)then
--	   input <= timer_game - 70;
--		seg1 <= output;
--		seg0 <= x"F8";
--	 elsif( timer_game >= 60)then
--	   input <= timer_game - 60;
--		seg1 <= output;
--		seg0 <= x"82";
--	 els
	 if( timer_game >= 50)then
	   input <= timer_game - 50;
		seg1 <= output;
		seg0 <= x"92";
	 elsif( timer_game >= 40)then
	   input <= timer_game - 40;
		seg1 <= output;
		seg0 <= x"99";
	 elsif( timer_game >= 30)then
	   input <= timer_game - 30;
		seg1 <= output;
		seg0 <= x"B0";
	 elsif( timer_game >= 20)then
	   input <= timer_game - 20;
		seg1 <= output;
		seg0 <= x"A4";
	 elsif( timer_game >= 10)then
	   input <= timer_game - 10;
		seg1 <= output;
		seg0 <= x"F9";
	 else
	   input <= timer_game;
		seg1 <= output;
		seg0 <= x"C0";
	 end if;
	end if;
	if(timer_game >= 59) then

		time_end_game <= '1';
   end if;
--	if(hit_end_game = '1') then
--		seg0 <= x"c7";
--		seg1 <= x"c0";
--		seg2 <= x"92";
--	   seg3 <= x"86"; 
--	end if;
	if(time_end_game = '1' or score_end_game = '1') then
	   seg0 <= x"92";
	   seg1 <= x"c1";
		seg2 <= x"c6";
	   seg3 <= x"c6";
	end if;
	end if;
	end process;
	
	--equal value of integer input in binary format to send to segment
  process (input)
  begin
  case input is
 	when 0 => output <= x"c0";
	when 1 => output <= x"F9";
	when 2 => output <= x"A4";
	when 3 => output <= x"B0";
	when 4 => output <= x"99";
	when 5 => output <= x"92";
	when 6 => output <= x"82";
	when 7 => output <= x"F8";
	when 8 => output <= x"80";
	when others => output <= x"98";
  end case;
  end process;
	 
end CAD971Test;
