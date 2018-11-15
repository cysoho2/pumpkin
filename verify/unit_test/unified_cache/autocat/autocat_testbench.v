`include "parameters.h"

module autocat_testbench();

    autocat
    #()
    autocat
    (
        .clk_in                         (),
        .reset_in                       (),
        .access_valid_in                (),
        .hit_vec_in                     (),
        .suggested_waymask_out          ()
    );

    initial
    begin
	    `ifdef DUMP
        	$dumpfile(`DUMP_FILENAME);
            $dumpvars(0, autocat_testbench);
	    `endif

        $display("\n[info-testbench] simulation for %m begins now");

        #(`FULL_CYCLE_DELAY) $display("[info-testbench] simulation comes to the end\n");
        $finish;
    end

    //always begin #(`HALF_CYCLE_DELAY) clk_in <= ~clk_in; end

endmodule
