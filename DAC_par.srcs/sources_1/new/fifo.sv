module fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16,
    parameter START_NUMBER = 0
)(
    input  logic clk,
    input  logic reset_n,
    
    output  logic [DATA_WIDTH-1:0] s_axis_tdata,
    output  logic s_axis_tvalid,
    input logic s_axis_tready,
    
    input logic [DATA_WIDTH-1:0] m_axis_tdata,
    input logic m_axis_tvalid,
    output  logic m_axis_tready
);
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH)-1:0] wr_ptr;
    logic [$clog2(DEPTH)-1:0] rd_ptr;
    logic [$clog2(DEPTH):0] count;
    

    logic full, empty;
    
    assign full = (count == DEPTH);
    assign empty = (count == 0);
    
    assign m_axis_tready = !full;  
    assign s_axis_tvalid = (!empty);
    
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= START_NUMBER;
            s_axis_tdata <= 0;
            //mem[0] <= 32'h01810000;
            //mem[1] <= 32'h01810003;
        end else begin
        
            if (m_axis_tvalid && m_axis_tready) begin
                mem[wr_ptr] <= m_axis_tdata;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            end
            
            if (s_axis_tvalid && s_axis_tready ) begin
                s_axis_tdata <= mem[rd_ptr];
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;

            end
            case ({m_axis_tvalid && m_axis_tready, s_axis_tvalid && s_axis_tready})
                2'b01: count <= count - 1;  // Only read
                2'b10: count <= count + 1;  // Only write
                2'b11: count <= count;      // Simultaneous read and write
                default: ;                  // No operation
            endcase
        end
    end
endmodule