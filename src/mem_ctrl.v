`include "constants.v"
module mem_ctrl (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    output reg  [ `Mem_Bus] mem_din,   // data input bus
    input  wire [ `Mem_Bus] mem_dout,  // data output bus
    output reg  [`Data_Bus] mem_a,     // address bus (only 17:0 is used)
    output reg              mem_wr,    // write/read signal (1 for write)

    //For ICache

    input  wire             IC_rn,     //read_enable(read only)
    input  wire [`Data_Bus] IC_addr,
    output reg              IC_ready,
    output reg  [`Data_Bus] IC_value,


    //For LSB
    input  wire             LSB_rn,      //read_enable
    input  wire             LSB_wn,      //Write_enable
    input  wire [`Data_Bus] LSB_Wvalue,
    input  wire [`Data_Bus] LSB_addr,
    input  wire [     16:0] Inst_Name,
    output reg              LSB_ready,
    output reg  [`Data_Bus] LSB_value
);
    localparam OffWork = 0, IC = 1, LSB_r = 2, LSB_w = 3;
    integer Reading = OffWork;
    integer BeZero = 1;
    reg startable = `True;  //is mem_ctrl occupied or not
    integer boss;  //the one who in process of reading(2-->LSB_Write 1 --> IC,0--> LSB)
    integer PreviousBoss;
    reg [`Data_Bus] data;
    reg [`Data_Bus] TmpAddr;
    integer Log_File, cycle;
    integer ICRead, LSBWrite, LSBRead, Spare;
    initial begin
        data = 0;
        TmpAddr = 0;
        IC_ready = `True;
        IC_value = 0;
        mem_a = 0;
        mem_wr = 0;
        LSB_ready = `True;
        LSB_value = 0;
        boss = OffWork;
        `ifdef DEBUG
        Log_File = $fopen("Mem_Ctrl_Log", "w");
        `endif 
        cycle = 0;
        PreviousBoss = 0;
        ICRead = 0;
        LSBWrite = 0;
        LSBRead = 0;
        Spare = 0;
        
    end
    `ifdef DEBUG
    always @(posedge clk) begin
        cycle <= cycle + 1;
        $fdisplay(Log_File, "Cycle:%d", cycle);
        case (boss)
            OffWork: begin
                $fdisplay(Log_File, "State:Offwork");
            end
            IC: begin
                $fdisplay(Log_File, "State:IC_Reading");
            end
            LSB_w: begin
                $fdisplay(Log_File, "State:LSB_Writing");
            end
            LSB_r: begin
                $fdisplay(Log_File, "State:LSB_Reading");
            end
        endcase
    end
    `endif
    always @(Reading) begin
        if (Reading == 0) begin  //indicating Reading 5 -> 0
            case (boss)
                IC: begin
                    IC_ready = `True;
                end
                LSB_r, LSB_w: begin
                    LSB_ready = `True;
                end
            endcase
            boss = OffWork;
        end

    end
    always @(posedge clk) begin
        if (boss == OffWork) begin
            Spare = Spare + 1;
        end
        if(boss ==IC)begin
            ICRead=ICRead+1;

        end
        if(boss==LSB_w)begin
            LSBWrite=LSBWrite+1;
        end
        if(boss==LSB_r)begin
            LSBRead=LSBRead+1;
        end
    end
    always @(negedge clk) begin
        if (boss == OffWork) begin
            if (LSB_wn&&(PreviousBoss!=LSB_w)) begin//Make Sure ROB has enough time to react
                boss = LSB_w;
            end else if (LSB_rn&&(PreviousBoss!=LSB_r)) begin//Make Sure ROB has enough time to react
                boss = LSB_r;
            end else if (IC_rn) begin
                boss = IC;
            end
        end
        PreviousBoss = boss;
    end
    always @(IC_addr) begin
        if (IC_rn) begin
            IC_ready = `False;
        end
    end
    always @(LSB_addr, LSB_wn, LSB_rn) begin
        if (LSB_rn) begin
            LSB_ready = `False;
        end
        if (LSB_wn) begin
            LSB_ready = `False;
            `ifdef DEBUG
            if (LSB_addr == 32'h30004) begin  //End
                $display("");
                $display("End:%d", cycle);
                $display("ICRead Time:%d LSBRead Time:%d LSBWrite Time:%d Spare Time:%d",ICRead,LSBRead,LSBWrite,Spare);
            end
            `endif 
        end
    end
    always @(posedge clk) begin
        if (rst) begin  //Reset EveryThing!

        end else if (boss == 1) begin
            case (Reading)
                0: begin
                    mem_a <= IC_addr;
                    mem_wr <= `LOW;
                    TmpAddr <= IC_addr + 1;
                    Reading <= Reading + 1;
                    data <= 0;
                end
                1: begin
                    mem_a   <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                2: begin
                    data[7:0] <= mem_dout;
                    mem_a <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                3: begin
                    data[15:8] <= mem_dout;
                    mem_a <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                4: begin
                    data[23:16] <= mem_dout;
                    Reading <= Reading + 1;

                end
                5: begin
                    data[31:24] <= mem_dout;
                    IC_value <= {mem_dout, data[23:0]};
                    Reading <= 0;
                end

            endcase
        end else if (boss == LSB_r) begin
            case (Reading)
                0: begin
                    mem_a <= LSB_addr;
                    mem_wr <= `LOW;
                    Reading <= Reading + 1;
                    TmpAddr <= LSB_addr + 1;
                    data <= 0;
                end
                1: begin
                    if (Inst_Name != `LB && Inst_Name != `LBU) begin
                        mem_a <= TmpAddr;
                    end
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;

                end
                2: begin
                    data[7:0] <= mem_dout;
                    if (Inst_Name != `LB && Inst_Name != `LBU) begin
                        if (Inst_Name != `LH && Inst_Name != `LHU) begin
                            mem_a <= TmpAddr;
                        end
                        TmpAddr <= TmpAddr + 1;
                        Reading <= Reading + 1;
                    end else begin
                        Reading   <= 0;
                        LSB_value <= {24'b0, mem_dout};
                    end

                end
                3: begin
                    data[15:8] <= mem_dout;
                    if (Inst_Name != `LH && Inst_Name != `LHU) begin
                        mem_a   <= TmpAddr;
                        TmpAddr <= TmpAddr + 1;
                        Reading <= Reading + 1;
                    end else begin
                        Reading   <= 0;
                        LSB_value <= {16'b0, mem_dout, data[7:0]};
                    end

                end
                4: begin
                    data[23:16] <= mem_dout;
                    Reading <= Reading + 1;

                end
                5: begin
                    data[31:24] <= mem_dout;
                    LSB_value <= {mem_dout, data[23:0]};
                    Reading <= 0;
                end

            endcase
        end else if (boss == LSB_w) begin
            case (Reading)
                0: begin
                    mem_a <= LSB_addr;
                    mem_wr <= `HIGH;
                    mem_din <= LSB_Wvalue[7:0];
                    TmpAddr <= LSB_addr + 1;
                    Reading <= Reading + 1;
                    data <= 0;
                end
                1: begin
                    if (Inst_Name != `SB) begin
                        mem_a   <= TmpAddr;
                        TmpAddr <= TmpAddr + 1;
                        mem_din <= LSB_Wvalue[15:8];
                        Reading <= Reading + 1;
                    end else begin
                        Reading <= 0;
                        mem_wr  <= `LOW;
                        mem_a   <= 0;
                    end
                end
                2: begin
                    if (Inst_Name != `SH) begin
                        mem_din <= LSB_Wvalue[23:16];
                        mem_a   <= TmpAddr;
                        TmpAddr <= TmpAddr + 1;
                        Reading <= Reading + 1;
                    end else begin
                        Reading <= 0;
                        mem_wr  <= `LOW;
                        mem_a   <= 0;
                    end
                end
                3: begin
                    mem_din <= LSB_Wvalue[31:24];
                    mem_a   <= TmpAddr;
                    TmpAddr <= TmpAddr + 1;
                    Reading <= Reading + 1;
                end
                4: begin
                    mem_wr  <= `LOW;  // Stop Writing Immediately
                    Reading <= 0;
                end
            endcase
        end
    end
endmodule
