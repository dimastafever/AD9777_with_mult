//pipelined y=k * x + b module for fixed point numbers

module fixed_point_linear #(
    parameter INTEGER_W = 16,
    parameter FRACTIONAL_W = 16,
    parameter VALUE_OG_WIDTH = INTEGER_W + FRACTIONAL_W,
    parameter K_WIDTH = 32,  
    parameter B_WIDTH = INTEGER_W + FRACTIONAL_W,
    parameter VALUE_OUT_WIDTH = INTEGER_W + FRACTIONAL_W,
    parameter MULT_RESULT_WIDTH = VALUE_OG_WIDTH + K_WIDTH
) (
    input  logic clk,
    input  logic rst_n,
    
    input  logic signed [VALUE_OG_WIDTH-1:0] value_og,
    input  logic signed [K_WIDTH-1:0] k,
    input  logic signed [B_WIDTH-1:0] b,
    input  logic                      valid_i,
    output logic                      ready_o,
    
    input  logic                      ready_i,
    output logic                      valid_o,
    output logic signed [VALUE_OUT_WIDTH-1:0] value_out
);

    // Pipeline registers for data
    logic signed [VALUE_OG_WIDTH-1:0] value_og_reg;
    logic signed [K_WIDTH-1:0] k_reg;
    logic signed [B_WIDTH-1:0] b_reg;
    
    logic signed [MULT_RESULT_WIDTH-1:0] multiplication_reg;
    logic signed [MULT_RESULT_WIDTH-1:0] scaled_mult_reg;
    logic signed [VALUE_OUT_WIDTH-1:0] value_out_reg;
    
    // Pipeline registers for valid signals
    logic valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // Internal signals
    logic signed [MULT_RESULT_WIDTH-1:0] multiplication;
    logic signed [MULT_RESULT_WIDTH-1:0] scaled_mult;
    logic signed [MULT_RESULT_WIDTH-1:0] addition;
    
    // Signed saturation logic
    // Max positive value for VALUE_OUT_WIDTH bits
    logic signed [VALUE_OUT_WIDTH-1:0] max_positive;
    logic signed [VALUE_OUT_WIDTH-1:0] max_negative;

    // Ready signal logic - we're ready if stage1 can accept new data
    assign ready_o = ~valid_stage1 || (valid_stage1 && ready_i);

    // Stage 1: Input registration
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            value_og_reg <= '0;
            k_reg <= '0;
            b_reg <= '0;
            valid_stage1 <= 1'b0;
        end else begin
            if (ready_o) begin // Only update if we're ready to accept new data
                value_og_reg <= value_og;
                k_reg <= k;
                b_reg <= b;
                valid_stage1 <= valid_i;
            end
        end
    end

    // Stage 2: Multiplication
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            multiplication_reg <= '0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin // Only propagate valid data
                multiplication_reg <= value_og_reg * k_reg;
                valid_stage2 <= valid_stage1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    assign multiplication = multiplication_reg;

    // Stage 3: Scaling (right shift) - use arithmetic shift for signed numbers
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            scaled_mult_reg <= '0;
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin // Only propagate valid data
                scaled_mult_reg <= multiplication >>> FRACTIONAL_W; // Arithmetic shift
                valid_stage3 <= valid_stage2;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    assign scaled_mult = scaled_mult_reg;

    // Stage 4: Signed addition and saturation
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            value_out_reg <= '0;
            valid_stage4 <= 1'b0;
        end else begin
            if (valid_stage3) begin // Only propagate valid data
                // Sign-extend b to MULT_RESULT_WIDTH before addition
                addition = scaled_mult + {{(MULT_RESULT_WIDTH-B_WIDTH){b_reg[B_WIDTH-1]}}, b_reg};
                
                max_positive = (1 << (VALUE_OUT_WIDTH-1)) - 1;  // 2^(n-1)-1
                max_negative = -(1 << (VALUE_OUT_WIDTH-1));     // -2^(n-1)
                
                if ($signed(addition) > $signed(max_positive)) begin
                    value_out_reg <= max_positive;
                end else if ($signed(addition) < $signed(1'b0)) begin
                    value_out_reg <= 0;
                end else begin
                    value_out_reg <= addition[VALUE_OUT_WIDTH-1:0];
                end
                valid_stage4 <= valid_stage3;
            end else begin
                valid_stage4 <= 1'b0;
            end
        end
    end

    // Output assignment with backpressure
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            value_out <= '0;
        end else begin
            if (ready_i) begin // Only update output if consumer is ready
                valid_o <= valid_stage4;
                value_out <= value_out_reg;
            end
        end
    end

endmodule
