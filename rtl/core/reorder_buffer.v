module reorder_buffer
#(
    parameter NUM_GENERAL_PURPOSE_REGISTER = 32,
    parameter NUM_ROB_ENTRY = 6,

    parameter NUM_ROB_STATE = 4,

    parameter ROB_INSTRUCTION_TYPE_WIDTH_IN_BITS = 6,
    parameter ROB_STATE_WIDTH_IN_BITS = $clog2(NUM_ROB_STATE),
    parameter ROB_DST_WIDTH_IN_BITS = $clog2(NUM_GENERAL_PURPOSE_REGISTER),
    parameter ROB_ADDRESS_WIDTH_IN_BITS = 32,
    parameter ROB_VALUE_WIDTH_IN_BITS = 64,

    parameter REGISTER_STATUS_ROB_INDEX_WIDTH_IN_BITS = $clog2(NUM_ROB_ENTRY + 1) + 1,

    //parameter NUM_DISPATCH_STAGE_REQUEST = 2,
    //parameter DISPATCH_STAGE_REQUEST_FLATTED_WIDTH_IN_BITS = NUM_DISPATCH_STAGE_REQUEST *
)
(
    input clk_in,
    input reset_in,

    // dispatch
    output issue_ack_out,
    input dispatch_valid_in,
    input [ROB_INSTRUCTION_TYPE_WIDTH_IN_BITS - 1 : 0] dispatch_instruction_type_in,
    input [ROB_DST_WIDTH_IN_BITS - 1 : 0] dispatch_dst_in,

    // commit
);

// register status
reg [NUM_GENERAL_PURPOSE_REGISTER - 1 : 0]              register_status_busy_bit_array;
reg [REGISTER_STATUS_ROB_INDEX_WIDTH_IN_BITS - 1 : 0]   register_status_rob_index_table [NUM_GENERAL_PURPOSE_REGISTER - 1 : 0];

// reorder buffer
reg [NUM_ROB_ENTRY - 1 : 0]                             rob_busy_bit_array;
reg [ROB_INSTRUCTION_TYPE_WIDTH_IN_BITS - 1 : 0]        rob_instruction_type_table      [NUM_ROB_ENTRY - 1 : 0];
reg [ROB_STATE_WIDTH_IN_BITS - 1 : 0]                   rob_state_table                 [NUM_ROB_ENTRY - 1 : 0];
reg [ROB_DST_WIDTH_IN_BITS - 1 : 0]                     rob_dst_table                   [NUM_ROB_ENTRY - 1 : 0];
reg [ROB_ADDRESS_WIDTH_IN_BITS - 1 : 0]                 rob_address_table               [NUM_ROB_ENTRY - 1 : 0];
reg [ROB_VALUE_WIDTH_IN_BITS - 1 : 0]                   rob_valud_table                 [NUM_ROB_ENTRY - 1 : 0];

endmodule
