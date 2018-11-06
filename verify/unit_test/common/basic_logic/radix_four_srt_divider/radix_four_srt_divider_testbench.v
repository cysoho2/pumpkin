`include "sim_config.h"
`include "parameters.h"

module radix_four_rst_divider_testbench;

parameter OPERAND_WIDTH_IN_BITS = 64;
parameter NUM_RADIX = 4;
parameter DIVISOR_INSPECTED_WIDTH_IN_BITS = 3; //from most significant bit to least significant bit
parameter PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS = 5; //from most significant bit to least significant bit

reg reset_in;
reg clk_in;

wire request_ack_out;
reg dividend_sign_in;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0] dividend_in;
reg divisor_sign_in;
reg [OPERAND_WIDTH_IN_BITS - 1 : 0] divisor_in;

reg request_ack_in;
wire quotient_sign_out;
wire [OPERAND_WIDTH_IN_BITS - 1 : 0] quotient_out;
wire remainder_sign_out;
wire [OPERAND_WIDTH_IN_BITS - 1 : 0] remainder_out;

initial
begin
    `ifdef DUMP
        $dumpfile(`DUMP_FILENAME);
        $dumpvars(0, radix_four_rst_divider);
    `endif

    $display("\n[info-testbench] simulation for %m begins now");
    reset_in = 1;
    clk_in = 1;

    #(`FULL_CYCLE_DELAY * 10) dividend_in <= 53;
                              divisor_in <= 7;
    #(`FULL_CYCLE_DELAY * 10) reset_in <= 0;

    #(`FULL_CYCLE_DELAY * 50) $display("\n[info-rtl] simulation comes to the end\n");
                              $finish;
end

always begin #(`HALF_CYCLE_DELAY) clk_in        <= ~clk_in; end


radix_four_rst_divider
#(
    .OPERAND_WIDTH_IN_BITS(OPERAND_WIDTH_IN_BITS),
    .NUM_RADIX(NUM_RADIX),
    .DIVISOR_INSPECTED_WIDTH_IN_BITS(DIVISOR_INSPECTED_WIDTH_IN_BITS), //from most significant bit to least significant bit
    .PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS(PARTIAL_REMAINDER_INSPECTED_WIDTH_IN_BITS) //from most significant bit to least significant bit
)
radix_four_rst_divider
(
    .reset_in(reset_in),
    .clk_in(clk_in),

    .request_ack_out(request_ack_out),
    .dividend_sign_in(dividend_sign_in),
    .dividend_in(dividend_in),
    .divisor_sign_in(divisor_sign_in),
    .divisor_in(divisor_in),

    .request_ack_in(request_ack_in),
    .quotient_sign_out(quotient_sign_out),
    .quotient_out(quotient_out),
    .remainder_sign_out(remainder_sign_out),
    .remainder_out(remainder_out)
);


endmodule

