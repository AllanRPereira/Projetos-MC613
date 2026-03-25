library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.estados.all;

entity Boxxo is
	port (
		CLOCK_50: in std_logic;
		KEY: in std_logic_vector(1 downto 0);
		SW: in std_logic_vector(9 downto 0);
		LEDR: out std_logic_vector(1 downto 0);
		HEX0, HEX1, HEX2, HEX3, HEX4, HEX5: out std_logic_vector(6 downto 0)
		);
	end entity Boxxo;
	
	
	architecture main of Boxxo is
	
		signal prod_display std_logic;
		signal pay_enable std_logic;
		signal buy_enable std_logic;
		signal devolu std_logic;
		signal cancela std_logic;
		
		begin
		