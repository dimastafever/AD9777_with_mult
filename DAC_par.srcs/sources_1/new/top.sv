`timescale 1ns / 1ps

module top#(       
    parameter FIFO_DEPTH = 16,
    parameter DATA_WIDTH = 32,
    parameter START_NUMBER = 0    
)(
    input  logic        GCLK,
    input  logic        OTG_RESETN,
    input  logic [DATA_WIDTH-1:0] wdatax,
    input  logic [DATA_WIDTH-1:0] wdatay,
    input  logic        validx,
    input  logic        validy,
    
    input  logic [DATA_WIDTH-1:0] kx_u,
    input  logic [DATA_WIDTH-1:0] bx_u,
    
    input  logic [DATA_WIDTH-1:0] kx_c,
    input  logic [DATA_WIDTH-1:0] bx_c,
    
    input  logic [DATA_WIDTH-1:0] ky_u,
    input  logic [DATA_WIDTH-1:0] by_u,
    
    input  logic [DATA_WIDTH-1:0] ky_c,
    input  logic [DATA_WIDTH-1:0] by_c,
    
    output logic        sel_1_0,
    output logic        sel_1_1,
    output logic        AS2_r,
    output  logic       wready,
    output logic        JB1,
    output logic        JB2,
    output logic        JB3,
    output logic        JB4,
    output logic        JB7,
    output logic        JB8,
    output logic        JB9,
    output logic        JB10,
    
    output logic        JA1,
    output logic        JA2,
    output logic        JA3,
    output logic        JA4,
    output logic        JA7,
    output logic        JA8,
    output logic        JA9,
    output logic        JA10,
    
    output logic        JC1_N,
    output logic        JC1_P,
        input logic        JC2_N,
    output logic        JC2_P,
    output logic        JC3_N,
    output logic        JC3_P,
    output logic        JC4_N,
    output logic        JC4_P
);

 assign JC4_N = GCLK;
 assign JC1_P = 1'b0;
 logic [31:0]  in_data;
 logic  in_valid;
 logic in_ready;
    logic                  u_ready;
    logic                  u_valid;
    logic [DATA_WIDTH-1:0] u_data;
    
    logic                  c_ready;
    logic                  c_valid;
    logic [DATA_WIDTH-1:0] c_data;  

    
    logic [DATA_WIDTH-1:0] k_u;
    logic [DATA_WIDTH-1:0] b_u;
    
    logic [DATA_WIDTH-1:0] k_c;
    logic [DATA_WIDTH-1:0] b_c;
    
    logic [DATA_WIDTH-1:0] wdata;
    logic  wvalid;
    logic  store_valid;
    logic  done; 
always_ff @(posedge GCLK or negedge OTG_RESETN) begin
    if (!OTG_RESETN) begin
        store_valid <= 1'b0;
        done<= 1'b0;
    end else begin
        if (validx && validy) begin
            store_valid <= validy;
            done <= validy;
        end else if (!validx && !validy && u_valid) begin
            done <= store_valid;
            store_valid <=1'b0;
        end
    end
end

always_ff @(posedge GCLK or negedge OTG_RESETN) begin
        if (!OTG_RESETN) begin
        wdata <= '0;
        k_u <= '0;
        b_u <= '0;
        k_c <= '0;
        b_c <= '0;
        wvalid <= 1'b0;
    end else if (validx) begin
        wdata <= wdatax;
        k_u <= kx_u;
        b_u <= bx_u;
        wvalid <= validx;
    end else if (u_valid) begin
        if (store_valid) begin
            wdata <= wdatay;
            k_u <= ky_u;
            b_u <= by_u;
            k_c <= kx_c;
            b_c <= bx_c;
            wvalid <= u_valid;
        end else if (done) begin
            k_c <= ky_c;
            b_c <= by_c;
        end
    end else begin
        wdata <= '0;
        wvalid <= 1'b0;
    end
end
parallel_DAC #(
    .FIFO_DEPTH(FIFO_DEPTH),
    .DATA_WIDTH(DATA_WIDTH),
    .START_NUMBER(START_NUMBER)
)dac_inst (
    .in_clk(GCLK),
    .in_reset(OTG_RESETN),
    .in_sdo(JC2_N), 
    .in_data(in_data),
    .out_sclk(JC2_P),
    .out_ss(JC1_N),
    .out_sdio(JC3_P),
    .out_busy(),
    .valid(in_valid), 
    .sel_1_0(sel_1_0),
    .sel_1_1(sel_1_1),
    .ready(in_ready),
    .out_data({JA1,JA2,JA3,JA4,JA7,JA8,JA9,JA10,JB1,JB2,JB3,JB4,JB7,JB8,JB9,JB10})
);


    
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) fifo_inst (
        .clk(GCLK),
        .reset_n(OTG_RESETN),
        .s_axis_tdata(in_data),
        .s_axis_tvalid(in_valid),
        .s_axis_tready(in_ready),
    
        .m_axis_tdata({wdata[31:16],c_data[31:16]}),
        .m_axis_tvalid(c_valid),
        .m_axis_tready(c_ready)
    );

fixed_point_linear mult_u (
    .clk(GCLK),
    .rst_n(OTG_RESETN),
    
    .value_og({wdata[15:0],16'b0}),
    .k(k_u),
    .b(b_u),
    .valid_i(wvalid),
    .ready_o(wready),
    
    .ready_i(u_ready),
    .valid_o(u_valid),
    .value_out(u_data)
);
fixed_point_linear mult_code (
    .clk(GCLK),
    .rst_n(OTG_RESETN),
    
    .value_og(u_data),
    .k(k_c),
    .b(b_c),
    .valid_i(u_valid),
    .ready_o(u_ready),
    
    .ready_i(c_ready),
    .valid_o(c_valid),
    .value_out(c_data)
);


endmodule