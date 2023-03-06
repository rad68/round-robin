`timescale 1ns / 1ps

module test();

reg clock;
reg reset;

initial clock = 0;
always #4 clock <= !clock;

localparam W = 2;

reg  [2**W-1:0] cnt;
reg  [2**W-1:0] req;
wire [2**W-1:0] gnt;

integer i,k;
genvar j;

task delay;
input [31:0] d;
begin
    repeat (d) @(posedge clock);
end
endtask

function [2**W-1:0] b2g;
input [2**W-1:0] v;
integer i;
begin 
    b2g[2**W-1] = v[2**W-1];
    for (i = 2**W-1; i > 0; i = i-1)
        b2g[i-1] = v[i] ^ v[i-1];
end
endfunction

initial begin
    reset = 0;
    #100;
    reset = 1;
    #100;
    reset = 0;
    req = 0;
    #100;
    req = #1 1;
    delay(2);
    //One-hot Shift test
    for (i = 0; i < 2**W; i = i + 1) begin
        req = #1 req << 1;
        delay(2);
    end

    //Up-Down counter
    for (i = 0; i < 2**(2**W)-1; i = i + 1) begin
        req = #1 req + 1;
        delay(2);
    end
    delay(10);
    for (i = 0; i < 2**(2**W)-1; i = i + 1) begin
        req = #1 req - 1;
        delay(2);
    end
    
    //Wrap Around conuter (twice)
    delay(10);
    for (i = 0; i < 2**(2**W+1); i = i + 1) begin
        req = #1 req + 1;
        delay(2);
    end

    //Random input test
    delay(100);
    for (k = 0; k < 20; k = k + 1) begin
        req = #1 $random;
        delay(10);
    end
    
    //Gray code test
    req = 0;
    cnt = 0;
    delay(100);
    for (k = 0; k < 2**(2**W); k = k + 1) begin
        cnt = cnt + 1;
        delay(1);
        req = b2g(cnt);
        delay(10);
    end
    delay(100);
    $finish;
end

rr
#(.W(W))
rr
(
     .clock (clock)
    ,.reset (reset)
    ,.req   (req)
    ,.gnt   (gnt)
);

endmodule
