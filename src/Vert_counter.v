`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Delhi
// Engineer: Naman Jain
// 
// Create Date: 09/22/2025 06:16:52 PM
// Design Name: 
// Module Name: Vert_counter
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


module Vert_counter #(
        parameter ver = 480,
        parameter WIDTH = 10
    )
    (
        input pclk,
        input En,
        input rst,
        output [WIDTH-1:0] Vcnt
    );
    reg [WIDTH-1:0] count = 0;
    
    always @ (posedge pclk) begin
        if (rst)
            count <= 0;
        else if (En == 1) begin
            if (count == ver-1)
                count <= 0;
            else
                count <= count + 1;
        end
    end
    assign Vcnt = count;
endmodule
