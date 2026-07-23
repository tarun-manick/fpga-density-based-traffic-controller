//Final code for distance

module ultrasonic_dist(
    input  wire clk,              // 50 MHz system clock
    input  wire reset_n,          // Active-LOW reset (EP2C5 board button)
    input  wire echo,             // HC-SR04 ECHO signal
    output reg  trigger,          // HC-SR04 TRIGGER signal
    output reg  traffic_detected  // HIGH if distance < 10cm, stays on for 3 sec
);

    // ================================================
    // Parameters
    // ================================================
    parameter CLK_FREQ = 50_000_000;           // 50 MHz
    parameter TRIGGER_TIME = 500;              // 10µs = 500 cycles at 50MHz
    parameter ECHO_TIMEOUT = 1_500_000;        // 30ms timeout
    parameter MEASUREMENT_DELAY = 3_000_000;   // 60ms delay between measurements
    parameter LED_HOLD_TIME = 150_000_000;     // 3 seconds at 50MHz (changed from 0.5 sec)
    
    // Distance threshold: 10cm
    // Distance (cm) = (echo_time * 34300) / (2 * CLK_FREQ)
    // For 10cm: echo_time = (10 * 2 * 50_000_000) / 34300 ≈ 29,155 cycles
    parameter DISTANCE_THRESHOLD = 29_155;
    
    // ================================================
    // State Machine States
    // ================================================
    localparam IDLE        = 3'd0;
    localparam TRIGGER     = 3'd1;
    localparam WAIT_ECHO   = 3'd2;
    localparam MEASURE     = 3'd3;
    localparam CALC        = 3'd4;
    localparam DELAY       = 3'd5;
    
    // ================================================
    // Registers
    // ================================================
    reg [2:0] state = IDLE;
    reg [31:0] counter = 0;
    reg [31:0] echo_counter = 0;
    reg [31:0] traffic_timer = 0;
    reg traffic_hold_active = 0;
    
    // ================================================
    // Main State Machine
    // ================================================
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin  // Active-LOW reset
            state <= IDLE;
            trigger <= 0;
            traffic_detected <= 0;
            counter <= 0;
            echo_counter <= 0;
            traffic_timer <= 0;
            traffic_hold_active <= 0;
        end else begin
            
            // Traffic detection hold timer logic (runs independently)
            if (traffic_hold_active) begin
                if (traffic_timer > 0) begin
                    traffic_timer <= traffic_timer - 1;
                    traffic_detected <= 1;  // Keep signal HIGH
                end else begin
                    traffic_detected <= 0;
                    traffic_hold_active <= 0;
                end
            end else begin
                // If timer expired and no new detection, turn off signal
                traffic_detected <= 0;
            end
            
            // State machine
            case (state)
                // =============================================
                // IDLE: Initialize for new measurement
                // =============================================
                IDLE: begin
                    trigger <= 0;
                    counter <= 0;
                    echo_counter <= 0;
                    state <= TRIGGER;
                end
                
                // =============================================
                // TRIGGER: Generate 10µs trigger pulse
                // =============================================
                TRIGGER: begin
                    if (counter < TRIGGER_TIME) begin
                        trigger <= 1;
                        counter <= counter + 1;
                    end else begin
                        trigger <= 0;
                        counter <= 0;
                        state <= WAIT_ECHO;
                    end
                end
                
                // =============================================
                // WAIT_ECHO: Wait for echo to go high
                // =============================================
                WAIT_ECHO: begin
                    if (echo == 1) begin
                        echo_counter <= 0;
                        state <= MEASURE;
                    end else if (counter >= ECHO_TIMEOUT) begin
                        // Timeout - no echo received
                        counter <= 0;
                        state <= DELAY;
                    end else begin
                        counter <= counter + 1;
                    end
                end
                
                // =============================================
                // MEASURE: Count echo pulse width
                // =============================================
                MEASURE: begin
                    if (echo == 1) begin
                        if (echo_counter < ECHO_TIMEOUT) begin
                            echo_counter <= echo_counter + 1;
                        end else begin
                            // Timeout protection
                            state <= DELAY;
                            counter <= 0;
                        end
                    end else begin
                        // Echo went low - measurement complete
                        state <= CALC;
                    end
                end
                
                // =============================================
                // CALC: Calculate distance and control output
                // =============================================
                CALC: begin
                    // Check if distance < 10cm
                    // echo_counter represents time in clock cycles
                    if (echo_counter > 0 && echo_counter < DISTANCE_THRESHOLD) begin
                        // Object detected within 10cm - restart timer
                        traffic_hold_active <= 1;
                        traffic_timer <= LED_HOLD_TIME;
                        traffic_detected <= 1;
                    end
                    // If object is far (>10cm), let the timer continue countdown
                    // Don't reset traffic_hold_active here, let it expire naturally
                    counter <= 0;
                    state <= DELAY;
                end
                
                // =============================================
                // DELAY: Wait before next measurement (60ms)
                // =============================================
                DELAY: begin
                    if (counter >= MEASUREMENT_DELAY) begin
                        counter <= 0;
                        state <= IDLE;
                    end else begin
                        counter <= counter + 1;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
endmodule
