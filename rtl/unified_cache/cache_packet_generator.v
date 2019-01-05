`include "parameters.vh"

module cache_packet_generator
#(
    parameter NUM_WAY                                       = 2,
    parameter NUM_REQUEST                                   = 16,
    parameter TIMING_OUT_CYCLE                              = 10000,

    parameter MEM_SIZE                                      = 65536,
    parameter NUM_TEST_CASE                                 = 8,
    parameter MAX_NUM_TASK                                  = 2,
    parameter NUM_TASK_TYPE                                 = 2,

    parameter UNIFIED_CACHE_PACKET_WIDTH_IN_BITS            = `UNIFIED_CACHE_PACKET_WIDTH_IN_BITS,

    parameter DEFAULT_WAY_TIME_DELAY                        = 4
)
(
    input                                                           reset_in,
    input                                                           clk_in,

    output  [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS * NUM_WAY - 1 : 0]  test_packet_flatted_out,
    input   [NUM_WAY                                      - 1 : 0]  test_packet_ack_flatted_in,

    input   [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS * NUM_WAY - 1 : 0]  return_packet_flatted_in,
    output  [NUM_WAY                                      - 1 : 0]  return_packet_ack_flatted_out,

    output                                                          done,
    output                                                          error,

    input                                                           test_case_ack_in,
    output reg                                                      test_case_ack_out,
    
    output [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0]debug
);

// generate ctrl state
`define STATE_INIT      0
`define STATE_CLEAR     1
`define STATE_FINAL     2
`define STATE_CASE_0    3
`define STATE_CASE_1    (`STATE_CASE_0 + 1)
`define STATE_CASE_2    (`STATE_CASE_1 + 1)
`define STATE_CASE_3    (`STATE_CASE_2 + 1)
`define STATE_CASE_4    (`STATE_CASE_3 + 1)
`define STATE_CASE_5    (`STATE_CASE_4 + 1)
`define STATE_CASE_6    (`STATE_CASE_5 + 1)
`define STATE_CASE_7    (`STATE_CASE_6 + 1)

// test case ctrl state
`define TEST_CASE_STATE_IDLE        0
`define TEST_CASE_STATE_CONFIG      1
`define TEST_CASE_STATE_DELAY       2
`define TEST_CASE_STATE_PREPROCESS  3
`define TEST_CASE_STATE_RUNNING     4
`define TEST_CASE_STATE_CHECK       5
`define TEST_CASE_STATE_RECORD      6
`define TEST_CASE_STATE_FINAL       7

integer     reg_index;

// test case state
reg [31:0] test_case;
reg [31:0] generator_ctrl_state = 0;
reg [31:0] test_case_ctrl_state = 0;

