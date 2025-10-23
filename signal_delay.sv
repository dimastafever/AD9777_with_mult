module signal_delay #(
    parameter int WIDTH = 8,    // Signal width
    parameter int N     = 4     // Number of delay stages
) (
    input  logic             clk,
    input  logic             rst_n,
    
    // Input interface
    input  logic [WIDTH-1:0] data_in,
    input  logic             valid_in,
    output logic             ready_out,
    
    // Output interface
    output logic [WIDTH-1:0] data_out,
    output logic             valid_out,
    input  logic             ready_in
);

    // Register chains
    logic [WIDTH-1:0] delay_chain [N];
    logic             valid_chain [N];
    
    // Internal signals
    logic chain_advance;

    // The chain advances when downstream is ready and we have valid data
    assign chain_advance = ready_in && valid_chain[N-1];

    // Ready output: we can accept new data if the chain can advance or if there's space
    assign ready_out = (N == 0) ? 1'b1 : (chain_advance || !valid_chain[N-1]);

    // Output assignments
    assign data_out  = (N == 0) ? data_in : delay_chain[N-1];
    assign valid_out = (N == 0) ? valid_in : valid_chain[N-1];

    generate
        if (N == 0) begin : NO_DELAY
            // Zero delay case - pass through (no registers needed)
            
        end else if (N == 1) begin : SINGLE_DELAY
            // Single register delay
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    delay_chain[0] <= '0;
                    valid_chain[0] <= 1'b0;
                end else if (chain_advance || !valid_chain[0]) begin
                    delay_chain[0] <= data_in;
                    valid_chain[0] <= valid_in;
                end
            end
            
        end else begin : MULTI_DELAY
            // Multiple register delay
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    foreach (valid_chain[i]) begin
                        delay_chain[i] <= '0;
                        valid_chain[i] <= 1'b0;
                    end
                end else if (chain_advance) begin
                    // Shift the entire chain when advancing
                    delay_chain[0] <= data_in;
                    valid_chain[0] <= valid_in;
                    
                    for (int i = 1; i < N; i++) begin
                        delay_chain[i] <= delay_chain[i-1];
                        valid_chain[i] <= valid_chain[i-1];
                    end
                end else begin
                    // Bubble propagation - fill empty slots
                    for (int i = 1; i < N; i++) begin
                        if (!valid_chain[i] && valid_chain[i-1]) begin
                            delay_chain[i] <= delay_chain[i-1];
                            valid_chain[i] <= 1'b1;
                            valid_chain[i-1] <= 1'b0;
                        end
                    end
                    
                    // First stage can accept new data if empty
                    if (!valid_chain[0] && valid_in) begin
                        delay_chain[0] <= data_in;
                        valid_chain[0] <= valid_in;
                    end
                end
            end
        end
    endgenerate

endmodule