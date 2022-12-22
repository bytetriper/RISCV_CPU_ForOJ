`include "constants.v"
module Processor (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //From Fetcher
    input wire [31:0] PC,
    input wire [31:0] Inst,
    input wire Inst_Ready,

    //To Fetcher
    output wire received,

    //From Flow Controler
    input wire clr,

    //To ROB(then RS)
    output reg ready,
    output reg [`Data_Bus] rd,
    output reg [`Data_Bus] vj,
    output reg [`Data_Bus] vk,
    output reg [`Data_Bus] qj,
    output reg [`Data_Bus] qk,
    output reg [16:0] name,
    output reg [`Data_Bus] Imm,
    //From ROB
    input wire success,
    //From ROB
    input wire ROB_Ready,
    input wire [`Data_Bus] ROB_Value,
    input wire [`Register_Width] ROB_Addr,
    input wire[`ROB_Width] ROB_Tag,//nesscary when deciding whether to remove Tags[Rob_addr]

    input wire [`ROB_Width] ROB_Tail,
    //From Predictor
    input wire Predict_Jump_Bool
);
    reg [31:0] REGISTER[`Reg_Size];
    reg [31:0] Tags[`Reg_Size];
    assign received = success;
    integer Out_File, Log, Log_Register;
    integer cycle;
    initial begin
        `ifdef DEBUG
        Out_File = $fopen("Error.txt", "w");
        Log = $fopen("Log_Processor.txt", "w");
        Log_Register = $fopen("Register_Log.txt", "w");
        cycle = 0;
        `endif
    end
    integer k;
    initial begin
        ready = `False;
        for (k = 0; k < 32; k = k + 1) begin
            REGISTER[k] = 0;
            Tags[k] = `Empty;
        end
    end
    `ifdef DEBUG
    always @(posedge clk) begin
        cycle <= cycle + 1;
        $fdisplay(Log_Register, "Cycle:%d", cycle);
        for (k = 0; k < 32; k = k + 1) begin
            $fwrite(Log_Register, "%4d ", k);
        end
        $fdisplay(Log_Register, "\n");
        for (k = 0; k < 32; k = k + 1) begin
            $fwrite(Log_Register, "%4d ", REGISTER[k]);
        end
        $fdisplay(Log_Register, "\n");
        for (k = 0; k < 32; k = k + 1) begin
            $fwrite(Log_Register, "%4d ", Tags[k]);
        end
        $fdisplay(Log_Register, "\n");

    end
    `endif
    always @(negedge clk) begin
        ready = `False;
    end
    always @(posedge Inst_Ready) begin
        if (rst) begin
        end else if (clr) begin
            //DO something maybe?
        end else if (Inst_Ready & success) begin
            //Decode:Opcode Inst[6:0]
            case (Inst[6:0])
                `I_LOAD: begin
                    rd = {27'b0, Inst[11:7]};
                    if (Tags[Inst[19:15]] != `Empty) begin
                        qj = Tags[Inst[19:15]];
                    end else begin
                        vj = REGISTER[Inst[19:15]];
                        qj = `Empty;
                    end
                    if (rd != 0) begin
                        Tags[rd] = {28'b0, ROB_Tail};
                    end
                    qk = `Empty;
                    Imm = {{20{Inst[31]}}, Inst[31:20]};
                    //Imm= $signed (Imm) ;
                    //name = (`I_LOAD << 10) | (Inst[14:12] << 7);
                    name = {`I_LOAD, Inst[14:12], 7'b0};
                    ready = `True;
                end
                `I_BINARY: begin
                    rd = {27'b0, Inst[11:7]};

                    if (Tags[Inst[19:15]] != `Empty) begin
                        qj = Tags[Inst[19:15]];
                    end else begin
                        vj = REGISTER[Inst[19:15]];
                        qj = `Empty;
                    end
                    if (rd != 0) begin
                        Tags[rd] = {28'b0, ROB_Tail};
                    end
                    qk = `Empty;
                    Imm = {{20{Inst[31]}}, Inst[31:20]};
                    name = {`I_BINARY, Inst[14:12], 7'b0};
                    ready = `True;
                end
                `U_AUIPC: begin
                    rd = {27'b0, Inst[11:7]};
                    if (rd != 0) begin
                        Tags[rd] = {28'b0, ROB_Tail};
                    end
                    Imm = {Inst[31:12], 12'b0};
                    vj = PC;
                    qk = `Empty;
                    qj = `Empty;
                    name = `AUIPC;
                    ready = `True;
                end
                `U_LUI: begin
                    rd = {27'b0, Inst[11:7]};
                    if (rd != 0) begin
                        Tags[rd] = {28'b0, ROB_Tail};
                    end
                    Imm = {Inst[31:12], 12'b0};
                    qk = `Empty;
                    qj = `Empty;
                    name = `LUI;
                    ready = `True;
                end
                `S_SAVE: begin
                    if (Tags[Inst[19:15]] != `Empty) begin
                        qj = Tags[Inst[19:15]];
                    end else begin
                        vj = REGISTER[Inst[19:15]];
                        qj = `Empty;
                    end
                    if (Tags[Inst[24:20]] != `Empty) begin
                        qk = Tags[Inst[24:20]];
                    end else begin
                        vk = REGISTER[Inst[24:20]];
                        qk = `Empty;
                    end
                    /*
                    Imm[11:5] = Inst[31:25];
                    Imm[4:0] = Inst[11:7];*/
                    Imm   = {{20{Inst[31]}}, Inst[31:25], Inst[11:7]};
                    name  = {`S_SAVE, Inst[14:12], 7'b0};
                    ready = `True;
                end
                `R_PRIMARY: begin
                    rd  = {27'b0, Inst[11:7]};
                    Imm = 0;
                    if (Tags[Inst[19:15]] != `Empty) begin
                        qj = Tags[Inst[19:15]];
                    end else begin
                        vj = REGISTER[Inst[19:15]];
                        qj = `Empty;
                    end
                    if (Tags[Inst[24:20]] != `Empty) begin
                        qk = Tags[Inst[24:20]];
                    end else begin
                        vk = REGISTER[Inst[24:20]];
                        qk = `Empty;
                    end
                    if (rd != 0) begin
                        Tags[rd] = {28'b0, ROB_Tail};
                    end
                    name  = {`R_PRIMARY, Inst[14:12], Inst[31:25]};
                    ready = `True;
                end
                `SB_ALL: begin
                    /*
                    Imm[11]   = Inst[7];
                    Imm[4:1]  = Inst[11:8];
                    Imm[12]   = Inst[31];
                    Imm[10:5] = Inst[30:25];
                    */
                    Imm = {
                        {19{Inst[31]}}, Inst[31], Inst[7], Inst[30:25], Inst[11:9], 2'b0
                    };
                    if (Tags[Inst[19:15]] != `Empty) begin
                        qj = Tags[Inst[19:15]];
                    end else begin
                        vj = REGISTER[Inst[19:15]];
                        qj = `Empty;
                    end
                    if (Tags[Inst[24:20]] != `Empty) begin
                        qk = Tags[Inst[24:20]];
                    end else begin
                        vk = REGISTER[Inst[24:20]];
                        qk = `Empty;
                    end
                    rd = {PC[31:1], Predict_Jump_Bool}+4;
                    Imm = PC+Imm;
                    //$display("ASDDD:%x",PC);
                    name  = {`SB_ALL, Inst[14:12], 7'b0};
                    ready = `True;
                end
                `I_JALR: begin
                    rd = {27'b0, Inst[11:7]};

                    if (Tags[Inst[19:15]] != `Empty) begin
                        qj = Tags[Inst[19:15]];
                    end else begin
                        vj = REGISTER[Inst[19:15]];
                        qj = `Empty;
                    end
                    if (rd != 0) begin
                        Tags[rd] = {28'b0, ROB_Tail};
                    end
                    vk = PC + 4;
                    qk = `Empty;
                    //Imm[11:0] = Inst[31:20];
                    Imm = {{20{Inst[31]}}, Inst[31:22],2'b0};
                    name = `JALR;
                    ready = `True;
                end
                `UJ_JAL: begin
                    rd = {27'b0, Inst[11:7]};
                    if (rd != 0) begin
                        Tags[rd] = {28'b0, ROB_Tail};
                    end
                    vk = PC + 4;  //risky
                    qj = `Empty;
                    qk = `Empty;
                    /*
                    Imm[20] = Inst[31];
                    Imm[10:1] = Inst[30:21];
                    Imm[11] = Inst[20];
                    Imm[19:12] = Inst[19:12];
                    */
                    Imm = {
                        {11{Inst[31]}},
                        Inst[31],
                        Inst[19:12],
                        Inst[20],
                        Inst[30:22],
                        2'b0
                    };
                    name = `JAL;
                    ready = `True;
                end

                default: begin
                    ready = `False;
                    `ifdef DEBUG
                    $fdisplay(Out_File, "[Fatal Error] %x", Inst);
                    `endif
                end
            endcase
        end else begin
            if (Inst_Ready) ready = `False;
        end
    end
    always @(posedge ROB_Ready) begin  //Update value
        if (rst) begin

        end else if (ROB_Ready) begin
            if (Tags[ROB_Addr][3:0] == ROB_Tag) begin
                Tags[ROB_Addr] = `Empty;
            end
            if(ROB_Addr!=0)begin
                REGISTER[ROB_Addr] = ROB_Value;
            end
        end
    end

    //Must put under ROB_Ready Block
    always @(posedge clr) begin
        for (k = 0; k < 32; k = k + 1) begin
            Tags[k] = `Empty;
        end
    end
endmodule
