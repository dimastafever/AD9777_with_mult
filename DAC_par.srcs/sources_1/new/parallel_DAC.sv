`timescale 1ns / 1ps
    
module parallel_DAC #(     
    parameter FIFO_DEPTH = 4,
    parameter DATA_WIDTH = 32,
    parameter START_NUMBER = 4       
)(
    input logic      in_clk,
    input logic      in_reset,
    input logic      in_sdo, 
    input logic [DATA_WIDTH-1:0] in_data,
    input logic      valid, 

    
    output logic      ready,
    output logic     out_sclk,
    output logic     out_ss,
    output logic     out_sdio,
    output logic     out_busy,
    output logic        sel_1_0,
    output logic        sel_1_1,
    output logic        sel_2_0,
    output logic        sel_2_1,
    output logic        AS2_r,
    output logic [15:0] out_data
);
    logic      in_start;
    logic [5:0] timer;
    logic sclk, sclk_buf;
    logic sdio, ss, busy;
    logic [15:0] dout;
    logic [7:0] counter_data;
    logic [3:0] timer_sclk;
    logic [5:0] timer_delay;
    logic [15:0] data;
    logic sclk_pos; assign sclk_pos = ~sclk_buf & sclk;
    logic sclk_neg; assign sclk_neg = ~sclk & sclk_buf;
    logic     data_went;
    assign data [15:0] = in_data[15:0];
    assign out_sdio = sdio;
    assign out_sclk = sclk;
    assign out_ss = ss;
    assign out_busy = busy;

    logic [2:0] sel_r;
    logic block;
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            timer_sclk <= 4'd0;
        end else begin
            timer_sclk <= (in_start && (timer_sclk < 4'd5)) ? 
                         timer_sclk + 1 : 4'd0;
        end
    end
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            in_start <= 'd0;
        end else if (valid && ready ) begin
            in_start <= 1'b1;
        end else if (timer_delay == 6'd30 )
            in_start <= 'd0;
    end
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            out_data <= 'd0;
        end else if (in_start) begin
            if (timer_delay == 6'd29) begin
                out_data <= data;
            end 
        end
    end
    
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            sclk <= 1'b1;
        end else begin
            if(in_start) begin
                if(timer_sclk == 4'd4 && counter_data != 8'd16) 
                    sclk <= ~sclk;
                else if(counter_data == 8'd16) 
                    sclk <= 1'b1;
            end else begin
                sclk <= 1'b1;
            end
        end
    end
    
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            sclk_buf <= 1'b1;
        end else begin
            sclk_buf <= sclk;
        end
    end
    
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            counter_data <= 8'd0;
        end else begin
            if(in_start) begin
                if(sclk_pos && (counter_data < 8'd16)) 
                    counter_data <= counter_data + 1;
                else if( !in_start)
                    counter_data <= 8'd0;
            end else begin
                counter_data <= 8'd0;
            end
        end
    end
    
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            dout <= 16'd0;
            block <= 0;
        end else begin
            if(in_start && !block) begin
                if(counter_data == 8'd0) begin
                    dout <= in_data[31:16];
                end else if((counter_data > 0) && (counter_data < 16) && sclk_neg) begin
                    dout <= {dout[14:0], 1'b0};
                end else if(counter_data == 16)
                 block <= 1'b1;   
            end 
        end
    end
    
        always_comb begin
        if(!in_reset) begin
            ready <= 1'b0;
        end else begin
            if (valid && !in_start) begin
                ready <= 1'b1;
            end else  begin
                ready <= 1'b0;
            end
        end
    end
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            sdio <= 1'b0;
        end else begin
            sdio <= (in_start) ? dout[15] : 1'b0;
        end
    end
    
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            timer_delay <= 6'd0;
        end else begin
            if(in_start) begin
                if((counter_data == 8'd16) && (timer_delay < 6'd30)) 
                    timer_delay <= timer_delay + 1;
                else if(counter_data != 8'd16) 
                    timer_delay <= 6'd0;
                    
            end else begin
                timer_delay <= 6'd0;
            end
        end
    end
    
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            ss <= 1'b1;
        end else begin
            ss <= (busy) ? 1'b0 : 1'b1;
        end
    end
    
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            busy <= 1'b0;
            data_went <= 1'b0; 
        end else begin
            if( in_start) begin
                busy <= (timer_delay != 6'd30);          
                data_went <= (timer_delay == 6'd29); 
            end else begin
                busy <= 1'b0;
            end
        end
    end
     always_ff @(posedge in_clk) begin
    if (!in_reset) begin
        sel_r <= 'b0;
    end else if (data_went) begin
            sel_r<=sel_r + 1'b1;
       end else if(sel_r == 3'b010) begin
            AS2_r <= 1'b1;
        end else if(sel_r == 3'b100) begin
            sel_r <= 'b0;
            AS2_r <= 1'b0;
        end
end
assign sel_1_0 = (sel_r == 3'b001);
assign sel_1_1 = (sel_r == 3'b010);
assign sel_2_0 = (sel_r == 3'b011);
assign sel_2_1 = (sel_r == 3'b100);
endmodule