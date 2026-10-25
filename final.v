  module program_memory(
    input clk,
    input [2:0] addr,
    output reg [15:0] instruction,

    input write_en,
    input [7:0] write_addr,
    input [15:0] write_data
);

    reg [15:0] mem [0:127];

    always @(posedge clk) begin
        if (write_en)
            mem[write_addr] <= write_data;

        instruction <= mem[addr];
    end

endmodule


module reg_1(
    input clk,
    input rst,
    input [15:0] instruction_in,
    output reg [15:0] instruction_out
);

    always @(posedge clk) begin
        if (rst)
            instruction_out <= 16'b0110_0000_0000_0000;
        else
            instruction_out <= instruction_in;
    end

endmodule


module decoder(
    input [15:0] instruction,

    output [3:0] opcode,
    output [1:0] rd,
    output [1:0] rs,
    output [7:0] value
);

    assign opcode = instruction[15:12];
    assign rd     = instruction[11:10];
    assign rs     = instruction[9:8];
    assign value  = instruction[7:0];

endmodule


module reg_2(
    input clk,
    input rst,

    input [3:0] opcode_in,
    input [1:0] rd_in,
    input [1:0] rs_in,
    input [7:0] value_in,

    output reg [3:0] opcode_out,
    output reg [1:0] rd_out,
    output reg [1:0] rs_out,
    output reg [7:0] value_out
);

    always @(posedge clk) begin
        if (rst) begin
            opcode_out <= 4'b0110;
            rd_out <= 2'b0;
            rs_out <= 2'b0;
            value_out <= 8'b0;
        end
        else begin
            opcode_out <= opcode_in;
            rd_out <= rd_in;
            rs_out <= rs_in;
            value_out <= value_in;
        end
    end

endmodule


module control_unit(
    input [3:0] opcode,

    output reg alu_en,
    output reg reg_write,
    output reg load_select,
    output reg counter_en,
    output reg flag_en,
    output reg pwm_set,
    output reg blink_set
);

    always @(*) begin

        alu_en = 1'b0;
        reg_write = 1'b0;
        load_select = 1'b0;
        counter_en = 1'b0;
        flag_en = 1'b0;
        pwm_set = 1'b0;
        blink_set = 1'b0;

        case(opcode)

            4'b0000: begin
                alu_en = 1'b1;
                reg_write = 1'b1;
                flag_en = 1'b1;
            end

            4'b0001: begin
                alu_en = 1'b1;
                reg_write = 1'b1;
                flag_en = 1'b1;
            end

            4'b0010: begin
                alu_en = 1'b1;
                reg_write = 1'b1;
                flag_en = 1'b1;
            end

            4'b0011: begin
                alu_en = 1'b1;
                reg_write = 1'b1;
                flag_en = 1'b1;
            end

            4'b0100: begin
                load_select = 1'b1;
                reg_write = 1'b1;
            end

            4'b0101: begin
                alu_en = 1'b1;
            end

            4'b0110: begin
            end

            4'b0111: begin
                counter_en = 1'b1;
            end

            4'b1000: begin
                pwm_set = 1'b1;
            end

            4'b1001: begin
                blink_set = 1'b1;
            end

            default: begin
            end

        endcase

    end

endmodule


module program_loader(
    input clk,
    input rst,

    input [7:0] rx_data,
    input rx_valid,

    output reg pm_write_en,
    output reg [7:0] pm_write_addr,
    output reg [15:0] pm_write_data
);

    reg [1:0] load_state;

    always @(posedge clk) begin

        if (rst) begin

            load_state <= 2'd0;

            pm_write_en <= 1'b0;
            pm_write_addr <= 8'd0;
            pm_write_data <= 16'd0;

        end
        else begin

            pm_write_en <= 1'b0;

            if (rx_valid) begin

                case (load_state)

                    2'd0: begin
                        pm_write_addr <= rx_data;
                        load_state <= 2'd1;
                    end

                    2'd1: begin
                        pm_write_data[15:8] <= rx_data;
                        load_state <= 2'd2;
                    end

                    default: begin
                        pm_write_data[7:0] <= rx_data;
                        pm_write_en <= 1'b1;
                        load_state <= 2'd0;
                    end

                endcase

            end

        end

    end

endmodule


