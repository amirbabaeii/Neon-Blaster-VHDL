----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:27:56 01/26/2024 
-- Design Name: 
-- Module Name:    VGA_SQ2 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VGA_Square2 is
	port ( CLK_24MHz		: in std_logic;
			CLK_200HZ		: in std_logic;
			RESET				: in std_logic;
			Btns          	: in std_logic_vector(3 downto 0);  --use Key(0) to BtnUP
			end_game       : in bit;
			score          : inout integer;
			lose           : out bit;
			ColorOut			: out std_logic_vector(5 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in integer range 0 to 255;
			SQUAREHEIGHT	: in integer range 0 to 255;
			BulletWidth		: in integer range 0 to 255;
			EnemyWidth		: in integer range 0 to 255;
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0);
			GameStart		: inout std_logic;
			time_end_game  : in std_logic;
			hit_end_game	: inout std_logic;
			score_end_game : inout std_logic;
			reset_flag 		: inout std_logic
  );
end VGA_Square2;

architecture Behavioral of VGA_Square2 is
  signal ColorOutput: std_logic_vector(5 downto 0);
  signal SquareX: integer range 0 to 1023 := 300;  
  signal SquareY: integer range 0 to 1023 := 360; 
  signal SquareXMoveDir, SquareYMoveDir: std_logic := '0'; -- not used 
  --constant SquareWidth: std_logic_vector(4 downto 0) := "11001";
  constant SquareXmin: std_logic_vector(9 downto 0) := "0000000001"; -- not used 
  signal SquareXmax: std_logic_vector(9 downto 0); -- := "1010000000"-SquareWidth;
  constant SquareYmin: std_logic_vector(9 downto 0) := "0000000001"; -- not used 
  signal SquareYmax: std_logic_vector(9 downto 0); -- := "0111100000"-SquareWidth;
  signal ColorSelect: std_logic_vector(2 downto 0) := "001"; -- not used 
  signal Prescaler: std_logic_vector(30 downto 0); -- not used 
  --location of wall first
  --signal wallX1: std_logic_vector(9 downto 0):="1111111111";
  --signal wallY1: std_logic_vector(9 downto 0):="1111111111";
  --location of wall second
  --signal wallX2: std_logic_vector(9 downto 0):="1111111111";
  --signal wallY2: std_logic_vector(9 downto 0):="1111111111";
  --use in random function 
  signal pseudo_rand: std_logic_vector(31 downto 0) :=(others => '0');
  signal p_rand1: std_logic_vector(9 downto 0); -- not used 
  signal p_rand2: std_logic_vector(9 downto 0); -- not used 
  signal score_signal: integer range 0 to 11 :=0; -- not used 
  signal Bullet1X: integer range 0 to 1023 := 340;  
  signal Bullet1Y: integer range 0 to 1023 := 360;  
  signal Bullet2X: integer range 0 to 1023 := 340;  
  signal Bullet2Y: integer range 0 to 1023 := 360;  
  signal bullet1shot: bit := '0';
  signal bullet2shot: bit := '0';
  signal bullet1Hit: bit := '0';
  signal bullet2Hit: bit := '0';
  signal enemyHit: bit := '0';
  signal EnemyIn: bit := '0';
  signal EnemyX: integer range 0 to 1023 := 0;  
  signal EnemyY: integer range 0 to 1023 := 0;
  signal EnemyXP: integer range 0 to 8 := 0;
  signal EnemyYP: integer range 0 to 8 := 0;
  signal EnemyXD: std_logic := '0';
  signal EnemyYD: std_logic := '0';
