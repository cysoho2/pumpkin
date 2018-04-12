`define SIG_TABLE_SET                           512
`define SIG_TABLE_ASSOCIATIVITY                 2
`define SIG_TABLE_PAGE_NUM_TAG_BITS             8
`define SIG_TABLE_SET_INDEX_BITS                $clog2(`SIG_TABLE_SET)
        
`define PT_TABLE_SIG_SET                        256
`define PT_TABLE_SIG_ASSOCIATIVITY              4
`define PT_TABLE_DELTA_SET                      (`PT_TABLE_SIG_SET) * (`PT_TABLE_SIG_ASSOCIATIVITY)
`define PT_TABLE_DELTA_ASSOCIATIVITY            4

`define SIG_LENTH                               12
`define SIG_SHIFT                               3
`define NUM_DELTA_PER_SIG                       3
`define DELTA_LENGTH_IN_SIG                     (`SIG_LENTH)/(`NUM_DELTA_PER_SIG)
        
`define PT_TABLE_SIG_INDEX_BITS                 ($clog2(`PT_TABLE_SIG_SET)/$clog2(2))
`define PT_TABLE_SIG_TAG_BITS                   ((`SIG_LENTH) - (`PT_TABLE_SIG_INDEX_BITS))
`define PT_TABLE_SIG_COUNTER_BITS               4

`define PT_TABLE_DELTA_INDEX_BITS               $clog2(`PT_TABLE_DELTA_SET)
`define DELTA_BITS                              7
`define PT_TABLE_DELTA_COUNTER_BITS             4

`define INPUT_REQUEST_QUEUE_SIZE                16
`define PREFETCH_OUTPUT_QUEUE_SIZE              8