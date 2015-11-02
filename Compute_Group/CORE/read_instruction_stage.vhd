library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--	This stage just updates the PC and requests the proper address from memory.
-- Memory sends the result directly to the next stage
entity read_instruction_stage is
	port(
		clk	:	in std_logic;
		reset_n	:	in std_logic;
		stall : 	in	std_logic;
		
		start_address : in std_logic_vector(31 downto 0);
		
		cbranch	:	in std_logic;
		cbranch_addr : in std_logic_vector(31 downto 0);
		ubranch : in std_logic;
		ubranch_addr : in std_logic_vector(31 downto 0);
		--outputs
		next_pc : out std_logic_vector(31 downto 0);
		--memory
		r_addr_inst	:	out std_logic_vector(31 downto 0)
	);
end entity;

architecture a1 of read_instruction_stage is
	signal pc : std_logic_vector(31 downto 0);
begin
	with reset_n select
		r_addr_inst <= pc when '1', start_address when others;
	process(clk, reset_n, start_address) begin
		if (reset_n = '0') then
			pc <= start_address;
			next_pc <= std_logic_vector(unsigned(start_address)+to_unsigned(3,32));
		elsif (rising_edge(clk)) then
			if(stall = '0') then 
			
				if (cbranch = '1') then
					pc <= cbranch_addr;
					next_pc <= std_logic_vector(unsigned(cbranch_addr) + to_unsigned(3,32));
				elsif (ubranch = '1') then
					pc <= ubranch_addr;
					next_pc <= std_logic_vector(unsigned(ubranch_addr) + to_unsigned(3,32));
				else 
					pc <= std_logic_vector(unsigned(pc) + to_unsigned(3,32));
					next_pc <= std_logic_vector(unsigned(pc) + to_unsigned(6,32));
				end if;	
				
			else
				--hold previous value on stall (automatic)
			end if;
		end if;
	end process;
end architecture;