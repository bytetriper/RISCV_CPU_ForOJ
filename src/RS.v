`include "constants.v"
module RS (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    //Exposed
    input wire clr,
    //From Proccessor

    input wire ready,
    input wire [`Data_Bus] rd,
    input wire [`Data_Bus] vj,
    input wire [`Data_Bus] vk,
    input wire [`Data_Bus] qj,
    input wire [`Data_Bus] qk,
    input wire [16:0] name,
    input wire [`Data_Bus] Imm,
    input wire [`ROB_Width] tag,  //position in ROB


    //To ROB
    output reg ROB_Ready,  //log(RS_Size)=log(16)=4
    output reg [`ROB_Width] ROB_Addr,
    output reg [`Data_Bus] ROB_A,
    output reg [`Data_Bus] ROB_Rd,  //SP:For Load And Store
    //From ROB
    input wire [`ROB_Size] ROB_Valid,
    input wire [511:0] ROB_Value,  //32*ROB_Size-1:0
    //TO ALU
    output reg ALU_ready,
    input wire ALU_success,
    output reg [`Data_Bus] LV,
    output reg [`Data_Bus] RV,
    output reg[3:0]  Op,//Look Into "Constants.v" to see the definition of Operations
    input wire [`Data_Bus] result,

    //TO Predictor
    output reg Train_Ready,
    output reg Train_Result,
    output reg [31:0] Train_PC

);
    reg [`Data_Bus] Vj[`RS_Size];
    reg [`Data_Bus] Vk[`RS_Size];
    reg [`Data_Bus] Qj[`RS_Size];
    reg [`Data_Bus] Qk[`RS_Size];
    reg [`Data_Bus] A[`RS_Size];
    reg [16:0] Name[`RS_Size];
    reg [`ROB_Width] Tag[`RS_Size];
    reg [`Data_Bus] Rd[`RS_Size];
    wire [`Data_Bus] Tmp_Value[`ROB_Size];
    reg Busy[`RS_Size];
    reg Valid[`RS_Size];
    genvar i;
    integer j;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign Tmp_Value[i] = ROB_Value[(i<<5)+31:i<<5];
        end
    endgenerate
    initial begin
        for (j = 0; j < 32; j = j + 1) begin
            Busy[j]  = `False;
            Valid[j] = `False;
        end
        Train_Ready = `False;
        ALU_ready = `False;
        ROB_Ready = `False;
        LV = 0;
        RV = 0;
        Op = `Add;
    end
    integer Log_File;
    integer clkcycle;
    `ifdef DEBUG
    initial begin
        Log_File = $fopen("RS_LOG.txt", "w");
        clkcycle = 0;
    end
    `endif
    reg [`RS_Width] Working_RS;
    wire HasFree;
    wire HasValid;
    wire [16:0] Name_RS_TEST = Name[Working_RS];
    wire [`RS_Width] valid_tag, free_tag;
    assign free_tag =  ~Busy[0]?0:
                            ~Busy[1]?1:
                                ~Busy[2]?2:
                                    ~Busy[3]?3:
                                        ~Busy[4]?4:
                                            ~Busy[5]?5:
                                                ~Busy[6]?6:
                                                    ~Busy[7]?7:
                                                        ~Busy[8]?8:
                                                            ~Busy[9]?9:
                                                                ~Busy[10]?10:
                                                                    ~Busy[11]?11:
                                                                        ~Busy[12]?12:
                                                                            ~Busy[13]?13:
                                                                                ~Busy[14]?14:
                                                                                    ~Busy[15]?15:
                                                                                        ~Busy[16]?16:
                                                                                            ~Busy[17]?17:
                                                                                                ~Busy[18]?18:
                                                                                                    ~Busy[19]?19:
                                                                                                        ~Busy[20]?20:
                                                                                                            ~Busy[21]?21:
                                                                                                                ~Busy[22]?22:
                                                                                                                    ~Busy[23]?23:
                                                                                                                        ~Busy[24]?24:
                                                                                                                            ~Busy[25]?25:
                                                                                                                                ~Busy[26]?26:
                                                                                                                                    ~Busy[27]?27:
                                                                                                                                        ~Busy[28]?28:
                                                                                                                                            ~Busy[29]?29:
                                                                                                                                                ~Busy[30]?30:
                                                                                                                                                    ~Busy[31]?31:0;
    assign valid_tag=  (Valid[0]&Busy[0])?0:
                            (Valid[1]&Busy[1])?1:
                                (Valid[2]&Busy[2])?2:
                                    (Valid[3]&Busy[3])?3:
                                        (Valid[4]&Busy[4])?4:
                                            (Valid[5]&Busy[5])?5:
                                                (Valid[6]&Busy[6])?6:
                                                    (Valid[7]&Busy[7])?7:
                                                        (Valid[8]&Busy[8])?8:
                                                            (Valid[9]&Busy[9])?9:
                                                                (Valid[10]&Busy[10])?10:
                                                                    (Valid[11]&Busy[11])?11:
                                                                        (Valid[12]&Busy[12])?12:
                                                                            (Valid[13]&Busy[13])?13:
                                                                                (Valid[14]&Busy[14])?14:
                                                                                    (Valid[15]&Busy[15])?15:
                                                                                        (Valid[16]&Busy[16])?16:
                                                                                            (Valid[17]&Busy[17])?17:
                                                                                                (Valid[18]&Busy[18])?18:
                                                                                                    (Valid[19]&Busy[19])?19:
                                                                                                        (Valid[20]&Busy[20])?20:
                                                                                                            (Valid[21]&Busy[21])?21:
                                                                                                                (Valid[22]&Busy[22])?22:
                                                                                                                    (Valid[23]&Busy[23])?23:
                                                                                                                        (Valid[24]&Busy[24])?24:
                                                                                                                            (Valid[25]&Busy[25])?25:
                                                                                                                                (Valid[26]&Busy[26])?26:
                                                                                                                                    (Valid[27]&Busy[27])?27:
                                                                                                                                        (Valid[28]&Busy[28])?28:
                                                                                                                                            (Valid[29]&Busy[29])?29:
                                                                                                                                                (Valid[30]&Busy[30])?30:
                                                                                                                                                    (Valid[31]&Busy[31])?31:0;
    assign HasFree=1^(Busy[0]
                        &Busy[1]
                            &Busy[2]
                                &Busy[3]
                                    &Busy[4]
                                        &Busy[5]
                                            &Busy[6]
                                                &Busy[7]
                                                    &Busy[8]
                                                        &Busy[9]
                                                            &Busy[10]
                                                                &Busy[11]
                                                                    &Busy[12]
                                                                        &Busy[13]
                                                                            &Busy[14]
                                                                                &Busy[15]
                                                                                    &Busy[16]
                                                                                        &Busy[17]
                                                                                            &Busy[18]
                                                                                                &Busy[19]
                                                                                                    &Busy[20]
                                                                                                        &Busy[21]
                                                                                                            &Busy[22]
                                                                                                                &Busy[23]
                                                                                                                    &Busy[24]
                                                                                                                        &Busy[25]
                                                                                                                            &Busy[26]
                                                                                                                                &Busy[27]
                                                                                                                                    &Busy[28]
                                                                                                                                        &Busy[29]
                                                                                                                                            &Busy[30]
                                                                                                                                                &Busy[31]);
    assign HasValid=(Valid[0]&Busy[0])
                        |(Valid[1]&Busy[1])
                            |(Valid[2]&Busy[2])
                                |(Valid[3]&Busy[3])
                                    |(Valid[4]&Busy[4])
                                        |(Valid[5]&Busy[5])
                                            |(Valid[6]&Busy[6])
                                                |(Valid[7]&Busy[7])
                                                    |(Valid[8]&Busy[8])
                                                        |(Valid[9]&Busy[9])
                                                            |(Valid[10]&Busy[10])
                                                                |(Valid[11]&Busy[11])
                                                                    |(Valid[12]&Busy[12])
                                                                        |(Valid[13]&Busy[13])
                                                                            |(Valid[14]&Busy[14])
                                                                                |(Valid[15]&Busy[15])
                                                                                    |(Valid[16]&Busy[16])
                                                                                        |(Valid[17]&Busy[17])
                                                                                            |(Valid[18]&Busy[18])
                                                                                                |(Valid[19]&Busy[19])
                                                                                                    |(Valid[20]&Busy[20])
                                                                                                        |(Valid[21]&Busy[21])
                                                                                                            |(Valid[22]&Busy[22])
                                                                                                                |(Valid[23]&Busy[23])
                                                                                                                    |(Valid[24]&Busy[24])
                                                                                                                        |(Valid[25]&Busy[25])
                                                                                                                            |(Valid[26]&Busy[26])
                                                                                                                                |(Valid[27]&Busy[27])
                                                                                                                                    |(Valid[28]&Busy[28])
                                                                                                                                        |(Valid[29]&Busy[29])
                                                                                                                                            |(Valid[30]&Busy[30])
                            
    `ifdef DEBUG                                                                                                                    |(Valid[31]&Busy[31]);
    always @(posedge clk) begin
        clkcycle <= clkcycle + 1;
        $fdisplay(Log_File, "Cycle:%d", clkcycle);
        for (j = 0; j < 32; j++) begin
            if (Busy[j]) begin
                $fdisplay(
                    Log_File,
                    "[%d]Valid:%d,Name:%x,Tag:%d,qj:%d,qk:%d,vj:0x%x,vk:0x%x rd:%d A:0x%x",
                    j, Valid[j], Name[j], Tag[j], Qj[j], Qk[j], Vj[j], Vk[j],
                    Rd[j], A[j]);
            end
        end
    end
    `endif;
    
    always @(posedge clk) begin
        if (rst) begin
            for (j = 0; j < 32; j = j + 1) begin
                Busy[j]  <= `False;
                Valid[j] <= `False;
            end
            Train_Ready <= `False;
            ALU_ready <= `False;
            ROB_Ready <= `False;
            LV <= 0;
            RV <= 0;
            Op <= `Add;
        end
        if (clr) begin
            for (j = 0; j < 32; j = j + 1) begin
                Busy[j]  <= `False;
                Valid[j] <= `False;
            end
            Train_Ready <= `False;
            ALU_ready <= `False;
            ROB_Ready <= `False;
            LV <= 0;
            RV <= 0;
            Op <= `Add;
        end else if (HasValid) begin
            Working_RS <= valid_tag;
            ALU_ready <= `True;
            Valid[valid_tag] <= `False;  //Already Calculated
            case (Name[valid_tag])
                `LB, `LH, `LW, `LBU, `LHU, `LWU, `SB, `SH, `SW: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Add;
                    //A[IsValid]<=A[IsValid]+Vj[IsValid];
                end
                `LUI: begin                    
                    LV <= 0;
                    RV <= A[valid_tag];
                    Op <= `Add;
                end
                `ADD: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `Add;
                end
                `ADDI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Add;
                end
                `AND: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `And;
                    //A[IsValid]<=Vj[IsValid]&Vk[IsValid];
                end
                `ANDI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `And;
                    //A[IsValid]<=Vj[IsValid]&A[IsValid];
                end
                `AUIPC: begin
                    LV <= Vj[valid_tag];
                    RV <= {A[valid_tag][31:12], 12'b0};
                    Op <= `Add;
                    //A[IsValid]<=Vj[IsValid]+{A[IsValid][31:12], 12'b0};
                end
                `BEQ: begin//SP for jumps,A[0] indicates the prediction 1:jump 0:not
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `Equal;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BGE: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `GEQ_S;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BGEU: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `GEQ;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BLT: begin
                    LV <= $signed(Vj[valid_tag]);
                    RV <= $signed(Vk[valid_tag]);
                    Op <= `Less_S;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BLTU: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `Less;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `BNE: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `NotEqual;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `JAL: begin
                    LV <= Vk[valid_tag];
                    RV <= {A[valid_tag][31:1], 1'b0};
                    Op <= `Add;
                    //A[IsValid]<=Rd[IsValid]+{A[IsValid][31:1], 1'b0};
                end
                `JALR: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Add;
                    //A[IsValid]<=Rd[IsValid]+A[IsValid];
                end
                `OR: begin
                    LV <=Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `Or;
                    //A[IsValid]<=Vj[IsValid]|Vk[IsValid];
                end
                `ORI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Or;
                    //A[IsValid]<=Vj[IsValid]|A[IsValid];
                end
                `SLL: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `LeftShift;
                    //A[IsValid]<=Vj[IsValid]<<Vk[IsValid];
                end
                `SLLI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `LeftShift;
                    //A[IsValid]<=Vj[IsValid]<<A[IsValid];
                end
                `SLT: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `Less_S;
                end
                `SLTI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Less_S;
                end
                `SLTIU: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Less;
                end
                `SLTU: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Less;
                end
                `SRA: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `RightShift_A;
                end
                `SRAI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `RightShift_A;
                end
                `SRL: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `RightShift;
                end
                `SRLI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `RightShift;
                end
                `SUB: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `Minus;
                end
                `XOR: begin
                    LV <= Vj[valid_tag];
                    RV <= Vk[valid_tag];
                    Op <= `Xor;
                end
                `XORI: begin
                    LV <= Vj[valid_tag];
                    RV <= A[valid_tag];
                    Op <= `Xor;
                end
                default:begin
                    $display("[ALU FATAL]:%d",clkcycle);
                end
            endcase
        end else begin
            ALU_ready <= `False;
        end
    end
    always @(posedge clk) begin
        if (rst) begin

        end
        if (clr) begin

        end else if (ALU_success) begin  //COMMIT
            if (Busy[Working_RS]) begin
                Busy[Working_RS]  <= `False;
                Valid[Working_RS] <= `False;
                //Train Predictor
                case (Name[Working_RS])
                    `BEQ, `BNE, `BLT, `BGE, `BLTU, `BGEU: begin
                        Train_Ready  <= `True;
                        Train_Result <= result[0];
                        Train_PC<= Rd[Working_RS]-4;
                    end
                    default: begin
                        Train_Ready <= `False;
                    end
                endcase
                //commit
                case (Name[Working_RS])
                    `LB, `LH, `LW, `LBU, `LHU, `LWU: begin
                        ROB_Ready <= `True;
                        ROB_Addr <= Tag[Working_RS];
                        ROB_A <= result;
                        ROB_Rd <= Rd[Working_RS];
                    end
                    `LUI: begin
                        ROB_Ready <= `True;
                        ROB_Addr <= Tag[Working_RS];
                        ROB_A <= result;
                        ROB_Rd <= Rd[Working_RS];
                    end
                    `SB, `SH, `SW: begin
                        ROB_Ready <= `True;
                        ROB_Addr <= Tag[Working_RS];
                        ROB_A <= Vk[Working_RS];
                        ROB_Rd <= result;
                    end
                    `BEQ, `BNE, `BLT, `BGE, `BLTU, `BGEU: begin
                        ROB_Ready <= `True;
                        ROB_Addr <= Tag[Working_RS];
                        ROB_A <= {A[Working_RS][31:1], result[0]};
                        //$display("[BBB]:%d %x",clkcycle,Rd[Working_RS]);
                        ROB_Rd <= Rd[Working_RS];
                    end
                    `JALR: begin
                        ROB_A <= result;  //SP
                        ROB_Ready <= `True;
                        ROB_Addr <= Tag[Working_RS];
                        ROB_Rd <= Rd[Working_RS];
                    end
                    `JAL: begin
                        ROB_A <= Vk[Working_RS];  //SP
                        ROB_Ready <= `True;
                        ROB_Addr <= Tag[Working_RS];
                        ROB_Rd <= Rd[Working_RS];
                    end
                    default: begin
                        ROB_Ready <= `True;
                        ROB_Addr <= Tag[Working_RS];
                        ROB_A <= result;
                        ROB_Rd <= Rd[Working_RS];
                    end
                endcase
                //Broadcast
            end else begin
                ROB_Ready <= `False;
            end
        end else begin
            ROB_Ready <= `False;
        end
    end
    always @(posedge ready) begin  //Introduce new inst into RS
        if (!HasFree || clr) begin
        end else begin
            Vj[free_tag] = vj;
            Qj[free_tag] = qj;
            Vk[free_tag] = vk;
            Qk[free_tag] = qk;
            A[free_tag] = Imm;
            Rd[free_tag] = rd;
            Tag[free_tag] = tag;
            Name[free_tag] = name;
            $fdisplay(Log_File, "[Pushing Inst]cycle:%d", clkcycle);
            $fdisplay(Log_File, "Name:%x Vj:%x Qj:%d Vk:%x Qk:%d Imm:%x", name,
                      vj, qj, vk, qk, Imm);
            if (qj != `Empty) begin
                if (ROB_Valid[qj]) begin
                    Vj[free_tag] = Tmp_Value[qj];
                    Qj[free_tag] = `Empty;
                end
            end
            if (qk != `Empty) begin
                if (ROB_Valid[qk]) begin
                    Vk[free_tag] = Tmp_Value[qk];
                    Qk[free_tag] = `Empty;
                end
            end
            Valid[free_tag] = `False;
            Busy[free_tag]  = `True;  //LAST indeed
        end
    end

    always @(posedge clk) begin
        if (clr) begin

        end else begin
            for (j = 0; j < 32; j++) begin
                case (Name[j])
                    default: begin
                        if (Qj[j] != `Empty) begin
                            if (ROB_Valid[Qj[j]]) begin
                                Vj[j] = Tmp_Value[Qj[j]];
                                Qj[j] = `Empty;
                            end
                        end
                        if (Qk[j] != `Empty) begin
                            if (ROB_Valid[Qk[j]]) begin
                                Vk[j] = Tmp_Value[Qk[j]];
                                Qk[j] = `Empty;

                            end
                        end
                    end
                endcase
                if (Qj[j] == `Empty & Qk[j] == `Empty) begin
                    Valid[j] = `True;
                end
            end
        end
    end
    //Make Sure clr is mostly false ;TODO CHECK
endmodule
