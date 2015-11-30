`timescale 1ns / 1ns
`default_nettype none

module cpu_testbench;

/// 
/// regs/wires/assigns 
///
logic clock_50;
logic reset_n;

logic c0_reset_n;
logic [16:0] c0_ram_addr_a;
logic [16:0] c0_ram_addr_b;
logic [31:0] ram_c0_data_a;
logic [31:0] ram_c0_data_b;
logic ram_c0_en;
logic c0_ram_we_b;
logic [31:0] c0_ram_data_b;

logic c1_reset_n;
logic [16:0] c1_ram_addr_a;
logic [16:0] c1_ram_addr_b;
logic [31:0] ram_c1_data_a;
logic [31:0] ram_c1_data_b;
logic ram_c1_en;
logic c1_ram_we_b;
logic [31:0] c1_ram_data_b;

// Instantiate the units under test
cpu cpu0 (	
    .clock( clock_50 ),
    .reset_n( c0_reset_n ),
    .cpu_local_id( 1'd0 ),

    .c_ram_addr_a( c0_ram_addr_a ),
    .c_ram_addr_b( c0_ram_addr_b ),
    .ram_c_data_a( ram_c0_data_a ),
    .ram_c_data_b( ram_c0_data_b ),
    .ram_c_en( ram_c0_en ),

    .c_ram_we_b( c0_ram_we_b ),
    .c_ram_data_b( c0_ram_data_b )
);

cpu cpu1 (	
    .clock( clock_50 ),
    .reset_n( c1_reset_n ),
    .cpu_local_id( 1'd1 ),

    .c_ram_addr_a( c1_ram_addr_a ),
    .c_ram_addr_b( c1_ram_addr_b ),
    .ram_c_data_a( ram_c1_data_a ),
    .ram_c_data_b( ram_c1_data_b ),
    .ram_c_en( ram_c1_en ),

    .c_ram_we_b( c1_ram_we_b ),
    .c_ram_data_b( c1_ram_data_b )
);

// Generate a 50 MHz clock
always begin
    #10;
    clock_50 = ~clock_50;
end

// Task for generating master reset 
task master_reset;
begin
    wait (clock_50 !== 1'bx);
    @ (posedge clock_50);
    reset_n = 1'b0;
    ram_c0_data_a = 0;
    ram_c0_data_b = 0;
    ram_c0_en = 0; 
    ram_c1_data_a = 0;
    ram_c1_data_b = 0;
    ram_c1_en = 0; 
    // Activate reset for 1 clock cycle
    @ (posedge clock_50);
    reset_n = 1'b1;
end
endtask

// Initialize signals
initial begin
    clock_50 = 1'b0;
   
    // Apply master reset
    master_reset;

    run_tests;
end

task run_tests;
    // e_ / expected values
    integer e_c0_ram_addr_a, e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, e_c0_ram_data_b;
    integer e_c1_ram_addr_a, e_c1_ram_addr_b, e_ram_c1_data_a, e_ram_c1_data_b, e_c1_ram_we_b, e_c1_ram_data_b;
    integer c0_file, c1_file, errcount;
begin
    c0_file=$fopen("../../cpu0.csv", "r");
    c1_file=$fopen("../../cpu1.csv", "r");


// CPU TESTS 
// the following tests drive the CPU inputs with values from a file (not connected to memory)

    //TEST 0; test one CPU with no memory latency
    //  this test only matters if one core ever runs independently within a compute group 
    //  (TODO: there currently isn't any support for this)
    $display("BEGINNING TEST 0");
    test0(c0_file, 15, errcount);
    if(errcount == 0) $display("test0 passed");
    else $display("test0 failed");

    //TEST 1: test one CPU with arbitrary memory latency 
    //  i.e., stall CPUs by setting ram_c0_en to 0 sometimes
    //  this resembles a global memory write
    $display("BEGINNING TEST 1");
    test1(c0_file, 15, errcount);
    if(errcount == 0) $display("test1 passed");
    else $display("test1 failed");

    //TEST 2: test two CPUs with 1cc memory latency
    $display("BEGINNING TEST 2");
    test2(c0_file, c1_file, 15, errcount);
    if(errcount == 0) $display("test2 passed");
    else $display("test2 failed");

// MEMORY TESTS
// the following tests drive the memory inputs with hard-coded values (not connected to CPU)

    //TEST 3: test normal 2-CPU operation 
    $display("BEGINNING TEST 3");
    test3(errcount);
    if(errcount == 0) $display("test3 passed");
    else $display("test3 failed");

    //TEST 4: test a CPU read from global memory
    //TEST 5: test a CPU write to global memory
    //TEST 6: test io_controller read from local memory
    //TEST 7: test io_controller write to local memory


    $fclose(c0_file);
    $fclose(c1_file);
end
endtask

//file:     the csv file containing expected values from RAM and the CPU
//limit:    the number of clock cycles to run for (not equal to number of instructions)
//errcount: the number of clock cycles in which at least one value was not equal to expected value
task test0;
    input integer file, limit;
    integer e_c0_ram_addr_a, e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, e_c0_ram_data_b, e_state;
    output integer errcount;
begin   
    c1_reset_n = 0;
    errcount = 0;
    $fseek(file, 0, 0);

    @(posedge clock_50);
    c0_reset_n = 0;
    @(posedge clock_50);
    c0_reset_n = 1;

    ram_c0_en = 1;
    for(int i = 0; i < limit; i++) begin
        
        $fscanf(file, "%d,%d,%d,%d,%d,%d,%d\n", e_c0_ram_addr_a, 
                e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, 
                e_c0_ram_data_b, e_state); 
         
        ram_c0_data_a = e_ram_c0_data_a;
        ram_c0_data_b = e_ram_c0_data_b; 

        #1; 
        if( e_c0_ram_addr_a != int'(c0_ram_addr_a) ||
                e_c0_ram_addr_b != int'(c0_ram_addr_b) || 
                e_ram_c0_data_a != int'(ram_c0_data_a) || 
                e_ram_c0_data_b != int'(ram_c0_data_b) || 
                e_c0_ram_we_b != int'(c0_ram_we_b) || 
                e_c0_ram_data_b != int'(c0_ram_data_b) ) begin
            $display("ERROR: in cycle: %d\n\tcsv:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n\tcpu:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n",
                    i, e_c0_ram_addr_a, e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, e_c0_ram_data_b, e_state,
                    int'(c0_ram_addr_a), int'(c0_ram_addr_b), int'(ram_c0_data_a), int'(ram_c0_data_b), int'(c0_ram_we_b), 
                    int'(c0_ram_data_b), int'(cpu0.state));
            errcount = errcount + 1;
        end
        @(posedge clock_50);
    end
    ram_c1_en = 0;
end
endtask

task test1;
    input integer file, limit;
    integer e_c0_ram_addr_a, e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, e_c0_ram_data_b, e_state;
    output integer errcount;
begin
    c1_reset_n = 0;
    errcount = 0;
    ram_c0_en = 0;
    for(int latency = 1; latency < 4; latency++) begin
        $fseek(file, 0, 0);

        @(posedge clock_50);
        c0_reset_n = 0;
        @(posedge clock_50);
        c0_reset_n = 1;
        
        for(int i = 0; i < limit; i++) begin
            $fscanf(file, "%d,%d,%d,%d,%d,%d,%d\n", e_c0_ram_addr_a, 
                    e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, 
                    e_c0_ram_data_b, e_state); 
            
            //make the cpu wait for the ram data
            ram_c0_en = 0;
            for(int j = 0; j < latency; j++) begin
                @(posedge clock_50);
            end
            ram_c0_en = 1;
            ram_c0_data_a = e_ram_c0_data_a;
            ram_c0_data_b = e_ram_c0_data_b; 

            #1; 
            if( e_c0_ram_addr_a != int'(c0_ram_addr_a) ||
                    e_c0_ram_addr_b != int'(c0_ram_addr_b) || 
                    e_ram_c0_data_a != int'(ram_c0_data_a) || 
                    e_ram_c0_data_b != int'(ram_c0_data_b) || 
                    e_c0_ram_we_b != int'(c0_ram_we_b) || 
                    e_c0_ram_data_b != int'(c0_ram_data_b) ) begin
                $display("ERROR: in cycle:%d with latency:%d\n\tcsv:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n\tcpu:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n",
                        i, latency, e_c0_ram_addr_a, e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, e_c0_ram_data_b, e_state,
                        int'(c0_ram_addr_a), int'(c0_ram_addr_b), int'(ram_c0_data_a), int'(ram_c0_data_b), int'(c0_ram_we_b), 
                        int'(c0_ram_data_b), int'(cpu0.state));
                errcount = errcount + 1;
            end
            @(posedge clock_50);
        end
    end
    ram_c0_en = 0;
end
endtask

task test2;
    input integer c0_file, c1_file, limit;
    integer e_c0_ram_addr_a, e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, e_c0_ram_data_b, e_c0_state;
    integer e_c1_ram_addr_a, e_c1_ram_addr_b, e_ram_c1_data_a, e_ram_c1_data_b, e_c1_ram_we_b, e_c1_ram_data_b, e_c1_state;
    output integer errcount;
begin   
    errcount = 0;
    $fseek(c0_file, 0, 0);
    $fseek(c1_file, 0, 0);

    @(posedge clock_50);
    c0_reset_n = 0;
    c1_reset_n = 0;
    @(posedge clock_50);
    c0_reset_n = 1;
    c1_reset_n = 1;


    for(int i = 0; i < limit; i++) begin
        ram_c0_en = 1;
        ram_c1_en = 0;
        $fscanf(c0_file, "%d,%d,%d,%d,%d,%d,%d\n", e_c0_ram_addr_a, 
                e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, 
                e_c0_ram_data_b, e_c0_state); 
         
        ram_c0_data_a = e_ram_c0_data_a;
        ram_c0_data_b = e_ram_c0_data_b; 

        #1; 
        if( e_c0_ram_addr_a != int'(c0_ram_addr_a) ||
                e_c0_ram_addr_b != int'(c0_ram_addr_b) || 
                e_ram_c0_data_a != int'(ram_c0_data_a) || 
                e_ram_c0_data_b != int'(ram_c0_data_b) || 
                e_c0_ram_we_b != int'(c0_ram_we_b) || 
                e_c0_ram_data_b != int'(c0_ram_data_b) ) begin
            $display("ERROR: in cycle: %d\n\tcsv:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n\tcpu:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n",
                    i, e_c0_ram_addr_a, e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, e_c0_ram_data_b, e_c0_state,
                    int'(c0_ram_addr_a), int'(c0_ram_addr_b), int'(ram_c0_data_a), int'(ram_c0_data_b), int'(c0_ram_we_b), 
                    int'(c0_ram_data_b), int'(cpu0.state));
            errcount = errcount + 1;
        end
        @(posedge clock_50);
        ram_c0_en = 0;
        ram_c1_en = 1;
        $fscanf(c1_file, "%d,%d,%d,%d,%d,%d,%d\n", e_c1_ram_addr_a, 
                e_c1_ram_addr_b, e_ram_c1_data_a, e_ram_c1_data_b, e_c1_ram_we_b, 
                e_c1_ram_data_b, e_c1_state); 
         
        ram_c1_data_a = e_ram_c1_data_a;
        ram_c1_data_b = e_ram_c1_data_b; 

        #1; 
        if( e_c1_ram_addr_a != int'(c1_ram_addr_a) ||
                e_c1_ram_addr_b != int'(c1_ram_addr_b) || 
                e_ram_c1_data_a != int'(ram_c1_data_a) || 
                e_ram_c1_data_b != int'(ram_c1_data_b) || 
                e_c1_ram_we_b != int'(c1_ram_we_b) || 
                e_c1_ram_data_b != int'(c1_ram_data_b) ) begin
            $display("ERROR: in cycle: %d\n\tcsv:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n\tcpu:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n",
                    i, e_c1_ram_addr_a, e_c1_ram_addr_b, e_ram_c1_data_a, e_ram_c1_data_b, e_c1_ram_we_b, e_c1_ram_data_b, e_c1_state,
                    int'(c1_ram_addr_a), int'(c1_ram_addr_b), int'(ram_c1_data_a), int'(ram_c1_data_b), int'(c1_ram_we_b), 
                    int'(c1_ram_data_b), int'(cpu0.state));
            errcount = errcount + 1;
        end
        @(posedge clock_50);
    end
    ram_c0_en = 0;
    ram_c1_en = 0;
end
endtask

endmodule
