`timescale 10ns/1ns
`include "parameters.h"

module fifo_testbench();

parameter QUEUE_SIZE = 16;
parameter QUEUE_PTR_WIDTH_IN_BITS = 4;
parameter SINGLE_ENTRY_WIDTH_IN_BITS = 32;
parameter STORAGE_TYPE = "LUTRAM";

reg                                             clk_in;
reg                                             reset_in;
reg     [31:0]                                  clk_ctr;

wire                                            is_empty;
wire		                                is_full;

reg     [SINGLE_ENTRY_WIDTH_IN_BITS - 1:0]      request_in;
reg                                             request_valid_in;
wire                                            issue_ack_from_fifo;
wire    [SINGLE_ENTRY_WIDTH_IN_BITS - 1:0]      request_out;
wire                                            request_valid_out;
reg     	                                issue_ack_to_fifo;

fifo_queue
#
(
        .QUEUE_SIZE(QUEUE_SIZE),
        .QUEUE_PTR_WIDTH_IN_BITS(QUEUE_PTR_WIDTH_IN_BITS),
        .SINGLE_ENTRY_WIDTH_IN_BITS(SINGLE_ENTRY_WIDTH_IN_BITS),
        .STORAGE_TYPE(STORAGE_TYPE)
)
fifo_queue
(
        .clk_in			(clk_in),
        .reset_in		(reset_in),
        
        .is_empty_out		(is_empty),
        .is_full_out		(is_full),

        .request_in		(request_in), 
        .request_valid_in	(request_valid_in),
        .issue_ack_out		(issue_ack_from_fifo),
        .request_out		(request_out),
        .request_valid_out      (request_valid_out),
        .issue_ack_in		(issue_ack_to_fifo),
        .fifo_entry_packed_out	(),
        .fifo_entry_valid_packed_out ()
);

always @(posedge clk_in or posedge reset_in)
begin
        if(reset_in)
        begin
                request_in <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b1}};
                request_valid_in <= 1'b0;
        end
        
        else if(issue_ack_from_fifo)
        begin
                request_in <= request_in - 1'b1;
                request_valid_in <= 1'b1;
        end

        else
        begin
                request_in       <= request_in;
                request_valid_in <= 1'b1;       
        end
end

always @(posedge clk_in or posedge reset_in)
begin
        if(reset_in)
        begin
                clk_ctr           <= 0;
                issue_ack_to_fifo <= 1'b0;
        end
        
        else
        begin
                clk_ctr <= clk_ctr + 1'b1;
                if(clk_ctr[3:0] == 5'b00000 & request_valid_out)
                begin
                        issue_ack_to_fifo <= 1'b1;
                end
                
                else
                begin
                        issue_ack_to_fifo <= 1'b0;
                end
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

always begin #1 clk_in <= ~clk_in; end

endmodule
