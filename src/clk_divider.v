`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Delhi
// Engineer: Naman Jain
// 
// Create Date: 09/22/2025 06:24:54 PM
// Design Name: 
// Module Name: clk_divider
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


module clk_divider #(
        parameter N = 4
    )
    (
        input clk,
        output pclk
    );
    
    localparam thres = (N/2) - 1; 
    reg [$clog2(N/2) - 1:0] count = 0; // TODO: Remove use of log2?
    reg temp = 0;
    always @ (posedge clk) begin
        if (count == thres) begin
            count <= 0;
            temp <= ~temp;
        end
        else
            count <= count + 1;
       end
    assign pclk = temp;
endmodule
