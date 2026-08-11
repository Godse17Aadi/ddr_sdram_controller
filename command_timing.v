module command_timing (
    input clk,

    // Timing parameters from REG1
    input [1:0] sc_cl,
    input [1:0] sc_rc,
    input [3:0] sc_rrd,
    input [3:0] sc_bl,

    // Command Generator
    input [2:0] timer_select,
    input       timer_start,

    // Outputs
    output reg  timer_done,
    output reg  oe
);

    localparam TIMER_TRCD = 3'd0;
    localparam TIMER_CL   = 3'd1;
    localparam TIMER_TWR  = 3'd2;
    localparam TIMER_TRP  = 3'd3;
    localparam TIMER_TRFC = 3'd4;
    localparam TIMER_TMRD = 3'd5;

    // Fixed delays introduced by our FSM implementation.
    localparam [3:0] DELAY_TWR  = 4'd2;
    localparam [3:0] DELAY_TRP  = 4'd2;
    localparam [3:0] DELAY_TMRD = 4'd2;

    reg [3:0] counter;
    reg       timer_busy;

    always @(posedge clk) begin

        // Default: done is a one-clock pulse
        timer_done <= 1'b0;

        // Start a new timer only when idle
        if (timer_start && !timer_busy) begin

            case (timer_select)

                TIMER_TRCD:
                    counter <= {2'b00, sc_rc};

                TIMER_CL: begin
                    case (sc_cl)
                        2'b00: counter <= 4'd2; // 1.5 -> 2
                        2'b01: counter <= 4'd2; // 2.0
                        2'b10: counter <= 4'd3; // 2.5 -> 3
                        2'b11: counter <= 4'd3; // 3.0
                        default: counter <= 4'd0;
                    endcase
                end

                TIMER_TRFC:
                    counter <= sc_rrd;

                TIMER_TWR:
                    counter <= DELAY_TWR;

                TIMER_TRP:
                    counter <= DELAY_TRP;

                TIMER_TMRD:
                    counter <= DELAY_TMRD;

                default:
                    counter <= 4'd0;

            endcase

            timer_busy <= 1'b1;
        end

        else if (timer_busy) begin

            if (counter > 1) begin
                counter <= counter - 1'b1;
            end

            else begin
                timer_done <= 1'b1;
                timer_busy <= 1'b0;
            end

        end

    end

    // OE intentionally left unspecified for now.
    always @(*) begin
        oe = 1'b0;
    end

endmodule


