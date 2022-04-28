// booth-one-parameter
// max value = 16384 = 2'b0100 0000 0000 0000

module booth_mult#(parameter width=8)(
           input clk,
           input rst_n,
           input en,

           input [width-1:0]A,    // input data A
           input [width-1:0]B,    // input data B

           output reg done,       // done flag
           output reg [2*width-1:0]M   // output data multiply
       );


reg [1:0]					state;      // machine state
reg [2*width-1:0]			mult_A;     // result of A, extend to 2*width
reg [width:0]				mult_B;     // result of B
reg [2*width-1:0]			inv_A;      // reverse result of A, extend to 2*width
reg [2*width-1:0]			result_tmp; // operation register
wire [1:0]					booth_code; // booth code
assign booth_code = mult_B[1:0];       // booth code always equal to B[1:0]
reg [31:0]                  count;      // count

always @ ( posedge clk or negedge rst_n )
    if( !rst_n )
    begin // reset
        state <= 0;
        mult_A <= 0;
        inv_A <= 0;
        result_tmp <= 0;
        done <= 0;
        M <= 0;
        count <= 0;
    end
    else if( en )
    begin
        case( state )
            0:
            begin
                mult_A <= { { width{ A[width-1]} }, A}; // A[width-1] is the MSB of A, and extend to width bits
                inv_A <= ~{ { width{ A[width-1]} }, A} + 1'b1 ; // inv_A = reverse (-A) = reverse(A) + 1'b1
                result_tmp <= 0;
                mult_B <= { B, 1'b0}; // initialize mult_B
                state <= state + 1'b1;
            end
            1:
            begin
                if( count < width )
                begin // if not stop, calculate result_tmp according to booth code
                    case(booth_code)
                        2'b01 :
                            result_tmp <= result_tmp + mult_A;  // add mult_A
                        2'b10 :
                            result_tmp <= result_tmp + inv_A;   // add inv_A
                        default:
                            result_tmp <= result_tmp;       // do nothing
                    endcase
                    mult_A <= {mult_A[2*width-2:0],1'b0};  // shift mult_A to left, and add 1'b0 to the right
                    inv_A <=  {inv_A[2*width-2:0],1'b0};   // shift inv_A to left, and add 1'b0 to the right
                    mult_B <= {mult_B[width],mult_B[width:1]}; // shift mult_B to left, and extend singed bit
                    count <= count + 1;
                end
                else
                begin
                    state <= state + 1'b1;
                    count <= 0;
                end
            end
            2:
            begin
                done <= 1'b1;       // done flag
                M <= result_tmp;    // output result
                state <= state + 1'b1;
            end
            3:
            begin
                done <= 1'b0;
                state <= 0;
            end
            default:
            begin
                state <= 0;
            end
        endcase
    end
endmodule


