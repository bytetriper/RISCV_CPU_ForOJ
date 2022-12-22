`include "constants.v"
module Rob (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //From Flow_Control
    output reg clr,
    output reg [`Data_Bus] Clr_PC,

    //From Processor
    input wire ready,
    input wire [`Data_Bus] rd,
    input wire [16:0] name,
    input wire [`Data_Bus] Imm,
    input wire [`Data_Bus] PC,
    //To Processor
    output wire success,
    output wire [`ROB_Width] tail,
    //Public
    output wire [`ROB_Size] ROB_Valid,
    output wire [511:0] ROB_Imm,

    //From RS
    input wire RS_Ready,
    input wire [`Data_Bus] RS_A,
    input wire [`ROB_Width] RS_Tag,
    input wire [`Data_Bus] RS_Rd,

    //To RS
    output reg ROB_TO_RS_ready,
    output reg [3:0] ROB_TO_RS_Tag,
    //To Register(Processor)
    output reg ROB_Ready,
    output reg [`Data_Bus] ROB_Value,
    output reg [`Register_Width] ROB_Addr,
    output reg[`ROB_Width] ROB_Tag,//nessecary when deciding whether to remove Tags[Rob_addr]

    //To Mem_ctrl
    output reg              RN,           //read_enable
    output reg              WN,
    output reg  [`Data_Bus] Wvalue,
    output reg  [`Data_Bus] Addr,
    output reg  [     16:0] Inst_Name,
    input  wire             Mem_Success,
    input  wire [`Data_Bus] Read_Value
);
    reg [`Data_Bus] Rd[`ROB_Size];
    reg [16:0] Name[`ROB_Size];
    reg [`Data_Bus] A[`ROB_Size];
    reg [`Data_Bus] ROB_PC[`ROB_Size];
    reg Valid[`ROB_Size];
    reg Read_Able[`ROB_Size], Readed[`ROB_Size];
    reg [`ROB_Width] Tail;  //To automatic overflow
    reg [`ROB_Width] Head;  //To automatic overflow
    assign tail = Tail;
    wire [`ROB_Width] TAIL_ADD_ONE=Tail+1;//To automatic overflow
    //add inst from Processor
    assign success = (Head != TAIL_ADD_ONE);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign ROB_Valid[i] = Valid[i] & Readed[i];
            assign ROB_Imm[(i<<5)+31:(i<<5)] = A[i];
        end
    endgenerate
    wire HasRead;
    assign HasRead=(Read_Able[0]&!Readed[0])|
                        (Read_Able[1]&!Readed[1])|
                            (Read_Able[2]&!Readed[2])|
                                (Read_Able[3]&!Readed[3])|
                                    (Read_Able[4]&!Readed[4])|
                                        (Read_Able[5]&!Readed[5])|
                                            (Read_Able[6]&!Readed[6])|
                                                (Read_Able[7]&!Readed[7])|
                                                    (Read_Able[8]&!Readed[8])|
                                                        (Read_Able[9]&!Readed[9])|
                                                            (Read_Able[10]&!Readed[10])|
                                                                (Read_Able[11]&!Readed[11])|
                                                                    (Read_Able[12]&!Readed[12])|
                                                                        (Read_Able[13]&!Readed[13])|
                                                                            (Read_Able[14]&!Readed[14])|
                                                                                (Read_Able[15]&!Readed[15]);
    wire[`ROB_Width] Read_Tag =  (Read_Able[0]&!Readed[0])?0:
                                    (Read_Able[1]&!Readed[1])?1:
                                        (Read_Able[2]&!Readed[2])?2:
                                            (Read_Able[3]&!Readed[3])?3:
                                                (Read_Able[4]&!Readed[4])?4:
                                                    (Read_Able[5]&!Readed[5])?5:
                                                        (Read_Able[6]&!Readed[6])?6:
                                                            (Read_Able[7]&!Readed[7])?7:
                                                                (Read_Able[8]&!Readed[8])?8:
                                                                    (Read_Able[9]&!Readed[9])?9:
                                                                        (Read_Able[10]&!Readed[10])?10:
                                                                            (Read_Able[11]&!Readed[11])?11:
                                                                                (Read_Able[12]&!Readed[12])?12:
                                                                                    (Read_Able[13]&!Readed[13])?13:
                                                                                        (Read_Able[14]&!Readed[14])?14:
                                                                                            (Read_Able[15]&!Readed[15])?15:0;
    integer Log_File, cycle;
    integer k;
    reg [4:0] Working_ROB;  //ROB_Width+1
    initial begin
        for (k = 0; k < 16; k = k + 1) begin
            Valid[k] = `False;
            Read_Able[k] = `False;
            Readed[k] = `True;
            A[k]=0;
        end
        RN = `False;
        WN = `False;
        Head = 1;
        Tail = 1;
        Wvalue = 0;
        Addr = 0;
        ROB_Ready = `False;
        ROB_Value = 0;
        ROB_Addr = 0;
        ROB_Tag = 0;
        ROB_TO_RS_ready = `False;
        clr = `False;
        Working_ROB = 16;
        `ifdef DEBUG
        Log_File = $fopen("ROB_LOG.txt", "w");
        cycle = 0;
    `endif
    end
    reg [3:0] w;
    `ifdef DEBUG
    always @(posedge clk) begin
        cycle = cycle + 1;
        $fdisplay(Log_File, "Cycle:%d Head:%d Tail:%d Full:%d HasRead:%d Read_Tag:%d", cycle, Head,
                  Tail, success ? 0 : 1,HasRead,Read_Tag);
        for (w = Head; w != Tail; w = w + 1) begin
            $fdisplay(
                Log_File,
                "[%d]Name:%x Rd:%d A:%x Readable:%d Valid:%d Readed:%d PC:%x",
                w, Name[w], Rd[w], A[w], Read_Able[w], Valid[w], Readed[w],
                ROB_PC[w]);
        end
    end
   
    always @(posedge clr) begin
        $fdisplay(Log_File, "Cycle:%d", cycle);
        $fdisplay(Log_File, "Clear Signal Activated; PC:%x ", Clr_PC);
    end
     `endif
    always @(posedge ready) begin
        if (rst) begin
            for (k = 0; k < 16; k = k + 1) begin
                Valid[k] = `False;
                Read_Able[k] = `False;
                Readed[k] = `True;
            end
            Tail = Head;  //Clear
        end else if (ready) begin
            if (Head == Tail + 1) begin
                ROB_TO_RS_ready = `False;
            end else begin
                Rd[Tail] = rd;
                Name[Tail] = name;
                ROB_PC[Tail] = PC;
                Valid[Tail] = `False;
                Read_Able[Tail]=`False;
                case (name)
                    `LB, `LH, `LW, `LBU, `LHU, `LWU, `SB, `SH, `SW: begin
                        Readed[Tail] = `False;
                    end
                    default: begin
                        Readed[Tail] = `True;
                    end
                endcase
                ROB_TO_RS_ready = `True;
                ROB_TO_RS_Tag = Tail;
                Tail = Tail + 1;
            end
        end else begin
            ROB_TO_RS_ready = `False;
        end
    end
    always @(negedge clk) begin//To make sure New Insts always come with a posedge ROB_TO_RS_ready
        ROB_TO_RS_ready = `False;
    end
    //Push
    always @(posedge clr) begin
        for (k = 0; k < 16; k = k + 1) begin
            Valid[k] = `False;
            Read_Able[k] = `False;
            Readed[k] = `True;
        end
        Tail = Head;  //Clear
    end
    always @(posedge clk) begin
        if (rst) begin
        end else if (Valid[Head] && (Head != Tail)) begin
            case (Name[Head])
                `LB, `LH, `LW, `LBU, `LHU, `LWU: begin
                    Read_Able[Head] <= `True;
                    //$display("Rd:%d TAG:%d",Rd[Head],Head);
                    if (Readed[Head]) begin
                        ROB_Ready <= `True;
                        ROB_Addr <= Rd[Head][4:0];
                        ROB_Tag <= Head;
                        ROB_Value <= A[Head];
                        Valid[Head] <= `False;
                        Head <= Head + 1;
                    end
                end
                `SB, `SH, `SW: begin
                    if(Readed[Head])begin
                        Head<=Head+1;
                    end
                end
                `BEQ, `BNE, `BLT, `BGE, `BLTU, `BGEU: begin
                    //$display("[Comm]:%d",cycle);
                    if (A[Head][0] ^ Rd[Head][0]) begin
                        clr <= `True;
                        if (A[Head][0]) begin
                            Clr_PC <= {15'b0, A[Head][16:2], 2'b0};
                        end else begin
                            Clr_PC <= {15'b0, Rd[Head][16:2], 2'b0};
                        end
                    end else begin
                        ROB_Ready <= `False;
                        ROB_Addr <= `Empty;
                        ROB_Tag <= Head;
                        Head <= Head + 1;
                    end
                    Valid[Head] <= `False;
                end
                `JALR: begin
                    clr <= `True;
                    Clr_PC <= {15'b0, A[Head][16:2], 2'b0};
                    ROB_Ready <= `True;
                    ROB_Addr <= Rd[Head][4:0];
                    ROB_Tag <= Head;
                    ROB_Value <= ROB_PC[Head];
                    Valid[Head] <= `False;
                end
                `JAL: begin
                    ROB_Ready <= `True;
                    ROB_Value <= ROB_PC[Head];
                    ROB_Addr <= Rd[Head][4:0];
                    ROB_Tag <= Head;
                    Head <= Head + 1;
                    Valid[Head] <= `False;
                end
                default: begin
                    ROB_Ready <= `True;
                    ROB_Value <= A[Head];
                    ROB_Addr <= Rd[Head][4:0];
                    ROB_Tag <= Head;
                    Head <= Head + 1;
                    Valid[Head] <= `False;
                end
            endcase
        end else begin
            ROB_Ready <= `False;
        end
    end
    always @(negedge clk) begin  //Make sure A posedge Always happens
        ROB_Ready <= `False;
    end
    always @(posedge clk) begin  //Make Sure Clr always last for only one cycle
        if (clr) begin
            clr <= `False;
        end
    end
    always @(posedge Mem_Success) begin
        /*Read Result*/
        if (Working_ROB != 16) begin
            Readed[Working_ROB[3:0]] = `True;
            case (Name[Working_ROB[3:0]])
                `LB, `LH,`LW : begin
                    A[Working_ROB[3:0]] = $signed(Read_Value);
                end
                 `LBU, `LHU, `LWU:begin
                    A[Working_ROB[3:0]] =Read_Value;
                 end
            endcase
        end
    end
    always @(posedge clk) begin
        if (rst) begin

        end else begin
            if (Mem_Success) begin
                /*Send New Inst*/
                if(Valid[Head]&&(Head!=Tail)&&(!Readed[Head])&&(Name[Head]==`SB||Name[Head]==`SW||Name[Head]==`SH))begin
                    WN <= `True;
                    RN <= `False;
                    Wvalue <= A[Head];
                    Addr <= Rd[Head];
                    Inst_Name <= Name[Head];
                    Working_ROB <= {1'b0, Head};
                end else if (HasRead) begin
                    WN <= `False;
                    RN <= `True;
                    Addr <= A[Read_Tag];
                    Inst_Name <= Name[Head];
                    Working_ROB <= {1'b0, Read_Tag};
                end else begin
                    WN <= `False;
                    RN <= `False;
                    Working_ROB <= 16;
                end
            end
        end
    end

    //Issue from RS
    always @(posedge clk) begin
        if (rst) begin
        end else if (RS_Ready) begin
            //assert occupied[RS_Tag] to be true here
            A[RS_Tag] <= RS_A;
            Valid[RS_Tag] <= `True;
            Rd[RS_Tag] <= RS_Rd;
            //$display("[CCC]:%d %d  %x",cycle,RS_Tag,RS_Rd);

        end
    end
    always @(negedge clk) begin  //Overclock
        if (rst) begin

        end else if (RS_Ready) begin
            case (Name[RS_Tag])
                `LB, `LH, `LW, `LBU, `LHU, `LWU: begin
                    //Read_Able[RS_Tag] = (RS_A != 32'h30000);
                    Read_Able[RS_Tag] = `False;
                    for (w = Head; w != RS_Tag; w = w + 1) begin
                        case (Name[w])
                            `SB, `SH, `SW: begin
                                Read_Able[RS_Tag]=Read_Able[RS_Tag]&Valid[w]&(A[w]==RS_A);
                            end
                        endcase
                    end
                end
            endcase
        end
    end
endmodule
