import core_pkg::*;
module core_fetch_stage
(
    input  logic                            clk,          // clock
    input  logic                            rst,          // reset
    input  logic                            fetch_stall,  // stall 
    input  logic  [ADDR_WIDTH  - 1: 0]      new_pc,       // new pc value for branch instruction
    input  logic                            is_branch,    // control signal for branch instruction     
    output logic  [INSTR_WIDTH  - 1: 0]     instr,        // fetched instruction
    output logic  [DATA_WIDTH     - 1: 0]   cur_pc,       // current pc

    // AXI_lite READ channel
    input  logic  [DATA_WIDTH-1:0]     RDATA,
    input  logic                       RVALID,
    output logic                       RREADY,
    
    //AXI_lite READ ADDR channel
    input  logic                       ARREADY,
    output logic  [ADDR_WIDTH-1:0]     ARADDR,
    output logic                       ARVALID
);
    logic [31:0] pc_value;

    logic                       memory_stall;
    logic [ADDR_WIDTH-1:0]      pc_write;
    logic                       pc_write_en;

    instruction_fetch_unit IFU0(
        .clk          (clk         ),
        .rst          (rst         ),
        .is_branch    (is_branch   ),
        .fetch_stall  (fetch_stall ),
        .pc_write     (pc_write    ),
        .pc_write_en  (pc_write_en ),
        .RVALID       (RVALID      ),
        .new_pc       (new_pc      ),
        .pc_value     (pc_value    )
    );
    
    always_ff @(posedge clk) 
    begin
        if(!rst) begin
            ARVALID <= 'b0;
            ARADDR  <= 'b0;
            RREADY  <= 'b0;
            memory_stall <= 1'b0;
            pc_write_en  <= 1'b0;
            cur_pc  <= 'b0;
        end
        else if(fetch_stall) begin
            ARVALID         <= 'b0;
            ARADDR          <= cur_pc >> 2;
            RREADY          <= 'b0;
            pc_write        <= cur_pc + 4;
            pc_write_en     <= 1'b1;
            memory_stall    <= 1;
        end
        else if(memory_stall) begin
            memory_stall    <= 1'b0;
            pc_write        <= pc_value + 4;
            cur_pc          <= pc_value + 4;
            pc_write_en     <= 1'b1;
        end
        else if(ARREADY & ARVALID) begin
            RREADY          <= 1'b1;
            ARVALID         <= 1'b0;
            pc_write_en     <= 1'b0;
        end
        else if(RREADY & RVALID) begin
            RREADY          <= 1'b0;
            pc_write_en     <= 1'b0;
        end
        else if(is_branch) begin
            ARVALID         <= 'b0;
            pc_write_en     <= 1'b0;
        end
        else if(ARREADY & !memory_stall) begin
            ARVALID         <= 1'b1;
            ARADDR          <= pc_value >> 2;
            cur_pc          <= pc_value;
            pc_write_en     <= 1'b0;
        end
    end

    assign instr        = RDATA;
endmodule