 module reorder_buffer
#(
    parameter NUM_GENERAL_PURPOSE_REGISTER = 32,
    parameter NUM_ROB_ENTRY = 6,
    parameter ROB_PTR_WIDTH_IN_BITS = $clog2(NUM_ROB_ENTRY) + 1;

    parameter NUM_ROB_STATE = 4,

    parameter ROB_INSTRUCTION_TYPE_WIDTH_IN_BITS = 6,
    parameter ROB_STATE_WIDTH_IN_BITS = $clog2(NUM_ROB_STATE),
    parameter ROB_DEST_WIDTH_IN_BITS = $clog2(NUM_GENERAL_PURPOSE_REGISTER),
    parameter ROB_ADDRESS_WIDTH_IN_BITS = 32,
    parameter ROB_VALUE_WIDTH_IN_BITS = 64,

    parameter REGISTER_STATUS_ROB_INDEX_WIDTH_IN_BITS = $clog2(NUM_ROB_ENTRY + 1) + 1,

    //parameter NUM_DISPATCH_STAGE_REQUEST = 2,
    //parameter DISPATCH_STAGE_REQUEST_FLATTED_WIDTH_IN_BITS = NUM_DISPATCH_STAGE_REQUEST *
)
(
    input clk_in,
    input reset_in,

    input flush_in,

    // dispatch
    output is_busy_out,
    output [ROB_PTR_WIDTH_IN_BITS - 1 : 0] now_rob_entry_index,
    input dispatch_valid_in,
    input [ROB_INSTRUCTION_TYPE_WIDTH_IN_BITS - 1 : 0] dispatch_instruction_type_in,
    input [ROB_DEST_WIDTH_IN_BITS - 1 : 0] dispatch_dest_in,

    // write back
    input wb_valid_in,
    input [ROB_PTR_WIDTH_IN_BITS - 1 : 0] wb_rob_entry_index_in;
    input [ROB_VALUE_WIDTH_IN_BITS - 1 : 0] wb_value_in;

    // commit
    output reg commit_valid_out,
    output reg commit_is_mem_out,
    output reg [ROB_ADDRESS_WIDTH_IN_BITS - 1 : 0] commit_address_out,
    output reg [ROB_VALUE_WIDTH_IN_BITS - 1 : 0] commit_value_out,
);

// queue
wire is_full;
wire is_empty;
reg [ROB_PTR_WIDTH_IN_BITS - 1 : 0] write_ptr;
reg [ROB_PTR_WIDTH_IN_BITS - 1 : 0] read_ptr;

wire [ROB_PTR_WIDTH_IN_BITS - 1 : 0] next_write_ptr = (write_ptr == ROB_PTR_WIDTH_IN_BITS - 1)? 0 : write_ptr + 1;
wire [ROB_PTR_WIDTH_IN_BITS - 1 : 0] next_read_ptr = (read_ptr == ROB_PTR_WIDTH_IN_BITS - 1)? 0 : read_ptr + 1;

// reorder buffer
wire [NUM_ROB_ENTRY - 1 : 0]                            rob_busy_bit_array;

reg [ROB_INSTRUCTION_TYPE_WIDTH_IN_BITS - 1 : 0]        rob_instruction_type_table      [NUM_ROB_ENTRY - 1 : 0];
//reg [ROB_STATE_WIDTH_IN_BITS - 1 : 0]                   rob_state_table                 [NUM_ROB_ENTRY - 1 : 0];
reg [NUM_ROB_ENTRY - 1 : 0]                             rob_ready_bit_array;

reg [ROB_DEST_WIDTH_IN_BITS - 1 : 0]                    rob_dest_table                  [NUM_ROB_ENTRY - 1 : 0];
reg [ROB_ADDRESS_WIDTH_IN_BITS - 1 : 0]                 rob_address_table               [NUM_ROB_ENTRY - 1 : 0];
reg [ROB_VALUE_WIDTH_IN_BITS - 1 : 0]                   rob_value_table                 [NUM_ROB_ENTRY - 1 : 0];

wire record_enable = ~is_full & dispatch_valid_in;
wire commit_enable = ~is_empty & |(rob_ready_bit_array & rob_busy_bit_array);

assign is_full = &rob_busy_bit_array;
assign is_empty = ~(|rob_busy_bit_array);
assign is_busy_out = is_full;
assign now_rob_entry_index = write_ptr;

generate
genvar ENTRY_INDEX;

for (ENTRY_INDEX = 0; ENTRY_INDEX < NUM_ROB_ENTRY; ENTRY_INDEX = ENTRY_INDEX + 1)
begin
    reg busy_bit;
    reg ready_bit;

    assign rob_busy_bit_array[ENTRY_INDEX] = busy_bit;

    always @ (posedge clk_in)
    begin
        if (reset_in)
        begin
            busy_bit <= 0;
            ready_bit <= 0;
        end
        else
        begin
            if (flush_in)
            begin
                busy_bit <= 0;
            end
            else
            begin
                if (record_enable & (write_ptr == ENTRY_INDEX))
                begin
                    busy_bit <= 1;
                    ready_bit <= 0;
                end

                if (commit_enable & (read_ptr == ENTRY_INDEX))
                begin
                    busy_bit <= 0;
                    ready_bit <= ready_bit
                end

                if (wb_valid_in & (wb_rob_entry_index_in == ENTRY_INDEX))
                begin
                    busy_bit <= busy_bit;
                    ready_bit <= 1;
                end
            end
        end
    end
end

endgenerate


always @ (posedge clk_in)
begin
    if (reset_in)
    begin
        write_ptr <= 0;
        read_ptr <= 0;

        for (ENTRY_INDEX = 0; ENTRY_INDEX < NUM_ROB_ENTRY; ENTRY_INDEX = ENTRY_INDEX + 1)
        begin
            rob_instruction_type_table[ENTRY_INDEX] <= 0;
            rob_ready_bit_array[ENTRY_INDEX] <= 0;
            rob_dest_table[ENTRY_INDEX] <= 0;
            rob_address_table[ENTRY_INDEX] <= 0;
            rob_value_table[ENTRY_INDEX] <= 0;
        end
    end
    else
    begin
        if (record_enable)
        begin
            write_ptr <= next_write_ptr;
            rob_instruction_type_table[write_ptr] <= dispatch_instruction_type_in;
            rob_dest_table[write_ptr] <= dispatch_dest_in;
        end

        if (commit_enable)
        begin
            read_ptr <= next_read_ptr;

            commit_is_mem_out <= (rob_instruction_type_table[read_ptr] == );
            commit_valid_out <= 1;
            commit_address_out <= rob_address_table[read_ptr];
            commit_value_out <= rob_value_table[read_ptr];
        end
        else
        begin
            read_ptr <= read_ptr;

            commit_is_mem_out <= 0;
            commit_valid_out <= 0;
            commit_address_out <= 0;
            commit_value_out <= 0;
        end

        if (wb_valid_in)
        begin
            rob_value_table[wb_rob_entry_index_in] <= wb_value_in;
        end
    end
end


endmodule
