`include "sim_config.h"
`include "parameters.h"

module fifo_testbench();

parameter QUEUE_SIZE = 8;
parameter QUEUE_PTR_WIDTH_IN_BITS = 3;
parameter SINGLE_ENTRY_WIDTH_IN_BITS = 32;
parameter STORAGE_TYPE = "LUTRAM";

parameter TEST_CASE_1 = "write invalue data";
parameter TEST_CASE_2 = "normal write/read";
parameter TEST_CASE_3 = "write data then read more data";
parameter TEST_CASE_4 = "write data to full queue";
parameter TEST_CASE_5 = "read data from empty queue";

integer i;


reg                                             clk_in;
reg                                             reset_in;
reg     [31:0]                                  clk_ctr;

integer                                    		test_case;
reg     [31:0]                                  test_ctr;
reg                                             test_stage;
reg                                             test_wait;
reg                                             test_end_flag;
reg                                             test_check_buffer;
reg     [SINGLE_ENTRY_WIDTH_IN_BITS - 1:0]      test_buffer[QUEUE_SIZE - 1:0];

wire                                            is_empty;
wire		                                	is_full;

reg     [SINGLE_ENTRY_WIDTH_IN_BITS - 1:0]      request_in;
reg                                             request_valid_in;
wire                                            issue_ack_from_fifo;
wire    [SINGLE_ENTRY_WIDTH_IN_BITS - 1:0]      request_out;
wire                                            request_valid_out;
reg     	                                	issue_ack_to_fifo;

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
	.clk_in				(clk_in),
	.reset_in			(reset_in),
	
	.is_empty_out		(is_empty),
	.is_full_out		(is_full),

	.request_in			(request_in), 
	.request_valid_in	(request_valid_in),
	.issue_ack_out		(issue_ack_from_fifo),
	.request_out		(request_out),
	.request_valid_out  (request_valid_out),
	.issue_ack_in		(issue_ack_to_fifo)
);

