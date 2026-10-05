module top_tm1638_demo #(
    parameter integer CLOCK_HZ = 12000000
)(
    input  wire clk,
    output reg  tm_cs,
    output wire tm_clk,
    inout  wire tm_dio
);

    localparam HIGH = 1'b1;
    localparam LOW  = 1'b0;

    localparam [6:0]
        SEG_0    = 7'b0111111,
        SEG_1    = 7'b0000110,
        SEG_2    = 7'b1011011,
        SEG_3    = 7'b1001111,
        SEG_4    = 7'b1100110,
        SEG_5    = 7'b1101101,
        SEG_6    = 7'b1111101,
        SEG_7    = 7'b0000111,
        SEG_8    = 7'b1111111,
        SEG_9    = 7'b1101111,
        SEG_DASH = 7'b1000000,
        SEG_T    = 7'b1110000,
        SEG_E    = 7'b1111001,
        SEG_BLK  = 7'b0000000;

    localparam [7:0]
        C_READ  = 8'b01000010,
        C_WRITE = 8'b01000000,
        C_DISP  = 8'b10001111,
        C_ADDR  = 8'b11000000;

    localparam integer CLK_1S = CLOCK_HZ - 1;

    localparam [1:0]
        MODE_PINGPONG = 2'b00,
        MODE_LEFT     = 2'b01,
        MODE_RIGHT    = 2'b10;

    // ================================================================
    // NIM:
    // "22-505938-tE-55406" = 18 chars.
    //
    // 44-element buffer, fixed 8digit window,
    // berarti posisi scroll ada = 0..26.
    // ================================================================
    localparam [5:0] MAX_SCROLL = 6'd26;

    reg rst = HIGH;
    reg [5:0] instruction_step;
    reg [7:0] keys;
    reg [7:0] key_scan;

    reg [23:0] anim_counter;
    reg [5:0]  scroll_pos;
    reg        scroll_dir;

    reg [6:0] scroll_buffer [0:43];
    reg [6:0] frame [0:7];

    integer buffer_index;
    integer frame_index;

    // ================================================================
    // S1 -> Ping-Pong
    // S2 -> Left
    // S3 -> Right
    // ================================================================
    reg [1:0] mode;
    reg [2:0] previous_keys;

    wire [2:0] pressed_keys = keys[2:0] & ~previous_keys;

    always @(posedge clk) begin

        if (rst) begin
            mode <= MODE_PINGPONG;
            previous_keys <= 3'b000;

        end else begin

            previous_keys <= keys[2:0];

            if (pressed_keys[0])
                mode <= MODE_PINGPONG;

            else if (pressed_keys[1])
                mode <= MODE_LEFT;

            else if (pressed_keys[2])
                mode <= MODE_RIGHT;

        end

    end

    // ================================================================
    // LED1 for S1 / Ping-Pong
    // LED2 for S2 / Left
    // LED3 for S3 / Right
    // ================================================================
    wire [7:0] led_data =
        (mode == MODE_PINGPONG) ? 8'b00000001 :
        (mode == MODE_LEFT)     ? 8'b00000010 :
        (mode == MODE_RIGHT)    ? 8'b00000100 :
                                  8'b00000000;

    // ================================================================
    // DIO tri-state
    // ================================================================
    reg tm_rw;

    wire dio_in;
    wire dio_out;

    SB_IO #(
        .PIN_TYPE(6'b101001),
        .PULLUP(1'b1)
    ) tm_dio_io (
        .PACKAGE_PIN(tm_dio),
        .OUTPUT_ENABLE(tm_rw),
        .D_IN_0(dio_in),
        .D_OUT_0(dio_out)
    );

    // ================================================================
    // Low-level TM1638 driver
    // ================================================================
    reg        tm_latch;
    wire       busy;
    wire [7:0] tm_data;
    wire [7:0] tm_in;
    reg  [7:0] tm_out;

    assign tm_in   = tm_data;
    assign tm_data = tm_rw ? tm_out : 8'bzzzzzzzz;

    tm1638 u_tm1638 (
        .clk(clk),
        .rst(rst),
        .data_latch(tm_latch),
        .data(tm_data),
        .rw(tm_rw),
        .busy(busy),
        .sclk(tm_clk),
        .dio_in(dio_in),
        .dio_out(dio_out)
    );

    // ================================================================
    // NIM / text ROM
    //
    // NIM = 22-505938-tE-55406
    // ================================================================
    function [6:0] text_char;
        input integer index;

        begin
            case (index)

                 0: text_char = SEG_2;
                 1: text_char = SEG_2;
                 2: text_char = SEG_DASH;

                 3: text_char = SEG_5;
                 4: text_char = SEG_0;
                 5: text_char = SEG_5;
                 6: text_char = SEG_9;
                 7: text_char = SEG_3;
                 8: text_char = SEG_8;

                 9: text_char = SEG_DASH;

                10: text_char = SEG_T;
                11: text_char = SEG_E;

                12: text_char = SEG_DASH;

                13: text_char = SEG_5;
                14: text_char = SEG_5;
                15: text_char = SEG_4;
                16: text_char = SEG_0;
                17: text_char = SEG_6;

                default: text_char = SEG_BLK;

            endcase
        end
    endfunction

    // ================================================================
    // Fixed display window:
    // buffer[18..25]
    //
    // NIM mulai di buffer[26..43]
    // ================================================================

    task shift_left;
        integer i;

        begin
            for (i = 0; i < 43; i = i + 1)
                scroll_buffer[i] <= scroll_buffer[i + 1];

            scroll_buffer[43] <= SEG_BLK;
        end
    endtask

    task shift_right;
        integer i;

        begin
            for (i = 43; i > 0; i = i - 1)
                scroll_buffer[i] <= scroll_buffer[i - 1];

            scroll_buffer[0] <= SEG_BLK;
        end
    endtask

    task display_digit;
        input [2:0] digit;

        begin
            tm_latch <= HIGH;
            tm_out <= {1'b0, frame[digit]};
        end
    endtask

    task display_led;
        input [2:0] led;

        begin
            tm_latch <= HIGH;
            tm_out <= {7'b0000000, led_data[led]};
        end
    endtask

    // ================================================================
    // Scrolling
    // ================================================================

    wire anim_tick = anim_counter >= CLK_1S;

    always @(posedge clk) begin

        if (rst) begin

            anim_counter <= 24'd0;
            scroll_pos   <= 6'd0;
            scroll_dir   <= 1'b1;

            for (
                buffer_index = 0;
                buffer_index < 44;
                buffer_index = buffer_index + 1
            )
                scroll_buffer[buffer_index]
                    <= text_char(buffer_index - 26);

        end else begin

            if (anim_tick) begin

                anim_counter <= 24'd0;

                // ========================================================
                // S1 / MODE_PINGPONG
                // ========================================================

                if (mode == MODE_PINGPONG) begin

                    if (scroll_dir) begin

                        if (scroll_pos >= MAX_SCROLL) begin

                            scroll_pos <= MAX_SCROLL - 1'b1;
                            scroll_dir <= 1'b0;

                            shift_right;

                        end else begin

                            scroll_pos <= scroll_pos + 1'b1;

                            shift_left;

                        end

                    end else begin

                        if (scroll_pos == 0) begin

                            scroll_pos <= 6'd1;
                            scroll_dir <= 1'b1;

                            shift_left;

                        end else begin

                            scroll_pos <= scroll_pos - 1'b1;

                            shift_right;

                        end
                    end

                end

                // ========================================================
                // S2 / MODE_LEFT
                // ========================================================

                else if (mode == MODE_LEFT) begin

                    scroll_dir <= 1'b1;

                    if (scroll_pos >= MAX_SCROLL) begin

                        scroll_pos <= 6'd0;

                        for (
                            buffer_index = 0;
                            buffer_index < 44;
                            buffer_index = buffer_index + 1
                        )
                            scroll_buffer[buffer_index]
                                <= text_char(buffer_index - 26);

                    end else begin

                        scroll_pos <= scroll_pos + 1'b1;

                        shift_left;

                    end

                end

                // ========================================================
                // S3 / MODE_RIGHT
                // ========================================================

                else if (mode == MODE_RIGHT) begin

                    scroll_dir <= 1'b0;

                    if (scroll_pos == 0) begin

                        scroll_pos <= MAX_SCROLL;

                        for (
                            buffer_index = 0;
                            buffer_index < 44;
                            buffer_index = buffer_index + 1
                        )
                            scroll_buffer[buffer_index]
                                <= text_char(buffer_index);

                    end else begin

                        scroll_pos <= scroll_pos - 1'b1;

                        shift_right;

                    end

                end

            end else begin

                anim_counter <= anim_counter + 1'b1;

            end

        end
    end

    // ================================================================
    // TM1638 protocol FSM
    // ================================================================

    reg [5:0] scan_div;

    always @(posedge clk) begin

        if (rst) begin

            instruction_step <= 6'd0;

            tm_cs    <= HIGH;
            tm_rw    <= HIGH;
            tm_latch <= LOW;
            tm_out   <= 8'b00000000;

            keys     <= 8'b00000000;
            key_scan <= 8'b00000000;

            scan_div <= 6'd0;

            rst <= LOW;

            for (
                frame_index = 0;
                frame_index < 8;
                frame_index = frame_index + 1
            )
                frame[frame_index] <= SEG_BLK;

        end else begin

            scan_div <= scan_div + 1'b1;

            if (tm_latch) begin

                tm_latch <= LOW;

            end else if (scan_div[0] && !busy) begin

                case (instruction_step)

                    // ====================================================
                    // READ KEYS
                    // ====================================================

                    6'd1:
                        begin
                            tm_cs <= LOW;
                            tm_rw <= HIGH;
                        end

                    6'd2:
                        begin
                            tm_latch <= HIGH;
                            tm_out <= C_READ;
                        end

                    6'd3:
                        begin
                            tm_latch <= HIGH;
                            tm_rw <= LOW;
                        end

                    6'd4:
                        begin
                            key_scan[0] <= tm_in[0];
                            key_scan[4] <= tm_in[4];
                        end

                    6'd5:
                        tm_latch <= HIGH;

                    6'd6:
                        begin
                            key_scan[1] <= tm_in[0];
                            key_scan[5] <= tm_in[4];
                        end

                    6'd7:
                        tm_latch <= HIGH;

                    6'd8:
                        begin
                            key_scan[2] <= tm_in[0];
                            key_scan[6] <= tm_in[4];
                        end

                    6'd9:
                        tm_latch <= HIGH;

                    6'd10:
                        begin
                            key_scan[3] <= tm_in[0];
                            key_scan[7] <= tm_in[4];
                        end

                    6'd11:
                        begin
                            tm_cs <= HIGH;
                            tm_rw <= HIGH;
                            keys <= key_scan;
                        end

                    // ====================================================
                    // AUTO-INCREMENT WRITE
                    // ====================================================

                    6'd12:
                        begin
                            tm_cs <= LOW;
                            tm_rw <= HIGH;
                        end

                    6'd13:
                        begin
                            tm_latch <= HIGH;
                            tm_out <= C_WRITE;
                        end

                    6'd14:
                        tm_cs <= HIGH;

                    // ====================================================
                    // WRITE DISPLAY RAM
                    // ====================================================

                    6'd15:
                        begin

                            tm_cs <= LOW;
                            tm_rw <= HIGH;

                            for (
                                frame_index = 0;
                                frame_index < 8;
                                frame_index = frame_index + 1
                            )
                                frame[frame_index]
                                    <= scroll_buffer[18 + frame_index];

                        end

                    6'd16:
                        begin
                            tm_latch <= HIGH;
                            tm_out <= C_ADDR;
                        end

                    6'd17:
                        display_digit(3'd0);

                    6'd18:
                        display_led(3'd0);

                    6'd19:
                        display_digit(3'd1);

                    6'd20:
                        display_led(3'd1);

                    6'd21:
                        display_digit(3'd2);

                    6'd22:
                        display_led(3'd2);

                    6'd23:
                        display_digit(3'd3);

                    6'd24:
                        display_led(3'd3);

                    6'd25:
                        display_digit(3'd4);

                    6'd26:
                        display_led(3'd4);

                    6'd27:
                        display_digit(3'd5);

                    6'd28:
                        display_led(3'd5);

                    6'd29:
                        display_digit(3'd6);

                    6'd30:
                        display_led(3'd6);

                    6'd31:
                        display_digit(3'd7);

                    6'd32:
                        display_led(3'd7);

                    6'd33:
                        tm_cs <= HIGH;

                    // ====================================================
                    // DISPLAY ON / MAX BRIGHTNESS
                    // ====================================================

                    6'd34:
                        begin
                            tm_cs <= LOW;
                            tm_rw <= HIGH;
                        end

                    6'd35:
                        begin
                            tm_latch <= HIGH;
                            tm_out <= C_DISP;
                        end

                    6'd36:
                        tm_cs <= HIGH;

                    default:
                        begin
                        end

                endcase

                if (instruction_step == 6'd36)
                    instruction_step <= 6'd0;
                else
                    instruction_step <= instruction_step + 1'b1;

            end else if (busy) begin

                tm_latch <= LOW;

            end

        end
    end

endmodule