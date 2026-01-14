`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IIT Delhi
// Engineer: Naman Jain
// 
// Create Date: 09/22/2025 05:07:30 PM
// Design Name: 
// Module Name: VGA_driver
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


module VGA_driver #(
        parameter WIDTH = 10
    )
    (
        input clk,
        input [3:0] vgaRed, vgaGreen, vgaBlue,
        output pixel_clock,
        output [WIDTH-1:0] hor_pix, ver_pix,
        output HS, VS,
        output reg [11:0] vgaRGB
    );
    
    localparam HACTIVE = 640;
    localparam HFP = 16;
    localparam HSYNC = 96;
    localparam HBP = 48;
    
    localparam VACTIVE = 480;
    localparam VFP = 10;
    localparam VSYNC = 2;
    localparam VBP = 33;
    
    localparam HTOT = HACTIVE+HFP+HSYNC+HBP;
    localparam HS_start = HACTIVE+HFP;
    localparam HS_end = HACTIVE+HFP+HSYNC;
    localparam VTOT = VACTIVE+VFP+VSYNC+VBP;
    localparam VS_start = VACTIVE+VFP;
    localparam VS_end = VACTIVE+VFP+VSYNC;
    
    localparam PCLK_DIV = 4; //100 Mhz to 25 Mhz (100/4)
    
//    wire pixel_clock;
    wire Vcnt_en;
    wire hor_rst, ver_rst;
    reg tempHS = 0, tempVS = 0;
    reg video_on;
    
    clk_divider #(
        .N(PCLK_DIV)
    ) PCLK_MOD (
        .clk(clk),
        .pclk(pixel_clock)
    );
    
    Horiz_counter #(
        .hor(HTOT),
        .WIDTH(WIDTH)
    ) HORIZ_C (
        .pclk(pixel_clock),
        .rst(hor_rst),
        .Hcnt(hor_pix),
        .TC(Vcnt_en)
    );
    
    Vert_counter #(
        .ver(VTOT),
        .WIDTH(WIDTH)
    ) VERT_C (
        .pclk(pixel_clock),
        .En(Vcnt_en),
        .rst(ver_rst),
        .Vcnt(ver_pix)
    );
    
    assign hor_rst = 0;
    assign ver_rst = 0;
    assign HS = tempHS;
    assign VS = tempVS;
    
    always @ (posedge pixel_clock) begin
        if (hor_pix >= 0 && hor_pix < HACTIVE && ver_pix >= 0 && ver_pix < VACTIVE)
            video_on <= 1;
        else
            video_on <= 0;
    end
    
    always @ (posedge pixel_clock) begin
        if (hor_pix >= HS_start && hor_pix < HS_end)
            tempHS <= 1;
        else
            tempHS <= 0;
    end
    
    always @ (posedge pixel_clock) begin
        if (ver_pix >= VS_start && ver_pix < VS_end)
            tempVS <= 1;
        else
            tempVS <= 0;
    end

    always @ (posedge pixel_clock) begin
        if (video_on == 1) begin
            vgaRGB [11:8] <= vgaGreen;
            vgaRGB [7:4] <= vgaBlue;
            vgaRGB [3:0] <= vgaRed;
        end
        else begin
            vgaRGB [11:8] <= 0;
            vgaRGB [7:4] <= 0;
            vgaRGB [3:0] <= 0;
        end
    end
endmodule
