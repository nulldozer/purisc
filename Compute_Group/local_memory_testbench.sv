`timescale 1ns / 1ns
`default_nettype none

module local_memory_testbench;

/// 
/// regs/wires/assigns 
///
logic clock_50;
logic reset_n;

//connections to CPUs
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


//connections to local mem
logic lm_reset_n;
logic [16:0] lm_ioc_addr;
logic ioc_lm_re;  // ioc reads from lm
logic [31:0] lm_ioc_data;
logic ioc_lm_we;  // ioc writes to lm
logic ioc_lm_addr;
logic [31:0] ioc_lm_data;
logic [16:0] lm_gm_addr;
logic [31:0] lm_gm_data; // lm writes to gm
logic lm_gm_we;
logic lm_gm_re;   // lm reads from gm
logic [31:0] gm_lm_data;
logic [16:0] c0_lm_addr_a;
logic [16:0] c0_lm_addr_b;
logic [31:0] lm_c0_data_a;
logic [31:0] lm_c0_data_b;
logic [31:0] c0_lm_data_b;
logic c0_lm_we_b;   
logic [16:0] c1_lm_addr_a;
logic [16:0] c1_lm_addr_b;
logic [31:0] lm_c1_data_a;
logic [31:0] lm_c1_data_b;
logic [31:0] c1_lm_data_b;
logic c1_lm_we_b;   

local_memory (
    .clock_50(clock_50),
    .reset_n(reset_n),
    
    .lm_ioc_addr(lm_ioc_addr),
    .ioc_lm_re(ioc_lm_re),  // ioc reads from lm
    .lm_ioc_data(lm_ioc_data),
    .ioc_lm_we(ioc_lm_we),  // ioc writes to lm
    .ioc_lm_addr(ioc_lm_addr),
    .ioc_lm_data(ioc_lm_data),

    .lm_gm_addr(lm_gm_addr),
    .lm_gm_data(lm_gm_data), // lm writes to gm
    .lm_gm_we(lm_gm_we),
    .lm_gm_re(lm_gm_re),   // lm reads from gm
    .gm_lm_data(gm_lm_data),

    .c0_lm_addr_a(c0_lm_addr_a),
    .c0_lm_addr_b(c0_lm_addr_b),
    .lm_c0_data_a(lm_c0_data_a), //cpu reads from lm
    .lm_c0_data_b(lm_c0_data_b),
    .c0_lm_data_b(c0_lm_data_b), //cpu writes to lm (only one port)
    .c0_lm_we_b(c0_lm_we_b),
    
    .c1_lm_addr_a(c1_lm_addr_a),
    .c1_lm_addr_b(c1_lm_addr_b),
    .lm_c1_data_a(lm_c1_data_a), //cpu reads from lm
    .lm_c1_data_b(lm_c1_data_b),
    .c1_lm_data_b(c1_lm_data_b), //cpu writes to lm (only one port)
    .c1_lm_we_b(c1_lm_we_b)
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

    //TEST 0: test normal 2-CPU operation 
    $display("BEGINNING TEST 3");
    test3(errcount);
    if(errcount == 0) $display("test3 passed");
    else $display("test3 failed");

    //TEST 1: test a CPU read from global memory
    //TEST 2: test a CPU write to global memory
    //TEST 3: test io_controller read from local memory
    //TEST 4: test io_controller write to local memory


    $fclose(c0_file);
    $fclose(c1_file);
end
endtask

task test0;
    input integer c0_file, c1_file, limit;
    integer e_c0_ram_addr_a, e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, e_c0_ram_data_b, e_c0_state;
    integer e_c1_ram_addr_a, e_c1_ram_addr_b, e_ram_c1_data_a, e_ram_c1_data_b, e_c1_ram_we_b, e_c1_ram_data_b, e_c1_state;
    output integer errcount;
begin   
    errcount = 0;
    $fseek(c0_file, 0, 0);
    $fseek(c1_file, 0, 0);


    for(int i = 0; i < limit; i++) begin
        ram_c0_en = 1;
        ram_c1_en = 0;
        $fscanf(c0_file, "%d,%d,%d,%d,%d,%d,%d\n", e_c0_ram_addr_a, 
                e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, 
                e_c0_ram_data_b, e_c0_state); 
         
        c0_ram_addr_a = e_c0_ram_addr_a;
        c0_ram_addr_b = e_c0_ram_addr_b;
        c0_ram_we_b = e_c0_ram_we_b;
        c0_ram_data_b = e_c0_ram_data_b;

        #1; 
        if( e_c0_ram_addr_a != int'(c0_ram_addr_a) ||
                e_c0_ram_addr_b != int'(c0_ram_addr_b) || 
                e_ram_c0_data_a != int'(ram_c0_data_a) || 
                e_ram_c0_data_b != int'(ram_c0_data_b) || 
                e_c0_ram_we_b != int'(c0_ram_we_b) || 
                e_c0_ram_data_b != int'(c0_ram_data_b) ) begin
            $display("ERROR: in cycle: %d\n\tcsv:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n\tram:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n",
                    i, e_c0_ram_addr_a, e_c0_ram_addr_b, e_ram_c0_data_a, e_ram_c0_data_b, e_c0_ram_we_b, e_c0_ram_data_b, e_c0_state,
                    int'(c0_ram_addr_a), int'(c0_ram_addr_b), int'(ram_c0_data_a), int'(ram_c0_data_b), int'(c0_ram_we_b), 
                    int'(c0_ram_data_b), int'(cpu0.state));
            errcount = errcount + 1;
        end
        @(posedge clock_50);
        $fscanf(c1_file, "%d,%d,%d,%d,%d,%d,%d\n", e_c1_ram_addr_a, 
                e_c1_ram_addr_b, e_ram_c1_data_a, e_ram_c1_data_b, e_c1_ram_we_b, 
                e_c1_ram_data_b, e_c1_state); 
         
        c1_ram_addr_a = e_c1_ram_addr_a;
        c1_ram_addr_b = e_c1_ram_addr_b;
        c1_ram_we_b = e_c1_ram_we_b;
        c1_ram_data_b = e_c1_ram_data_b;

        #1; 
        if( e_c1_ram_addr_a != int'(c1_ram_addr_a) ||
                e_c1_ram_addr_b != int'(c1_ram_addr_b) || 
                e_ram_c1_data_a != int'(ram_c1_data_a) || 
                e_ram_c1_data_b != int'(ram_c1_data_b) || 
                e_c1_ram_we_b != int'(c1_ram_we_b) || 
                e_c1_ram_data_b != int'(c1_ram_data_b) ) begin
            $display("ERROR: in cycle: %d\n\tcsv:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n\tram:\t%8d,%8d,%8d,%8d,%8d,%8d,%8d\n",
                    i, e_c1_ram_addr_a, e_c1_ram_addr_b, e_ram_c1_data_a, e_ram_c1_data_b, e_c1_ram_we_b, e_c1_ram_data_b, e_c1_state,
                    int'(c1_ram_addr_a), int'(c1_ram_addr_b), int'(ram_c1_data_a), int'(ram_c1_data_b), int'(c1_ram_we_b), 
                    int'(c1_ram_data_b), int'(cpu0.state));
            errcount = errcount + 1;
        end
        @(posedge clock_50);
    end
end
endtask

endmodule