module counter_unit #(
    parameter WIDTH = 26
)(
    input clk,
    input rst,
    input counter_en,
    input pwm_set,
    input blink_set,
    input [1:0] sel,
    input [7:0] cmp_data,

    output reg [WIDTH-1:0] counter0,
    output reg [WIDTH-1:0] counter1,
    output pwm0_out,
    output blink0_out,
    output pwm1_out,
    output blink1_out
);

    reg running0;
    reg running1;
    reg [7:0] cmp0;
    reg [7:0] cmp1;
    reg [7:0] cmp2;
    reg [7:0] cmp3;

    always @(posedge clk) begin

        if (rst) begin
            counter0 <= {WIDTH{1'b0}};
            counter1 <= {WIDTH{1'b0}};
            running0 <= 1'b0;
            running1 <= 1'b0;
            cmp0 <= 8'd0;
            cmp1 <= 8'd0;
            cmp2 <= 8'd0;
            cmp3 <= 8'd0;
        end
        else begin

            if (counter_en) begin
                case (sel)
                    2'd0: running0 <= 1'b1;
                    2'd1: running1 <= 1'b1;
                    default: begin
                        running0 <= 1'b1;
                        running1 <= 1'b1;
                    end
                endcase
            end

            if (running0)
                counter0 <= counter0 + 1'b1;

            if (running1)
                counter1 <= counter1 + 1'b1;

            if (pwm_set) begin
                case (sel)
                    2'd0: cmp0 <= cmp_data;
                    2'd1: cmp1 <= cmp_data;
                    2'd2: cmp2 <= cmp_data;
                    default: cmp3 <= cmp_data;
                endcase
            end

            if (blink_set)
                cmp1 <= cmp_data;

        end

    end

    assign pwm0_out   = (counter0[15:8] < cmp0);
    assign blink0_out = (counter0[WIDTH-1:WIDTH-8] < cmp1);
    assign pwm1_out   = (counter1[15:8] < cmp2);
    assign blink1_out = (counter1[WIDTH-1:WIDTH-8] < cmp3);

endmodule

module cpu_top(
    input clk,
    input rst,

    input uart_rx_pin,

    output [11:0] leds,
    output onboard_led,
    output [1:0] timer1_out
);

    wire [2:0] pc_out;

    wire [15:0] instruction;

    wire [15:0] instruction_reg;

    wire [3:0] opcode_out;
    wire [1:0] rd_out;
    wire [1:0] rs_out;
    wire [7:0] value_out;

    wire [3:0] opcode_out_we;
    wire [1:0] rd_out_we;
    wire [1:0] rs_out_we;
    wire [7:0] value_out_we;

    wire [7:0] rs1_data;
    wire [7:0] rs2_data;

    wire [7:0] alu_a_pre;
    wire [7:0] alu_b_pre;
    wire [7:0] alu_a;
    wire [7:0] alu_b;
    wire [7:0] alu_result;
    wire [7:0] ex_result;

    wire forward_a_mem;
    wire forward_a_wb;
    wire forward_b_mem;
    wire forward_b_wb;

    wire alu_en;
    wire reg_write;
    wire load_select;
    wire counter_en;
    wire flag_en;
    wire pwm_set;
    wire blink_set;

    wire alu_carry;
    wire alu_zero;
    wire zero_flag;
    wire carry_flag;

    wire [7:0] mem_result;
    wire [1:0] mem_rd;
    wire mem_reg_write;

    wire [7:0] wb_data;
    wire [1:0] wb_rd;
    wire wb_reg_write;

    wire [1:0] write_addr;
    wire [7:0] write_data;
    wire write_en;

    wire [25:0] counter0;
    wire [25:0] counter1;
    wire pwm_out;
    wire blink_out;
    wire pwm1_out;
    wire blink1_out;

    wire baud_tick;

    wire [7:0] uart_rx_data;
    wire uart_rx_valid;

    wire pm_write_en;
    wire [7:0] pm_write_addr;
    wire [15:0] pm_write_data;
    reg [23:0] program_led_timer;
    reg program_led;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            program_led_timer <= 24'd0;
            program_led       <= 1'b0;
        end

        else begin

            if (pm_write_en) begin
                program_led_timer <= 24'd0;
                program_led       <= 1'b1;
            end

            else if (program_led) begin

                if (program_led_timer < 24'd13_500_000) begin
                    program_led_timer <= program_led_timer + 1'b1;
                end

                else begin
                    program_led_timer <= 24'd0;
                    program_led       <= 1'b0;
                end

            end

        end

    end
    assign onboard_led = ~program_led;

    pc pc_unit(
        .clk(clk),
        .rst(rst),
        .pc(pc_out)
    );

    baud_generator #(
        .CLK_FREQ(27_000_000),
        .BAUD_RATE(115200)
    ) baud_gen(
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick)
    );

    uart_rx uart_receiver(
        .clk(clk),
        .rst(rst),
        .rx(uart_rx_pin),
        .baud_tick(baud_tick),
        .data_out(uart_rx_data),
        .data_valid(uart_rx_valid)
    );

    program_loader loader(
        .clk(clk),
        .rst(rst),
        .rx_data(uart_rx_data),
        .rx_valid(uart_rx_valid),
        .pm_write_en(pm_write_en),
        .pm_write_addr(pm_write_addr),
        .pm_write_data(pm_write_data)
    );

    program_memory pm(
        .clk(clk),
        .addr(pc_out),
        .instruction(instruction),

        .write_en(pm_write_en),
        .write_addr(pm_write_addr),
        .write_data(pm_write_data)
    );

    reg_1 pipeline_1(
        .clk(clk),
        .rst(rst),
        .instruction_in(instruction),
        .instruction_out(instruction_reg)
    );

    decoder dec(
        .instruction(instruction_reg),

        .opcode(opcode_out),
        .rd(rd_out),
        .rs(rs_out),
        .value(value_out)
    );

    reg_2 pipeline_2(
        .clk(clk),
        .rst(rst),

        .opcode_in(opcode_out),
        .rd_in(rd_out),
        .rs_in(rs_out),
        .value_in(value_out),

        .opcode_out(opcode_out_we),
        .rd_out(rd_out_we),
        .rs_out(rs_out_we),
        .value_out(value_out_we)
    );

    control_unit control(
        .opcode(opcode_out_we),

        .alu_en(alu_en),
        .reg_write(reg_write),
        .load_select(load_select),
        .counter_en(counter_en),
        .flag_en(flag_en),
        .pwm_set(pwm_set),
        .blink_set(blink_set)
    );

    reg_file registers(
        .clk(clk),
        .rst(rst),

        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),

        .rs1(rd_out_we),
        .rs2(rs_out_we),

        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    forwarding_unit forwarding(
        .id_rs1(rd_out_we),
        .id_rs2(rs_out_we),

        .mem_rd(mem_rd),
        .mem_reg_write(mem_reg_write),

        .wb_rd(wb_rd),
        .wb_reg_write(wb_reg_write),

        .forward_a_mem(forward_a_mem),
        .forward_a_wb(forward_a_wb),
        .forward_b_mem(forward_b_mem),
        .forward_b_wb(forward_b_wb)
    );

    mux_2to1 mux_a_wb(
        .a(rs1_data),
        .b(wb_data),
        .select(forward_a_wb),
        .y(alu_a_pre)
    );

    mux_2to1 mux_a(
        .a(alu_a_pre),
        .b(mem_result),
        .select(forward_a_mem),
        .y(alu_a)
    );

    mux_2to1 mux_b_wb(
        .a(rs2_data),
        .b(wb_data),
        .select(forward_b_wb),
        .y(alu_b_pre)
    );

    mux_2to1 mux_b(
        .a(alu_b_pre),
        .b(mem_result),
        .select(forward_b_mem),
        .y(alu_b)
    );

    alu alu_unit(
        .a(alu_a),
        .b(alu_b),
        .alu_opcode(opcode_out_we[2:0]),

        .result(alu_result),
        .carry(alu_carry),
        .zero(alu_zero)
    );

    mux_2to1 mux_ex(
        .a(alu_result),
        .b(value_out_we),
        .select(load_select),
        .y(ex_result)
    );

    flag_register flags(
        .clk(clk),
        .rst(rst),
        .flag_en(flag_en),
        .zero_in(alu_zero),
        .carry_in(alu_carry),

        .zero_flag(zero_flag),
        .carry_flag(carry_flag)
    );

    reg_3 pipeline_3(
        .clk(clk),
        .rst(rst),

        .alu_result_in(ex_result),
        .rd_in(rd_out_we),
        .reg_write_in(reg_write),

        .alu_result_out(mem_result),
        .rd_out(mem_rd),
        .reg_write_out(mem_reg_write)
    );

    reg_4 pipeline_4(
        .clk(clk),
        .rst(rst),

        .data_in(mem_result),
        .rd_in(mem_rd),
        .reg_write_in(mem_reg_write),

        .data_out(wb_data),
        .rd_out(wb_rd),
        .reg_write_out(wb_reg_write)
    );

    assign write_addr = wb_rd;
    assign write_data = wb_data;
    assign write_en = wb_reg_write;

    counter_unit #(
        .WIDTH(26)
    ) counter_inst(
        .clk(clk),
        .rst(rst),
        .counter_en(counter_en),
        .pwm_set(pwm_set),
        .blink_set(blink_set),
        .sel(rd_out_we),
        .cmp_data(value_out_we),
        .counter0(counter0),
        .counter1(counter1),
        .pwm0_out(pwm_out),
        .blink0_out(blink_out),
        .pwm1_out(pwm1_out),
        .blink1_out(blink1_out)
    );

    reg [7:0] led_result;

    always @(posedge clk or posedge rst) begin
        if (rst)
            led_result <= 8'b0;
        else if (mem_reg_write)
            led_result <= mem_result;
    end

    assign leds[7:0]  = led_result;
    assign leds[8]    = zero_flag;
    assign leds[9]    = carry_flag;
    assign leds[10]   = blink_out;
    assign leds[11]   = pwm_out;

    assign timer1_out[0] = pwm1_out;
    assign timer1_out[1] = blink1_out;

endmodule
