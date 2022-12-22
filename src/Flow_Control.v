module Flow_Control (
    //From RS
    input wire RS_Stop,
    input wire  [3:0] RS_Tag,
    input wire [31:0] PC,
    //Public
    output wire  clr,

    //TO Processor
    output wire [31:0] PC_out,
    //TO ROB
    output wire  [3:0] Tag
);
assign  clr=RS_Stop;
assign  Tag=RS_Tag;
assign  PC_out=PC;
endmodule