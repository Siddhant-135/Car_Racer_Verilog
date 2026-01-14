`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Delhi
// Engineer: Naman Jain
// 
// Create Date: 09/22/2025 06:25:22 PM
// Design Name: 
// Module Name: Horiz_counter
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


module Horiz_counter #(
        parameter hor = 640,
        parameter WIDTH = 10
    )
    (
        input pclk,
        input rst,
        output [WIDTH-1:0] Hcnt,
        output TC
    );
    reg [WIDTH-1:0] count = 0;
    reg tempTC = 0;
    
    always @ (posedge pclk) begin
        if (rst) begin
            count <= 0;
            tempTC <= 0;
        end
        else begin
            if (count == hor-1) begin
                count <= 0;
                tempTC <= 0;
            end
            else if (count == hor-2) begin
                count <= count + 1;
                tempTC <= 1;
            end
            else begin
                count <= count + 1;
                tempTC <= 0;
            end
        end
    end
    assign Hcnt = count;
    assign TC = tempTC;
endmodule
