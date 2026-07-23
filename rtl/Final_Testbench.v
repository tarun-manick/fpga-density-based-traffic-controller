// ============================================================================
// MODULE 4: TESTBENCH
// ============================================================================
`timescale 1ns/1ps

module tb_smart_traffic_controller;

    reg clk;
    reg reset_n;
    reg echo_a, echo_b, echo_c, echo_d;
    reg sound_sensor;
    wire trigger_a, trigger_b, trigger_c, trigger_d;
    wire [2:0] lights_a, lights_b, lights_c, lights_d;
    
    // Clock generation (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 20ns period = 50MHz
    end
    
    // DUT instantiation
    smart_traffic_controller dut (
        .clk(clk),
        .reset_n(reset_n),
        .echo_a(echo_a),
        .echo_b(echo_b),
        .echo_c(echo_c),
        .echo_d(echo_d),
        .sound_sensor(sound_sensor),
        .trigger_a(trigger_a),
        .trigger_b(trigger_b),
        .trigger_c(trigger_c),
        .trigger_d(trigger_d),
        .lights_a(lights_a),
        .lights_b(lights_b),
        .lights_c(lights_c),
        .lights_d(lights_d)
    );
    
    // Display traffic light status
    task display_lights;
        begin
            $display("Time=%0t | Lane A: %s | Lane B: %s | Lane C: %s | Lane D: %s", 
                     $time,
                     lights_a == 3'b100 ? "GREEN " : lights_a == 3'b010 ? "YELLOW" : "RED   ",
                     lights_b == 3'b100 ? "GREEN " : lights_b == 3'b010 ? "YELLOW" : "RED   ",
                     lights_c == 3'b100 ? "GREEN " : lights_c == 3'b010 ? "YELLOW" : "RED   ",
                     lights_d == 3'b100 ? "GREEN " : lights_d == 3'b010 ? "YELLOW" : "RED   ");
        end
    endtask
    
    initial begin
        // Initialize
        reset_n = 0;
        echo_a = 0; echo_b = 0; echo_c = 0; echo_d = 0;
        sound_sensor = 0;
        
        #100;
        reset_n = 1;
        
        $display("=== Smart Traffic Light Controller Test ===");
        
        // Test 1: Default sequence (no traffic)
        $display("\nTest 1: Default sequence (no traffic detected)");
        #5_000_000;
        display_lights();
        
        // Test 2: Traffic on lane B
        $display("\nTest 2: Traffic detected on lane B");
        echo_b = 1;
        #100;
        echo_b = 0;
        #5_000_000;
        display_lights();
        
        // Test 3: Sound sensor priority
        $display("\nTest 3: Sound sensor triggers lane A priority");
        sound_sensor = 1;
        #5_000_000;
        display_lights();
        sound_sensor = 0;
        
        $display("\n=== Test Complete ===");
        $finish;
    end

endmodule