reg  [NUM_WAY - 1 : 0]                              return_packet_ack;
wire [NUM_WAY - 1 : 0]                              done_way;
wire [NUM_WAY - 1 : 0]                              error_way;
wire [`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN - 1 : 0]  write_mask;

// error & done
reg [NUM_WAY - 1 : 0] done_vector [NUM_TEST_CASE - 1 : 0];
reg [NUM_WAY - 1 : 0] error_vector [NUM_TEST_CASE - 1 : 0];

assign done                             = &(done_vector[(generator_ctrl_state >= `STATE_CASE_0)? generator_ctrl_state - `STATE_CASE_0 : 0]);
assign error                            = |(error_vector[(generator_ctrl_state >= `STATE_CASE_0)? generator_ctrl_state - `STATE_CASE_0 : 0]);
assign return_packet_ack_flatted_out    = return_packet_ack;
assign write_mask                       = {{(`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN/2){2'b11}}};

reg [`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS - 1 : 0] sim_memory [MEM_SIZE - 1 : 0];


// request buffer
wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] packed_way_packet_out_buffer [(NUM_REQUEST * NUM_WAY) - 1 : 0];
wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] packed_way_packet_in_buffer [(NUM_REQUEST * NUM_WAY) - 1 : 0];
wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] packed_way_packet_expected_buffer [(NUM_REQUEST * NUM_WAY) - 1 : 0];


reg [31 : 0] packed_way_packet_out_buffer_boundry [NUM_WAY - 1 : 0];
wire [31 : 0] packed_way_packet_in_buffer_boundry [NUM_WAY - 1 : 0];
wire [31 : 0] packed_way_packet_expected_buffer_boundry [NUM_WAY - 1 : 0];
reg [31 : 0] packed_way_packet_buffer_start [NUM_WAY - 1 : 0];
//reg [31 : 0] packed_way_packet_in_buffer_start [NUM_WAY - 1 : 0];
reg [31 : 0] packed_way_packet_expected_buffer_start [NUM_WAY - 1 : 0];


//reg [NUM_REQUEST - 1 : 0] way_in_valid_array [NUM_WAY - 1 : 0];
//reg [NUM_REQUEST - 1 : 0] way_expected_valid_array [NUM_WAY - 1 : 0];
wire [(NUM_REQUEST * NUM_WAY) - 1 : 0] way_in_valid_array_packed;
wire [(NUM_REQUEST * NUM_WAY) - 1 : 0] way_expected_valid_array_packed;
// couter
reg [$clog2(MAX_NUM_TASK) - 1 : 0] task_list_ctr;

reg [31 : 0] preprocess_counter;
wire preprocess_more_than_half = preprocess_counter >= (NUM_REQUEST / 2);
wire preprocess_counter_odd = (preprocess_counter[0]) == 1;
wire preprocess_counter_even = ~preprocess_counter_odd;
wire [31 : 0] preprocess_read_after_write_index = preprocess_counter >> 1;
wire [31 : 0] preprocess_way_packet_buffer_index [NUM_WAY - 1 : 0];
wire [31 : 0] preprocess_way_packet_buffer_half_index [NUM_WAY - 1 : 0];

wire [31 : 0] preprocess_index_times_17 = (preprocess_read_after_write_index << 4) + preprocess_read_after_write_index;
wire [31 : 0] preprocess_index_times_7 = (preprocess_read_after_write_index << 3) - preprocess_read_after_write_index;

integer preprocess_way_index;

generate
genvar gen;
    for (gen = 0; gen < NUM_WAY; gen = gen + 1)
    begin
        assign preprocess_way_packet_buffer_index[gen] = preprocess_counter + packed_way_packet_buffer_start[gen];
        assign preprocess_way_packet_buffer_half_index[gen] = (preprocess_counter >> 1) + packed_way_packet_buffer_start[gen];

//        assign way_in_valid_array_packed[(gen + 1) * NUM_REQUEST - 1 : gen * NUM_REQUEST] = way_in_valid_array[gen];
//        assign way_expected_valid_array_packed[(gen + 1) * NUM_REQUEST - 1 : gen * NUM_REQUEST] = way_expected_valid_array[gen];
    end
endgenerate

// test case config reg - task list
reg [MAX_NUM_TASK - 1 : 0] task_type_list_reg;
reg [MAX_NUM_TASK - 1 : 0] task_num_request_reg [NUM_REQUEST - 1 : 0];
reg [$clog2(MAX_NUM_TASK) - 1 : 0] num_task;

// test case config reg - request in & out
reg [NUM_WAY - 1 : 0] way_enable_reg;
//reg [NUM_WAY - 1 : 0] way_out_enable_reg;
reg [31:0] way_time_delay_reg [NUM_WAY - 1 : 0];
//reg [NUM_WAY * 32 - 1 : 0] way_out_time_delay;

// test case config reg - check
reg check_mode_reg; // 0 - default check method (scoreboard), 1 - user-defined
reg [(NUM_REQUEST * NUM_WAY) - 1 : 0]check_valid_mask;

// test case config reg - preprocess
reg preprocess_mode_reg; // 0 - no pretreatment, 1 - user-defined
reg preprocess_end_flag;

// way control
wire [NUM_WAY - 1 : 0] packet_in_enable_way;
wire [NUM_WAY - 1 : 0] packet_out_enable_way;
wire [NUM_WAY - 1 : 0] check_enable_way;
wire [NUM_WAY - 1 : 0] packet_out_end_way_flag;
wire [NUM_WAY - 1 : 0] packet_in_end_way_flag;
wire [NUM_WAY - 1 : 0] check_end_way_flag;
//wire packet_out_end_flag;
//wire packet_in_end_flag;
wire check_end_flag;
reg  way_clear_flag;

assign packet_in_enable_way = way_enable_reg;
assign packet_out_enable_way = way_enable_reg;
assign check_enable_way = {(NUM_WAY){(check_mode_reg == 0)}} & way_enable_reg;

// task way control flag
wire running_end_flag;
wire [NUM_WAY * NUM_TASK_TYPE - 1 : 0] task_end_way_flag;
wire task_end_flag;
wire next_task_clear_flag;

assign running_end_flag = &(packet_in_end_way_flag & packet_out_end_way_flag | (~packet_in_enable_way));
assign check_end_flag = &(check_end_way_flag | (~check_enable_way));

// test case state abstract
wire test_case_idle = test_case_ctrl_state == `TEST_CASE_STATE_IDLE;
wire test_case_config = test_case_ctrl_state == `TEST_CASE_STATE_CONFIG;
wire test_case_preprocess = test_case_ctrl_state == `TEST_CASE_STATE_PREPROCESS;
wire test_case_running = test_case_ctrl_state == `TEST_CASE_STATE_RUNNING;
wire test_case_check = test_case_ctrl_state == `TEST_CASE_STATE_CHECK;
wire test_case_final = test_case_ctrl_state == `TEST_CASE_STATE_FINAL;
wire test_case_record = test_case_ctrl_state == `TEST_CASE_STATE_RECORD;

// send & recieve
generate
genvar WAY_INDEX, REQUEST_INDEX;

for(WAY_INDEX = 0; WAY_INDEX < NUM_WAY; WAY_INDEX = WAY_INDEX + 1)
begin:way_logic

    if(WAY_INDEX >= 0)
    begin

        integer scoreboard_index;
        integer valid_index;

        reg  [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0]   test_packet;

        // counter
        reg  [31                                     : 0]   request_counter;
        reg  [63                                     : 0]   timeout_counter;
        reg  [31                                     : 0]   delay_counter;
        reg  [31                                     : 0]   check_request_in_counter;
        reg  [31                                     : 0]   buffer_virtual_counter;
        
        wire [31                                     : 0]   next_request_counter = request_counter + 1'b1;
        wire [31                                     : 0]   next_buffer_virtual_counter = buffer_virtual_counter + 1;
        wire [31                                     : 0]   buffer_physical_counter;

        reg [NUM_REQUEST - 1 : 0] way_expected_valid_array;
        wire [NUM_REQUEST - 1 : 0] way_in_valid_array;
        
        reg done_way_reg;
        reg error_way_reg;
        
        assign way_expected_valid_array_packed[(WAY_INDEX + 1) * NUM_REQUEST - 1 : WAY_INDEX * NUM_REQUEST] = way_expected_valid_array;
        assign way_in_valid_array_packed[(WAY_INDEX + 1) * NUM_REQUEST - 1 : WAY_INDEX * NUM_REQUEST] = way_in_valid_array;
        
        assign done_way[WAY_INDEX] = done_way_reg;
        assign error_way[WAY_INDEX] = error_way_reg;

        wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0]   packet_concatenated;
        wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0]   packet_from_buffer;


        ////////////////////////////////////////////////////////////////
        if (WAY_INDEX == 0)
        begin
            assign  debug = packet_from_buffer;
        end

        // enable signal
        wire   request_in_enable;
        wire   request_out_enable;
        wire   check_enable;

        // boundry
        wire [31:0]packet_out_buffer_boundry = packed_way_packet_out_buffer_boundry[WAY_INDEX];
        wire [31:0]packet_in_buffer_boundry = packed_way_packet_in_buffer_boundry[WAY_INDEX];
        wire [31:0]packet_expected_buffer_boundry = packed_way_packet_expected_buffer_boundry[WAY_INDEX];


        assign test_packet_flatted_out[WAY_INDEX * UNIFIED_CACHE_PACKET_WIDTH_IN_BITS +: UNIFIED_CACHE_PACKET_WIDTH_IN_BITS] = test_packet;
        assign packet_in_end_way_flag[WAY_INDEX] = error_way[WAY_INDEX] | (buffer_virtual_counter == packet_in_buffer_boundry) & packet_in_enable_way[WAY_INDEX];
        assign packet_out_end_way_flag[WAY_INDEX] = done_way[WAY_INDEX] & packet_in_enable_way[WAY_INDEX];



        assign buffer_physical_counter = buffer_virtual_counter + packed_way_packet_buffer_start[WAY_INDEX];
        assign packet_from_buffer = (packed_way_packet_out_buffer[WAY_INDEX * NUM_REQUEST + request_counter]);

        // enable signal
        assign request_in_enable = packet_in_enable_way[WAY_INDEX] & test_case_running;
        assign request_out_enable = packet_out_enable_way[WAY_INDEX] & test_case_running;
        assign check_enable = check_enable_way[WAY_INDEX] & test_case_check;

        // end flag
        assign check_end_way_flag[WAY_INDEX] = check_request_in_counter == packet_expected_buffer_boundry;

        // from buffer
        packet_concat test_packet_concat
        (
            .addr_in        (packet_from_buffer[`UNIFIED_CACHE_PACKET_ADDR_POS_HI : `UNIFIED_CACHE_PACKET_ADDR_POS_LO]),
            .data_in        (packet_from_buffer[`UNIFIED_CACHE_PACKET_DATA_POS_HI : `UNIFIED_CACHE_PACKET_DATA_POS_LO]),
            .type_in        (packet_from_buffer[`UNIFIED_CACHE_PACKET_TYPE_POS_HI : `UNIFIED_CACHE_PACKET_TYPE_POS_LO]),
            .write_mask_in  (packet_from_buffer[`UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI : `UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO]),
            .port_num_in    (packet_from_buffer[`UNIFIED_CACHE_PACKET_PORT_NUM_HI : `UNIFIED_CACHE_PACKET_PORT_NUM_LO]),
            .valid_in       (packet_from_buffer[`UNIFIED_CACHE_PACKET_VALID_POS]),
            .is_write_in    (packet_from_buffer[`UNIFIED_CACHE_PACKET_IS_WRITE_POS]),
            .cacheable_in   (packet_from_buffer[`UNIFIED_CACHE_PACKET_CACHEABLE_POS]),
            .packet_out     (packet_concatenated)
        );


        reg [31:0] request_out_time_delay_counter;
        reg test_packet_flag;

        wire test_packet_valid_bit = test_packet[`UNIFIED_CACHE_PACKET_VALID_POS];
        
        // request out
        always@(posedge clk_in)
        begin
            if(reset_in)
            begin
                test_packet                     <= 0;
                request_counter                 <= 0;
                done_way_reg                    <= 0;

                request_out_time_delay_counter  <= 0;
                test_packet_flag                <= 0;
            end

            else if(request_out_enable)
            begin

                if (~error_way[WAY_INDEX])
                begin

                    // request out delay
                    if (request_out_time_delay_counter < way_time_delay_reg[WAY_INDEX])
                    begin
                        request_out_time_delay_counter <= request_out_time_delay_counter + 1;
                    end

                    else if(~test_packet_flag & ~done_way[WAY_INDEX] & test_packet_ack_flatted_in[WAY_INDEX])
                    begin
                        test_packet                     <= packet_concatenated;
                        test_packet_flag                <= 1;
                        //request_counter                 <= request_counter;
                        done_way_reg                    <= 0;
                    end

                    else if(test_packet_flag & ~done_way[WAY_INDEX] & test_packet_valid_bit)
                    begin
                        request_out_time_delay_counter  <= 0;
                        test_packet                     <= 0;
                        test_packet_flag                <= 0;
                        request_counter                 <= next_request_counter;
                        done_way_reg                    <= next_request_counter == packet_out_buffer_boundry;
                    end

                    else
                    begin
                        test_packet                     <= test_packet;
                        request_counter                 <= request_counter;
                        done_way_reg                    <= done_way[WAY_INDEX];
                    end
                end

            end
            else if (way_clear_flag)
            begin
                test_packet                     <= 0;
                request_counter                 <= 0;
                done_way_reg                    <= 0;
               
                request_out_time_delay_counter  <= 0;
                test_packet_flag                <= 0;
            end
        end

        integer request_index;
        wire[UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] way_packet_in_buffer [NUM_REQUEST - 1 : 0];

        for (REQUEST_INDEX = 0; REQUEST_INDEX < NUM_REQUEST; REQUEST_INDEX = REQUEST_INDEX + 1)
        begin
            assign packed_way_packet_in_buffer [WAY_INDEX * NUM_REQUEST + REQUEST_INDEX] = way_packet_in_buffer[REQUEST_INDEX];
        end


        wire return_packet_valid_in = return_packet_flatted_in[(WAY_INDEX) * UNIFIED_CACHE_PACKET_WIDTH_IN_BITS + `UNIFIED_CACHE_PACKET_VALID_POS];
        wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] return_packet_in = return_packet_flatted_in[WAY_INDEX * UNIFIED_CACHE_PACKET_WIDTH_IN_BITS +: UNIFIED_CACHE_PACKET_WIDTH_IN_BITS];

        // way valid array
        for (REQUEST_INDEX = 0; REQUEST_INDEX < NUM_REQUEST; REQUEST_INDEX = REQUEST_INDEX + 1)
        begin
            reg way_in_valid_reg;
            //reg way_expected_valid_reg;
            reg [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] way_packet_in_reg;
            
            wire is_right_reg = buffer_virtual_counter == REQUEST_INDEX;
            wire way_in_valid_enable = is_right_reg & request_in_enable & (~error_way[WAY_INDEX]) & return_packet_valid_in;
            
            assign way_in_valid_array[REQUEST_INDEX] = way_in_valid_reg;
            assign way_packet_in_buffer[REQUEST_INDEX] = way_packet_in_reg;
            //assign way_expected_valid_array[REQUEST_INDEX] = way_expected_valid_reg;
            
            always@(posedge clk_in)
            begin
                if (reset_in)
                begin
                    way_in_valid_reg        <= 0;
                   // way_expected_valid_reg  <= 0;
                    way_packet_in_reg       <= 0;
                end
                
                else
                begin
                    if (way_in_valid_enable)
                    begin
                        way_in_valid_reg    <= 1;
                        way_packet_in_reg   <= return_packet_in;
                    end
                    
                    else if (way_clear_flag)
                    begin
                        way_in_valid_reg    <= 0;
                       // way_expected_valid_reg <= 1;
                        way_packet_in_reg   <= 0;
                    end
                    
                    else
                    begin
                        way_in_valid_reg    <= way_in_valid_reg;
                        way_packet_in_reg   <= way_packet_in_reg;
                    end
                end
            end
        end

        //reg [31 : 0] last_buffer_virtual_counter;
        // request in
        
        
        always@(posedge clk_in)
        begin
            if(reset_in)
            begin
                return_packet_ack[WAY_INDEX]    <= 0;
                timeout_counter                 <= 0;
                error_way_reg                   <= 0;
                buffer_virtual_counter          <= 0;

                //way_in_valid_array              <= 0;

                //for (request_index = 0; request_index < NUM_REQUEST; request_index = request_index + 1)
                //begin
                //    way_packet_in_buffer[request_index] <= 0;
                //end
            end

            else if (request_in_enable)
            begin

                if(~error_way[WAY_INDEX])
                begin

                    // wait
                    if(~return_packet_valid_in)
                    begin
                        return_packet_ack[WAY_INDEX]    <= 1;
                        timeout_counter                 <= timeout_counter + 1'b1;
                        error_way_reg                   <= timeout_counter >= TIMING_OUT_CYCLE;

                        buffer_virtual_counter          <= buffer_virtual_counter;
                    end

                    else if(return_packet_valid_in)
                    begin
                        return_packet_ack[WAY_INDEX]    <= 1;
                        timeout_counter                 <= 0;
                        error_way_reg                   <= timeout_counter >= TIMING_OUT_CYCLE;
                        //way_packet_in_buffer
                            //[buffer_virtual_counter]   <= return_packet_flatted_in[WAY_INDEX * UNIFIED_CACHE_PACKET_WIDTH_IN_BITS +: UNIFIED_CACHE_PACKET_WIDTH_IN_BITS];
                        //way_in_valid_array
                        //   [buffer_virtual_counter]   <= 1'b1;
                            
                        //last_buffer_virtual_counter   <= buffer_virtual_counter;
                        buffer_virtual_counter         <= next_buffer_virtual_counter;
                    end
                   
                end
            end
            else if (way_clear_flag)
            begin
                return_packet_ack[WAY_INDEX]        <= 0;
                timeout_counter                     <= 0;
                error_way_reg                       <= 0;
                buffer_virtual_counter              <= 0;

               // way_in_valid_array                  <= 0;

//                for (request_index = 0; request_index < NUM_REQUEST; request_index = request_index + 1)
//                begin
//                    way_packet_in_buffer[request_index] <= 0;
//                end
            end
        end


        wire [`CPU_ADDR_LEN_IN_BITS - 1 : 0] check_address_from_in_buffer = (way_in_valid_array[check_request_in_counter])? 
                                                                                packed_way_packet_in_buffer[packed_way_packet_buffer_start[WAY_INDEX] + check_request_in_counter]
                                                                                    [`UNIFIED_CACHE_PACKET_ADDR_POS_HI : `UNIFIED_CACHE_PACKET_ADDR_POS_LO]
                                                                                : {(`CPU_ADDR_LEN_IN_BITS){1'b1}};
        
        wire [`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS - 1 : 0] check_data_from_in_buffer = (way_in_valid_array[check_request_in_counter])?
                                                                                (packed_way_packet_in_buffer[packed_way_packet_buffer_start[WAY_INDEX] + check_request_in_counter]
                                                                                    [`UNIFIED_CACHE_PACKET_DATA_POS_HI : `UNIFIED_CACHE_PACKET_DATA_POS_LO]
                                                                                 & packed_way_packet_in_buffer[packed_way_packet_buffer_start[WAY_INDEX] + check_request_in_counter]
                                                                                    [`UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI : `UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO])
                                                                                 : {(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b0}};

        


        // request check
        always@(posedge clk_in)
        begin
            if (reset_in)
            begin
                // init

                check_request_in_counter <= 0;
                way_expected_valid_array <= {(NUM_REQUEST){1'b1}};
            end
            else
            begin
                if (way_clear_flag)
                begin
                    check_request_in_counter <= 0;
                    way_expected_valid_array <= {(NUM_REQUEST){1'b1}};

                end

                if (check_enable)
                begin
                    if (~check_end_way_flag[WAY_INDEX])
                    begin
                        // scoreboard

                        check_request_in_counter <= check_request_in_counter + 1'b1;

                        for (scoreboard_index = 0; scoreboard_index < NUM_REQUEST; scoreboard_index = scoreboard_index + 1'b1)
                        begin: next_score

                            if ((check_address_from_in_buffer == packed_way_packet_expected_buffer[packed_way_packet_buffer_start[WAY_INDEX] + scoreboard_index]
                                    [`UNIFIED_CACHE_PACKET_ADDR_POS_HI : `UNIFIED_CACHE_PACKET_ADDR_POS_LO])

                                && way_expected_valid_array[scoreboard_index])
                            begin
                                if (check_data_from_in_buffer == (packed_way_packet_expected_buffer[packed_way_packet_buffer_start[WAY_INDEX] + scoreboard_index]
                                    [`UNIFIED_CACHE_PACKET_DATA_POS_HI : `UNIFIED_CACHE_PACKET_DATA_POS_LO] 
                                    & packed_way_packet_expected_buffer
                                    [packed_way_packet_buffer_start[WAY_INDEX] + scoreboard_index][`UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI : `UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO]))
                                    
                                begin
                                    way_expected_valid_array[scoreboard_index] <= 1'b0;
                                    disable next_score;
                                end
                            end
                        end
                    end
                end
            end
        end

    end



end
endgenerate


reg [`CPU_ADDR_LEN_IN_BITS - 1 : 0] preprocess_addr_buffer [NUM_WAY - 1 : 0];
reg [`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS - 1 : 0] preprocess_data_buffer [NUM_WAY - 1 : 0];
reg [`UNIFIED_CACHE_PACKET_TYPE_WIDTH - 1 : 0] preprocess_type_buffer [NUM_WAY - 1 : 0];
reg [`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN - 1 : 0] preprocess_byte_mask_buffer [NUM_WAY - 1 : 0];
reg [`UNIFIED_CACHE_PACKET_PORT_ID_WIDTH - 1 : 0] preprocess_port_num_buffer [NUM_WAY - 1 : 0];
reg [NUM_WAY - 1 : 0] preprocess_valid_buffer;
reg [NUM_WAY - 1 : 0] preprocess_is_write_buffer;
reg [NUM_WAY - 1 : 0] preprocess_cacheable_buffer;

wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] data_to_packet_out_buffer [NUM_WAY - 1 : 0];
wire [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] data_to_packet_expected_buffer [NUM_WAY - 1 : 0];

wire data_to_buffer_write_enable = test_case_preprocess & ~(preprocess_counter == 0);
wire [31 : 0]preprocess_compensation_counter = preprocess_end_flag? (preprocess_counter) : preprocess_counter - 1;
wire [31 : 0] data_to_buffer_counter = (preprocess_counter == 0)? 0 : preprocess_compensation_counter;
wire data_to_buffer_counter_odd = data_to_buffer_counter[0];
wire [31 : 0] data_to_buffer_counter_half = data_to_buffer_counter >> 1;

wire out_buffer_write_enable = data_to_buffer_write_enable;
wire expected_buffer_write_enable = data_to_buffer_counter_odd;

generate
for (WAY_INDEX = 0; WAY_INDEX < NUM_WAY; WAY_INDEX = WAY_INDEX + 1)
begin
    integer buffer_index;

    reg [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] way_packet_out_buffer [NUM_REQUEST - 1 : 0];
    reg [UNIFIED_CACHE_PACKET_WIDTH_IN_BITS - 1 : 0] way_packet_expected_buffer [NUM_REQUEST - 1 : 0];

    reg [31 : 0] way_packet_in_buffer_boundry;
    reg [31 : 0] way_packet_expected_buffer_boundry;
    
    assign packed_way_packet_in_buffer_boundry[WAY_INDEX] = way_packet_in_buffer_boundry;
    assign packed_way_packet_expected_buffer_boundry[WAY_INDEX] = way_packet_expected_buffer_boundry;


    assign data_to_packet_out_buffer[WAY_INDEX][`UNIFIED_CACHE_PACKET_ADDR_POS_HI : `UNIFIED_CACHE_PACKET_ADDR_POS_LO] = preprocess_addr_buffer[WAY_INDEX];
    assign data_to_packet_out_buffer[WAY_INDEX][`UNIFIED_CACHE_PACKET_DATA_POS_HI : `UNIFIED_CACHE_PACKET_DATA_POS_LO] = preprocess_data_buffer[WAY_INDEX];
    assign data_to_packet_out_buffer[WAY_INDEX][`UNIFIED_CACHE_PACKET_TYPE_POS_HI : `UNIFIED_CACHE_PACKET_TYPE_POS_LO] = preprocess_type_buffer[WAY_INDEX];
    assign data_to_packet_out_buffer[WAY_INDEX][`UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI : `UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO] = preprocess_byte_mask_buffer[WAY_INDEX];
    assign data_to_packet_out_buffer[WAY_INDEX][`UNIFIED_CACHE_PACKET_PORT_NUM_HI : `UNIFIED_CACHE_PACKET_PORT_NUM_LO] = preprocess_port_num_buffer[WAY_INDEX];
    assign data_to_packet_out_buffer[WAY_INDEX][`UNIFIED_CACHE_PACKET_VALID_POS] = preprocess_valid_buffer[WAY_INDEX];
    assign data_to_packet_out_buffer[WAY_INDEX][`UNIFIED_CACHE_PACKET_IS_WRITE_POS] = preprocess_is_write_buffer[WAY_INDEX];
    assign data_to_packet_out_buffer[WAY_INDEX][`UNIFIED_CACHE_PACKET_CACHEABLE_POS] = preprocess_cacheable_buffer[WAY_INDEX];

    assign data_to_packet_expected_buffer[WAY_INDEX] = data_to_packet_out_buffer[WAY_INDEX];

    for (REQUEST_INDEX = 0; REQUEST_INDEX < NUM_REQUEST; REQUEST_INDEX = REQUEST_INDEX + 1)
    begin
        assign packed_way_packet_out_buffer [WAY_INDEX * NUM_REQUEST + REQUEST_INDEX]       = way_packet_out_buffer[REQUEST_INDEX];
        assign packed_way_packet_expected_buffer [WAY_INDEX * NUM_REQUEST + REQUEST_INDEX]  = way_packet_expected_buffer[REQUEST_INDEX];
    end

    always @ (posedge clk_in) begin
        if (reset_in)
        begin
            for (buffer_index = 0; buffer_index < NUM_WAY; buffer_index = buffer_index + 1)
            begin
                way_packet_out_buffer     [buffer_index]  <= 0;
                way_packet_expected_buffer[buffer_index]  <= 0;

                way_packet_expected_buffer_boundry        <= 0;
                way_packet_in_buffer_boundry              <= 0;
            end
        end
        else
        begin
            if (way_clear_flag)
            begin
                for (buffer_index = 0; buffer_index < NUM_WAY; buffer_index = buffer_index + 1)
                begin
                    //way_packet_out_buffer     [buffer_index]  <= 0;
                    //way_packet_expected_buffer[buffer_index]  <= 0;

                    way_packet_expected_buffer_boundry  <= 0;
                    way_packet_in_buffer_boundry        <= 0;
                end
            end

            else if (data_to_buffer_write_enable)
            begin
                if (out_buffer_write_enable)
                begin
                    way_packet_out_buffer       [data_to_buffer_counter] <= data_to_packet_out_buffer[WAY_INDEX];
                end

                if (expected_buffer_write_enable)
                begin
                    way_packet_expected_buffer  [data_to_buffer_counter_half] <= data_to_packet_expected_buffer[WAY_INDEX];

                    for (buffer_index = 0; buffer_index < NUM_WAY; buffer_index = buffer_index + 1)
                    begin
                        way_packet_expected_buffer_boundry                                        <= (data_to_buffer_counter + 1) >> 1;
                        way_packet_in_buffer_boundry                                              <= (data_to_buffer_counter + 1) >> 1;
                    end
                end
            end

            else
            begin
                way_packet_out_buffer       [data_to_buffer_counter] <= way_packet_out_buffer[data_to_buffer_counter];
                way_packet_expected_buffer  [data_to_buffer_counter_half] <= way_packet_expected_buffer[data_to_buffer_counter_half];
            end
        end
    end
end
endgenerate

// generator ctrl state
always @ (posedge clk_in)
begin
    if (reset_in)
    begin
        generator_ctrl_state <= `STATE_INIT;
    end
    else
    begin

        if (test_case_idle)
        begin
            test_case <= 0;

            // config reg
            way_enable_reg <= 0;

            for (reg_index = 0; reg_index < NUM_WAY; reg_index = reg_index + 1)
            begin
                way_time_delay_reg[reg_index] <= DEFAULT_WAY_TIME_DELAY + reg_index;
            end

            check_mode_reg <= 0;
            preprocess_mode_reg <= 0;

            // buffer
            for (reg_index = 0; reg_index < NUM_REQUEST * NUM_WAY; reg_index = reg_index + 1'b1)
            begin

                if (reg_index % NUM_REQUEST == 0)
                begin
                    packed_way_packet_buffer_start[reg_index / NUM_REQUEST] <= reg_index;
                end
            end

            // boundry
            for (reg_index = 0; reg_index < NUM_WAY; reg_index = reg_index + 1'b1)
            begin
                packed_way_packet_out_buffer_boundry[reg_index] <= NUM_REQUEST;
                
                /* addr */      preprocess_addr_buffer[reg_index] <= 0;
                /* data */      preprocess_data_buffer[reg_index] <= 0;
                /* type */      preprocess_type_buffer[reg_index] <= 0;
                /* byte mask */ preprocess_byte_mask_buffer[reg_index] <= 0;
                /* port num */  preprocess_port_num_buffer[reg_index] <= 0;

                /* valid */     preprocess_valid_buffer[reg_index] <= 0;
                /* is write */  preprocess_is_write_buffer[reg_index] <= 0;
                /*cacheable*/   preprocess_cacheable_buffer[reg_index] <= 0;
            end

            //counter
            preprocess_counter <= 0;
            preprocess_end_flag <= 0;
        end

        case (generator_ctrl_state)


            `STATE_INIT:
            begin
                generator_ctrl_state <= `STATE_CASE_0;
            end


            `STATE_CLEAR:
            begin

            end


            `STATE_FINAL:
            begin
                generator_ctrl_state <= generator_ctrl_state;
            end


            // random
            `STATE_CASE_0:
            begin
                if (test_case_config)
                begin
                    test_case               <= 0;

                    way_enable_reg          <= 1;
                    way_time_delay_reg[0]   <= DEFAULT_WAY_TIME_DELAY;
                    check_mode_reg          <= 0;
                    preprocess_mode_reg     <= 1;

                    check_valid_mask        <= {{(NUM_REQUEST){1'b0}}, {(NUM_REQUEST){1'b1}}};
                end

                if (test_case_preprocess)
                begin

                    /* packet in buffer */

                    /* addr */      preprocess_addr_buffer[0] <= {(`CPU_ADDR_LEN_IN_BITS){8'b0000_0000 + ((preprocess_index_times_17) << `UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS)}};
                    /* data */      preprocess_data_buffer[0] <= {(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b1}} - preprocess_read_after_write_index;
                    /* type */      preprocess_type_buffer[0] <= {(`UNIFIED_CACHE_PACKET_TYPE_WIDTH){1'b0}};
                    /* byte mask */ preprocess_byte_mask_buffer[0] <= {(`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN){2'b11}};
                    /* port num */  preprocess_port_num_buffer[0] <= {(`UNIFIED_CACHE_PACKET_PORT_ID_WIDTH){1'b0}};
    
                    /* valid */     preprocess_valid_buffer[0] <= {1'b1};
                    /* is write */  preprocess_is_write_buffer[0] <= preprocess_counter_even;
                    /*cacheable*/   preprocess_cacheable_buffer[0] <= {1'b1};
                
                    // end flag
                    if (preprocess_counter == NUM_REQUEST - 1)
                    begin
                        preprocess_end_flag <= 1;
                    end
                    else
                    begin
                        preprocess_counter  <= preprocess_counter + 1'b1;
                    end
                end

                if (test_case_final)
                begin
                    //state transition
                    if (generator_ctrl_state == `STATE_CASE_0 + NUM_TEST_CASE - 1)
                    begin
                        generator_ctrl_state <= `STATE_FINAL;
                    end
                    else
                    begin
                        generator_ctrl_state <= generator_ctrl_state + 1;
                    end

                end
            end

            // different bank
            `STATE_CASE_1:
            begin
                if (test_case_config)
                begin
                    test_case               <= 0;

                    way_enable_reg          <= 1;
                    way_time_delay_reg[0]   <= DEFAULT_WAY_TIME_DELAY;
                    check_mode_reg          <= 0;
                    preprocess_mode_reg     <= 1;

                    check_valid_mask        <= {{(NUM_REQUEST){1'b0}}, {(NUM_REQUEST){1'b1}}};
                end

                if (test_case_preprocess)
                begin

                    /* packet in buffer */

                    /* addr */      preprocess_addr_buffer[0] <= {(`CPU_ADDR_LEN_IN_BITS){8'b0000_0000 + ({{(32 - $clog2(`UNIFIED_CACHE_NUM_BANK)){1'b0}}, {(preprocess_index_times_17[$clog2(`UNIFIED_CACHE_NUM_BANK) - 1 : 0])}} << `UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS)}};
                    /* data */      preprocess_data_buffer[0] <= {(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b1}} - preprocess_read_after_write_index;
                    /* type */      preprocess_type_buffer[0] <= {(`UNIFIED_CACHE_PACKET_TYPE_WIDTH){1'b0}};
                    /* byte mask */ preprocess_byte_mask_buffer[0] <= {(`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN){2'b11}};
                    /* port num */  preprocess_port_num_buffer[0] <= {(`UNIFIED_CACHE_PACKET_PORT_ID_WIDTH){1'b0}};

                    /* valid */     preprocess_valid_buffer[0] <= {1'b1};
                    /* is write */  preprocess_is_write_buffer[0] <= preprocess_counter_even;
                    /*cacheable*/   preprocess_cacheable_buffer[0] <= {1'b1};


                    // end flag
                    if (preprocess_counter == NUM_REQUEST - 1)
                    begin
                        preprocess_end_flag <= 1;
                    end
                    else
                    begin
                        preprocess_counter  <= preprocess_counter + 1'b1;
                    end
                end

                if (test_case_final)
                begin
                    //state transition
                    if (generator_ctrl_state == `STATE_CASE_0 + NUM_TEST_CASE - 1)
                    begin
                        generator_ctrl_state <= `STATE_FINAL;
                    end
                    else
                    begin
                        generator_ctrl_state <= generator_ctrl_state + 1;
                    end

                end
            end

            // same bank
            `STATE_CASE_2:
            begin
                if (test_case_config)
                begin
                    test_case               <= 0;

                    way_enable_reg          <= 1;
                    way_time_delay_reg[0]   <= DEFAULT_WAY_TIME_DELAY;
                    check_mode_reg          <= 0;
                    preprocess_mode_reg     <= 1;

                    check_valid_mask        <= {{(NUM_REQUEST){1'b0}}, {(NUM_REQUEST){1'b1}}};
                end

                if (test_case_preprocess)
                begin

                    /* packet in buffer */

                    /* addr */      preprocess_addr_buffer[0] <= {(`CPU_ADDR_LEN_IN_BITS){32'b0000_0000 + (({{preprocess_index_times_17[31 : ($clog2(`UNIFIED_CACHE_NUM_BANK))]}, {($clog2(`UNIFIED_CACHE_NUM_BANK)){1'b0}}}) << `UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS)}};
                    /* data */      preprocess_data_buffer[0] <= {(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b1}} - preprocess_read_after_write_index;
                    /* type */      preprocess_type_buffer[0] <= {(`UNIFIED_CACHE_PACKET_TYPE_WIDTH){1'b0}};
                    /* byte mask */ preprocess_byte_mask_buffer[0] <= {(`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN){2'b11}};
                    /* port num */  preprocess_port_num_buffer[0] <= {(`UNIFIED_CACHE_PACKET_PORT_ID_WIDTH){1'b0}};

                    /* valid */     preprocess_valid_buffer[0] <= {1'b1};
                    /* is write */  preprocess_is_write_buffer[0] <= preprocess_counter_even;
                    /*cacheable*/   preprocess_cacheable_buffer[0]  <= {1'b1};

                    

                    // end flag
                    if (preprocess_counter == NUM_REQUEST - 1)
                    begin
                        preprocess_end_flag <= 1;
                    end
                    else
                    begin
                        preprocess_counter  <= preprocess_counter + 1'b1;
                    end
                end

                if (test_case_final)
                begin
                    //state transition
                    if (generator_ctrl_state == `STATE_CASE_0 + NUM_TEST_CASE - 1)
                    begin
                        generator_ctrl_state <= `STATE_FINAL;
                    end
                    else
                    begin
                        generator_ctrl_state <= generator_ctrl_state + 1;
                    end

                end
            end

            // same set
            `STATE_CASE_3:
            begin
                if (test_case_config)
                begin
                    test_case               <= 0;

                    way_enable_reg          <= 1;
                    way_time_delay_reg[0]   <= DEFAULT_WAY_TIME_DELAY;
                    check_mode_reg          <= 0;
                    preprocess_mode_reg     <= 1;

                    check_valid_mask        <= {{(NUM_REQUEST){1'b0}}, {(NUM_REQUEST){1'b1}}};
                end

                if (test_case_preprocess)
                begin

                    /* packet in buffer */

                    /* addr */      preprocess_addr_buffer[0] <= {(`CPU_ADDR_LEN_IN_BITS){8'b0000_0000 + ((preprocess_read_after_write_index << ($clog2(`UNIFIED_CACHE_NUM_SETS))) << `UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS)}};
                    /* data */      preprocess_data_buffer[0] <= {(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b1}} - preprocess_read_after_write_index;
                    /* type */      preprocess_type_buffer[0] <= {(`UNIFIED_CACHE_PACKET_TYPE_WIDTH){1'b0}};
                    /* byte mask */ preprocess_byte_mask_buffer[0] <= {(`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN){2'b11}};
                    /* port num */  preprocess_port_num_buffer[0] <= {(`UNIFIED_CACHE_PACKET_PORT_ID_WIDTH){1'b0}};

                    /* valid */     preprocess_valid_buffer[0] <= {1'b1};
                    /* is write */  preprocess_is_write_buffer[0] <= preprocess_counter_even;
                    /*cacheable*/   preprocess_cacheable_buffer[0] <= {1'b1};


                    // end flag
                    if (preprocess_counter == NUM_REQUEST - 1)
                    begin
                        preprocess_end_flag <= 1;
                    end
                    else
                    begin
                        preprocess_counter  <= preprocess_counter + 1'b1;
                    end
                end
           // end

                if (test_case_final)
                begin
                    //state transition
                    if (generator_ctrl_state == `STATE_CASE_0 + NUM_TEST_CASE - 1)
                    begin
                        generator_ctrl_state <= `STATE_FINAL;
                    end
                    else
                    begin
                        generator_ctrl_state <= generator_ctrl_state + 1;
                    end

                end
            end

            // dual-way random
            `STATE_CASE_4:
            begin
                if (test_case_config)
                begin
                    test_case <= test_case + 1;

                    way_enable_reg <= {(NUM_WAY){1'b1}};
                    check_mode_reg <= 0;
                    preprocess_mode_reg <= 1;

                    check_valid_mask <= {{(NUM_REQUEST){1'b1}}, {(NUM_REQUEST){1'b1}}};

                end

                if (test_case_preprocess)
                begin
                    for (preprocess_way_index = 0; preprocess_way_index < NUM_WAY; preprocess_way_index = preprocess_way_index + 1)
                    begin

                        /* packet in buffer */
                        preprocess_addr_buffer[preprocess_way_index] <= {(`CPU_ADDR_LEN_IN_BITS){8'b0000_0000 + ((preprocess_index_times_17 + NUM_REQUEST * preprocess_way_index) << `UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS)}};
                        preprocess_data_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b1}} - preprocess_read_after_write_index << preprocess_way_index;
                        preprocess_type_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_PACKET_TYPE_WIDTH){1'b0}};
                        preprocess_byte_mask_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN){2'b11}};
                        preprocess_port_num_buffer[preprocess_way_index] <= preprocess_way_index;

                        preprocess_valid_buffer[preprocess_way_index] <= {1'b1};
                        preprocess_is_write_buffer[preprocess_way_index] <= preprocess_counter_even;
                        preprocess_cacheable_buffer[preprocess_way_index] <= {1'b1};

                   end
                        // end flag
                        if (preprocess_counter == NUM_REQUEST - 1)
                        begin
                            preprocess_end_flag <= 1;
                        end
                        else
                        begin
                            preprocess_counter <= preprocess_counter + 1'b1;
                        end
                end

                if (test_case_final)
                begin
                    //state transition
                    if (generator_ctrl_state == `STATE_CASE_0 + NUM_TEST_CASE - 1)
                    begin
                        generator_ctrl_state <= `STATE_FINAL;
                    end
                    else
                    begin
                        generator_ctrl_state <= generator_ctrl_state + 1;
                    end
                end
            end

            // dual-way different bank
            `STATE_CASE_5:
            begin
                if (test_case_config)
                begin
                    test_case <= test_case + 1;

                    way_enable_reg <= {(NUM_WAY){1'b1}};
                    check_mode_reg <= 0;
                    preprocess_mode_reg <= 1;

                    check_valid_mask <= {{(NUM_REQUEST){1'b1}}, {(NUM_REQUEST){1'b1}}};

                end

                if (test_case_preprocess)
                begin
                    for (preprocess_way_index = 0; preprocess_way_index < NUM_WAY; preprocess_way_index = preprocess_way_index + 1)
                    begin

                        /* packet in buffer */
                        preprocess_addr_buffer[preprocess_way_index] <= {(`CPU_ADDR_LEN_IN_BITS){8'b0000_0000 + ((({{preprocess_index_times_17[$clog2(`UNIFIED_CACHE_NUM_BANK) - 1 : 0]}, {(32 - $clog2(`UNIFIED_CACHE_NUM_BANK)){1'b0}}} << $clog2(NUM_WAY)) + preprocess_way_index) << `UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS)}};
                        preprocess_data_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b1}} - preprocess_read_after_write_index << preprocess_way_index;
                        preprocess_type_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_PACKET_TYPE_WIDTH){1'b0}};
                        preprocess_byte_mask_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN){2'b11}};
                        preprocess_port_num_buffer[preprocess_way_index] <= preprocess_way_index;

                        preprocess_valid_buffer[preprocess_way_index] <= {1'b1};
                        preprocess_is_write_buffer[preprocess_way_index] <= preprocess_counter_even;
                        preprocess_cacheable_buffer[preprocess_way_index] <= {1'b1};

                   end
                        // end flag
                        if (preprocess_counter == NUM_REQUEST - 1)
                        begin
                            preprocess_end_flag <= 1;
                        end
                        else
                        begin
                            preprocess_counter <= preprocess_counter + 1'b1;
                        end
                end

                if (test_case_final)
                begin
                    //state transition
                    if (generator_ctrl_state == `STATE_CASE_0 + NUM_TEST_CASE - 1)
                    begin
                        generator_ctrl_state <= `STATE_FINAL;
                    end
                    else
                    begin
                        generator_ctrl_state <= generator_ctrl_state + 1;
                    end
                end
            end

            // dual-way same bank
            `STATE_CASE_6:
             begin
                if (test_case_config)
                begin
                    test_case <= test_case + 1;

                    way_enable_reg <= {(NUM_WAY){1'b1}};
                    check_mode_reg <= 0;
                    preprocess_mode_reg <= 1;

                    check_valid_mask <= {{(NUM_REQUEST){1'b1}}, {(NUM_REQUEST){1'b1}}};

                end

                if (test_case_preprocess)
                begin
                    for (preprocess_way_index = 0; preprocess_way_index < NUM_WAY; preprocess_way_index = preprocess_way_index + 1)
                    begin
                        /* packet in buffer */
                        preprocess_addr_buffer[preprocess_way_index] <= {(`CPU_ADDR_LEN_IN_BITS){8'b0000_0000 + ((({{preprocess_index_times_17[31 : $clog2(`UNIFIED_CACHE_NUM_BANK)]}, {($clog2(`UNIFIED_CACHE_NUM_BANK)){1'b0}}} << $clog2(NUM_WAY)) + preprocess_way_index) << `UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS)}};
                        preprocess_data_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b1}} - preprocess_read_after_write_index << preprocess_way_index;
                        preprocess_type_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_PACKET_TYPE_WIDTH){1'b0}};
                        preprocess_byte_mask_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN){2'b11}};
                        preprocess_port_num_buffer[preprocess_way_index] <= preprocess_way_index;

                        preprocess_valid_buffer[preprocess_way_index] <= {1'b1};
                        preprocess_is_write_buffer[preprocess_way_index] <= preprocess_counter_even;
                        preprocess_cacheable_buffer[preprocess_way_index] <= {1'b1};


                   end
                        // end flag
                        if (preprocess_counter == NUM_REQUEST - 1)
                        begin
                            preprocess_end_flag <= 1;
                        end
                        else
                        begin
                            preprocess_counter <= preprocess_counter + 1'b1;
                        end
                end

                if (test_case_final)
                begin
                    //state transition
                    if (generator_ctrl_state == `STATE_CASE_0 + NUM_TEST_CASE - 1)
                    begin
                        generator_ctrl_state <= `STATE_FINAL;
                    end
                    else
                    begin
                        generator_ctrl_state <= generator_ctrl_state + 1;
                    end
                end
            end

            // dual-way same set
            `STATE_CASE_7:
             begin
                if (test_case_config)
                begin
                    test_case <= test_case + 1;

                    way_enable_reg <= {(NUM_WAY){1'b1}};
                    check_mode_reg <= 0;
                    preprocess_mode_reg <= 1;


                    check_valid_mask <= {{(NUM_REQUEST){1'b1}}, {(NUM_REQUEST){1'b1}}};

                end

                if (test_case_preprocess)
                begin
                    for (preprocess_way_index = 0; preprocess_way_index < NUM_WAY; preprocess_way_index = preprocess_way_index + 1)
                    begin

                        /* packet in buffer */
                        preprocess_addr_buffer[preprocess_way_index] <= {(`CPU_ADDR_LEN_IN_BITS){8'b0000_0000 + ((({{preprocess_index_times_17[31 : $clog2(`UNIFIED_CACHE_NUM_SETS)]}, {($clog2(`UNIFIED_CACHE_NUM_SETS)){1'b0}}} << $clog2(NUM_WAY)) + preprocess_way_index) << `UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS)}};
                        preprocess_data_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS){1'b1}} - preprocess_read_after_write_index << preprocess_way_index;
                        preprocess_type_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_PACKET_TYPE_WIDTH){1'b0}};
                        preprocess_byte_mask_buffer[preprocess_way_index] <= {(`UNIFIED_CACHE_PACKET_BYTE_MASK_LEN){2'b11}};
                        preprocess_port_num_buffer[preprocess_way_index] <= preprocess_way_index;

                        preprocess_valid_buffer[preprocess_way_index] <= {1'b1};
                        preprocess_is_write_buffer[preprocess_way_index] <= preprocess_counter_even;
                        preprocess_cacheable_buffer[preprocess_way_index] <= {1'b1};

                   end
                        // end flag
                        if (preprocess_counter == NUM_REQUEST - 1)
                        begin
                            preprocess_end_flag <= 1;
                        end
                        else
                        begin
                            preprocess_counter <= preprocess_counter + 1'b1;
                        end
                end

                if (test_case_final)
                begin
                    //state transition
                    if (generator_ctrl_state == `STATE_CASE_0 + NUM_TEST_CASE - 1)
                    begin
                        generator_ctrl_state <= `STATE_FINAL;
                    end
                    else
                    begin
                        generator_ctrl_state <= generator_ctrl_state + 1;
                    end
                end
            end

/**
            `STATE_CASE_X:
            begin
                if (test_case_config)
                begin
                    // insert your code
                end
                if (test_case_preprocess)
                begin
                    // insert your code
                end
                if (test_case_check)
                begin
                    // insert your code
                end
                if (test_case_final)
                begin
                    //state transition
                    if (generator_ctrl_state == `STATE_CASE_0 + NUM_TEST_CASE - 1)
                    begin
                        generator_ctrl_state <= `STATE_FINAL;
                    end
                    else
                    begin
                        generator_ctrl_state <= generator_ctrl_state + 1;
                    end
                end
            end
 **/

            //default: begin end
        endcase

    end
end

// test case ctrl state
always @(posedge clk_in)
begin
    if (reset_in)
    begin
        test_case_ctrl_state <= 1'b0;
        test_case_ack_out    <= 1'b0;

        way_clear_flag      <= 0;
        for (reg_index = 0; reg_index < NUM_TEST_CASE; reg_index = reg_index + 1)
        begin
            done_vector[reg_index] <= 0;
            error_vector[reg_index] <= 0;
        end
    end
    else
    begin
        case (test_case_ctrl_state)

            `TEST_CASE_STATE_IDLE:
            begin
                if (generator_ctrl_state >= `STATE_CASE_0)
                begin
                    test_case_ctrl_state <= `TEST_CASE_STATE_CONFIG;
                    way_clear_flag <= 0;
                end
            end

            `TEST_CASE_STATE_CONFIG:
            begin
                test_case_ctrl_state <= `TEST_CASE_STATE_DELAY;
            end

            `TEST_CASE_STATE_DELAY:
            begin
                if (preprocess_mode_reg)
                begin
                    test_case_ctrl_state <= `TEST_CASE_STATE_PREPROCESS;
                end
                else
                begin
                    test_case_ctrl_state <= `TEST_CASE_STATE_RUNNING;
                end
            end

            `TEST_CASE_STATE_PREPROCESS:
            begin
                if (preprocess_end_flag)
                begin
                    test_case_ctrl_state <= `TEST_CASE_STATE_RUNNING;
                end
            end

            `TEST_CASE_STATE_RUNNING:
            begin
                if (running_end_flag)
                begin
                    test_case_ctrl_state <= `TEST_CASE_STATE_CHECK;
                end
            end

            `TEST_CASE_STATE_CHECK:
            begin
                if (check_end_flag)
                begin
                    test_case_ctrl_state <= `TEST_CASE_STATE_RECORD;
                end
            end

            `TEST_CASE_STATE_RECORD:
            begin

                if (test_case_ack_out & test_case_ack_in)
                begin
                        test_case_ctrl_state <= `TEST_CASE_STATE_FINAL;
                end
                    
                else if (test_case_ack_out & ~test_case_ack_in)
                begin
                    test_case_ack_out   <= test_case_ack_out;
                end
                
                else
                begin
                    done_vector[generator_ctrl_state - `STATE_CASE_0] <= done_way | ~way_enable_reg;
                        error_vector[generator_ctrl_state - `STATE_CASE_0] <= error_way & way_enable_reg | |(way_expected_valid_array_packed & way_in_valid_array_packed & check_valid_mask);
                    test_case_ack_out   <= 1'b1;
                end
            end

            `TEST_CASE_STATE_FINAL:
            begin
                test_case_ctrl_state <= `TEST_CASE_STATE_IDLE;
                way_clear_flag       <= 1;
                test_case_ack_out   <= 1'b0;
            end
        endcase
    end
end
endmodule
