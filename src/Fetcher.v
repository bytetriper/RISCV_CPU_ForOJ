`include "constants.v"
module Fetcher (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    input wire [`Data_Bus] Predict_Jump,  //jump or +4

    //From Flow Controler
    input wire clr,
    input wire [`Data_Bus] Clr_PC,
    //To ICache
    output reg [`Data_Bus] addr,  //only 17:0 is used
    output reg rn,  //read_enabled


    //From ICache
    input wire [`Data_Bus] Inst,
    input wire Read_ready,

    //To Processor
    output reg [`Data_Bus] CurrentInst,
    output reg ready,

    //From Processor
    input wire success,
    //Exposed
    output reg [`Data_Bus] Out_PC
);
    reg [`Data_Bus] PC,Previous_Clr_PC;
    reg [`Data_Bus] Inst_Buffer;
    reg Fixed;
    integer Stuck,Stuck_Log;
    initial begin
        ready = `False;
        rn = `False;
        PC = 32'b0;
        Previous_Clr_PC={1'b1,31'b0};//To Avoid Collision
        Inst_Buffer = 32'b0;
        Fixed = `False;
        Stuck=0;
        `ifdef DEBUG
        Stuck_Log=$fopen("Stuck.txt","w");
    `endif
    end
    always @(negedge clk) begin
        ready <= `False;
    end
    always @(posedge clk) begin
        if (rst) begin

        end else if (clr) begin
            if (Read_ready) begin  //ROB must be empty(so success=1) now
                if (PC == Clr_PC) begin  //issue like normal
                    rn <= `True;
                    addr <= Predict_Jump;
                    ready <= `True;
                    CurrentInst <= Inst;
                    Out_PC <= PC;
                    PC <= Predict_Jump;
                end else begin //Skip the current Inst, and jump to Clr_PC(Predict_Jump)
                    rn   <= `True;
                    addr <= Predict_Jump;
                    PC <=Predict_Jump;
                end
                Previous_Clr_PC<={1'b1,31'b0};//To Avoid Collision
                Fixed<=`False;
            end else begin//Save Until Next Inst Comes
                Fixed <= `True;
                Previous_Clr_PC<=Clr_PC;
            end
        end else if (Read_ready) begin
            if (success) begin
                if (Fixed&&Previous_Clr_PC!=PC) begin
                end else begin
                    ready <= `True;
                    CurrentInst <= Inst;
                end
                rn   <= `True;
                addr <= Predict_Jump;
                Fixed <= `False;
                Previous_Clr_PC<={1'b1,31'b0};
                PC <= Predict_Jump;
                Out_PC <= PC;
            end else begin
                rn <= `False;
                `ifdef DEBUG
                Stuck<=Stuck+1;
                $fwrite(Stuck_Log,"%d ",Stuck);
                `endif
            end
        end else begin

        end
    end
endmodule
