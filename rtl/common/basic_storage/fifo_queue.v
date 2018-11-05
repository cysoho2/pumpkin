module fifo_queue
#(
    parameter SINGLE_ENTRY_WIDTH_IN_BITS    = 512,
    parameter QUEUE_SIZE                    = 16,
    parameter QUEUE_PTR_WIDTH_IN_BITS       = 4,
    parameter WRITE_MASK_LEN                = SINGLE_ENTRY_WIDTH_IN_BITS / `BYTE_LEN_IN_BITS,
    parameter STORAGE_TYPE                  = "LUTRAM" /* option: FlipFlop, LUTRAM */
)
(
    input                                                                   clk_in,
    input                                                                   reset_in,

    output                                                                  is_empty_out,
    output                                                                  is_full_out,

    input           [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]                    request_in,
    input                                                                   request_valid_in,
    output  reg                                                             issue_ack_out,

    output  reg     [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]                    request_out,
    output  reg                                                             request_valid_out,
    input                                                                   issue_ack_in
);

wire [QUEUE_SIZE - 1 : 0] write_qualified;
wire [QUEUE_SIZE - 1 : 0] read_qualified;

wire [QUEUE_SIZE - 1 : 0] fifo_entry_valid_packed;
wire [SINGLE_ENTRY_WIDTH_IN_BITS  - 1 : 0] fifo_entry_packed [QUEUE_SIZE - 1 : 0];

reg  [QUEUE_PTR_WIDTH_IN_BITS     - 1 : 0] write_ptr;
reg  [QUEUE_PTR_WIDTH_IN_BITS     - 1 : 0] read_ptr;

assign is_full_out  = &fifo_entry_valid_packed;
assign is_empty_out = &(~fifo_entry_valid_packed);

always@(posedge clk_in, posedge reset_in)
begin
    if(reset_in)
    begin
        write_ptr     <= {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}};
        issue_ack_out <= 1'b0;
        read_ptr      <= {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}};
        request_out   <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b0}};
        request_valid_out <= 1'b0;
    end

    else
    begin
        // write logic
        // generate write_ptr when the queue is full but the issue_ack_in is high, save 1 cycle
        if(|write_qualified)
        begin
            write_ptr           <= write_ptr == {(QUEUE_PTR_WIDTH_IN_BITS){1'b1}} ? {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}} : write_ptr + 1'b1;
            issue_ack_out       <= 1'b1;
        end

        else
        begin
            write_ptr           <= write_ptr;
            issue_ack_out       <= 1'b0;
        end

        // read logic
        if(|read_qualified)
        begin
            read_ptr            <= read_ptr == {(QUEUE_PTR_WIDTH_IN_BITS){1'b1}} ? {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}} : read_ptr + 1'b1;
            request_out         <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b0}};
            request_valid_out   <= 1'b0;
        end

        else if(fifo_entry_valid_packed[read_ptr])
        begin
            read_ptr             <= read_ptr;
            request_out          <= fifo_entry_packed[read_ptr];
            request_valid_out    <= 1'b1;
        end

        else
        begin
            read_ptr             <= read_ptr;
            request_out          <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b0}};
            request_valid_out    <= 1'b0;
        end
    end
end

generate
genvar gen;

if(STORAGE_TYPE == "FlipFlop")
begin
    for(gen = 0; gen < QUEUE_SIZE; gen = gen + 1)
    begin
        reg [SINGLE_ENTRY_WIDTH_IN_BITS  - 1 : 0] entry;
        reg                                       entry_valid;

        assign fifo_entry_packed[gen]        =    entry;
        assign fifo_entry_valid_packed[gen]  =    entry_valid;

        assign write_qualified[gen] = (~is_full_out | (issue_ack_in & is_full_out & gen == read_ptr))
                                        & ~issue_ack_out & request_valid_in & gen == write_ptr;

        assign read_qualified[gen]  = ~is_empty_out & issue_ack_in & entry_valid & gen == read_ptr;

        always @(posedge clk_in, posedge reset_in)
        begin
            if (reset_in)
            begin
                entry       <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b0}};
                entry_valid <= 1'b0;
            end

            else
            begin
                if(write_qualified[gen] & read_qualified[gen])
                begin
                    entry       <= request_in;
                    entry_valid <= 1'b1;
                end

                else
                begin
                    if(read_qualified[gen])
                    begin
                        entry       <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b0}};
                        entry_valid <= 1'b0;
                    end

                    else if(write_qualified[gen])
                    begin
                        entry       <= request_in;
                        entry_valid <= 1'b1;
                    end

                    else
                    begin
                        entry       <= entry;
                        entry_valid <= entry_valid;
                    end
                end
            end
        end
    end
end

else if(STORAGE_TYPE == "LUTRAM")
begin
    for(gen = 0; gen < QUEUE_SIZE; gen = gen + 1)
    begin
        
        reg                                       entry_valid;
        assign fifo_entry_valid_packed[gen]  =    entry_valid;

        assign write_qualified[gen] = (~is_full_out | (issue_ack_in & is_full_out & gen == read_ptr))
                                        & ~issue_ack_out & request_valid_in & gen == write_ptr;

        assign read_qualified[gen]  = ~is_empty_out & issue_ack_in & entry_valid & gen == read_ptr;

        always @(posedge clk_in, posedge reset_in)
        begin
            if (reset_in)
            begin
                entry_valid <= 1'b0;
            end

            else
            begin
                if(write_qualified[gen] & read_qualified[gen])
                begin
                    entry_valid <= 1'b1;
                end

                else
                begin
                    if(read_qualified[gen])
                    begin
                        entry_valid <= 1'b0;
                    end

                    else if(write_qualified[gen])
                    begin
                        entry_valid <= 1'b1;
                    end

                    else
                    begin
                        entry_valid <= entry_valid;
                    end
                end
            end
        end

        single_port_lutram
        #(
            .SINGLE_ENTRY_WIDTH_IN_BITS     (SINGLE_ENTRY_WIDTH_IN_BITS),
            .NUM_SET                        (1),
            .SET_PTR_WIDTH_IN_BITS          (1),
            .WITH_VALID_REG_ARRAY           ("No")
        )
        single_port_lutram
        (
            .clk_in                         (clk_in),
            .reset_in                       (reset_in),

            .access_en_in                   (1'b1),
            .write_en_in                    (write_qualified[gen] ? {(WRITE_MASK_LEN){1'b1}} :
                                                                    {(WRITE_MASK_LEN){1'b0}}),
            .access_set_addr_in             (1'b0),

            .write_entry_in                 (request_in),
            .read_entry_out                 (fifo_entry_packed[gen]),
            .read_valid_out                 ()
        );
    end
end

endgenerate
endmodule
