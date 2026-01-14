`timescale 1ns / 1ps

module tb();
    reg clk;
    reg btnC, btnL, btnR;
    wire HS, VS;
    wire [11:0] vgaRGB;
    
    reg [2:0] prev_state;
    
    Display_sprite uut (
        .clk(clk),
        .btnC(btnC),
        .btnL(btnL),
        .btnR(btnR),
        .HS(HS),
        .VS(VS),
        .vgaRGB(vgaRGB)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        btnC = 0;
        btnL = 0;
        btnR = 0;
        prev_state = 3'b111;
        
        #100;
        
        $display("==================================================");
        $display("=== CAR GAME SIMULATION - HW ACCURATE TIMING ===");
        $display("==================================================");
        $display("Starting simulation at time %0t", $time);
        $display("NOTE: Debouncer requires > 10ms (10,000,000 ns) button press.");
        $display("NOTE: Game tick occurs every ~84ms (84,000,000 ns).");
        
        run_tests();
    end
    
    task run_tests;
    begin
            $display("\n[TEST 1] Resetting game (holding for 100ms)...");
            btnC = 1;
            #100000000; 
            btnC = 0;
            #10000000; 
            check_state("IDLE", 3'b001); 
            $display("   Car position: X=%0d", uut.car_x);
           

            $display("\n[TEST 5] Testing left wall collision (holding 600ms)...");
            btnL = 1;
            #600000000;
            btnL = 0;
            #10000000; // Wait 10ms
            check_state("COLLIDE", 3'b100);
            $display("   Car X: %0d (Should be 240 or less)", uut.car_x);
            
            $display("   Resetting game...");
            btnC = 1; #100000000; btnC = 0; #10000000;
            check_state("IDLE", 3'b001); 

            
            $display("\n[TEST 7] Testing rival collision (using force)...");
            force uut.rival_active = 1'b1;
            force uut.car_x = 200;
            force uut.car_y = 200;
            force uut.rival_x = 210; 
            force uut.rival_y = 210;
            #1000000; 
            check_state("COLLIDE", 3'b100);
            release uut.rival_active;
            release uut.car_x;
            release uut.car_y;
            release uut.rival_x;
            release uut.rival_y;
            #1000000;
            
            $display("   Resetting game...");
            btnC = 1; #100000000; btnC = 0; #10000000;
            check_state("IDLE", 3'b001); 

            $display("\n==================================================");
            $display("=== SIMULATION COMPLETE ===");
            $display("Total simulation time: %0t ns", $time);
            $display("==================================================");
            #1000;
            $finish;
    end
    endtask
    
    task check_state;
        input [71:0] expected_name;
        input [2:0] expected_state;
        begin
            if (uut.state === expected_state) begin
                $display(" State check PASS: %s", expected_name);
            end else begin
                $display("State check FAIL: Expected %s, Got %s", 
                         expected_name, get_state_name(uut.state));
            end
        end
    endtask
    
    function [71:0] get_state_name;
        input [2:0] state_val;
        begin
            case(state_val)
                3'b000: get_state_name = "START";
                3'b001: get_state_name = "IDLE";
                3'b010: get_state_name = "LEFT_CAR";
                3'b011: get_state_name = "RIGHT_CAR"; 
                3'b100: get_state_name = "COLLIDE";
                default: get_state_name = "UNKNOWN";
            endcase
        end
    endfunction
    
    always @(posedge clk) begin
        if (prev_state !== uut.state) begin
            $display("   [%0t] STATE CHANGE: %s -> %s", 
                     $time, get_state_name(prev_state), 
                     get_state_name(uut.state));
            prev_state <= uut.state;
        end
    end
    
    initial begin
        #1000000; 
        forever begin
            #10000000; 
            $display("   [Progress] Time: %0t ns, State: %s, Car_X: %0d", 
                     $time, get_state_name(uut.state), uut.car_x);
        end
    end
    
endmodule