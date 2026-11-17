`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2026 08:49:00 PM
// Design Name: 
// Module Name: tb_FP_Adder_Subtractor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_FP_Adder_Subtractor;
logic [31:0] A,B;
logic op;
logic [2:0] rounding_mode;
logic [31:0] result;
FP_Adder_Subtractor uut(
.A(A),
.B(B),
.op(op),
.result(result),
.rounding_mode(rounding_mode)
);
initial begin
A=32'h40000000;
B=32'h40400000;
op=0;
rounding_mode=3'b000;
#10;
$display("A      = %h",A);
$display("B      = %h",B);
$display("Result = %h",result);
if(result==32'h40A00000)
$display("TEST PASSED");
else
$display("TEST FAILED");
$finish;
end
endmodule
