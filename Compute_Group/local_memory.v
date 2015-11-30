module local_memory (
    clock_50,
    reset_n,
    
    //connections to io controller
    lm_ioc_addr,
    ioc_lm_re,  // ioc reads from lm
    lm_ioc_data,
    ioc_lm_we,  // ioc writes to lm
    ioc_lm_addr,
    ioc_lm_data,

    //connections to global memory
    lm_gm_addr,
    lm_gm_data, // lm writes to gm
    lm_gm_we,
    lm_gm_re,   // lm reads from gm
    gm_lm_data,

    //connections to cpu0
    c0_lm_addr_a,
    c0_lm_addr_b,
    lm_c0_data_a, //cpu reads from lm
    lm_c0_data_b,
    c0_lm_data_b, //cpu writes to lm (only one port)
    c0_lm_we_b,
    
    //connections to cpu1
    c1_lm_addr_a,
    c1_lm_addr_b,
    lm_c1_data_a, //cpu reads from lm
    lm_c1_data_b,
    c1_lm_data_b, //cpu writes to lm (only one port)
    c1_lm_we_b
);
input clock_50;
input reset_n;

//connections to io controller
output [16:0] lm_ioc_addr;
input ioc_lm_re;  // ioc reads from lm
output [31:0] lm_ioc_data;
input ioc_lm_we;  // ioc writes to lm
input ioc_lm_addr;
input [31:0] ioc_lm_data;

//connections to global memory
output [16:0] lm_gm_addr;
output [31:0] lm_gm_data; // lm writes to gm
output lm_gm_we;
output lm_gm_re;   // lm reads from gm
input [31:0] gm_lm_data;

//connections to cpu0
output [16:0] c0_lm_addr_a;
output [16:0] c0_lm_addr_b;
input [31:0] lm_c0_data_a;
input [31:0] lm_c0_data_b;
output [31:0] c0_lm_data_b;
output c0_lm_we_b;   

//connections to cpu1
output [16:0] c1_lm_addr_a;
output [16:0] c1_lm_addr_b;
input [31:0] lm_c1_data_a;
input [31:0] lm_c1_data_b;
output [31:0] c1_lm_data_b;
output c1_lm_we_b;   

reg [12:0] lm_ram_addr_a;
reg [12:0] lm_ram_addr_b;
reg lm_ram_wren_a;
reg lm_ram_wren_b;
reg [31:0] lm_ram_data_a;
reg [31:0] lm_ram_data_b;
reg [31:0] ram_lm_data_a;
reg [31:0] ram_lm_data_b;

local_RAM ram(
    .address_a(lm_ram_addr_a),
    .address_b(lm_ram_addr_b),
    .clock(clock_50),
    .data_a(lm_ram_data_a),
    .data_b(lm_ram_data_b),
    .wren_a(lm_ram_wren_a),
    .wren_b(lm_ram_wren_b),
    .q_a(ram_lm_data_a),
    .q_b(ram_lm_data_b)
);

reg [1:0] state;

always_ff @(posedge clock_50 or negedge reset_n) begin
    case(state) 
        0: begin
            if(
        end
        1: begin

        end 
        2: begin

        end
        default begin
        end
    endcase
end

always_comb begin

end

endmodule
