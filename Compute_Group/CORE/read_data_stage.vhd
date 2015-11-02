library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity read_data_stage is
	port(
		clk	:	in std_logic;
		reset_n	:	in std_logic;
		stall : 	in	std_logic;
		-- inputs
		start_address : in std_logic_vector(31 downto 0);
		ex_w_addr : in std_logic_vector(31 downto 0);
		ex_w_data : in std_logic_vector(31 downto 0);
		ex_we : in std_logic;
		
		a_in : in std_logic_vector(31 downto 0);
		b_in : in std_logic_vector(31 downto 0);
		c_in : in std_logic_vector(31 downto 0);
		addr_a : in std_logic_vector(31 downto 0);
		addr_b : in std_logic_vector(31 downto 0);
		addr_c : in std_logic_vector(31 downto 0);
		next_pc : in std_logic_vector(31 downto 0);
		ubranch_in : in std_logic;
		cbranch_in : in std_logic;
		--outputs
		a_out : out std_logic_vector(31 downto 0);
		b_out : out std_logic_vector(31 downto 0);
		c_out : out std_logic_vector(31 downto 0);
		addr_a_out : out std_logic_vector(31 downto 0);
		addr_b_out : out std_logic_vector(31 downto 0);
		addr_c_out : out std_logic_vector(31 downto 0);
		ubranch_out : out std_logic;
		noop_out : out std_logic;
		
		r_addr_0	:	out std_logic_vector(31 downto 0);
		r_addr_1	:	out std_logic_vector(31 downto 0);
		next_pc_out : out std_logic_vector(31 downto 0)
	);
end entity;

architecture a1 of read_data_stage is
--signals
	signal ubranch : std_logic;
	signal noop : std_logic;
	signal a_in_fwd : std_logic_vector(31 downto 0);
	signal b_in_fwd : std_logic_vector(31 downto 0);
--components
begin
	--determine forwarding (change inputs before they are used)
	a_in_fwd	<= ex_w_data when (ex_w_addr = addr_a and ex_we = '1') else a_in;
	b_in_fwd <= ex_w_addr when (ex_w_addr = addr_b and ex_we = '1') else b_in;
	
	--determine ubranch
	ubranch <= '1' when (a_in_fwd = b_in_fwd and not(next_pc = c_in) and not(ubranch_in = '1') and not(cbranch_in = '1')) 
			else '0';
			
	--determine noop
	noop <= ubranch_in or cbranch_in; --the ubranch generated above
	
	process(clk, reset_n, start_address) begin
		if (reset_n = '0') then
			--on boot
			noop_out <= '1';
			ubranch_out <= '0';
			r_addr_0 <= std_logic_vector(unsigned(start_address) + to_unsigned(4,32));
			r_addr_1 <= std_logic_vector(unsigned(start_address) + to_unsigned(5,32));
		elsif (rising_edge(clk)) then
			if(stall = '0') then 
				ubranch_out <= ubranch;
				noop_out <= noop;
				
				a_out <= a_in;
				b_out <= b_in;
				c_out <= c_in;
				
				r_addr_0 <= a_in;
				r_addr_1 <= b_in;
				
				addr_a_out <= addr_a;
				addr_b_out <= addr_b;
				addr_c_out <= addr_c;
				
				next_pc_out <= next_pc;
			else
				--hold previous outputs on stall (automatic)
			end if;
		end if;
	end process;
end architecture;