`timescale 1ns / 1ps

module car_fsm(
    input clk,
    input rst,
    input debounced_btnL,
    input debounced_btnR,
    input [9:0] car_x,
    input rival_collision,
    output reg [2:0] state
    );
    
    
    localparam START = 3'b000;
    localparam IDLE  = 3'b001;
    localparam LEFT_CAR= 3'b010;
    localparam RIGHT_CAR = 3'b011;
    localparam COLLIDE = 3'b100;
    
    localparam main_car_width = 14;

    reg [2:0] current_state, next_state;
    
    always @(*) begin
        next_state = current_state;
        
        case(current_state)
            START: begin
                if (debounced_btnR) begin 
                    next_state = RIGHT_CAR; 
                end
                else if (debounced_btnL) begin 
                    next_state = LEFT_CAR; 
                end
                else begin 
                    next_state = IDLE; 
                end
            end
            
            IDLE: begin
                if (rival_collision) begin 
                    next_state = COLLIDE; 
                end
                else if (debounced_btnR) begin 
                    next_state = RIGHT_CAR; 
                end
                else if (debounced_btnL) begin 
                    next_state = LEFT_CAR; 
                end
                else begin 
                    next_state = IDLE; 
                end
            end
            
            LEFT_CAR: begin
                if (car_x < 244 || rival_collision) begin 
                    next_state = COLLIDE; 
                end
                else if (debounced_btnR) begin 
                    next_state = RIGHT_CAR; 
                end
                else if (debounced_btnL) begin 
                    next_state = LEFT_CAR; 
                end
                else begin 
                    next_state = IDLE; 
                end
            end
            
            RIGHT_CAR: begin
                if (car_x + main_car_width > 318 || rival_collision) begin 
                    next_state = COLLIDE; 
                end
                else if (debounced_btnL) begin 
                    next_state = LEFT_CAR; 
                end
                else if (debounced_btnR) begin 
                    next_state = RIGHT_CAR; 
                end
                else begin 
                    next_state = IDLE; 
                end
            end
            
            COLLIDE: begin
                next_state = COLLIDE;
            end
            
            default: begin
                next_state = START;
            end
        endcase
    end

    always @(posedge clk) begin 
        if (rst) begin
            current_state <= START;
        end
        else begin
            current_state <= next_state;
        end
    end

    always @(posedge clk) begin
        state <= current_state;
    end
                    
            
endmodule