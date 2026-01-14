`timescale 1ns / 1ps

module lfsr_8bit (
    input clk,
    input rst,
    input enable,
    output reg [7:0] random_num
);
    wire feedback = random_num[7] ^ random_num[5] ^ random_num[4] ^ random_num[3];
    always @(posedge clk) begin
        if (rst) begin
            random_num <= 8'b01011001;
        end
        else if (enable) begin
            random_num <= {random_num[6:0], feedback};
        end
    end
endmodule

module Display_sprite #(
    parameter pixel_counter_width = 10,
    parameter OFFSET_BG_X = 200,
    parameter OFFSET_BG_Y = 150
)
(
    input clk,
    input btnC, btnL, btnR,
    output HS, VS,
    output [11:0] vgaRGB
);
    localparam bg1_width = 160;
    localparam bg1_height = 240;
    localparam main_car_width = 14;
    localparam main_car_height = 16;
    
    localparam GAME_TICK_DIVIDER = 4;
    localparam RIVAL_SPEED_DIVIDER = 10;
    localparam DEBOUNCE_MAX = 999999;
    
    localparam START = 3'b000;
    localparam IDLE  = 3'b001;
    localparam LEFT_CAR= 3'b010;
    localparam RIGHT_CAR = 3'b011;
    localparam COLLIDE = 3'b100;

    wire pixel_clock;
    wire [pixel_counter_width-1:0] hor_pix, ver_pix;
    wire [3:0] vgaRed_w, vgaGreen_w, vgaBlue_w;

    wire debounced_btnC, debounced_btnL, debounced_btnR;
    wire [2:0] state;
    wire [7:0] random_num;
    reg lfsr_enable;
    wire game_tick;
    reg [19:0] frame_counter = 0;
    
    reg [pixel_counter_width-1:0] car_x = 270;
    reg [pixel_counter_width-1:0] car_y = 300;
    reg [7:0] bg_scroll_offset;
    reg [pixel_counter_width-1:0] rival_x, rival_y;
    reg [7:0] frame_counter_rival = 0;
    reg rival_active = 0;

    wire [11:0] bg_color, car_color, rival_color;
    reg [15:0] bg_rom_addr;
    reg [7:0] car_rom_addr, rival_rom_addr;
    wire [11:0] muxed_color;
    
    reg car_on_reg, bg_on_reg, rival_on_reg;
    reg car_on_dly, bg_on_dly, rival_on_dly;
    
    VGA_driver #(
        .WIDTH(pixel_counter_width)
    )   display_driver (
        .clk(clk), 
        .vgaRed(vgaRed_w),
        .vgaGreen(vgaGreen_w),
        .vgaBlue(vgaBlue_w),
        .HS(HS),
        .VS(VS),
        .vgaRGB(vgaRGB),
        .pixel_clock(pixel_clock), 
        .hor_pix(hor_pix),
        .ver_pix(ver_pix)
    );
    
    bg_rom bg1_rom (
        .clka(pixel_clock), 
        .addra(bg_rom_addr),
        .douta(bg_color)
    );
    main_car_rom car1_rom (
        .clka(pixel_clock), 
        .addra(car_rom_addr),
        .douta(car_color)
    );
    rival_car_rom rival_rom(
        .clka(pixel_clock), 
        .addra(rival_rom_addr),
        .douta(rival_color)
    );
    
    debouncer #(.MAX_COUNT(DEBOUNCE_MAX)) db_btnc(
        .clk(clk),
        .btn(btnC),
        .clean(debounced_btnC)
    );
    debouncer #(.MAX_COUNT(DEBOUNCE_MAX)) db_btnl(
        .clk(clk),
        .btn(btnL),
        .clean(debounced_btnL)
    );
    debouncer #(.MAX_COUNT(DEBOUNCE_MAX)) db_btnr(
        .clk(clk),
        .btn(btnR),
        .clean(debounced_btnR)
    );
    
    wire frame_tick_pix = (hor_pix == 799) && (ver_pix == 524);

    wire rival_collision = rival_active &&
        (car_x < rival_x + main_car_width) &&
        (car_x + main_car_width > rival_x) &&
        (car_y < rival_y + main_car_height) &&
        (car_y + main_car_height > rival_y);
        
    car_fsm car_fsm_inst (
        .clk(clk),
        .rst(debounced_btnC),
        .debounced_btnL(debounced_btnL),
        .debounced_btnR(debounced_btnR),
        .car_x(car_x),
        .rival_collision(rival_collision),
        .state(state)
    );
    
    lfsr_8bit random_gen (
        .clk(clk),
        .rst(debounced_btnC), 
        .enable(lfsr_enable),
        .random_num(random_num)
    );
    
    always @(posedge clk) begin
        if (debounced_btnC) begin
            frame_counter <= 0;
        end else if (frame_tick_pix) begin 
            if (frame_counter == GAME_TICK_DIVIDER)
                frame_counter <= 0;
            else
                frame_counter <= frame_counter + 1;
        end
    end
    
    assign game_tick = (frame_tick_pix && (frame_counter == GAME_TICK_DIVIDER));
    
    always @(posedge clk) begin
        if (debounced_btnC) begin
            car_x <= 270;
            car_y <= 300;
            bg_scroll_offset <= 0;

        end else if (game_tick) begin
            
            case (state)
                START: begin
                    car_x <= 270;
                    car_y <= 300;
                    bg_scroll_offset <= 0;
                end
                IDLE: begin
                    car_x <= car_x;
                    car_y <= car_y;
                    if (bg_scroll_offset == 0)
                        bg_scroll_offset <= bg1_height - 1;
                    else
                        bg_scroll_offset <= bg_scroll_offset - 1;
                end
                LEFT_CAR: begin
                    car_x <= car_x - 5;
                    car_y <= car_y;
                    if (bg_scroll_offset == 0)
                        bg_scroll_offset <= bg1_height - 1;
                    else
                        bg_scroll_offset <= bg_scroll_offset - 1;
                end
                RIGHT_CAR: begin
                    car_x <= car_x + 5;
                    car_y <= car_y;
                    if (bg_scroll_offset == 0)
                        bg_scroll_offset <= bg1_height - 1;
                    else
                        bg_scroll_offset <= bg_scroll_offset - 1;
                end
                COLLIDE: begin
                    car_x <= car_x;
                    car_y <= car_y;
                    bg_scroll_offset <= bg_scroll_offset;
                end
                default: begin
                    car_x <= 270;
                    car_y <= 300;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        lfsr_enable <= 0; 
        if (debounced_btnC) begin
            rival_active <= 0;
            rival_y <= OFFSET_BG_Y;
            frame_counter_rival <= 0;
            lfsr_enable <= 0;
        end
        else if (frame_tick_pix) begin 
            if (!rival_active && state != START && state != COLLIDE) begin
                rival_x <= OFFSET_BG_X + 44 + (random_num % 61);
                rival_y <= OFFSET_BG_Y;
                rival_active <= 1;
                lfsr_enable <= 1;
            end
            else if (rival_active && state != COLLIDE) begin
                frame_counter_rival <= frame_counter_rival + 1;
                if (frame_counter_rival >= RIVAL_SPEED_DIVIDER) begin
                    rival_y <= rival_y + 2;
                    frame_counter_rival <= 0;
                    
                    if (rival_y > 390) begin
                        rival_active <= 0;
                    end
                end
            end
        end
    end

    wire [pixel_counter_width-1:0] hor_pix_ahead = hor_pix + 3;
    wire [pixel_counter_width-1:0] ver_pix_ahead = ver_pix;


    always @(posedge pixel_clock) begin
        if (hor_pix_ahead >= car_x && hor_pix_ahead < (car_x + main_car_width) &&
            ver_pix_ahead >= car_y && ver_pix_ahead < (car_y + main_car_height)) begin
            car_rom_addr <= (hor_pix_ahead - car_x) + (ver_pix_ahead - car_y)*main_car_width;
            car_on_reg <= 1;
        end else begin
            car_on_reg <= 0;
        end
        
        if (hor_pix_ahead >= OFFSET_BG_X && hor_pix_ahead < (OFFSET_BG_X + bg1_width) &&
            ver_pix_ahead >= OFFSET_BG_Y && ver_pix_ahead < (OFFSET_BG_Y + bg1_height)) begin
            bg_rom_addr <= (hor_pix_ahead - OFFSET_BG_X) + ( ((ver_pix_ahead - OFFSET_BG_Y) + bg_scroll_offset) % bg1_height ) * bg1_width;
            bg_on_reg <= 1;
        end else begin
            bg_on_reg <= 0;
        end

        if (rival_active &&
            hor_pix_ahead >= rival_x && hor_pix_ahead < (rival_x + main_car_width) &&
            ver_pix_ahead >= rival_y && ver_pix_ahead < (rival_y + main_car_height)) begin
            rival_rom_addr <= (hor_pix_ahead - rival_x) + (ver_pix_ahead - rival_y) * main_car_width;
            rival_on_reg <= 1;
        end else begin
            rival_on_reg <= 0;
        end
    end

    always @(posedge pixel_clock) begin
        car_on_dly <= car_on_reg;
        bg_on_dly <= bg_on_reg;
        rival_on_dly <= rival_on_reg;
    end

    assign muxed_color = (car_on_dly && car_color != 12'b101000001010) ?
                         car_color :
                         (rival_on_dly && rival_color != 12'b101000001010) ?
                         rival_color :
                         (bg_on_dly) ?
                         bg_color :
                         12'b0;

    assign vgaGreen_w = muxed_color[7:4]; 
    assign vgaBlue_w  = muxed_color[3:0];  
    assign vgaRed_w   = muxed_color[11:8];  

endmodule

module debouncer #(
    parameter MAX_COUNT = 999999
)(
    input clk, 
    input btn, 
    output reg clean
);
    reg [19:0] counter;
    reg curr;
    
    always @(posedge clk) begin
        curr <= btn;
        if (btn != curr) begin 
            counter <= 0;
            clean <= 0; 
        end
        else if (btn == 1) begin
            if(counter < MAX_COUNT)
                counter <= counter + 1;
            else
                clean <= 1;
        end else begin 
            clean <= 0;
            counter <= 0; 
        end
    end
endmodule