module register_status
#(
    parameter NUM_READ_PORT = 5,
    parameter NUM_GENERAL_PURPOSE_REGISTER = 32,
    parameter NUM_ROB_ENTRY = 6;
)
(
    input clk_in;
    input reset_in;

    // dispatch stage register renaming
    input renaming_valid_in;
    input [$clog2(NUM_GENERAL_PURPOSE_REGISTER) - 1 : 0] renaming_name_in;
    input [$clog2(NUM_ROB_ENTRY) - 1 : 0] renaming_rob_index_in;

    // commit stage release register
    input release_valid_in;
    input [$clog2(NUM_GENERAL_PURPOSE_REGISTER) - 1 : 0] release_name_in;
    input [$clog2(NUM_ROB_ENTRY) - 1 : 0] release_rob_index_in;

    // multi-port read
    input [NUM_READ_PORT - 1 : 0] read_enable_in;
    input [NUM_READ_PORT * $clog2(NUM_GENERAL_PURPOSE_REGISTER) - 1 : 0] read_reg_name_flatted_in;
    output [NUM_READ_PORT - 1 : 0] read_available_flatted_out;
    output [NUM_READ_PORT * $clog2(NUM_ROB_ENTRY) - 1 : 0] read_rob_index_flatted_out;

);

wire [NUM_GENERAL_PURPOSE_REGISTER - 1 : 0] available_array;
reg [$clog2(NUM_ROB_ENTRY) - 1 : 0] rob_index_array [NUM_GENERAL_PURPOSE_REGISTER - 1 : 0];

generate
genvar gen, ;
    for (gen = 0; gen < NUM_GENERAL_PURPOSE_REGISTER; gen = gen + 1)
    begin
        reg available_bit;

        wire is_right_renaming_way = (gen == renaming_name_in);
        wire is_right_release_way = (gen == release_name_in) & (rob_index_array[release_name_in] == release_rob_index_in);

        wire renaming_enable = renaming_valid_in & is_right_renaming_way;
        wire release_enable = release_valid_in & is_right_release_way;

        assign available_array[gen] = available_bit;

        always @ (posedge clk_in)
        begin
            if (reset_in)
            begin
                available_bit <= 0;
                rob_index_array[gen] <= 0;
            end
            else
            begin
                if (renaming_enable)
                begin
                    available_bit <= 0;
                    rob_index_array[renaming_name_in] <= renaming_rob_index_in;
                end
                else if (release_enable)
                begin
                    available_bit <= 1;
                end
            end
        end
    end

    for (PORT_INDEX = 0; PORT_INDEX < NUM_READ_PORT; PORT_INDEX = PORT_INDEX + 1)
    begin
        wire enable_in = read_enable_in[PORT_INDEX];
        wire [$clog2(NUM_GENERAL_PURPOSE_REGISTER) - 1 : 0] reg_name_in =
            read_reg_name_flatted_in[(PORT_INDEX + 1) * $clog2(NUM_GENERAL_PURPOSE_REGISTER) - 1
                                                        : PORT_INDEX * $clog2(NUM_GENERAL_PURPOSE_REGISTER)];

        assign read_available_flatted_out[PORT_INDEX] = enable_in? available_array[reg_name_in] : 0;
        assign read_rob_index_flatted_out[(PORT_INDEX + 1) * $clog2(NUM_ROB_ENTRY) - 1 : PORT_INDEX * clog2(NUM_ROB_ENTRY)]
                                                        = enable_in? rob_index_array[reg_name_in] : 0;

endgenerate

endmodule
