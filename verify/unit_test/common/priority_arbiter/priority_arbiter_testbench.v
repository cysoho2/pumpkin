`timescale 10ns/1ns
`include "parameters.h"

module priority_arbiter_testbench();

parameter NUM_REQUESTS  = 3;
parameter SINGLE_REQUEST_WIDTH_IN_BITS = 64;

reg                                                     clk_in;
reg                                                     reset_in;
reg     [31:0]                                          clk_ctr;

reg     [(SINGLE_REQUEST_WIDTH_IN_BITS - 1):0]          request_0_to_arb;
reg                                                     request_0_valid_to_arb;
reg                                                     request_0_critical_to_arb;
wire                                                    issue_ack_0_from_arb;

reg     [(SINGLE_REQUEST_WIDTH_IN_BITS - 1):0]          request_1_to_arb;
reg                                                     request_1_valid_to_arb;
reg                                                     request_1_critical_to_arb;
wire                                                    issue_ack_1_from_arb;

reg     [(SINGLE_REQUEST_WIDTH_IN_BITS - 1):0]          request_2_to_arb;
reg                                                     request_2_valid_to_arb;
reg                                                     request_2_critical_to_arb;
wire                                                    issue_ack_2_from_arb;

wire	[(SINGLE_REQUEST_WIDTH_IN_BITS - 1):0]          request_from_arb;
wire                                                    request_valid_from_arb;
reg	                                                issue_ack_to_arb;

priority_arbiter
#(.NUM_REQUESTS(NUM_REQUESTS), .SINGLE_REQUEST_WIDTH_IN_BITS(SINGLE_REQUEST_WIDTH_IN_BITS))
priority_arbiter
(
        .reset_in                   (reset_in),
        .clk_in                     (clk_in),

        // the arbiter considers priority from right(high) to left(low)
        .request_packed_in          ({request_2_to_arb, request_1_to_arb, request_0_to_arb}),
        .request_valid_packed_in    ({request_2_valid_to_arb, request_1_valid_to_arb, request_0_valid_to_arb}),
        .request_critical_packed_in ({request_2_critical_to_arb, request_1_critical_to_arb, request_0_critical_to_arb}),
        .issue_ack_out              ({issue_ack_2_from_arb, issue_ack_1_from_arb, issue_ack_0_from_arb}),
        
        .request_out                (request_from_arb),
        .request_valid_out          (request_valid_from_arb),
        .issue_ack_in               (issue_ack_to_arb)
);

always @(posedge clk_in or posedge reset_in)
begin
        if(reset_in)
        begin
                clk_ctr                   <= 0;
                
                request_0_to_arb          <= {(SINGLE_REQUEST_WIDTH_IN_BITS){1'b0}} + 1'b1;
                request_0_valid_to_arb    <= 1'b0;
                request_0_critical_to_arb <= 1'b0;

                request_1_to_arb          <= {{(SINGLE_REQUEST_WIDTH_IN_BITS/2){1'b1}},{(SINGLE_REQUEST_WIDTH_IN_BITS/2){1'b0}}};
                request_1_valid_to_arb    <= 1'b0;
                request_1_critical_to_arb <= 1'b0;

                request_2_to_arb          <= {(SINGLE_REQUEST_WIDTH_IN_BITS){1'b1}};
                request_2_valid_to_arb    <= 1'b0;
                request_2_critical_to_arb <= 1'b0;

                issue_ack_to_arb          <= {(NUM_REQUESTS){1'b0}};
        end
        
        else
        begin
                clk_ctr <= clk_ctr + 1'b1;

                // request 0
                if(issue_ack_0_from_arb & request_0_valid_to_arb)
                begin
                        request_0_to_arb       <= request_0_to_arb + 1'b1;
                        request_0_valid_to_arb <= 1'b1;
                end
                else
                begin
                        request_0_to_arb       <= request_0_to_arb;
                        request_0_valid_to_arb <= 1'b1;
                end

                if(clk_ctr % 25 == 0 & request_0_valid_to_arb)
                begin
                        request_0_critical_to_arb <= 1'b1;
                end
                
                else if(request_0_critical_to_arb & issue_ack_0_from_arb)
                begin
                        request_0_critical_to_arb <= 1'b0;
                end

                // request 1
                if(issue_ack_1_from_arb & request_1_valid_to_arb)
                begin
                        request_1_to_arb       <= request_1_to_arb + 1'b1;
                        request_1_valid_to_arb <= 1'b1;
                end
                else
                begin
                        request_1_to_arb       <= request_1_to_arb;
                        request_1_valid_to_arb <= 1'b1;
                end

                if(clk_ctr % 15 == 0 & request_1_valid_to_arb)
                begin
                        request_1_critical_to_arb <= 1'b1;
                end
                
                else if(request_1_critical_to_arb & issue_ack_1_from_arb)
                begin
                        request_1_critical_to_arb <= 1'b0;
                end

                // request 2
                if(issue_ack_2_from_arb & request_2_valid_to_arb)
                begin
                        request_2_to_arb       <= request_2_to_arb + 1'b1;
                        request_2_valid_to_arb <= 1'b1;
                end
                else
                begin
                        request_2_to_arb       <= request_2_to_arb;
                        request_2_valid_to_arb <= 1'b1;
                end

                if(clk_ctr % 10 == 0 & request_2_valid_to_arb)
                begin
                        request_2_critical_to_arb <= 1'b1;
                end
                
                else if(request_2_critical_to_arb & issue_ack_2_from_arb)
                begin
                        request_2_critical_to_arb <= 1'b0;
                end

                // issue ack to arb
                if(clk_ctr % 3 == 0 & request_valid_from_arb)
                begin
                        issue_ack_to_arb <= 1'b1;
                end
                
                else
                begin
                        issue_ack_to_arb <= 1'b0;
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
