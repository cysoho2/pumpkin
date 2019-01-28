module issue_queue
#(
    parameter NUM_ISSUE_QUEUE_ENTRY = 6,

    parameter INST_TYPE_LENGTH_IN_BITS = 2,
    parameter REG_INDEX_LENGTH_IN_BITS = 5,
    parameter CPU_OPERAND_LENGTH_IN_BITS = 32;
)
(
    input clk_in;
    input reset_in;

    output is_full_out;

    // allocation stage wake up
    input wake_up_valid_in;

    input [INS_TYPE_LENGTH_IN_BITS - 1 : 0] wake_up_inst_type_in;
    input wake_up_rs_ready_bit_in;
    input wake_up_rt_ready_bit_in;
    input [REG_INDEX_LENGTH_IN_BITS - 1 : 0] wake_up_rs_in;
    input [REG_INDEX_LENGTH_IN_BITS - 1 : 0] wake_up_rt_in;

        // input wake_up_rs_valid_in;
        // input wake_up_rt_valid_in;
    input [CPU_OPERAND_LENGTH_IN_BITS - 1 : 0] wake_up_rs_value_in;
    input [CPU_OPERAND_LENGTH_IN_BITS - 1 : 0] wake_up_rt_value_in;

    // commit stage bypass
    input commit_bypass_valid_in;
    input [REG_INDEX_LENGTH_IN_BITS - 1 : 0] commit_bypass_operand_index_in;
    input [CPU_OPERAND_LENGTH_IN_BITS - 1 : 0] commit_bypass_operand_value_in;

    // execute stage bypass
    input execute_bypass_valid_in;
    input [REG_INDEX_LENGTH_IN_BITS - 1 : 0] execute_bypass_operand_index_in;

    // issue stage drive
    input alu_enable_in;

    output reg select_valid_out;
    output reg [INST_TYPE_LENGTH_IN_BITS - 1 : 0] select_inst_type_out;
    output reg [CPU_OPERAND_LENGTH_IN_BITS - 1 : 0] select_rs_value_out;
    output reg [CPU_OPERAND_LENGTH_IN_BITS - 1 : 0] select_rt_value_out;
);

reg [NUM_ISSUE_QUEUE_ENTRY - 1 : 0] inst_type_array [INST_TYPE_LENGTH_IN_BITS - 1 : 0];

reg [NUM_ISSUE_QUEUE_ENTRY - 1 : 0] rs_array [REG_INDEX_LENGTH_IN_BITS - 1 : 0];
reg [NUM_ISSUE_QUEUE_ENTRY - 1 : 0] rt_array [REG_INDEX_LENGTH_IN_BITS - 1 : 0];

reg [$clog2(NUM_ISSUE_QUEUE_ENTRY) - 1 : 0] wake_up_ptr;
reg [$clog2(NUM_ISSUE_QUEUE_ENTRY) - 1 : 0] select_ptr;

wire [NUM_ISSUE_QUEUE_ENTRY - 1 : 0] rs_value_array [CPU_OPERAND_LENGTH_IN_BITS - 1 : 0];
wire [NUM_ISSUE_QUEUE_ENTRY - 1 : 0] rt_value_array [CPU_OPERAND_LENGTH_IN_BITS - 1 : 0];

wire [NUM_ISSUE_QUEUE_ENTRY - 1 : 0] busy_bit_array;
wire [NUM_ISSUE_QUEUE_ENTRY - 1 : 0] rs_ready_bit_array;
wire [NUM_ISSUE_QUEUE_ENTRY - 1 : 0] rt_ready_bit_array;

wire [NUM_ISSUE_QUEUE_ENTRY - 1 : 0] wake_up_array;

wire [NUM_ISSUE_QUEUE_ENTRY - 1 : 0] operand_ready_bit_array = rs_ready_bit_array & rt_ready_bit_array;
wire operand_ready_bit_merged = |(operand_ready_bit_array);

wire select_enable = operand_ready_bit_merged & alu_enable_in;

assign is_full_out = &(busy_bit_array);