begin

	reset_flag_process: process (RESET)
	begin
	if RESET = '1' then
		reset_flag <= '1';
	end if ;
	end process;
	win_process: process (CLK_200Hz, RESET)
		variable counter: integer range 0 to 2 := 0;
	begin
		if RESET = '1' then
			score_end_game <= '0';
			score <= 0;
			enemyhit <= '0';
			bullet1hit <= '0';
			bullet2hit <= '0'; 
		elsif CLK_200Hz'event and CLK_200Hz = '1' then
			if (Bullet1X <= EnemyX + EnemyWidth and Bullet1X + BulletWidth >= EnemyX and
				Bullet1Y < EnemyY + EnemyWidth and Bullet1Y + BulletWidth >= EnemyY) then
				counter := counter + 1;
				if counter = 2 then 
					score <= score + 1;
					bullet1hit <= '1';
					enemyhit <= '1';
					counter := 0;
				end if;
			elsif(Bullet2X <= EnemyX + EnemyWidth and Bullet2X + BulletWidth >= EnemyX and
				Bullet2Y < EnemyY + EnemyWidth and Bullet2Y + BulletWidth >= EnemyY) then
				counter := counter + 1;
				if counter = 2 then 
					score <= score + 1;
					bullet2hit <= '1';
					enemyhit <= '1';
					counter := 0;
				end if;
			else
				bullet1hit <= '0';
				bullet2hit <= '0';
				enemyhit <= '0';
				
			end if;
			if score = 10 then
				score_end_game <= '1';
			end if;
		end if;
	end process;

	lose_process: process (CLK_24MHz, RESET)
	begin
		if RESET = '1' then
			hit_end_game <= '0';
		elsif CLK_24MHz'event and CLK_24MHz = '1' then
			if EnemyX <= SquareX + SquareWidth and EnemyX + EnemyWidth >= SquareX and
				EnemyY < SquareY + SquareHeight and EnemyY + EnemyWidth >= SquareY then
				hit_end_game <= '1';
			end if;
		end if;
	end process;


	enemy_process: process (CLK_200HZ, RESET)
		

		impure function lfsr32(x : std_logic_vector(31 downto 0)) return std_logic_vector is
		begin
			return x(30 downto 0) & (x(0) xnor x(1) xnor x(21) xnor x(31));
		end function;
	begin
		if RESET = '1' then
			
			pseudo_rand <= lfsr32(pseudo_rand); 
			EnemyIn <= '0';
			EnemyXP <= to_integer(signed("00"&pseudo_rand(8 downto 8)&"1"));
			EnemyYP <= 1;
			EnemyX  <= to_integer(signed("00"&pseudo_rand(7 downto 0))&"11111");
			EnemyY  <= 0;
			EnemyXD <= pseudo_rand(10);
			EnemyYD <= '1';
			EnemyIn <= '1';
		elsif CLK_200HZ'event and CLK_200HZ = '1' then
			if GameStart = '1' and reset_flag = '1' then 
				if EnemyHit = '1' then
					EnemyIn <= '0';
				end if;
				if EnemyIn = '0' then
				
					pseudo_rand <= lfsr32(pseudo_rand);
					EnemyXP <= to_integer(signed("00"&pseudo_rand(8 downto 8)&"1"));
					EnemyYP <= 1;
					EnemyX  <= to_integer(signed("00"&pseudo_rand(3 downto 0))&"11111");
					EnemyY  <= 0;
					EnemyXD <= pseudo_rand(10);
					EnemyYD <= '1';
					EnemyIn <= '1';
				else
					if EnemyXD = '1' then
						EnemyX <= EnemyX + EnemyXP;
						if EnemyX >= 640 - EnemyWidth then 
							EnemyXD <= '0';
						end if;
					else
						EnemyX <= EnemyX - EnemyXP; 
						if EnemyX <= EnemyWidth then 
							EnemyXD <= '1';
						end if;
					end if;
					if EnemyYD = '1' then
						EnemyY <= EnemyY + EnemyYP;
						if EnemyY >= 480 - EnemyWidth then 
							EnemyYD <= '0';
						end if;	
						
					else
						EnemyY <= EnemyY - EnemyYP;
						if EnemyY <= EnemyWidth then 
							EnemyYD <= '1';
						end if;			
						
					end if;
				end if;
			end if;
		end if;
		
	end process;

	bullet_process: process (CLK_200HZ, RESET)
		variable counter: integer range 0 to 400 :=0;
	begin
		if RESET = '1' then
			Bullet1X <= 340;
			Bullet1Y <= 360;
			Bullet2X <= 340;
			Bullet2Y <= 360;
			bullet1shot <= '0';
			bullet2shot <= '0';
		elsif CLK_200HZ'event and CLK_200HZ = '1' then
			if GameStart = '1' and reset_flag = '1' then 
			
				
				
				counter := counter + 1;
				if counter = 200 and bullet1shot = '0' then
					bullet1shot <= '1';
				elsif counter = 400 and bullet2shot = '0' then
					bullet2shot <= '1';
					counter := 0;
				end if;
				if bullet1shot = '1' then
					bullet1Y <= bullet1Y - 1;
					if bullet1hit = '1' or bullet1Y = 0  then
						Bullet1shot <= '0';
						Bullet1X <= SquareX + 40;
						Bullet1Y <= 360;
					end if;
					
				end if;
				if bullet2shot = '1' then
					bullet2Y <= bullet2Y - 1;
					if bullet2hit = '1' or bullet2Y = 0  then
						Bullet2shot <= '0';
						Bullet2X <= SquareX + 40;
						Bullet2Y <= 360;
					end if;
					
				end if;
				if btns(0) = '0' then
					if bullet1shot = '0' then 
						bullet1X <= bullet1X + 1;
						
					end if;
					if bullet2shot = '0' then 
						bullet2X <= bullet2X + 1;
					end if;
				elsif btns(1) = '0' then
					if bullet1shot = '0' then 
						bullet1X <= bullet1X - 1;
					end if;
					if bullet2shot = '0' then 
						bullet2X <= bullet2X - 1;
					end if;
				end if;
			end if;
		end if;
	
	end process;
	btns_process: process (CLK_200HZ, RESET)
	begin
		if RESET = '1' then
			SquareX <= 300;
			SquareY <= 360;
			GameStart <= '0';
		elsif CLK_200HZ'event and CLK_200HZ = '1' then
			if btns(0) = '0' then
				if SquareX + squareWidth <= 640 then
					SquareX <= SquareX + 1;
					GameStart <= '1';
				end if;
			elsif btns(1) = '0' then
				if SquareX >= 20 then
					SquareX <= SquareX - 1;
					GameStart <= '1';
				end if;
			end if;
			if time_end_game = '1' or hit_end_game = '1' or score_end_game = '1' then
				GameStart <= '0';
			end if;
		end if;
		
	end process;



	ColorOutput <=	"001100" when (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareHeight)
					else "000011" when (ScanlineX > Bullet1X AND ScanlineY > Bullet1Y AND ScanlineX < Bullet1X+BulletWidth AND ScanlineY < Bullet1Y+BulletWidth)
					else "000011" when (ScanlineX > Bullet2X AND ScanlineY > Bullet2Y AND ScanlineX < Bullet2X+BulletWidth AND ScanlineY < Bullet2Y+BulletWidth)
					else "110000" when (ScanlineX > EnemyX AND ScanlineY > EnemyY AND ScanlineX < EnemyX+EnemyWidth AND ScanlineY < EnemyY+EnemyWidth)
					
					else	"111111";

	ColorOut <= ColorOutput;
	

	
end Behavioral;

