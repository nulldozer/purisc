module cpu (
    clock,
    reset_n,
    cpu_local_id,

    c_ram_addr_a,
    c_ram_addr_b,
    ram_c_data_a,
    ram_c_data_b,
    ram_c_en, //this indicates that data will be ready on next cycle

    c_ram_we_b,
    c_ram_data_b,
);

input logic clock;
input logic reset_n;
input logic cpu_local_id;

output logic [16:0] c_ram_addr_a;
output logic [16:0] c_ram_addr_b;
input logic [31:0] ram_c_data_a;
input logic [31:0] ram_c_data_b;
input logic ram_c_en;

output logic c_ram_we_b;
output logic [31:0] c_ram_data_b;

reg [12:0] pc;
reg hold_state;
reg [16:0] c_ram_addr_a_hold;
reg [16:0] c_ram_addr_b_hold;
reg [16:0] c_ram_we_b_hold;
reg [16:0] c_ram_data_b_hold;
reg branch;

enum integer {S_F=0, S_D=1, S_X=2} state;

//state change logic
always_ff @(posedge clock or negedge reset_n) begin
    if(reset_n == 0) begin
        if(cpu_local_id == 0) begin
            pc=0;
        end else begin
            pc=13'd4096;
        end
        hold_state = 0;
        branch = 0;
        state = S_F;

        c_ram_addr_a_hold <= 0;
        c_ram_addr_b_hold <= 0;
        c_ram_data_b_hold <= 0;
        c_ram_we_b_hold <= 0;
    end else begin  
        if(ram_c_en) begin
            hold_state <= 0;
            
            c_ram_addr_a_hold <= c_ram_addr_a;
            c_ram_addr_b_hold <= c_ram_addr_b;
            c_ram_data_b_hold <= c_ram_data_b;
            c_ram_we_b_hold <= c_ram_we_b;
        end else if(hold_state == 0) begin
            hold_state <= 1;
        end

        case (state) 
            S_F: begin
                if(ram_c_en) begin
                    state <= S_D;

                    if(branch) begin
                        pc <= ram_c_data_a;
                    end
                end
            end
            S_D: begin
                if(ram_c_en) begin
                    state <= S_X;
                end 
            end
            S_X: begin
                if(ram_c_en) begin
                    state <= S_F;

                    if(ram_c_data_b - ram_c_data_a <= 0) begin
                        branch <= 1;
                    end else begin
                        branch <= 0;
                        pc <= pc+3;
                    end
                end
            end
        endcase
    end
end
//output logic
always_comb begin
    if(ram_c_en == 0 || reset_n == 0) begin
        c_ram_addr_a = c_ram_addr_a_hold;
        c_ram_addr_b = c_ram_addr_b_hold;
        c_ram_we_b = c_ram_we_b_hold;
        c_ram_data_b = c_ram_data_b_hold;
    end else begin
        case (state)
            S_F: begin
                c_ram_data_b = 32'h0abc;
                c_ram_we_b = 0;

                if(branch) begin 
                    c_ram_addr_a = ram_c_data_a;
                    c_ram_addr_b = ram_c_data_a+1;
                end else begin
                    c_ram_addr_a = pc;
                    c_ram_addr_b = pc+1;
                end
            end
            S_D: begin
                c_ram_data_b = 32'h0123;
                c_ram_we_b = 0;

                c_ram_addr_a = ram_c_data_a;
                c_ram_addr_b = ram_c_data_b;
            end
            S_X: begin
                c_ram_data_b = ram_c_data_b - ram_c_data_a;
                c_ram_we_b = 1;

                c_ram_addr_a = pc+2;
                c_ram_addr_b = 0; //arbitrary value
            end
            default begin

            end
        endcase
    end
end
endmodule 

