`timescale 1ns / 1ps

/*
Description: Light-weight, fair, parameterized Round-Robin design 
             based on Han-Carlson parallel prefix network
             
Designed by Ruslan Dashkin

Inspired by: 
    author = {Fatih Ugurdag, H. and Baskirt, Onur},
    title = {Fast Parallel Prefix Logic Circuits for N2n Round-Robin Arbitration},
    year = {2012},
    month = {aug},
    volume = {43},
    number = {8},
    doi = {10.1016/j.mejo.2012.04.005},
    journal = {Microelectron. J.}
*/

module rr
#(
    parameter   W   =   4
)(
     input              clock
    ,input              reset
    ,input  [2**W-1:0]  req
    ,output [2**W-1:0]  gnt
);

//Thermo-Fixed Priority Encoders
//0 - High Priority
//1 - Whole Vector
wire    [2**W-1:0]  tfpe [W:0][1:0];

//High Priority Grant select
//0 - Whole vector
//1 - High Priority
wire                hp_gnt;

//FF to store thermo mask from the previous
//arbitration case
reg     [2**W-1:0]  mask;

//Thermo-encoded grant before being converted
//into one-hot
wire    [2**W-1:0]  th_gnt;

//Masked request
wire    [2**W-1:0]  req_masked;

always @(posedge clock)
if (reset)          mask <= 0;
else                mask <= th_gnt; 

assign req_masked = req & mask;

genvar i, j, k;
generate
for (j = 0; j < 2; j = j + 1) begin
    for (k = 0; k < W+1; k = k + 1) begin
        for (i = 0; i < 2**W; i = i + 1) begin
    
        //Level = 0
        if (k == 0) begin
            if (j == 0)
                if ((i % 2) == 1)   assign tfpe[k][j][i] = req_masked[i];
                else                assign tfpe[k][j][i] = req_masked[i] | req_masked[i+1];
            else
                if ((i % 2) == 1)   assign tfpe[k][j][i] = req[i];
                else                assign tfpe[k][j][i] = req[i] | req[i+1];
        end
     
        //Level = W
        else if (k == W) begin
            if (i == 0 | i == (2**W-1)) assign tfpe[k][j][i] = tfpe[k-1][j][i];
            else if ((i % 2) == 1)      assign tfpe[k][j][i] = tfpe[k-1][j][i] | tfpe[k-1][j][i+1];
            else                        assign tfpe[k][j][i] = tfpe[k-1][j][i];
        end
    
        //0 < Level < W
        else begin
            if (((i % 2) == 1) | ((i > (2**W-2**k-1)))) assign tfpe[k][j][i] =  tfpe[k-1][j][i];
            else                                        assign tfpe[k][j][i] =  tfpe[k-1][j][i] | tfpe[k-1][j][i+(2**k)];
        end
        
        end
    end
end
endgenerate

assign hp_gnt = |tfpe[W][0];
assign th_gnt = hp_gnt ? tfpe[W][0] : tfpe[W][1];

//Pre-grant is an intermediate signal to convert
//thermo-encoding into one-hot encoding
wire [2**W:0] pre_gnt;
assign pre_gnt = {1'b0, th_gnt} ^ {th_gnt, 1'b1};
assign gnt = pre_gnt[2**W:1];

endmodule
