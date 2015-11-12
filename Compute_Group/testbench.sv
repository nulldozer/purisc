`timescale 1ns / 1ns
// `include "io_controller/ethmac/rtl/verilog/timescale.v"
`default_nettype none
//`include "project_includes.v"
// ACRONYMS:
//  cg   compute group
//  gm   global magic
//  iomc io_memory_controller

// NAMING CONVENTION:
//  source_dest_purpose
//  e.g. cg_gm_address_a
//  e.g. gm_cg_data_a

module compute_group_testbench;

/// 
/// regs/wires/assigns 
///
logic Clock_50;
logic reset_n;
logic [31:0] cg_gm_address_a; 
logic [31:0] cg_gm_address_b; 
logic [31:0] cg_gm_address_c; 
logic [31:0] cg_gm_address_0; 
logic [31:0] cg_gm_address_1; 
logic [31:0] cg_gm_address_w; 
logic [31:0] iomc_cg_address_w; 
logic [31:0] iomc_cg_data_w;
logic iomc_cg_en; 
logic [31:0] cg_gm_data; 
logic cg_gm_w_en; 
reg tb_cg_reset_n;
logic cg_gm_en; 
logic [1:0] tb_cg_ident; 
logic [31:0] gm_cg_data_a; 
logic [31:0] gm_cg_data_b; 
logic [31:0] gm_cg_data_c; 
logic [31:0] gm_cg_data_0; 
logic [31:0] gm_cg_data_1; 
logic gm_cg_stall;

// Instantiate the unit under test
Compute_Group cg (	
    .ADDRESS_A(cg_gm_address_a),    //out to global magic
    .ADDRESS_B(cg_gm_address_b),    //out "
    .ADDRESS_C(cg_gm_address_c),    //out "
    .ADDRESS_0(cg_gm_address_0),    //out "
    .ADDRESS_1(cg_gm_address_1),    //out "
    .ADDRESS_W(cg_gm_address_w),    //out "
    .ADDRESS_IO(iomc_cg_address_w), //in from io_memory_controller
    .DATA_IO(iomc_cg_data_w),      //in "
    .IO_ENABLE(iomc_cg_en),         //in "
    .DATA_TO_W(cg_gm_data),     //out to global magic
    .W_EN(cg_gm_w_en),          //out "
    .CLK(Clock_50),         //in from testbench
    .RESET_n(tb_cg_reset_n),      //in "
    .GLOBAL_EN(cg_gm_en),   //out - WATCH THIS (shouldn't go high)
    .IDENT_IN(tb_cg_ident),     //in from testbench
    .DATA_OUT_A(gm_cg_data_a),  //in from global magic
    .DATA_OUT_B(gm_cg_data_b),  //in "
    .DATA_OUT_C(gm_cg_data_c),  //in "
    .DATA_OUT_0(gm_cg_data_0),  //in "
    .DATA_OUT_1(gm_cg_data_1),  //in " 
    .STALL_GLOB(gm_cg_stall)    //in "
);

// Generate a 50 MHz clock
always begin
    #10;
    Clock_50 = ~Clock_50;
end

