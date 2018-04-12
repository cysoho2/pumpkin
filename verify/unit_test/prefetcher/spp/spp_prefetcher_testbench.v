module spp_prefetcher_testbench();

spp_prefetcher spp_prefetcher
(
        .clk_in(),
        .reset_in(),

        .access_address_in(),
        .access_valid_in(),
        .access_address_ack_out(),
        
        .prefetch_confidence_out(),
        .prefetch_critical_out(),

        .l3_read_queue_ack_in(),
        .l3_read_queue_full_in(),

        .access_write_in(),
        .access_core_id_in(),
        .access_inst_flag_in(),
        .access_type_in(),

        .evict_address_in(),
        .evict_valid_in(),

        .refill_address_in(),
        .refill_valid_in()
);

endmodule