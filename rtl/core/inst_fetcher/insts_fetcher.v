`include "parameters.h"
`include "isa_encoding.h"

`ifdef FULL_TEST
`include "sim_addr.h"
`endif

module inst_fetcher
(
    input                                                           reset_in,
    input                                                           clk_in,
    
    input   [(`INSTS_FETCH_WIDTH_IN_BITS)   - 1 : 0]                insts_fetch_in,
    input                                                           insts_fetch_valid_in,
    input                                                           insts_fetch_ack_in,
    output  [(`CPU_INST_LEN_IN_BITS)        - 1 : 0]                insts_fetch_addr_out,
    output                                                          insts_fetch_addr_valid_out,
    
    output  [(`INSTS_FETCH_WIDTH_IN_BITS)   - 1 : 0]                insts_to_idecoder_out
);

reg [(`CPU_INST_LEN_IN_BITS)        - 1 : 0]    pc_stage0_reg;
assign                                          insts_fetch_addr_out = pc_stage0_reg;
reg                                             insts_fetch_addr_valid_stage0_reg;
assign                                          insts_fetch_addr_valid_out = insts_fetch_addr_valid_stage0_reg;

reg                                             branch_detected_stage0_reg;

reg [(`INSTS_FETCH_WIDTH_IN_BITS)   - 1 : 0]    insts_fetch_stage1_reg;
reg [(`INSTS_FETCH_WIDTH_IN_BITS)   - 1 : 0]    insts_fetch_stage2_reg;
assign                                          insts_to_idecoder_out = insts_fetch_stage2_reg;

wire [(`CPU_INST_LEN_IN_BITS)       - 1 : 0]    insts_separation_stage0 [(`NUM_INSTS_FETCH_PER_CYCLE) - 1 : 0];
wire [(`NUM_INSTS_FETCH_PER_CYCLE)  - 1 : 0]    insts_branch_mark_stage0;
genvar gen;
for(gen = 0; gen < (`NUM_INSTS_FETCH_PER_CYCLE); gen = gen + 1)
begin
    assign insts_separation_stage0[gen]     = insts_fetch_valid_in
                                              ? insts_fetch_in[(gen+1) * (`CPU_INST_LEN_IN_BITS) - 1 : gen * (`CPU_INST_LEN_IN_BITS)]
                                              : {(`CPU_INST_LEN_IN_BITS){1'b0}};
    
    assign insts_branch_mark_stage0[gen]    = `IS_BR_INST(insts_separation_stage0[gen]);
end

//scans the fetched insts for the first branch inst
integer i;
reg [(`NUM_INSTS_FETCH_PER_CYCLE) - 1 : 0] sel;
always@*
begin : Find_First_Branch_Inst
sel <= {(`NUM_INSTS_FETCH_PER_CYCLE){1'b1}};
for( i = 0; i < (`NUM_INSTS_FETCH_PER_CYCLE); i = i + 1)
    begin
        if(insts_branch_mark_stage0[i])
        begin
            sel <= i;
            disable Find_First_Branch_Inst; //TO exit the loop
        end
    end
end

always@(posedge clk_in, posedge reset_in)
begin
    if(reset_in)
    begin
        branch_detected_stage0_reg <= 1'b0;
    end

    else
    begin
        branch_detected_stage0_reg <= sel != {(`NUM_INSTS_FETCH_PER_CYCLE){1'b1}};
    end
end

for(gen = 0; gen < (`NUM_INSTS_FETCH_PER_CYCLE); gen = gen + 1)
begin
    always@(posedge clk_in, posedge reset_in)
    begin
        if(reset_in)
        begin
            insts_fetch_stage1_reg[(gen+1) * (`CPU_INST_LEN_IN_BITS) - 1 : gen * (`CPU_INST_LEN_IN_BITS)]             
            <= {(`CPU_INST_LEN_IN_BITS){1'b0}};
            
            insts_fetch_stage2_reg[(gen+1) * (`CPU_INST_LEN_IN_BITS) - 1 : gen * (`CPU_INST_LEN_IN_BITS)]
            <= {(`CPU_INST_LEN_IN_BITS){1'b0}};
        end
        
        else if(insts_fetch_valid_in)
        begin
            
            insts_fetch_stage1_reg[(gen+1) * (`CPU_INST_LEN_IN_BITS) - 1 : gen * (`CPU_INST_LEN_IN_BITS)]
            <= insts_separation_stage0[gen];
                
            insts_fetch_stage2_reg[(gen+1) * (`CPU_INST_LEN_IN_BITS) - 1 : gen * (`CPU_INST_LEN_IN_BITS)]
            <= insts_branch_mark_stage0[gen] ? insts_fetch_stage1_reg[(gen+1) * (`CPU_INST_LEN_IN_BITS) - 1 : gen * (`CPU_INST_LEN_IN_BITS)] : {(`CPU_INST_LEN_IN_BITS){1'b0}};
            
        end
    end
end

//Insts fetching FSM
always@(posedge clk_in, posedge reset_in)
begin
    if(reset_in)
    begin
        `ifdef FULL_TEST
        pc_stage0_reg                               <= `PC_RESET;
        `else
        pc_stage0_reg                               <= 0;
        `endif
        insts_fetch_addr_valid_stage0_reg           <= 1'b0;
    end
    
    else
    begin
        if(~insts_fetch_ack_in)
        begin
            pc_stage0_reg                           <= pc_stage0_reg;
            insts_fetch_addr_valid_stage0_reg       <= 1'b1;
        end

        if(insts_fetch_ack_in)
        begin
            pc_stage0_reg                           <= pc_stage0_reg;
            insts_fetch_addr_valid_stage0_reg       <= 1'b0;  
        end

        if(insts_fetch_valid_in)
        begin
            //if branch inst exists, pc stalls at the branch point
            pc_stage0_reg                           <= branch_detected_stage0_reg ? pc_stage0_reg : pc_stage0_reg + (`NUM_INSTS_FETCH_PER_CYCLE) * (`CPU_INST_LEN_IN_BYTES);
            insts_fetch_addr_valid_stage0_reg       <= branch_detected_stage0_reg ? 1'b0 : 1'b1;
        end
    end
end

endmodule