// Task for generating master reset
task master_reset;
begin
    wait (Clock_50 !== 1'bx);
    @ (posedge Clock_50);
    reset_n = 1'b0;
    // Activate reset for 1 clock cycle
    @ (posedge Clock_50);
    reset_n = 1'b1;
end
endtask

// Initialize signals
initial begin
    Clock_50 = 1'b0;
   
   // Set any hardcoded inputs before reset
    iomc_cg_address_w = 0;
    iomc_cg_data_w = 0;
    iomc_cg_en = 0;
    tb_cg_ident = 0;
    gm_cg_data_a = 0;
    gm_cg_data_b = 1;
    gm_cg_data_c = 2;
    gm_cg_data_0 = 3;
    gm_cg_data_1 = 4;
    gm_cg_stall = 0; //TODO: check if this needs some special sequence?
    //keep cg off until tests begin
    tb_cg_reset_n = 0;
    
    // Apply master reset
    master_reset;

    run_tests;
end


task run_tests;
begin
    //  use these functions
    // $display("OPENING FILE: ../../machine_code/combined_updown.machine\n");
    // data_file = $fopen("../../machine_code/combined_updown.machine", "r");
    // $fseek(data_file, sd, 0);
    
    //TEST 0: run initial RAM contents properly
    //  expected: each core executes its own independent program in agreement with simulation
    //  
    //  in order to use the same MIF as other test cases, this testcase uses the bootloader MIF
    //  files with the ready flat set TO 1 (TODO: is this right?) and with executable code after them which is
    //  later overwritten by the io_controller in later test cases
    test0;
    //TEST 1: write to local memory, but don't execute
    //  expected: bootloader continues to loop without any issue

    //TEST 2: write executable code to local memory, set flags
    //  expected: BOTH cores branch to executable code, start running in infinite loops

    //TEST 3: write executable code to memory, run it, send return value back to io_controller
    //  expected: cores individually set flags upon completion, branch back to bootloader

end
endtask


task test0;
    integer core_0_cycle,core_1_cycle,result_0,result_1,f_csv_core_0,f_csv_core_1;
    integer c;
//    logic [31:0] c;
    logic [31:0] r_addr_a;
    logic [31:0] r_addr_b;
    logic [31:0] r_addr_c;   
    logic [31:0] r_data_a;
    logic [31:0] r_data_b; 
    logic [31:0] r_data_c; 
    logic [31:0] r_addr_0; 
    logic [31:0] r_addr_1;
    logic [31:0] r_data_0;
    logic [31:0] r_data_1;
    logic we;
    logic [31:0] w_data; 
    logic [31:0] w_addr;
begin
    $display("::::::::::::::::::::::::::::::::");
    $display(":: TEST 0: run programs independently on two CPUs");
    $display("::::::::::::::::::::::::::::::::\n");
    tb_cg_reset_n=1;
    
    $display("loading csv file");
    f_csv_core_0=$fopen("../../tests/0/csv/cpu0.csv", "r");
    f_csv_core_1=$fopen("../../tests/0/csv/cpu1.csv", "r");
    if(f_csv_core_0 == 0) begin
        $display("f_csv_core_0 is NULL");
    end 
    if(f_csv_core_1 == 0) begin
        $display("f_csv_core_1 is NULL");
    end 
    core_0_cycle=0;
    core_1_cycle=0;
    do begin
        @(posedge Clock_50);
       
        //if cpu0 isn't stalled
        if(cg.core_0.stall == 0) begin
            //get ideal values for CPU0 from CSV
            result_0=$fscanf(f_csv_core_0, "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n", 
                    c,r_addr_a,r_addr_b,r_addr_c,   r_data_a,r_data_b, r_data_c, 
                    r_addr_0, r_addr_1,   r_data_0, r_data_1,
                    we, w_data, w_addr
            );
            //compare to actual values of cg.core_0
            if(c != core_0_cycle) begin
                $display("error: cycle:%03d\ti:%3d",c,core_0_cycle);
            end
            if (r_addr_a != cg.core_0.r_addr_a) begin
                $display("error: cycle:%03d\tr_addr_a:0x%8x\tcg.core_0.r_addr_a:0x%8x",c,r_addr_a,cg.core_0.r_addr_a);
            end 
            if (r_addr_b != cg.core_0.r_addr_b) begin
                $display("error: cycle:%03d\tr_addr_b:0x%8x\tcg.core_0.r_addr_b:0x%8x",c,r_addr_b,cg.core_0.r_addr_b);  
            end 
            if (r_addr_c != cg.core_0.r_addr_c) begin
                $display("error: cycle:%03d\tr_addr_c:0x%8x\tcg.core_0.r_addr_c:0x%8x",c,r_addr_c,cg.core_0.r_addr_c);  
            end 
            if (r_addr_0 != cg.core_0.r_addr_0) begin
                $display("error: cycle:%03d\tr_addr_0:0x%8x\tcg.core_0.r_addr_0:0x%8x",c,r_addr_0,cg.core_0.r_addr_0);  
            end 
            if (r_addr_1 != cg.core_0.r_addr_1) begin
                $display("error: cycle:%03d\tr_addr_1:0x%8x\tcg.core_0.r_addr_1:0x%8x",c,r_addr_1,cg.core_0.r_addr_1);  
            end 
            if (r_data_a != cg.core_0.r_data_a) begin
                $display("error: cycle:%03d\tr_data_a:0x%8x\tcg.core_0.r_data_a:0x%8x",c,r_data_a,cg.core_0.r_data_a);  
            end 
            if (r_data_b != cg.core_0.r_data_b) begin
                $display("error: cycle:%03d\tr_data_b:0x%8x\tcg.core_0.r_data_b:0x%8x",c,r_data_b,cg.core_0.r_data_b);  
            end 
            if (r_data_c != cg.core_0.r_data_c) begin
                $display("error: cycle:%03d\tr_data_c:0x%8x\tcg.core_0.r_data_c:0x%8x",c,r_data_c,cg.core_0.r_data_c);  
            end 
            if (r_data_0 != cg.core_0.r_data_0) begin
                $display("error: cycle:%03d\tr_data_0:0x%8x\tcg.core_0.r_data_0:0x%8x",c,r_data_0,cg.core_0.r_data_0);  
            end 
            if (r_data_1 != cg.core_0.r_data_1) begin
                $display("error: cycle:%03d\tr_data_1:0x%8x\tcg.core_0.r_data_1:0x%8x",c,r_data_1,cg.core_0.r_data_1);  
            end 
            if (we != cg.core_0.we) begin
                $display("error: cycle:%03d\twe:0x%8x\tcg.core_0.we:0x%8x\n",c,we,cg.core_0.we);
            end 
            if (w_data != cg.core_0.w_data) begin
                $display("error: cycle:%03d\tw_data:0x%8x\tcg.core_0.w_data:0x%8x",c,w_data,cg.core_0.w_data);
            end 
            if (w_addr != cg.core_0.w_addr) begin
                $display("error: cycle:%03d\tw_addr:0x%8x\tcg.core_0.w_addr:0x%8x",c,w_addr,cg.core_0.w_addr);
            end
            $display("\n");
            core_0_cycle=core_0_cycle+1;
        end

        if(cg.core_1.stall == 0) begin
            //get ideal values for CPU1 from CSV
            result_1=$fscanf(f_csv_core_1, "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n", 
                    c,r_addr_a,r_addr_b,r_addr_c,   r_data_a,r_data_b, r_data_c, 
                    r_addr_0, r_addr_1,   r_data_0, r_data_1,
                    we, w_data, w_addr
            );
            if(c != core_1_cycle) begin
                $display("error: cycle:%03d\ti:%3d",c,core_1_cycle);
            end 
            //compare to actual values of cg.core_1
            if (r_addr_a != cg.core_1.r_addr_a) begin
                $display("error: cycle:%03d\tr_addr_a:0x%8x\tcg.core_1.r_addr_a:0x%8x",c,r_addr_a,cg.core_1.r_addr_a);
            end 
            if (r_addr_b != cg.core_1.r_addr_b) begin
                $display("error: cycle:%03d\tr_addr_b:0x%8x\tcg.core_1.r_addr_b:0x%8x",c,r_addr_b,cg.core_1.r_addr_b);  
            end 
            if (r_addr_c != cg.core_1.r_addr_c) begin
                $display("error: cycle:%03d\tr_addr_c:0x%8x\tcg.core_1.r_addr_c:0x%8x",c,r_addr_c,cg.core_1.r_addr_c);  
            end 
            if (r_addr_0 != cg.core_1.r_addr_0) begin
                $display("error: cycle:%03d\tr_addr_0:0x%8x\tcg.core_1.r_addr_0:0x%8x",c,r_addr_0,cg.core_1.r_addr_0);  
            end 
            if (r_addr_1 != cg.core_1.r_addr_1) begin
                $display("error: cycle:%03d\tr_addr_1:0x%8x\tcg.core_1.r_addr_1:0x%8x",c,r_addr_1,cg.core_1.r_addr_1);  
            end 
            if (r_data_a != cg.core_1.r_data_a) begin
                $display("error: cycle:%03d\tr_data_a:0x%8x\tcg.core_1.r_data_a:0x%8x",c,r_data_a,cg.core_1.r_data_a);  
            end 
            if (r_data_b != cg.core_1.r_data_b) begin
                $display("error: cycle:%03d\tr_data_b:0x%8x\tcg.core_1.r_data_b:0x%8x",c,r_data_b,cg.core_1.r_data_b);  
            end 
            if (r_data_c != cg.core_1.r_data_c) begin
                $display("error: cycle:%03d\tr_data_c:0x%8x\tcg.core_1.r_data_c:0x%8x",c,r_data_c,cg.core_1.r_data_c);  
            end 
            if (r_data_0 != cg.core_1.r_data_0) begin
                $display("error: cycle:%03d\tr_data_0:0x%8x\tcg.core_1.r_data_0:0x%8x",c,r_data_0,cg.core_1.r_data_0);  
            end 
            if (r_data_1 != cg.core_1.r_data_1) begin
                $display("error: cycle:%03d\tr_data_1:0x%8x\tcg.core_1.r_data_1:0x%8x",c,r_data_1,cg.core_1.r_data_1);  
            end 
            if (we != cg.core_1.we) begin
                $display("error: cycle:%03d\twe:0x%8x\tcg.core_1.we:0x%8x\n",c,we,cg.core_1.we);
            end 
            if (w_data != cg.core_1.w_data) begin
                $display("error: cycle:%03d\tw_data:0x%8x\tcg.core_1.w_data:0x%8x",c,w_data,cg.core_1.w_data);
            end 
            if (w_addr != cg.core_1.w_addr) begin
                $display("error: cycle:%03d\tw_addr:0x%8x\tcg.core_1.w_addr:0x%8x",c,w_addr,cg.core_1.w_addr);
            end
            $display("\n");
            core_1_cycle=core_1_cycle+1;
        end
    end while (!$feof(f_csv_core_0) && !$feof(f_csv_core_1));
    $fclose(f_csv_core_0);
    $fclose(f_csv_core_1);
    #20;
    tb_cg_reset_n=0;
end
endtask

endmodule
