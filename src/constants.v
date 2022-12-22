`define True 1'b1
`define False 1'b0
`define byte 7
`define Byte-Width 7:0
`define Data_Bus 31:0
`define Mem_Bus 7:0
`define HIGH 1'b1
`define LOW 1'b0
//For ICache
//`define Cache_Line 15:0
//`define Cache_Size 7:0
`define Cache_Line 3:0
`define Cache_Size 31:0
//For Reg
`define Register_size 4:0
`define Reg_Size 31:0

//for decoder
`define Opcode 6:0

//
`define I_LOAD 7'b0000011
`define I_BINARY 7'b0010011
`define U_AUIPC 7'b0010111
`define U_LUI 7'b0110111
`define S_SAVE 7'b0100011
`define R_PRIMARY 7'b0110011
`define SB_ALL 7'b1100011
`define I_JALR 7'b1100111
`define UJ_JAL 7'b1101111

//func3+func7
`define TAKEAWAY 17'b00000001111111111
`define LB 17'b00000110000000000
`define LH 17'b00000110010000000
`define LW 17'b00000110100000000
`define LBU 17'b00000111000000000
`define LHU 17'b00000111010000000
`define LWU 17'b00000111100000000
`define ADDI 17'b00100110000000000
`define SLLI 17'b00100110010000000
`define SLTI 17'b00100110100000000
`define SLTIU 17'b00100110110000000
`define XORI 17'b00100111000000000
`define SRLI 17'b00100111010000000
`define SRAI 17'b00100111010100000
`define ORI 17'b00100111100000000
`define ANDI 17'b00100111110000000
`define AUIPC 17'b00101110000000000
`define SB 17'b01000110000000000
`define SH 17'b01000110010000000
`define SW 17'b01000110100000000
`define ADD 17'b01100110000000000
`define SUB 17'b01100110000100000
`define SLL 17'b01100110010000000
`define SLT 17'b01100110100000000
`define SLTU 17'b01100110110000000
`define XOR 17'b01100111000000000
`define SRL 17'b01100111010000000
`define SRA 17'b01100111010100000
`define OR 17'b01100111100000000
`define AND 17'b01100111110000000
`define LUI 17'b01101110000000000
`define BEQ 17'b11000110000000000
`define BNE 17'b11000110010000000
`define BLT 17'b11000111000000000
`define BGE 17'b11000111010000000
`define BLTU 17'b11000111100000000
`define BGEU 17'b11000111110000000
`define JALR 17'b11001110000000000
`define JAL 17'b11011110000000000

//For Predictor
`define BTB_Width 511:0
//For Register
`define Register_Width 4:0

//for RS
`define RS_Size 31:0
`define NO_RS_AVAILABLE 32
`define RS_Width 4:0
//for ALU

`define Add 4'd0
`define Or 4'd1
`define LeftShift 4'd2
`define Less 4'd3
`define RightShift 4'd4
`define Minus 4'd5
`define Xor 4'd6
`define And 4'd7
`define Equal 4'd8
`define NotEqual 4'd9
`define GEQ 4'd10
`define RightShift_A 4'd11
`define GEQ_S 4'd12
`define Less_S 4'd13
//for ROB
`define ROB_Size 15:0//in this case,should >= RS_Size
`define Empty 16 //ROB_size+1
`define ROB_Width 3:0


//for LSB
`define LSB_Size 15:0
