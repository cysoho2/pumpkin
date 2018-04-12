`timescale 10ns/1ns
`include "parameters.h"

module mux_testbench();

parameter NUMBER_WAYS = 8;
parameter SINGLE_ELEMENT_SIZE_IN_BITS = 4;

reg                                                             clk_in;
reg                                                             reset_in;
reg     [31:0]                                                  clk_ctr;

reg     [NUMBER_WAYS * SINGLE_ELEMENT_SIZE_IN_BITS - 1:0]       way_packed_in;
reg     [NUMBER_WAYS - 1 : 0]                                   sel_in;
wire    [SINGLE_ELEMENT_SIZE_IN_BITS - 1:0]                     way_packed_out;

mux_8
#
(
        .NUMBER_WAYS(NUMBER_WAYS),
        .SINGLE_ELEMENT_SIZE_IN_BITS(SINGLE_ELEMENT_SIZE_IN_BITS)
)
mux_8
(
        .way_packed_in			(way_packed_in),
        .sel_in		                (sel_in),
        .way_packed_out		        (way_packed_out)
);

always @(posedge clk_in or posedge reset_in)
begin
        if(reset_in)
        begin
                clk_ctr <= 0;
                sel_in  <= {{(NUMBER_WAYS-1){1'b0}}, {1'b1}};
                way_packed_in <= {4'd15, 4'd13, 4'd11, 4'd9, 4'd7, 4'd5, 4'd3, 4'd1};
        end
        
        else if(clk_ctr === 4'd15)
        begin
                clk_ctr <= 0;
                sel_in <= {sel_in[NUMBER_WAYS-2:0], sel_in[NUMBER_WAYS-1]}; 
        end

        else
        begin
                clk_ctr <= clk_ctr + 1'b1;
        end
end

initial
begin
        $display("\n[info-rtl] simulation begins now\n");
        clk_in   = 1'b0;
        reset_in = 1'b0;
#5      reset_in = 1'b1;
#5      reset_in = 1'b0;

#3000   $display("\n[info-rtl] simulation comes to the end\n");
        $finish;
end

always begin #1 clk_in <= ~clk_in; end;

endmodule
