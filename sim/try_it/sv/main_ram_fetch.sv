import core_pkg::*;
module main_ram_fetch // module for fetch tests  
(
    input  logic                        clk,
    input  logic                        rst,
   
    //AXI_LITE READ channel
    output logic  [DATA_WIDTH-1:0]      RDATA,
    output logic                        RVALID,
    input  logic                        RREADY,
     
    //AXI_lite READ ADDR channel
    output logic                        ARREADY,
    input  logic  [31:0]                ARADDR,
    input  logic                        ARVALID
);
    logic [31:0] mem [2 ** 8-1:0];
     
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
    
endmodule
