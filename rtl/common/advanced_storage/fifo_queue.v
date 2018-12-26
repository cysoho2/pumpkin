`include "parameters.vh"

module fifo_queue
#(
    parameter SINGLE_ENTRY_WIDTH_IN_BITS    = 64,
    parameter QUEUE_SIZE                    = 4, /* must be a power of 2*/
    parameter QUEUE_PTR_WIDTH_IN_BITS       = $clog2(QUEUE_SIZE),
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
    output                                                                  issue_ack_out,

    output  reg     [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0]                    request_out,
    output  reg                                                             request_valid_out,
    input                                                                   issue_ack_in
);

wire [QUEUE_SIZE - 1 : 0]                  write_qualified;
wire [QUEUE_SIZE - 1 : 0]                  read_complete;
wire [SINGLE_ENTRY_WIDTH_IN_BITS  - 1 : 0] storage_output;

wire [QUEUE_SIZE - 1 : 0]                  fifo_entry_valid_packed;
wire [SINGLE_ENTRY_WIDTH_IN_BITS  - 1 : 0] fifo_entry_packed [QUEUE_SIZE - 1 : 0];

reg  [QUEUE_PTR_WIDTH_IN_BITS     - 1 : 0] write_ptr;
reg  [QUEUE_PTR_WIDTH_IN_BITS     - 1 : 0] read_ptr;

wire [QUEUE_PTR_WIDTH_IN_BITS     - 1 : 0] next_write_ptr = (write_ptr == {(QUEUE_PTR_WIDTH_IN_BITS){1'b1}} ?
                                                                          {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}} :
                                                                          write_ptr + 1'b1);
wire [QUEUE_PTR_WIDTH_IN_BITS     - 1 : 0] next_read_ptr  = (read_ptr  == {(QUEUE_PTR_WIDTH_IN_BITS){1'b1}} ?
                                                                          {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}} :
                                                                          read_ptr + 1'b1);

assign is_full_out   = &fifo_entry_valid_packed;
assign is_empty_out  = &(~fifo_entry_valid_packed);
assign issue_ack_out = ~is_full_out | (issue_ack_in & request_valid_out & request_valid_in);

// read/write ptr management
always@(posedge clk_in)
begin
    if(reset_in)
    begin
        write_ptr           <= {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}};
        read_ptr            <= {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}};
        request_out         <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b0}};
        request_valid_out   <= 1'b0;
    end

    else
    begin
        // write logic
        // generate write_ptr when the queue is full but the issue_ack_in is high, save 1 cycle
        if(|write_qualified)
        begin
            write_ptr               <= next_write_ptr;
        end

        else
        begin
            write_ptr               <= write_ptr;
        end

        // read complete, move to next read
        if(|read_complete)
        begin     
            read_ptr                <= next_read_ptr;
            request_out             <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b0}};
            request_valid_out       <= 1'b0;
        end

        // hold on the current read
        else if(fifo_entry_valid_packed[read_ptr])
        begin
            read_ptr                <= read_ptr;
            request_out             <= storage_output;
            request_valid_out       <= 1'b1;
        end

        // current read ptr pointed an empty entry, but it's about to be written,
        // use the incoming write for fast output
        else if(~fifo_entry_valid_packed[read_ptr] & write_qualified[read_ptr])
        begin
            request_out             <= request_in;
            request_valid_out       <= 1'b1;
        end
        
        else
        begin
            read_ptr                <= read_ptr;
            request_out             <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b0}};
            request_valid_out       <= 1'b0;
        end
    end
end

// entry valid
generate
genvar gen;

for(gen = 0; gen < QUEUE_SIZE; gen = gen + 1)
begin
    
    reg                                   entry_valid;
    assign fifo_entry_valid_packed[gen] = entry_valid;

    assign write_qualified[gen]   = (~is_full_out | (issue_ack_in & request_valid_out & gen == read_ptr))
                                      & request_valid_in & gen == write_ptr;

    assign read_complete[gen]    = ~is_empty_out & issue_ack_in & entry_valid & request_valid_out & gen == read_ptr;

    always @(posedge clk_in)
    begin
        if (reset_in)
        begin
            entry_valid <= 1'b0;
        end

        else
        begin
            if(write_qualified[gen] & read_complete[gen])
            begin
                entry_valid <= 1'b1;
            end

            else
            begin
                if(read_complete[gen])
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
end

// entry storage
if(STORAGE_TYPE == "FlipFlop")
begin
    integer queue_index;
    reg    [SINGLE_ENTRY_WIDTH_IN_BITS - 1 : 0] regfile [QUEUE_SIZE - 1 : 0];
    assign storage_output = regfile[|read_complete ? next_read_ptr : read_ptr];
    
    always@(posedge clk_in)
    begin
        if(reset_in)
        begin
            for(queue_index = 0; queue_index < QUEUE_SIZE; queue_index = queue_index + 1)
            begin
                regfile[queue_index] <= 0;
            end
        end

        else
        begin
            if(|write_qualified && |read_complete && write_ptr == read_ptr)
            begin
                regfile[write_ptr] <= request_in;
            end

            else
            begin
                if(|read_complete)
                begin
                    regfile[read_ptr] <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b0}};
                end

                if(|write_qualified)
                begin
                    regfile[write_ptr] <= request_in;
                end
            end
        end
    end
end

else if(STORAGE_TYPE == "LUTRAM")
begin

    dual_port_lutram
    #(
        .SINGLE_ENTRY_WIDTH_IN_BITS     (SINGLE_ENTRY_WIDTH_IN_BITS),
        .NUM_SET                        (QUEUE_SIZE),
        .CONFIG_MODE                    ("WriteFirst"),
        .WITH_VALID_REG_ARRAY           ("No")
    )
    dual_port_lutram
    (
        .clk_in                         (clk_in),
        .reset_in                       (reset_in),

        .write_port_access_en_in        (1'b1),
        .write_port_write_en_in         (write_qualified[write_ptr] ? {(WRITE_MASK_LEN){1'b1}} :
                                                                      {(WRITE_MASK_LEN){1'b0}}),
        .write_port_access_set_addr_in  (write_ptr),
        .write_port_data_in             (request_in),

        .read_port_access_en_in         (1'b1),
        .read_port_access_set_addr_in   (|read_complete ? next_read_ptr : read_ptr),
        .read_port_data_out             (storage_output),
        .read_port_valid_out            ()
    );
end

else
begin
    assign storage_output = 0;
end

endgenerate
endmodule
