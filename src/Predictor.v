`include "constants.v"
module Predictor (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //From ROB
    input wire clr,
    input wire [`Data_Bus] Target_PC,

    //From Fetcher
    input wire [`Data_Bus] PC,
    input wire [`Data_Bus] Inst,
    input wire Ready,

    //To Fetcher
    output reg [`Data_Bus] Predict_Jump,
    //To RS
    output reg Predict_Jump_Bool,
    //From RS (Train)
    input wire Train_Ready,
    input wire Train_Result,
    input wire [`Data_Bus] Train_PC
);
    integer Imm, k;
    reg Fixed;
    reg [1:0] BTB[`BTB_Width];  //00:NN 01:N 10:Y 11:YY 

    initial begin
        Predict_Jump = 0;
        Predict_Jump_Bool = `False;
        Fixed = `False;
        for (k = 0; k < 512; k = k + 1) begin
            BTB[k] = 2'b01;
        end
    end
    always @(posedge rst) begin
        Predict_Jump = 0;
        Predict_Jump_Bool = `False;
        Fixed = `False;
        for (k = 0; k < 512; k = k + 1) begin
            BTB[k] = 2'b01;
        end
    end
    always @(posedge clr) begin
        if (Target_PC != PC) begin
            Fixed = `True;
            Predict_Jump = Target_PC;
        end
    end
    reg tmp = 0;
    always @(posedge Ready) begin
        if (Fixed && PC != Predict_Jump) begin
        end else begin
            case (Inst[6:0])
                `SB_ALL: begin
                    Imm = {
                        {19{Inst[31]}},
                        Inst[31],
                        Inst[7],
                        Inst[30:25],
                        Inst[11:9],
                        2'b0
                    };
                    if (BTB[PC[10:2]][1]) begin
                        //if (0) begin
                        Predict_Jump = Imm + PC;
                        Predict_Jump = {15'b0, Predict_Jump[16:0]};
                        Predict_Jump_Bool = `True;
                    end else begin
                        Predict_Jump = PC + 4;
                        Predict_Jump = {15'b0, Predict_Jump[16:0]};
                        Predict_Jump_Bool = `False;
                    end
                    tmp = tmp ^ 1;
                end
                `UJ_JAL: begin
                    Imm = {
                        {11{Inst[31]}},
                        Inst[31],
                        Inst[19:12],
                        Inst[20],
                        Inst[30:22],
                        2'b0
                    };
                    //$display("UJJAL:%x,Imm:%x", Inst, Imm);
                    Predict_Jump = PC + Imm;
                    Predict_Jump = {15'b0, Predict_Jump[16:0]};
                    Predict_Jump_Bool = `True;
                end
                default: begin
                    Predict_Jump = PC + 4;
                    Predict_Jump = {15'b0, Predict_Jump[16:0]};
                    Predict_Jump_Bool = `False;
                end
            endcase
        end
        Fixed = `False;
    end
    always @(posedge clk) begin
        if (rst) begin

        end else if (Train_Ready) begin
            if (Train_Result) begin
                case (BTB[Train_PC[10:2]])  //ADD is not a good behaviour
                    2'b00: begin
                        BTB[Train_PC[10:2]] <= 2'b01;
                    end
                    2'b01: begin
                        BTB[Train_PC[10:2]] <= 2'b10;
                    end
                    2'b10: begin
                        BTB[Train_PC[10:2]] <= 2'b11;
                    end
                    2'b11: begin
                        BTB[Train_PC[10:2]] <= 2'b11;
                    end
                endcase
            end else begin
                case (BTB[Train_PC[10:2]])
                    2'b00: begin
                        BTB[Train_PC[10:2]] <= 2'b00;
                    end
                    2'b01: begin
                        BTB[Train_PC[10:2]] <= 2'b00;
                    end
                    2'b10: begin
                        BTB[Train_PC[10:2]] <= 2'b01;
                    end
                    2'b11: begin
                        BTB[Train_PC[10:2]] <= 2'b10;
                    end
                endcase
            end
        end
    end
endmodule
