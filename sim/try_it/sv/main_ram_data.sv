import core_pkg::*;
module main_ram_data // module for data
(
    input  logic                            clk,
    input  logic                            rst,

    //AXI_LITE READ channel
    output  logic  [DATA_WIDTH-1:0]          RDATA,
    output  logic                            RVALID,    
    input   logic                            RREADY,
     
    //AXI_lite READ ADDR channel
    output logic                            ARREADY,
    input  logic  [31:0]                    ARADDR,
    input  logic                            ARVALID,

    //AXI_lite Write Address Channel
    input  logic [31:0]                     AWADDR,
    input  logic                            AWVALID,
    output logic                            AWREADY,

    //AXI_lite Write Data Channel
    input  logic [DATA_WIDTH-1:0]           WDATA,
    output logic                            WREADY,
    input  logic                            WVALID
);
    logic [31:0] mem [2 ** 8-1:0];
    logic [31:0] write_en;
    logic [31:0] data;

    always_comb
    begin
        data = 'bx;        
        for(int i = 0; i < 32; i++) begin
            if        (WDATA[i]      | !WDATA[i])           data[i] = WDATA[i];
            else if(mem[AWADDR][i] | !mem[AWADDR][i])       data[i] = mem[AWADDR][i];
            else                                            data[i] = 0;
        end
    end
    
    always_ff @(posedge clk)
    begin
        if (clk & (WVALID & WREADY)) begin
            write_en    <= 1'b1;
        end
        if (write_en) begin
            mem[AWADDR] <= data;
            write_en    <= 1'b0;
        end
    end
     
    always_ff @(posedge clk)
    begin
        if(!rst) begin
            ARREADY <= 'b0;
        end
        else if(ARREADY & ARVALID) begin
            ARREADY  <= 1'b0;
        end
        else ARREADY <= 1'b1;
    end

    always_ff @(posedge clk) begin
        if(!rst) begin
            RVALID  <= 1'b0;
            RDATA   <= 'b0;
        end
        else if(RREADY & RVALID) begin
            RVALID <= 1'b1;
            RDATA  <= mem[ARADDR];
        end
        else begin
            RVALID <= RREADY;
            RDATA  <= 'b0;
        end
    end

    always_ff @(posedge clk)
    begin
        if(!rst) begin
            WREADY <= 'b0;
        end
        else if(WREADY & WVALID) begin
            WREADY <= 1'b0;
        end
        else WREADY <= 1'b1;
    end


    always_ff @(posedge clk)
    begin
        if(!rst) begin
            AWREADY <= 'b0;
        end
        else if(AWREADY & AWVALID) begin
            AWREADY <= 1'b0;
        end
        else AWREADY <= 1'b1;
    end
    
endmodule