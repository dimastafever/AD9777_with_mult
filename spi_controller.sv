`timescale 1ns / 1ps

module spi_controller #(
    parameter DATA_WIDTH = 16
)(
    input logic      in_clk,
    input logic      in_reset,
    input logic      in_start,
    input logic [DATA_WIDTH-1:0] in_data,
    input logic [2:0] select_ss,
    
    output logic     out_sclk,
    output logic     out_ss_0,
    output logic     out_ss_1,
    output logic     out_ss_2,
    output logic     out_sdio,
    output logic     out_busy,
    output logic     out_data_went
);

    logic sclk, sclk_buf;
    logic sdio, ss, busy;
    logic [DATA_WIDTH-1:0] dout;
    logic [7:0] counter_data;
    logic [3:0] timer_sclk;
    logic [5:0] timer_delay;
    logic sclk_pos, sclk_neg;
    
    assign sclk_pos = ~sclk_buf & sclk;
    assign sclk_neg = ~sclk & sclk_buf;
    assign out_sdio = sdio;
    assign out_sclk = sclk;
    //assign out_ss = ss;
    assign out_busy = busy;
    
    logic in_start_reg;
    logic [15:0] in_data_reg;

    // SCLK timer
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            timer_sclk <= 4'd0;
        end else begin
            timer_sclk <= (in_start_reg && (timer_sclk < 4'd2)) ? 
                         timer_sclk + 1 : 4'd0;
        end
    end

    // SCLK generation
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            sclk <= 1'b1;
        end else begin
            if(in_start_reg) begin
                if(timer_sclk == 4'd2 && counter_data != 8'd16) 
                    sclk <= ~sclk;
                else if(counter_data == 8'd16) 
                    sclk <= 1'b1;
            end else begin
                sclk <= 1'b1;
            end
        end
    end

    // SCLK buffer
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            sclk_buf <= 1'b1;
        end else begin
            sclk_buf <= sclk;
        end
    end

    // Data counter
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            counter_data <= 8'd0;
        end else begin
            if(in_start_reg) begin
                if(sclk_pos && (counter_data < 8'd16)) 
                    counter_data <= counter_data + 1;
                else if(!in_start_reg)
                    counter_data <= 8'd0;
            end else begin
                counter_data <= 8'd0;
            end
        end
    end

    // Data shift register
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            dout <= 16'd0;
        end else begin
            if(in_start_reg) begin
                if(counter_data == 8'd0) begin
                    dout <= in_data_reg;
                end else if((counter_data > 0) && (counter_data < 16) && sclk_neg) begin
                    dout <= {dout[14:0], 1'b0};
                end
            end 
        end
    end

    // SDIO output
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            sdio <= 1'b0;
        end else begin
            sdio <= (in_start_reg) ? dout[15] : 1'b0;
        end
    end

    // Delay timer
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            timer_delay <= 6'd0;
        end else begin
            if(in_start_reg) begin
                if((counter_data == 8'd16) && (timer_delay < 6'd30)) 
                    timer_delay <= timer_delay + 1;
                else if(counter_data != 8'd16) 
                    timer_delay <= 6'd0;
            end else begin
                timer_delay <= 6'd0;
            end
        end
    end

    // Slave select
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            ss <= 1'b1;
        end else begin
            ss <= (busy) ? 1'b0 : 1'b1;
        end
    end

    // Busy and data_went signals
    always_ff @(posedge in_clk or negedge in_reset) begin
        if(!in_reset) begin
            busy <= 1'b0;
            out_data_went <= 1'b0;
        end else begin
            if(in_start_reg) begin
                busy <= (timer_delay != 6'd30);          
                out_data_went <= (timer_delay == 6'd29);
            end else begin
                busy <= 1'b0;
                out_data_went <= 1'b0;
            end
        end
    end
    
    always_ff @(posedge in_clk) begin
        if(!in_reset) begin
            in_start_reg <= 1'b0;
        end else begin
            if (in_start) in_start_reg <= 1'b1;
            else if (out_data_went)  in_start_reg <= 1'b0;
        end
    end
    
    always_ff @(posedge in_clk) begin
        if(!in_reset) begin
            in_data_reg <= 16'b0;
        end else begin
            if (in_start) in_data_reg <= in_data;
        end
    end
    
    always_comb begin
          case (select_ss) 
                3'b001: begin out_ss_0 = ss; out_ss_1 = 1; out_ss_2 = 1; end
                3'b010: begin out_ss_0 = 1; out_ss_1 = ss; out_ss_2 = 1; end
                3'b100: begin out_ss_0 = 1; out_ss_1 = 1; out_ss_2 = ss; end
                default: begin out_ss_0 = 1; out_ss_1 = 1; out_ss_2 = 1; end
          endcase 
    end

endmodule