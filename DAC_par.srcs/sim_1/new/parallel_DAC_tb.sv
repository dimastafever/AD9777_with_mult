`timescale 1ns / 1ps

module parallel_DAC_tb();
    logic       in_clk;
    parameter DATA_WIDTH = 32;
    logic       in_reset;
    logic       in_sdo;
    logic [31:0] wdata;
    logic [15:0] rdata;
    
    logic       out_sclk;
    logic       out_ss;
    logic       out_sdio;
    logic       out_busy;
    logic       in_valid;
    logic       in_ready;
    logic [31:0] in_data;
    
    logic       wvalid;
    logic       wready;
    logic      working;
    logic                  u_ready;
    logic                  u_valid;
    logic [31:0] u_data;
    
    logic                  c_ready;
    logic                  c_valid;
    logic [31:0] c_data;  

    logic [DATA_WIDTH-1:0] kx_u;
    logic [DATA_WIDTH-1:0] bx_u;
    
    logic [DATA_WIDTH-1:0] kx_c;
    logic [DATA_WIDTH-1:0] bx_c;
    
    logic [DATA_WIDTH-1:0] ky_u;
    logic [DATA_WIDTH-1:0] by_u;
    
    logic [DATA_WIDTH-1:0] ky_c;
    logic [DATA_WIDTH-1:0] by_c;
    logic        validx;
    logic        validy;
    logic [DATA_WIDTH-1:0] wdatax;
    logic [DATA_WIDTH-1:0] wdatay;
    parameter CLK_PERIOD = 10; 
    always #(CLK_PERIOD/2) in_clk = ~in_clk;
    
top top(
    .GCLK(in_clk),
    .OTG_RESETN(in_reset),
    .wdatax(wdatax),
    .wdatay(wdatay),
    .validx(validx),
    .validy(validy),
    
    .kx_u(kx_u),
    .bx_u(bx_u),
    
    .kx_c(kx_c),
    .bx_c(bx_c),
    
    .ky_u(ky_u),
    .by_u(by_u),
    
    .ky_c(ky_c),
    .by_c(by_c)

);
    initial begin
        in_clk = 0;
        in_reset = 0;
        in_sdo = 0;


        #30 in_reset = 1;
        #50;
        
            //in_data_out = $random;

        validx = 1;
        validy = 1;
        kx_u= 32'h00020001;
        bx_u= 32'h00010001;
        
        kx_c= 32'h00030001;
        bx_c= 32'h00020001;
        
        ky_u= 32'h00020000;
        by_u= 32'h00010000;
        
        ky_c= 32'h00030000;
        by_c= 32'h00020000;
        wdatax = 32'hD2345603;
        wdatay = 32'hDEA80003; 
        #10;
        validx = 0;
        validy = 0;
        #35;

        #1000;
        

        kx_u= 32'h00020002;
        bx_u= 32'h00010002;
        
        kx_c= 32'h00030002;
        bx_c= 32'h00020002;
        
        ky_u= 32'h00029900;
        by_u= 32'h00019900;
        
        ky_c= 32'h00039900;
        by_c= 32'h00029900;
        wdatax = 32'h99990111;
        wdatay = 32'h88880171;
        validx = 1;
        validy = 1;
        #10;
        validx = 0;
        validy = 0;
        #35;


        //in_reset = 0;
        #20;
        #1000;
        
        validx = 1;
        wdatax = 32'h98765432;
        #10;
        
        validx = 0; 
        #55;
       // #5 in_start = 0; 
        #10;
        #300;
        
        validy = 1;  
        wdatay = 32'h12310012;
        #10;
        validy = 0;
        #300 
        
        #1000;
        #3000;
        #3000;
        $finish;
    end

endmodule