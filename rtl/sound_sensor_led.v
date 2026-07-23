// SOUND SENSOR MODULE (50 MHz Clock)
// ============================================================================
module sound_sensor_led (
    input wire clk,           // System clock (50 MHz)
    input wire reset_n,       // Active low reset
    input wire sound_in,      // Digital output from HS-S53-L sensor
    output reg sound_sensor   // Sound detected output
);
    // Parameters for 50 MHz clock
    // 2 seconds = 2 * 50,000,000 = 100,000,000 cycles
    parameter LED_HOLD_TIME = 100_000_000;    // LED on-time (2 seconds at 50 MHz)

    // Signals
    reg sound_prev;
    reg [31:0] led_cnt;
    reg led_active;

    // Detect falling edge of sound_in (sound detected on active-low sensor)
    wire sound_detected;
    assign sound_detected = sound_prev && !sound_in;  // Falling edge detection

    // Edge detection and LED timer
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sound_prev <= 1;
            led_cnt <= 0;
            led_active <= 0;
            sound_sensor <= 0;
        end else begin
            // Update previous state
            sound_prev <= sound_in;

            // Trigger LED on sound detection
            if (sound_detected) begin
                led_active <= 1;
                led_cnt <= 0;
            end else if (led_active) begin
                if (led_cnt < LED_HOLD_TIME - 1) begin
                    led_cnt <= led_cnt + 1;
                end else begin
                    led_active <= 0;
                end
            end

            // Output LED state
            sound_sensor <= led_active;
        end
    end
endmodule
