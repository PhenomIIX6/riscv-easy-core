import core_pkg::*;
import mem_control_pkg::*;
module load_store_unit
(
   	input  logic							clk,
	input  logic							rst,

	input  logic                 			mem_op,
    output logic                            mem_op_read,
	input  logic [ADDR_WIDTH-1:0]			mem_addr,		// Address for write or read
	input  logic [MEM_WIDTH_CODE-1:0]		mem_control,
	output logic 							mem_op_valid,   // Read/Wrtie transaction is successful 
	input  logic [DATA_WIDTH-1:0]			mem_write_data,
    output logic                            mem_op_read_sync,
    output logic                            mem_op_sync,
	output logic [DATA_WIDTH-1:0]			mem_read_data,
    output logic                            fetch_stall,
    input  logic [4:0]                      rd_addr,
    output logic [4:0]                      rd_addr_sync,      

	//AXI_lite Read Address Channel
	output  logic [ADDR_WIDTH-1:0]			ARADDR,
	output  logic							ARVALID,
	input 	logic 							ARREADY,

	//AXI_lite Read Data Channel
	output logic 							RREADY,
	input  logic [DATA_WIDTH-1:0]			RDATA,
	input  logic 							RVALID,

	//AXI_lite Write Address Channel
	output logic [ADDR_WIDTH-1:0]			AWADDR,
	output logic 							AWVALID,
	input  logic							AWREADY,

	//AXI_lite Write Data Channel
	output  logic [DATA_WIDTH-1:0]			WDATA,
	output  logic 							WVALID,
	input 	logic 							WREADY
);
    logic [DATA_WIDTH-1:0] mem_write_data_wdata;
    logic [DATA_WIDTH-1:0] mem_write_data_wdata_sync;
    logic [ADDR_WIDTH-1:0] mem_addr_sync;
    logic [MEM_WIDTH_CODE-1:0] mem_control_sync;

    typedef enum logic [1:0] {              // FSM
        State_zero            = 2'b00,      // Reset
        State_wait_rd         = 2'b01,
        State_wait_wr         = 2'b10     
    } statetype;
    statetype state, nextstate;

    always_comb     // FSM
    begin
        nextstate = state;
        case(state)
            State_zero:         if(mem_op )             nextstate = mem_op_read ? State_wait_rd : State_wait_wr;
            State_wait_rd:      if(RVALID )             nextstate = State_zero;
            State_wait_wr:      if(WVALID )             nextstate = State_zero;
            default:                                    nextstate = State_zero;
        endcase
    end
    
    always_ff @(posedge clk) // FSM
    begin
        case(state)
            State_zero: begin
                mem_write_data_wdata_sync   <= mem_write_data_wdata;
                mem_op_read_sync            <= mem_op_read;
                mem_addr_sync               <= mem_addr;
                mem_op_sync                 <= mem_op;
                rd_addr_sync                <= rd_addr;
                mem_control_sync            <= mem_control;
            end
            State_wait_rd: begin 
                mem_write_data_wdata_sync   <= 'b0;
                mem_op_read_sync            <= mem_op_read_sync;
                mem_control_sync            <= mem_control_sync;
                mem_addr_sync               <= mem_addr_sync;
                mem_op_sync                 <= mem_op_sync;
                rd_addr_sync                <= rd_addr_sync;
            end
            State_wait_wr: begin
                mem_write_data_wdata_sync   <= mem_write_data_wdata_sync;
                mem_op_read_sync            <= mem_op_read_sync;
                mem_addr_sync               <= mem_addr_sync;
                mem_op_sync                 <= mem_op_sync;
                rd_addr_sync                <= rd_addr_sync;
            end
            default: begin
                mem_write_data_wdata_sync   <= mem_write_data_wdata_sync;
                mem_op_read_sync            <= mem_op_read_sync;
                mem_addr_sync               <= mem_addr_sync;
                mem_op_sync                 <= mem_op_sync;
                rd_addr_sync                <= rd_addr_sync;
            end                       
        endcase
    end

    assign fetch_stall = mem_op | mem_op_sync;

    always_ff @(posedge clk) // FSM
    begin
        if(!rst)        state <= State_zero;
        else if(clk)    state <= nextstate;
    end


	always_ff @(posedge clk)
    begin
        if(!rst) begin
            ARVALID <= 'b0;
            ARADDR  <= 'b0;
            RREADY  <= 'b0;
			ARADDR  <= 'b0;
        end
        else if(ARREADY & ARVALID & mem_op_read_sync & mem_op_sync) begin
            RREADY  <= 1'b1;
            ARVALID <= 1'b0;
        end
        else if(RREADY & RVALID & mem_op_read_sync & mem_op_sync) begin
            RREADY  <= 1'b0;
        end
        else if(ARREADY & mem_op_read_sync & mem_op_sync) begin
            ARVALID <= 1'b1;
            ARADDR  <= mem_addr_sync >> 2;
        end
        else begin
            ARVALID <= 'b0;
        end
    end

	always_ff @(posedge clk)
    begin
        if(!rst) begin
            AWVALID <= 'b0;
            AWADDR  <= 'b0;
            WVALID  <= 'b0;
            WDATA   <= 'b0;
        end
        else if(AWREADY & AWVALID & !mem_op_read_sync & mem_op_sync) begin
            WVALID  <= 1'b1;
            AWVALID <= 1'b0;
        end
        else if(WREADY & WVALID & !mem_op_read_sync & mem_op_sync) begin
            WVALID  <= 1'b0;
            WDATA   <= mem_write_data_wdata_sync;
        end
        else if(AWREADY & !mem_op_read_sync & mem_op_sync) begin
            AWVALID <= 1'b1;
            AWADDR  <= mem_addr_sync >> 2;
        end
        else begin
            AWVALID <= 'b0;
            AWADDR  <= 'b0;
            WVALID  <= 'b0;
            WDATA   <= 'b0;
        end
    end

    assign mem_op_read = (mem_control == mem_lb  | 
                        mem_control == mem_lbu |
                        mem_control == mem_lh  |
                        mem_control == mem_lhu |
                        mem_control == mem_lw);

    assign mem_op_valid = mem_op_read_sync ? RVALID : WVALID;

    always_comb
    begin
        mem_read_data           = 'b0;
        case(mem_control_sync)   
			mem_lb:
				begin
					case(mem_addr_sync[1:0])
						2'b00: mem_read_data = RDATA[7]  ? (32'hffffff00 | RDATA[7:0])   : (32'h000000ff & RDATA[7:0]);   // RDATA[7:0] with sign_ext
						2'b01: mem_read_data = RDATA[15] ? (32'hffffff00 | RDATA[15:8])  : (32'h000000ff & RDATA[15:8]);  // RDATA[15:8] with sign_ext
						2'b10: mem_read_data = RDATA[23] ? (32'hffffff00 | RDATA[23:16]) : (32'h000000ff & RDATA[23:16]); // RDATA[23:16] with sign_ext
						2'b11: mem_read_data = RDATA[31] ? (32'hffffff00 | RDATA[31:24]) : (32'h000000ff & RDATA[31:24]); // RDATA[31:24] with sign_ext
					endcase
				end
			mem_lh:
				begin
					case(mem_addr_sync[1:0])
						2'b00: mem_read_data = RDATA[15] ? (32'hffff0000 | RDATA[15:0])  : (32'h0000ffff & RDATA[15:0]);  // RDATA[15:0] with sign_ext
						2'b01: mem_read_data = RDATA[23] ? (32'hffff0000 | RDATA[23:8])  : (32'h0000ffff & RDATA[23:8]);  // RDATA[23:8] with sign_ext
						2'b10: mem_read_data = RDATA[31] ? (32'hffff0000 | RDATA[31:16]) : (32'h0000ffff & RDATA[31:16]); // RDATA[31:16] with sign_ext
						2'b11: mem_read_data = RDATA[31] ? (32'hffffff00 | RDATA[31:24]) : (32'h000000ff & RDATA[31:24]); // RDATA[31:24] with sign_ext
					endcase
				end
			mem_lw:
				begin
					case(mem_addr_sync[1:0])
						2'b00: mem_read_data = RDATA[31:0];
						2'b01: mem_read_data = RDATA[31:8];
						2'b10: mem_read_data = RDATA[31:16];
						2'b11: mem_read_data = RDATA[31:24];
					endcase
				end
			mem_lbu:
				begin
					case(mem_addr_sync[1:0])
						2'b00: mem_read_data = 32'h000000ff & RDATA[7:0]; 		// RDATA[7:0] with zero_ext
						2'b01: mem_read_data = 32'h000000ff & RDATA[15:8];  	// RDATA[15:8] with zero_ext
						2'b10: mem_read_data = 32'h000000ff & RDATA[23:16]; 	// RDATA[23:16] with zero_ext
						2'b11: mem_read_data = 32'h000000ff & RDATA[31:24]; 	// RDATA[31:24] with zero_ext
					endcase
				end
			mem_lhu:
				begin
					case(mem_addr_sync[1:0])
						2'b00: mem_read_data = 32'h0000ffff & RDATA[15:0];  // RDATA[15:0] with sign_ext
						2'b01: mem_read_data = 32'h0000ffff & RDATA[23:8];  // RDATA[15:8] with sign_ext
						2'b10: mem_read_data = 32'h0000ffff & RDATA[31:16]; // RDATA[23:16] with sign_ext
						2'b11: mem_read_data = 32'h000000ff & RDATA[31:24]; // RDATA[31:24] with sign_ext
					endcase
				end
        endcase
    end

	always_comb
	begin
		mem_write_data_wdata    = 'b0;
		case(mem_control)
			mem_sb:
				begin
					casez(mem_addr[1:0])
						2'b00: mem_write_data_wdata = {24'h??????, mem_write_data[7:0]}; 
						2'b01: mem_write_data_wdata = {16'h????, mem_write_data[7:0], 8'h??};
						2'b10: mem_write_data_wdata = {8'h??, mem_write_data[7:0], 16'h????};
						2'b11: mem_write_data_wdata = {mem_write_data[7:0], 24'h??????};
					endcase
				end
			mem_sh:
				begin
					casez(mem_addr[1:0])
						2'b00: mem_write_data_wdata = {16'h????, mem_write_data[15:0]}; 
						2'b01: mem_write_data_wdata = {8'h??, mem_write_data[15:0], 8'h??};
						2'b10: mem_write_data_wdata = {mem_write_data[15:0], 16'h????};
						2'b11: mem_write_data_wdata = {mem_write_data[7:0], 24'h??????};
					endcase
				end
			mem_sw:
				begin
					casez(mem_addr[1:0])
						2'b00: mem_write_data_wdata = mem_write_data[31:0]; 
						2'b01: mem_write_data_wdata = {mem_write_data[31:8], 8'h??};
						2'b10: mem_write_data_wdata = {mem_write_data[31:16], 16'h????};
						2'b11: mem_write_data_wdata = {mem_write_data[31:24], 24'h??????};
					endcase
				end
		endcase
	end
endmodule