// ============================================================================
// MODULE: TRAFFIC LIGHT FSM CONTROLLER - 50MHz CLOCK VERSION
// ============================================================================
module traffic_fsm(
    input  wire clk,              // 50 MHz system clock
    input  wire reset_n,          // Active-LOW reset
    input  wire A,                // Traffic detected on lane a
    input  wire B,                // Traffic detected on lane b
    input  wire C,                // Traffic detected on lane c
    input  wire D,                // Traffic detected on lane d
    input  wire sound_sensor,     // Sound sensor on lane a (priority)
    output reg [2:0] lane_a_lights, // [G, Y, R]
    output reg [2:0] lane_b_lights,
    output reg [2:0] lane_c_lights,
    output reg [2:0] lane_d_lights
);

    // Light encoding
    localparam GREEN  = 3'b100;
    localparam YELLOW = 3'b010;
    localparam RED    = 3'b001;
    
    // Timing parameters (50MHz clock)
    // 50MHz = 50,000,000 cycles per second
    parameter GREEN_TIME  = 100_000_000;      // 2 seconds minimum (100M cycles)
    parameter YELLOW_TIME = 100_000_000;      // 2 seconds (100M cycles)
    parameter MAX_GREEN_TIME = 500_000_000;   // 10 seconds maximum (500M cycles)
    
    // State definitions
    localparam LANE_A_GREEN  = 4'd0;
    localparam LANE_A_YELLOW = 4'd1;
    localparam LANE_B_GREEN  = 4'd2;
    localparam LANE_B_YELLOW = 4'd3;
    localparam LANE_C_GREEN  = 4'd4;
    localparam LANE_C_YELLOW = 4'd5;
    localparam LANE_D_GREEN  = 4'd6;
    localparam LANE_D_YELLOW = 4'd7;
    localparam DECIDE_NEXT   = 4'd8;
    
    reg [3:0] state, next_state;
    reg [31:0] timer;
    reg [1:0] priority_lane; // 0=a, 1=b, 2=c, 3=d
    reg [1:0] last_served_lane; // Track which lane was served last
    reg [1:0] current_serving_lane; // Which lane is currently being served
    reg priority_interrupt; // Flag for priority interrupt
    
    // Timer management and last served lane tracking
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            timer <= 0;
            state <= DECIDE_NEXT;
            last_served_lane <= 2'd3; // Start before lane 'a' so first cycle is 'a'
            current_serving_lane <= 2'd0;
        end else begin
            if (state != next_state) begin
                timer <= 0;
            end else begin
                timer <= timer + 1;
            end
            state <= next_state;
            
            // Track which lane is currently being served
            case (state)
                LANE_A_GREEN, LANE_A_YELLOW: current_serving_lane <= 2'd0;
                LANE_B_GREEN, LANE_B_YELLOW: current_serving_lane <= 2'd1;
                LANE_C_GREEN, LANE_C_YELLOW: current_serving_lane <= 2'd2;
                LANE_D_GREEN, LANE_D_YELLOW: current_serving_lane <= 2'd3;
            endcase
            
            // Update last served lane when yellow phase ends
            if ((state == LANE_A_YELLOW || state == LANE_B_YELLOW || 
                 state == LANE_C_YELLOW || state == LANE_D_YELLOW) && 
                timer >= YELLOW_TIME - 1) begin
                case (state)
                    LANE_A_YELLOW: last_served_lane <= 2'd0;
                    LANE_B_YELLOW: last_served_lane <= 2'd1;
                    LANE_C_YELLOW: last_served_lane <= 2'd2;
                    LANE_D_YELLOW: last_served_lane <= 2'd3;
                    default: last_served_lane <= last_served_lane;
                endcase
            end
        end
    end
    
    // Priority decision logic with interrupt detection
    always @(*) begin
        priority_interrupt = 1'b0;
        
        // Determine priority lane based on traffic/sound detection
        if (sound_sensor || A) begin
            priority_lane = 2'd0; // Lane a has highest priority
        end else if (B) begin
            priority_lane = 2'd1; // Lane b
        end else if (C) begin
            priority_lane = 2'd2; // Lane c
        end else if (D) begin
            priority_lane = 2'd3; // Lane d
        end else begin
            // No traffic detected, follow round-robin order a>b>c>d
            case (last_served_lane)
                2'd0: priority_lane = 2'd1; // After a, serve b
                2'd1: priority_lane = 2'd2; // After b, serve c
                2'd2: priority_lane = 2'd3; // After c, serve d
                2'd3: priority_lane = 2'd0; // After d, serve a
                default: priority_lane = 2'd0;
            endcase
        end
        
        // Check if we need to interrupt current lane based on priority
        // Priority order: A (sound/traffic) > B > C > D
        if (sound_sensor || A) begin
            // Lane A has highest priority - interrupt any other lane
            if (state == LANE_B_GREEN || state == LANE_C_GREEN || state == LANE_D_GREEN) begin
                priority_interrupt = 1'b1;
            end
        end else if (B) begin
            // Lane B interrupts C and D
            if (state == LANE_C_GREEN || state == LANE_D_GREEN) begin
                priority_interrupt = 1'b1;
            end
        end else if (C) begin
            // Lane C interrupts D only
            if (state == LANE_D_GREEN) begin
                priority_interrupt = 1'b1;
            end
        end
    end
    
    // Next state logic with priority interruption and extended green
    always @(*) begin
        next_state = state;
        
        case (state)
            LANE_A_GREEN: begin
                // Check for priority interrupt (shouldn't happen for lane A)
                if (priority_interrupt) begin
                    next_state = LANE_A_YELLOW; // Go to yellow immediately
                end else if (timer >= GREEN_TIME) begin
                    // Stay green if sound sensor or traffic A is still detected
                    // But enforce maximum green time to prevent starvation
                    if ((sound_sensor || A) && (timer < MAX_GREEN_TIME)) begin
                        next_state = LANE_A_GREEN; // Stay green
                    end else begin
                        next_state = LANE_A_YELLOW; // Go to yellow
                    end
                end
            end
            
            LANE_A_YELLOW: begin
                if (timer >= YELLOW_TIME)
                    next_state = DECIDE_NEXT;
            end
            
            LANE_B_GREEN: begin
                // Check for priority interrupt (A has higher priority)
                if (priority_interrupt) begin
                    next_state = LANE_B_YELLOW; // Go to yellow immediately
                end else if (timer >= GREEN_TIME) begin
                    // Stay green if traffic B is still detected
                    if (B && (timer < MAX_GREEN_TIME)) begin
                        next_state = LANE_B_GREEN; // Stay green
                    end else begin
                        next_state = LANE_B_YELLOW; // Go to yellow
                    end
                end
            end
            
            LANE_B_YELLOW: begin
                if (timer >= YELLOW_TIME)
                    next_state = DECIDE_NEXT;
            end
            
            LANE_C_GREEN: begin
                // Check for priority interrupt (A or B have higher priority)
                if (priority_interrupt) begin
                    next_state = LANE_C_YELLOW; // Go to yellow immediately
                end else if (timer >= GREEN_TIME) begin
                    // Stay green if traffic C is still detected
                    if (C && (timer < MAX_GREEN_TIME)) begin
                        next_state = LANE_C_GREEN; // Stay green
                    end else begin
                        next_state = LANE_C_YELLOW; // Go to yellow
                    end
                end
            end
            
            LANE_C_YELLOW: begin
                if (timer >= YELLOW_TIME)
                    next_state = DECIDE_NEXT;
            end
            
            LANE_D_GREEN: begin
                // Check for priority interrupt (A, B, or C have higher priority)
                if (priority_interrupt) begin
                    next_state = LANE_D_YELLOW; // Go to yellow immediately
                end else if (timer >= GREEN_TIME) begin
                    // Stay green if traffic D is still detected
                    if (D && (timer < MAX_GREEN_TIME)) begin
                        next_state = LANE_D_GREEN; // Stay green
                    end else begin
                        next_state = LANE_D_YELLOW; // Go to yellow
                    end
                end
            end
            
            LANE_D_YELLOW: begin
                if (timer >= YELLOW_TIME)
                    next_state = DECIDE_NEXT;
            end
            
            DECIDE_NEXT: begin
                // Decide next lane based on priority
                case (priority_lane)
                    2'd0: next_state = LANE_A_GREEN;
                    2'd1: next_state = LANE_B_GREEN;
                    2'd2: next_state = LANE_C_GREEN;
                    2'd3: next_state = LANE_D_GREEN;
                endcase
            end
            
            default: next_state = DECIDE_NEXT;
        endcase
    end
    
    // Output logic
    always @(*) begin
        // Default: all red
        lane_a_lights = RED;
        lane_b_lights = RED;
        lane_c_lights = RED;
        lane_d_lights = RED;
        
        case (state)
            LANE_A_GREEN: begin
                lane_a_lights = GREEN;
            end
            
            LANE_A_YELLOW: begin
                lane_a_lights = YELLOW;
            end
            
            LANE_B_GREEN: begin
                lane_b_lights = GREEN;
            end
            
            LANE_B_YELLOW: begin
                lane_b_lights = YELLOW;
            end
            
            LANE_C_GREEN: begin
                lane_c_lights = GREEN;
            end
            
            LANE_C_YELLOW: begin
                lane_c_lights = YELLOW;
            end
            
            LANE_D_GREEN: begin
                lane_d_lights = GREEN;
            end
            
            LANE_D_YELLOW: begin
                lane_d_lights = YELLOW;
            end
            
            DECIDE_NEXT: begin
                // All red during transition
                lane_a_lights = RED;
                lane_b_lights = RED;
                lane_c_lights = RED;
                lane_d_lights = RED;
            end
        endcase
    end

endmodule