generate
genvar gen;
    for (gen = 0; gen < NUM_ISSUE_QUEUE_ENTRY; gen = gen + 1)
    begin
        reg [CPU_OPERAND_LENGTH_IN_BITS - 1 : 0]rs_value;
        reg [CPU_OPERAND_LENGTH_IN_BITS - 1 : 0]rt_value;

        reg busy_bit;
        reg rs_ready_bit;
        reg rt_ready_bit;

        wire [REG_INDEX_LENGTH_IN_BITS - 1 : 0] reorder_buffer_index_rs = (busy_bit & ~rs_ready_bit) && (rs_array[gen]);
        wire [REG_INDEX_LENGTH_IN_BITS - 1 : 0] reorder_buffer_index_rt = (busy_bit & ~rt_ready_bit) && (rt_array[gen]);

        wire wake_up_enable = ~busy_bit & wake_up_valid_in & (gen == wake_up_ptr);
        wire commit_bypass_valid = busy_bit & commit_bypass_valid_in;
        wire commit_bypass_rs_enable = commit_bypass_valid & (reorder_buffer_index_rs == commit_bypass_operand_index_in);
        wire commit_bypass_rt_enable = commit_bypass_valid & (reorder_buffer_index_rt == commit_bypass_operand_index_in);

        wire excute_bypass_valid = busy_bit & excute_bypass_valid_in;
        wire execute_bypass_rs_issue = ~rs_ready_bit & rt_ready_bit & (execute_bypass_operand_index_in == rs_array[gen]);
        wire execute_bypass_rt_issue = ~rt_ready_bit & rs_ready_bit & (execute_bypass_operand_index_in == rt_array[gen])
        wire execute_bypass_rs_rt_issue = rs_ready_bit & rt_ready_bit & (execute_bypass_operand_index_in == rs_array[gen])
                                          (execute_bypass_operand_index_in == rt_array[gen]);
        wire execute_bypass_enable = excute_bypass_valid & (execute_bypass_rs_issue | execute_bypass_rt_issue | execute_bypass_rs_rt_issue);
        reg [REG_INDEX_LENGTH_IN_BITS - 1 : 0] excute_bypass_priority_select_ptr;

        wire is_selected = (gen == select_ptr);

        assign rs_value_array[gen] = rs_value;
        assign rt_value_array[gen] = rt_value;
        assign busy_bit_array[gen] = busy_bit;

        always @ (posedge clk_in)
        begin
            if (reset_in)
            begin
                rs_value <= 0;
                rt_value <= 0;
                busy_bit <= 0;
                rs_ready_bit <= 0;
                rt_ready_bit <= 0;

                execute_bypass_priority_select_ptr <= 0;

                select_valid_out <= 0;
                select_inst_type_out <= 0;
                select_rs_value_out <= 0;
                select_rt_value_out <= 0;
            end
            else
            begin
                if(wake_up_enable)
                begin
                    inst_type_array[gen] = wake_up_inst_type_in;

                    busy_bit        <= 1;
                    rs_ready_bit    <= wake_up_rs_ready_bit_in;
                    rt_ready_bit    <= wake_up_rt_ready_bit_in;
                    rs_value        <= wake_up_rs_in;
                    rt_value        <= wake_up_rt_in;
                end

                if(commit_bypass_rs_enable)
                begin
                    rs_ready_bit    <= 1;
                    rs_value        <= commit_bypass_operand_value_in;
                end

                if (commit_bypass_rt_enable)
                begin
                    rt_ready_bit    <= 1;
                    rt_value        <= commit_bypass_operand_value_in;
                end

                // if (excute_bypass_enable)
                // begin
                //     execute_bypass_priority_select_ptr <= gen;
                //
                //     if (execute_bypass_rs_issue)
                //     begin
                //         rs_ready_bit <= 1;
                //     end
                //     else if (execute_bypass_rt_issue)
                //     begin
                //         rt_ready_bit <= 1;
                //     end
                //     else if (execute_bypass_rs_rt_issue)
                //     begin
                //         rs_ready_bit <= 1;
                //         rt_ready_bit <= 1;
                //     end
                // end

                if (select_enable & is_selected)
                begin
                    busy_bit <= 0;
                end
            end
        end
    end

endgenerate

always @ (posedge clk_in)
begin
    if (reset_in)
    begin
        select_valid_out <= 0;
        select_inst_type_out <= 0;
        select_rs_value_out <= 0;
        select_rt_value_out <= 0;
    end
    else
    begin
        if (select_enable & ~select_valid_out)
        begin
            select_valid_out <= 1;
            select_inst_type_out <= inst_type_array[select_ptr];
            select_rs_value_out <= rs_value_array[select_ptr];
            select_rt_value_out <= rt_value_array[select_ptr];
        end
        else
        begin
            select_valid_out <= 0;
            select_inst_type_out <= 0;
            select_rs_value_out <= 0;
            select_rt_value_out <= 0;
        end
    end
end

// select
always @ (*)
begin
    for (gen = 0; gen < NUM_ISSUE_QUEUE_ENTRY; gen = gen + 1)
    begin: SELECT
        if (operand_ready_bit_array[gen])
        begin
            select_ptr <= gen;
            disable SELECT;
        end
        else
        begin
            select_ptr <= select_ptr;
        end
    end
end

// wake up
always @ (*)
begin
    for (gen = 0; gen < NUM_ISSUE_QUEUE_ENTRY; gen = gen + 1)
    begin: WAKE_UP
        if (~busy_bit_array[gen])
        begin
            wake_up_ptr <= gen;
            disable WAKE_UP;
        end
        else
        begin
            wake_up_ptr <= wake_up_ptr;
        end
    end
end


endmodule
