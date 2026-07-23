// ============================================================================
// TOP MODULE: SMART TRAFFIC CONTROLLER (50 MHz)
// ============================================================================
module smart_traffic_controller(
    input  wire clk,              // 50 MHz system clock
    input  wire reset_n,          // Active-LOW reset

    // Ultrasonic sensors
    input  wire echo_a,
    input  wire echo_b,
    input  wire echo_c,
    input  wire echo_d,
    output wire trigger_a,
    output wire trigger_b,
    output wire trigger_c,
    output wire trigger_d,

    // Sound sensor INPUT (from physical sensor)
    input  wire sound_in,         // Physical sound sensor input

    // Traffic lights (3 bits each: [Green, Yellow, Red])
    output wire [2:0] lights_a,
    output wire [2:0] lights_b,
    output wire [2:0] lights_c,
    output wire [2:0] lights_d
);
    // Internal signals
    wire traffic_a, traffic_b, traffic_c, traffic_d;
    wire sound_sensor;

    // Instantiate sound sensor module
    sound_sensor_led sound_module (
        .clk(clk),
        .reset_n(reset_n),
        .sound_in(sound_in),
        .sound_sensor(sound_sensor)
    );

    // Instantiate ultrasonic sensor modules
    ultrasonic_dist sensor_a (
        .clk(clk),
        .reset_n(reset_n),
        .echo(echo_a),
        .trigger(trigger_a),
        .traffic_detected(traffic_a)
    );

    ultrasonic_dist sensor_b (
        .clk(clk),
        .reset_n(reset_n),
        .echo(echo_b),
        .trigger(trigger_b),
        .traffic_detected(traffic_b)
    );

    ultrasonic_dist sensor_c (
        .clk(clk),
        .reset_n(reset_n),
        .echo(echo_c),
        .trigger(trigger_c),
        .traffic_detected(traffic_c)
    );

    ultrasonic_dist sensor_d (
        .clk(clk),
        .reset_n(reset_n),
        .echo(echo_d),
        .trigger(trigger_d),
        .traffic_detected(traffic_d)
    );

    // Instantiate traffic light FSM controller
    traffic_fsm controller (
        .clk(clk),
        .reset_n(reset_n),
        .A(traffic_a),
        .B(traffic_b),
        .C(traffic_c),
        .D(traffic_d),
        .sound_sensor(sound_sensor),
        .lane_a_lights(lights_a),
        .lane_b_lights(lights_b),
        .lane_c_lights(lights_c),
        .lane_d_lights(lights_d)
    );
endmodule