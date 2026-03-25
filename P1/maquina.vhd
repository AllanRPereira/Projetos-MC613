library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.estados.all;

entity maquina is
	port (
		keys: in std_logic_vector(1 downto 0);
		enable_pay: in std_logic;
		enable_finish: in std_logic;
		enable_hex5: out std_logic;
		enable_buy: out std_logic;
		enable_led: out std_logic
		);
		
	end entity maquina;
	
	
architecture muda of maquina is
	signal prox_estado: estado;
	signal estado_atual: estado;
	
	begin
	
		process (keys[1], prox_estado)
		begin
			if keys[1] = '1' then
				estado_atual <= inicial;
			
			else estado_atual <= prox_estado;
			end if;
		end process;
		
		process (estado_atual)
		begin
			case estado is
			
				when incial =>
					enable_hex5 <= 1;
					enable_buy <= 0;
					enable_led <= 0;
					
				when pagamento =>
					enable_hex5 <= 0;
					enable_buy <= 1;
					enable_led <= 0;
					
				when final =>
					enable_hex5 <= 0;
					enable_buy <= 0;
					enable_led <= 1;
			
			end case;
		end process;
		
		
		process (keys(0), enable_pay, enable_finish)
		begin
			case estado is
				when inicial =>
					if keys[0] = '1' and enable_pay = '0' and enable_finsh = '0' then
						prox_estado <= pagamento;
					end if;
						
					if keys[0] = '1' and enable_pay = '1' and enable_finsh = '0' then
						prox_estado <= pagamento;
					end if;
						
					if enable_finish = '0' then
						prox_estado <= final;
					end if;
			end case;
		end process;