always @(posedge clk_in or posedge reset_in)
begin

    case(test_case)
	
    0:
	begin
	
        if(reset_in)
        begin
            test_ctr            <= {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}}; 
            request_in          <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b1}};
            request_valid_in    <= 1'b0;
                
            test_stage          <= 1'b0;
            test_wait           <= 1'b0;
        end
	
		else if((test_ctr < QUEUE_SIZE / 2) & ~test_end_flag & ~test_stage)
		begin
			
			if (~test_wait)
			begin
				request_in          <= request_in - 1'b1;
				request_valid_in    <= 1'b0;
				test_ctr            <= test_ctr + 1;
			end
			
			else
				test_wait = 1'b0;
		end

		else
		begin
			request_in       <= request_in;
			request_valid_in <= 1'b0;   
			
			if(test_ctr == QUEUE_SIZE / 2)
			begin
				test_ctr    <= 1'b0;
				test_stage  <= 1'b1;
			end    
		end
			
    end
	
    1:
	begin
        	
        if(reset_in)
            begin
                test_ctr            <= {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}}; 
                request_in          <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b1}};
                request_valid_in    <= 1'b0;
                
                test_wait           <= 1'b0;
            end
    
		else if((test_ctr < QUEUE_SIZE / 2) & ~test_end_flag)
		begin
			if (~test_wait)
			begin
		
				request_in          <= request_in - 1'b1;
				request_valid_in    <= 1'b1;
		
				//record
				test_buffer[test_ctr]   <= request_in - 1'b1;
				test_ctr                <= test_ctr + 1'b1;
				test_wait               <= 1'b1;
			end
			
			else
				test_wait <= 1'b0;
		end

		else
		begin
			request_in       <= request_in;
			request_valid_in <= 1'b0;       
		end
    end
	
    2:
	begin

        if(reset_in)
        begin
             test_ctr         <= {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}}; 
             request_in       <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b1}};
             request_valid_in <= 1'b0;
                   
             test_stage       <= 1'b0;
        end
        
        else
        begin
            if(test_ctr < 1'b1)
            begin
                request_in       <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b1}};
                request_valid_in <= 1'b0;
                
                test_ctr         <= test_ctr + 1;
            end
            
            else
            begin
                request_in       <= request_in;
                request_valid_in <= 1'b0;       
            end
        end
               
    end

    3:
	begin
		if(reset_in)
		begin
			test_ctr            <= {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}}; 
			request_in          <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b1}};
			request_valid_in    <= 1'b0;
			
			test_wait = 1'b0;
			test_stage = 1'b0;
		end
	
		else if((test_ctr < QUEUE_SIZE * 2) & ~test_end_flag & (test_stage == 1'b0))
		begin
			if (~test_wait)
			begin
		
				request_in          <= request_in - 1'b1;
				request_valid_in    <= 1'b1;
		
				//record
				if(test_ctr >= QUEUE_SIZE)
				begin
					test_buffer[test_ctr]   <= request_in - 1'b1;
					test_ctr                <= test_ctr + 1'b1;
					test_wait               <= 1'b1;
				end
			end
			
			else
				test_wait <= 1'b0;
		end

		else
		begin
			request_in          <= request_in;
			request_valid_in    <= 1'b0;   
			
			test_stage          <= 1'b1;    
		end        
    end
	
	4:
	begin
        if(reset_in)
        begin
            test_ctr         <= {(QUEUE_PTR_WIDTH_IN_BITS){1'b0}}; 
            request_in       <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b1}};
            request_valid_in <= 1'b0;
               
            test_stage       <= 1'b0;
        end
        
        else
        begin
            request_in       <= request_in;
            request_valid_in <= 1'b0;
            
            test_stage       <= 1'b1;       
        end
           
    end
    endcase
end

always @(posedge clk_in or posedge reset_in)
begin
    
	case(test_case)
    
    0:
	begin   
        if(reset_in)
        begin
            issue_ack_to_fifo <= 1'b0;
        end
        
        else if(~test_end_flag)
        begin
            if(test_stage & (test_ctr < QUEUE_SIZE / 2))
            begin
            
                if(~issue_ack_to_fifo)
                    issue_ack_to_fifo <= 1'b1;
            
                else 
                begin
                
				if(~request_valid_out)
					#5 test_buffer[test_ctr]    <= request_out;
				else
					#5 test_buffer[test_ctr]    <= 1'b1;
					test_ctr                    <= test_ctr + 1'b1;
				end
            end
		
            else
            begin
                issue_ack_to_fifo <= 1'b0;
                
                if(test_ctr == QUEUE_SIZE / 2)
                    test_check_buffer <= 1'b1;
            end
        end
    end
	
    1:
	begin
	
        if(reset_in)
		begin
			issue_ack_to_fifo <= 1'b0;
		end
           
		else if(~test_end_flag)
		begin
			if((test_ctr >= QUEUE_SIZE / 2) && (test_ctr < QUEUE_SIZE))
			begin
			
				if(~issue_ack_to_fifo)
					issue_ack_to_fifo <= 1'b1;
			
				else if(request_valid_out)
				begin
					//record
					#5 test_buffer[test_ctr - QUEUE_SIZE / 2] <= test_buffer[test_ctr - QUEUE_SIZE / 2] ^ request_out;
					test_ctr                                  <= test_ctr + 1'b1;              
				end
			end
		
			else
			begin
				issue_ack_to_fifo <= 1'b0;
				
				if(test_ctr == QUEUE_SIZE)
					test_check_buffer <= 1'b1;
			end
		end
    end
	
    2:
	begin
		if(reset_in)
		begin
			issue_ack_to_fifo <= 1'b0;
		end
		
		else if(~test_end_flag & (test_ctr < QUEUE_SIZE))
		begin
			if(~issue_ack_to_fifo)
				issue_ack_to_fifo <= 1'b1;
			
			else if (test_ctr > 1'b0)
			begin
				//record
				#5 test_buffer[test_ctr]    <= request_out | request_valid_out;
				test_ctr                    <= test_ctr + 1'b1;              
			end
		end
		
		else   
		begin
			issue_ack_to_fifo <= 1'b0;
				
			if(test_ctr == QUEUE_SIZE)
				test_check_buffer  <= 1'b1;
		end
    end
	
    3:
	begin
		if(reset_in)
		begin
			issue_ack_to_fifo <= 1'b0;
		end
			
		else if(~test_end_flag)
		begin
		
			if(test_stage == 1'b1)
			begin
				
				if(~issue_ack_to_fifo)
				begin
					test_ctr = 1'b0;
					issue_ack_to_fifo <= 1'b1;
				end
				
				else if(request_valid_out &  (test_ctr < QUEUE_SIZE))
				begin
					//record
					#5 	test_buffer[test_ctr]  <= test_buffer[test_ctr] ^ request_out;
						test_ctr                <= test_ctr + 1'b1;              
				end
			end
			
			else
			begin
				issue_ack_to_fifo <= 1'b0;
				
				if(test_ctr == QUEUE_SIZE)
					test_check_buffer = 1'b1;
			end
		end
	end
	
	4:
	begin
        if(reset_in)
        begin
            issue_ack_to_fifo <= 1'b0;
        end
                
        else if(~test_end_flag & (test_ctr < QUEUE_SIZE))
        begin
             if(~issue_ack_to_fifo)
                  issue_ack_to_fifo <= 1'b1;
                            
             else
             begin
                //record
                #5 	test_buffer[test_ctr]    <= request_out | request_valid_out;
                	test_ctr                    <= test_ctr + 1'b1;              
             end
        end
                        
        else   
        begin
            issue_ack_to_fifo <= 1'b0;
                               
            if(test_ctr == QUEUE_SIZE)
                test_check_buffer  <= 1'b1;
        end
    end  
    endcase
end

always@*
begin
	//init buffer
	if(reset_in)
	begin
		for(i = 0; i < QUEUE_SIZE; i = i + 1)
		begin
			test_buffer[i] <= {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b0}};    
		end
	end

	//check data of buffer
	if(test_check_buffer & ~test_end_flag)
	begin
		for(i = 0; i < QUEUE_SIZE; i = i + 1)
		begin
			if(test_buffer[i] != {(SINGLE_ENTRY_WIDTH_IN_BITS){1'b0}})
				i = QUEUE_SIZE;
		end
		
		if (i == QUEUE_SIZE)
			case(test_case)
			0: $display("[info-rtl] test case 1%35s : \tpassed", TEST_CASE_1);
			1: $display("[info-rtl] test case 2%35s : \tpassed", TEST_CASE_2);
			2: $display("[info-rtl] test case 3%35s : \tpassed", TEST_CASE_3);
			3: $display("[info-rtl] test case 4%35s : \tpassed", TEST_CASE_4);
			4: $display("[info-rtl] test case 5%35s : \tpassed", TEST_CASE_5);
			endcase
		else
			case(test_case)
			0: $display("[info-rtl] test case 1%35s : \tfailed", TEST_CASE_1);
			1: $display("[info-rtl] test case 2%35s : \tfailed", TEST_CASE_2);
			2: $display("[info-rtl] test case 3%35s : \tfailed", TEST_CASE_3);
			3: $display("[info-rtl] test case 4%35s : \tfailed", TEST_CASE_4);
			4: $display("[info-rtl] test case 5%35s : \tfailed", TEST_CASE_5);
			endcase
			
		test_check_buffer   = 1'b0;
		test_end_flag       = 1'b1;
	end   
end


initial
begin
    `ifdef DUMP
        $dumpfile("sim_waves.fst");
        $dumpvars(0, fifo_testbench);
    `endif

		$display("\n[info-rtl] simulation begins now\n");

    	clk_in              = 1'b0;
    	reset_in            = 1'b0;
    	
    	test_end_flag       = 1'b1;
        test_check_buffer   = 1'b0;
        test_case           = 0;
    	
#10     reset_in            = 1'b1;
#10     reset_in            = 1'b0;

//test case 1
#10     test_case           = 0;     
#10     test_end_flag       = 1'b0;

//test case 2
#500    reset_in            = 1'b1;
#10     reset_in            = 1'b0;

#10     test_case           = 1;     
#10     test_end_flag       = 1'b0;

//test case 3
#500    reset_in            = 1'b1;
#10     reset_in            = 1'b0;

#10     test_case           = 2;     
#10     test_end_flag       = 1'b0;

//test case 4
#500    reset_in            = 1'b1;
#10     reset_in            = 1'b0;

#10     test_case           = 3;     
#10     test_end_flag       = 1'b0;

//test case 5
#500    reset_in            = 1'b1;
#10     reset_in            = 1'b0;

#10     test_case           = 4;     
#10     test_end_flag       = 1'b0;

#`FULL_CYCLE_DELAY   $display("\n[info-rtl] simulation comes to the end\n");
        $finish;
end

always begin #2.5 clk_in <= ~clk_in; end

endmodule
