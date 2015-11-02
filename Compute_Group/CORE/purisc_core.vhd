library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity purisc_core is
	port(
		clk, reset_n : in std_logic;
		r_addr_a, r_addr_b, r_addr_c, r_addr_0, r_addr_1 : out std_logic_vector(31 downto 0);
		w_data, w_addr :	out std_logic_vector(31 downto 0);
		we	:	out std_logic;
		stall : in std_logic;
		id	: in std_logic_vector(2 downto 0);
		r_data_a, r_data_b, r_data_c, 
		r_data_0, r_data_1	: 	in	std_logic_vector(31 downto 0)
	);
end entity;

architecture arch of purisc_core is
		--top core signals
		signal start_address : std_logic_vector(31 downto 0);
		--ri output signals
		signal ri_a : std_logic_vector(31 downto 0);
		signal ri_b : std_logic_vector(31 downto 0);
		signal ri_c : std_logic_vector(31 downto 0);
		signal ri_next_pc : std_logic_vector(31 downto 0);
		
		--rd output signals 
		signal rd_a : std_logic_vector(31 downto 0);
		signal rd_b : std_logic_vector(31 downto 0);
		signal rd_c : std_logic_vector(31 downto 0);
		signal rd_addr_a : std_logic_vector(31 downto 0);
		signal rd_addr_b : std_logic_vector(31 downto 0);
		signal rd_addr_c : std_logic_vector(31 downto 0);
		signal rd_next_pc : std_logic_vector(31 downto 0);
		signal rd_ubranch : std_logic;
		signal rd_noop : std_logic;
		
		--ex output signals
		signal ex_b : std_logic_vector(31 downto 0); --ex_b is another name for for ex_w_addr
		signal ex_db : std_logic_vector(31 downto 0); --ex_b is another name for for ex_w_data
		signal ex_cbranch : std_logic;
		signal ex_cbranch_addr : std_logic_vector(31 downto 0);
		signal ex_noop : std_logic;
		
		--ex input signals
		signal ex_da_in, ex_db_in : std_logic_vector(31 downto 0);
		
		--ex output signals
		signal ex_w_data, ex_w_addr : std_logic_vector(31 downto 0); 
		signal ex_we : std_logic;
		
		--ri stage
		component read_instruction_stage is
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
		end component;
		--rd stage
		component read_data_stage is
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
		end component;
		--ex stage
		component execute_stage is
			port(
				clk : in std_logic;
				reset_n : in std_logic;
				stall : 	in	std_logic;
				noop_in : in std_logic;
				--inputs
				ubranch_in : in std_logic;
				cbranch_in : in std_logic;
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
		end component;
	begin

	ri : read_instruction_stage  port map (
		--in
		clk => clk, 
		reset_n => reset_n, 
		stall => stall,
		
		start_address => start_address,
		
		cbranch => ex_cbranch,
		cbranch_addr => ex_cbranch_addr,
		ubranch => rd_ubranch,
		ubranch_addr => rd_c,
		
		next_pc => ri_next_pc,
		r_addr_inst => ri_a
	);
	rd : read_data_stage port map (
		clk => clk,
		reset_n => reset_n,
		stall => stall,
		-- inputs
		start_address => start_address,
		ex_w_addr => ex_w_addr,
		ex_w_data => ex_w_data,
		ex_we => ex_we,
		
		a_in => r_data_a,
		b_in => r_data_b,
		c_in => r_data_c,
		addr_a => ri_a,
		addr_b => ri_b,
		addr_c => ri_c,
		next_pc => ri_next_pc,
		ubranch_in => rd_ubranch,
		cbranch_in => ex_cbranch,
		--outputs
		a_out => rd_a,
		b_out => rd_b,
		c_out => rd_c,
		addr_a_out => rd_addr_a,
		addr_b_out => rd_addr_b,
		addr_c_out => rd_addr_c,
		ubranch_out => rd_ubranch,
		noop_out => rd_noop,
		
		r_addr_0	=> r_addr_0,
		r_addr_1	=> r_addr_1,
		next_pc_out => rd_next_pc
	);
	ex : execute_stage port map (
		clk => clk,
		reset_n => reset_n,
		stall => stall,
		noop_in => rd_noop,
		--inputs
		ubranch_in => rd_ubranch,
		cbranch_in => ex_cbranch,
		start_address => start_address,
		ex_w_addr => ex_w_addr,
		ex_w_data => ex_w_data,
		ex_we => ex_we,
		
		a_in => rd_a,
		b_in => rd_b,
		c_in => rd_c,
		addr_a => rd_addr_a,
		addr_b => rd_addr_b,
		addr_c => rd_addr_c,
		next_pc => rd_next_pc,
		--outputs
		cbranch_addr => ex_cbranch_addr,
		cbranch_out => ex_cbranch,
		
		-- memory
		da_in => r_data_0,
		db_in => r_data_1,
		w_data => ex_w_data,
		w_addr => ex_w_addr,
		we_out => ex_we
	);
	-- hard coded start address offset (this should be half of local memory size)
	start_address <= "00000000000000000000000000000000" when id(0)='0' else 
						  "00000000000000000001000000000000";
						  
	--address calculation for cache
	ri_b <= std_logic_vector(unsigned(ri_a) + 1);
	ri_c <= std_logic_vector(unsigned(ri_a) + 2);
	
	--connecting modules to top level io
	w_data <= ex_w_data;
	w_addr <= ex_w_addr;
	we <= ex_we;
	
	--alternate names
	r_addr_a <= ri_a;
	r_addr_b <= ri_b;
	r_addr_c <= ri_c;
end architecture;