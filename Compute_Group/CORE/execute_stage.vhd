library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execute_stage is
	port(
		clk : in std_logic;
		reset_n : in std_logic;
		stall : 	in	std_logic;
		noop_in : in std_logic;
		--inputs
		ubranch_in : in std_logic;
		cbranch_in : in std_logic;
		ex_w_addr : in std_logic_vector(31 downto 0);
		ex_w_data : in std_logic_vector(31 downto 0);
		ex_we : in std_logic;
		
		start_address : in std_logic_vector(31 downto 0);
		a_in : in std_logic_vector(31 downto 0);
		b_in : in std_logic_vector(31 downto 0);
		c_in : in std_logic_vector(31 downto 0);
		addr_a : in std_logic_vector(31 downto 0);
		addr_b : in std_logic_vector(31 downto 0);
		addr_c : in std_logic_vector(31 downto 0);
		next_pc : in std_logic_vector(31 downto 0);
		--outputs
		cbranch_out : out std_logic;
		cbranch_addr : out std_logic_vector(31 downto 0);
		
		-- memory
		da_in : in std_logic_vector(31 downto 0);
		db_in : in std_logic_vector(31 downto 0);
		w_data	: 	out std_logic_vector(31 downto 0);
		w_addr	:	out std_logic_vector(31 downto 0);
		we_out	:	out std_logic
	);
end entity;

architecture a1 of execute_stage is
--signals
	signal da_fwd : std_logic_vector(31 downto 0);
	signal db_fwd : std_logic_vector(31 downto 0);
	
-- --for self-modifying instruction forwarding
--	signal a_fwd : std_logic_vector(31 downto 0);
--	signal b_fwd : std_logic_vector(31 downto 0);
--	signal c_fwd : std_logic_vector(31 downto 0);

	signal sub : signed(31 downto 0);
	signal cbranch : std_logic;
	signal we : std_logic;
	
begin
	--determine forwarding
	da_fwd <= ex_w_data when (a_in = ex_w_addr and ex_we = '1') else da_in;
	db_fwd <= ex_w_data when (b_in = ex_w_addr and ex_we = '1') else db_in;

-- --self-modifying instruction forwarding (NOT USED. To enable this, replace instances of a with a_fwd, b with b_fwd ...)
--	a_fwd <= ex_db when (addr_a = ex_b) else a_in;
--	b_fwd <= ex_db when (addr_b = ex_b) else b_in;
--	c_fwd <= ex_db when (addr_c = ex_b) else c_in;
	
	--'execute'
	sub <= signed(db_fwd) - signed(da_fwd);
	
	--determine cbranch
	cbranch <= '1' when (sub <= 0 and not(noop_in = '1') and not(ubranch_in = '1') and not(next_pc = c_in)) else '0';
	
	--determine whether to write
	we <= '1' when (not(noop_in = '1') and not(cbranch_in = '1')) else '0';
	
	process(clk, reset_n, start_address) begin
		if(reset_n = '0') then
			--initial values
			w_data <= "00000000000000000000000000000000";
			w_addr <= std_logic_vector(unsigned(start_address) + to_unsigned(7,32)); --as if the third instruction is executing
			we_out <= '0';
			cbranch_out <= '0';
		elsif (rising_edge(clk)) then
			if(stall = '0') then 
				
				cbranch_out <= cbranch;
				cbranch_addr <= c_in;
				
				if(not(noop_in = '1')) then w_addr <= b_in; end if; --to prevent undefined address output after reset
				
				w_data <= std_logic_vector(sub);
				we_out <= we;
			else
				--hold previous outputs on stall (automatic)
			end if;
		end if;
	end process;
end architecture;
