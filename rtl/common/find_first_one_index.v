`define encoder_case(count) { {(VECTOR_LENGTH-(count)-1){1'b0}}, {{1'b1}}, {(count){1'bx}} } : first_one_index <= (count)

module find_first_one_index
#(
    parameter VECTOR_LENGTH = 8
)
(
    input       [VECTOR_LENGTH - 1 : 0] vector_input,
    output reg  [31                : 0] first_one_index
);

always@(*)
begin
    casex(vector_input)

    default:
    begin
            first_one_index <= 0;
    end

    `encoder_case(1);
    `encoder_case(2);
    `encoder_case(3);
    `encoder_case(4);
    `encoder_case(5);
    `encoder_case(6);
    `encoder_case(7);
    `encoder_case(8);
    `encoder_case(9);
    `encoder_case(10);
    `encoder_case(11);
    `encoder_case(12);
    `encoder_case(13);
    `encoder_case(14);
    `encoder_case(15);
    `encoder_case(16);
    `encoder_case(17);
    `encoder_case(18);
    `encoder_case(19);
    `encoder_case(20);
    `encoder_case(21);
    `encoder_case(22);
    `encoder_case(23);
    `encoder_case(24);
    `encoder_case(25);
    `encoder_case(26);
    `encoder_case(27);
    `encoder_case(28);
    `encoder_case(29);
    `encoder_case(30);
    `encoder_case(31);

    endcase
end

endmodule
