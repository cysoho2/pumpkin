// General
`define BYTE_LEN_IN_BITS                                8

`define CPU_DATA_LEN_IN_BITS                            64
`define CPU_DATA_LEN_IN_BYTES                           (`CPU_DATA_LEN_IN_BITS) / (`BYTE_LEN_IN_BITS)
`define CPU_INST_LEN_IN_BITS                            32
`define CPU_INST_LEN_IN_BYTES                           (`CPU_INST_LEN_IN_BITS) / (`BYTE_LEN_IN_BITS)

// For unified cache
`define UNIFIED_CACHE_SIZE_IN_BYTES                     128 * 1024
`define UNIFIED_CACHE_SET_ASSOCIATIVITY                 4              
`define UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES               4
`define UNIFIED_CACHE_NUM_SETS                          (`UNIFIED_CACHE_SIZE_IN_BYTES) / (`UNIFIED_CACHE_SET_ASSOCIATIVITY) / (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES)
`define UNIFIED_CACHE_BLOCK_SIZE_IN_BITS                (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES) * 8
`define UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS          ($clog2(`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES))
`define UNIFIED_CACHE_BLOCK_OFFSET_POS_HI               (`UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS) - 1
`define UNIFIED_CACHE_BLOCK_OFFSET_POS_LO               0
`define UNIFIED_CACHE_INDEX_LEN_IN_BITS                 ($clog2((`UNIFIED_CACHE_SIZE_IN_BYTES) / (`UNIFIED_CACHE_BLOCK_SIZE_IN_BYTES) / (`UNIFIED_CACHE_SET_ASSOCIATIVITY)))
`define UNIFIED_CACHE_INDEX_POS_HI                      (`UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS) + (`UNIFIED_CACHE_INDEX_LEN_IN_BITS) - 1
`define UNIFIED_CACHE_INDEX_POS_LO                      (`UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS)
`define UNIFIED_CACHE_TAG_LEN_IN_BITS                   (`CPU_DATA_LEN_IN_BITS) - (`UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS) - (`UNIFIED_CACHE_INDEX_LEN_IN_BITS)
`define UNIFIED_CACHE_TAG_POS_HI                        (`UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS) + (`UNIFIED_CACHE_INDEX_LEN_IN_BITS) + (`UNIFIED_CACHE_TAG_LEN_IN_BITS) - 1
`define UNIFIED_CACHE_TAG_POS_LO                        (`UNIFIED_CACHE_BLOCK_OFFSET_LEN_IN_BITS) + (`UNIFIED_CACHE_INDEX_LEN_IN_BITS)

`define UNIFIED_CACHE_PACKET_TYPE_WIDTH                 4
`define MEM_PACKET_TYPE_WIDTH                           (`UNIFIED_CACHE_PACKET_TYPE_WIDTH)

`define INST_PACKET_FLAG                                1
`define DATA_PACKET_FLAG                                0

// microarchtecture parameters for unified cache

`define INST_REQUEST_QUEUE_SIZE                         4
`define INST_REQUEST_QUEUE_PTR_WIDTH_IN_BITS            2

`define DATA_REQUEST_QUEUE_SIZE                         4
`define DATA_REQUEST_QUEUE_PTR_WIDTH_IN_BITS            2

`define WRITEBACK_BUFFER_SIZE                           4
`define WRITEBACK_BUFFER_PTR_WIDTH_IN_BITS              2

// unified cache packet format
`define UNIFIED_CACHE_PACKET_ADDR_POS_LO                0
`define UNIFIED_CACHE_PACKET_ADDR_POS_HI                (`UNIFIED_CACHE_PACKET_ADDR_POS_LO) + (`CPU_DATA_LEN_IN_BITS) - 1
`define UNIFIED_CACHE_PACKET_DATA_POS_LO                (`UNIFIED_CACHE_PACKET_ADDR_POS_HI) + 1
`define UNIFIED_CACHE_PACKET_DATA_POS_HI                (`UNIFIED_CACHE_PACKET_DATA_POS_LO) + (`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS) - 1
`define UNIFIED_CACHE_PACKET_VALID_POS                  (`UNIFIED_CACHE_PACKET_DATA_POS_HI) + 1
`define UNIFIED_CACHE_PACKET_IS_WRITE_POS               (`UNIFIED_CACHE_PACKET_VALID_POS) + 1
`define UNIFIED_CACHE_PACKET_TYPE_POS_LO                (`UNIFIED_CACHE_PACKET_IS_WRITE_POS) + 1
`define UNIFIED_CACHE_PACKET_TYPE_POS_HI                (`UNIFIED_CACHE_PACKET_TYPE_POS_LO) + (`UNIFIED_CACHE_PACKET_TYPE_WIDTH) - 1

`define UNIFIED_CACHE_PACKET_WIDTH_IN_BITS              (`UNIFIED_CACHE_PACKET_TYPE_POS_HI) - (`UNIFIED_CACHE_PACKET_ADDR_POS_LO) + 1

// unified cache <==> memory packet format
`define MEM_PACKET_ADDR_POS_LO                          0
`define MEM_PACKET_ADDR_POS_HI                          (`MEM_PACKET_ADDR_POS_LO) + (`CPU_DATA_LEN_IN_BITS) - 1
`define MEM_PACKET_DATA_POS_LO                          (`MEM_PACKET_ADDR_POS_HI) + 1
`define MEM_PACKET_DATA_POS_HI                          (`UNIFIED_CACHE_PACKET_DATA_POS_LO) + (`UNIFIED_CACHE_BLOCK_SIZE_IN_BITS) - 1
`define MEM_PACKET_VALID_POS                            (`MEM_PACKET_DATA_POS_HI) + 1
`define MEM_PACKET_IS_WRITE_POS                         (`MEM_PACKET_VALID_POS) + 1
`define MEM_PACKET_TYPE_POS_LO                          (`MEM_PACKET_IS_WRITE_POS) + 1
`define MEM_PACKET_TYPE_POS_HI                          (`MEM_PACKET_TYPE_POS_LO) + (`MEM_PACKET_TYPE_WIDTH) - 1                      

`define MEM_PACKET_WIDTH_IN_BITS                        (`MEM_PACKET_TYPE_POS_HI) - (`MEM_PACKET_ADDR_POS_LO) + 1
