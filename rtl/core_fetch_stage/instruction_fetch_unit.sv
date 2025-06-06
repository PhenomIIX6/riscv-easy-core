import core_pkg::*; // package with INSTR_WIDTH, DATA_WIDTH, REG_WIDTH and ADDR_WIDTH
module instruction_fetch_unit 
(
    input  logic                     clk,          // clock
    input  logic                     rst,          // reset
    
    input  logic  [ADDR_WIDTH - 1: 0]new_pc,        // new pc value for branch instruction
    input  logic                     is_branch,
    input  logic                     fetch_stall,

    input  logic  [ADDR_WIDTH-1:0]   pc_write,
    input  logic                     pc_write_en,
	 
    input  logic                     RVALID,

    output logic  [ADDR_WIDTH - 1: 0]pc_value       // pc value
);
    logic [ADDR_WIDTH-1:0] pc; // pc register

    typedef enum logic [1:0] {
        State_zero            = 2'b00,    // Reset PC
        State_wait            = 2'b01,    // Save PC
        State_free_pipe       = 2'b10,    // Update PC
        State_is_branch       = 2'b11
    } statetype;
    statetype state, nextstate;
     

    always_comb     // FSM
    begin
        nextstate = state;
        case(state)
            State_zero:                                             nextstate = State_free_pipe;
            State_wait:      if(RVALID)                             nextstate = State_free_pipe;
            State_is_branch:                                        nextstate = State_wait;
            State_free_pipe:                                        nextstate = is_branch ? State_is_branch : State_wait;
            default:                                                nextstate = State_zero;
        endcase
    end
    
    always_ff @(posedge clk) // FSM
    begin
        case(state)
            State_zero:      pc <= pc_write_en ? pc_write : 32'b0;
            State_wait:      pc <= pc_write_en ? pc_write : pc;
            State_is_branch: pc <= pc_write_en ? pc_write : pc + 4;
            State_free_pipe: pc <= pc_write_en ? pc_write : (is_branch ? new_pc : pc + 4); // branch_instruction or next_instruction
            default:         pc <= 32'b0;                               
        endcase
    end

    always_ff @(posedge clk) // FSM
    begin
        if     (!rst) state <= State_zero;
        else if( clk) state <= nextstate;
    end

    assign pc_value = pc;
endmodule
