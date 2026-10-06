module connector(
    input clk,
    input rst,
    output [3:0] leds,
    output zero
);
    wire rst_internal = rst;

    wire [2:0] pc_wire;
    wire [7:0] inst_wire;
    wire [2:0] op_wire;
    wire [1:0] rd_wire;
    wire [1:0] rs_wire;
    wire [2:0] value_wire;
    wire load_select_wire;
    wire write_en_wire;
    wire [1:0] alu_op_wire;
    wire [3:0] write_wire;
    wire [3:0] rd_data_wire;
    wire [3:0] rs_data_wire;
    wire [3:0] result_wire;
    wire zero_wire;
    wire [3:0] r0_display_wire;

    reg flag_zero;
    always @(posedge clk or posedge rst_internal) begin
        if (rst_internal)
            flag_zero <= 1'b0;
        else if (write_en_wire && !load_select_wire)
            flag_zero <= zero_wire;
    end

    assign leds = ~r0_display_wire;
    assign zero = ~flag_zero;

    program_counter pc (
        .rst(rst_internal),
        .clk(clk),
        .pc_out(pc_wire)
    );

    program_memory pm (
        .clk(clk),
        .rst(rst_internal),
        .pc(pc_wire),
        .instruction(inst_wire)
    );

    decoder d (
        .instruction(inst_wire),
        .opcode(op_wire),
        .rd(rd_wire),
        .rs(rs_wire),
        .value(value_wire)
    );

    control_unit cu (
        .opcode(op_wire),
        .load_select(load_select_wire),
        .write_en(write_en_wire),
        .alu_op(alu_op_wire)
    );

    register_file r (
        .write_en(write_en_wire),
        .clk(clk),
        .rst(rst_internal),
        .r_a_0(rd_wire),
        .r_a_1(rs_wire),
        .w_a(rd_wire),
        .w_d(write_wire),
        .r_d_0(rd_data_wire),
        .r_d_1(rs_data_wire),
        .r0_display(r0_display_wire)
    );

    alu my_alu (
        .a(rd_data_wire),
        .b(rs_data_wire),
        .alu_op(alu_op_wire),
        .result(result_wire),
        .zero(zero_wire)
    );

    assign write_wire = (load_select_wire) ? {1'b0, value_wire} : result_wire;

endmodule

module program_counter (
    input rst,
    input clk,
    output reg [2:0] pc_out
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_out <= 3'b000;
        else if (pc_out < 3'd3)
            pc_out <= pc_out + 1'b1;
    end
endmodule

module program_memory (
    input clk,
    input rst,
    input [2:0] pc,
    output reg [7:0] instruction
);
    always @(*) begin
        case(pc)
            3'd0: instruction = 8'b000_00_000;
            3'd1: instruction = 8'b000_01_000;
            3'd2: instruction = 8'b001_00_010;
            3'd3: instruction = 8'b111_00_000;
            default: instruction = 8'b111_00_000;
        endcase
    end
endmodule

module decoder (
    input [7:0] instruction,
    output wire [2:0] opcode,
    output wire [1:0] rd,
    output wire [1:0] rs,
    output wire [2:0] value
);
    assign opcode = instruction[7:5];
    assign rd     = instruction[4:3];
    assign rs     = instruction[2:1];
    assign value  = instruction[2:0];
endmodule

module control_unit (
    input [2:0] opcode,
    output reg load_select,
    output reg write_en,
    output reg [1:0] alu_op
);
    always @(*) begin
        write_en    = 1'b0;
        load_select = 1'b0;
        alu_op      = 2'b00;
        case(opcode)
            3'b000: begin
                write_en    = 1'b1;
                load_select = 1'b1;
                alu_op      = 2'b00;
            end
            3'b001: begin
                write_en    = 1'b1;
                load_select = 1'b0;
                alu_op      = 2'b00;
            end
            3'b010: begin
                write_en    = 1'b1;
                load_select = 1'b0;
                alu_op      = 2'b01;
            end
            3'b011: begin
                write_en    = 1'b1;
                load_select = 1'b0;
                alu_op      = 2'b10;
            end
            3'b100: begin
                write_en    = 1'b1;
                load_select = 1'b0;
                alu_op      = 2'b11;
            end

            default: begin
                write_en    = 1'b0;
                load_select = 1'b0;
                alu_op      = 2'b00;
            end
        endcase
    end
endmodule

module register_file (
    input write_en,
    input clk,
    input rst,
    input wire [1:0] r_a_0,
    input wire [1:0] r_a_1,
    input wire [1:0] w_a,
    input wire [3:0] w_d,
    output wire [3:0] r_d_0,
    output wire [3:0] r_d_1,
    output wire [3:0] r0_display
);
    reg [3:0] reg_file[3:0];

    assign r_d_0 = reg_file[r_a_0];
    assign r_d_1 = reg_file[r_a_1];
    reg [1:0] last_write_addr;
    always @(posedge clk or posedge rst) begin
    if (rst)
        last_write_addr <= 2'd0;
    else if (write_en)
        last_write_addr <= w_a;
    end
    assign r0_display = reg_file[last_write_addr];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_file[0] <= 4'd0;
            reg_file[1] <= 4'd0;
            reg_file[2] <= 4'd0;
            reg_file[3] <= 4'd0;
        end
        else if (write_en) begin
            reg_file[w_a] <= w_d;
        end
    end
endmodule

module alu (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [1:0] alu_op,
    output reg [3:0] result,
    output reg zero
);
    always @(*) begin
        case(alu_op)
            2'b00:   result = a + b;
            2'b01:   result = a - b;
            2'b10:   result = a&b;
            2'b11:   result = a|b;
            default: result = 4'd0;
        endcase

        if (result == 4'd0)
            zero = 1'b1;
        else
            zero = 1'b0;
    end
endmodule