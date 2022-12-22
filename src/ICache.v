`include "constants.v"
module ICache (
    input wire clk,  // system clock signal
    input wire rst,  // reset signal
    input wire rdy,  // ready signal, pause cpu when low

    output reg              IC_rn,     //read_enable(read only)
    output reg  [`Data_Bus] IC_addr,
    input  wire             IC_ready,
    input  wire [`Data_Bus] IC_value,


    input wire [31:0] addr,  //only 17:0 is used
    input wire rn,

    output reg [31:0] Inst,
    output reg ready,
    output reg Predict_Ready
);

    //reg [31:0] Cache[`Cache_Size][`Cache_Line];
    reg [31:0] Cache[`Cache_Size][`Cache_Line];
    reg [22:0] Tag [`Cache_Size];//20=32-log(32(4 byte each))-log(8(Cache Size 8))-log(16(Cache_Line size))
    reg [31:0] PC;
    reg ToRam = `False;
    reg [31:0] Ram_Addr;
    reg [31:0] Ram_Addr_limit;
    //reg [31:0] Cache[];
    integer i, j;
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            Tag[i] = ~(23'b0);  //Assure No Conflict at first
        end
        IC_rn = `False;
        ready = `True;
    end
    always @(negedge clk ) begin
        Predict_Ready=`False;
    end
    always @(addr) begin
        if (rst) begin

        end else if (rn) begin
            if (Tag[addr[8:4]] == addr[31:9]) begin
                ready = `True;
                Predict_Ready=`True;
                Inst  = Cache[addr[8:4]][addr[3:2]];
            end else begin
                ready = `False;
                ToRam = `True;
                IC_rn = `True;
                Tag[addr[8:4]] = addr[31:9];
                Ram_Addr = {addr[31:9], addr[8:4],4'b0};
                Ram_Addr_limit = {addr[31:9],addr[8:4],4'b1100};
                IC_addr = Ram_Addr;
            end
            PC = addr;
        end
    end
    always @(posedge IC_ready) begin
        if (rst) begin

        end else if (Ram_Addr != Ram_Addr_limit) begin
            IC_rn = `True;
            //$display("PC:%x IC:%x", IC_addr, IC_value);
            Cache[PC[8:4]][Ram_Addr[3:2]] = IC_value;
            Ram_Addr = Ram_Addr + 4;
            IC_addr = Ram_Addr;
        end else begin
            ToRam = `False;
            IC_rn = `False;
            ready = `True;
            Cache[PC[8:4]][Ram_Addr[3:2]] = IC_value;
            Inst  = Cache[PC[8:4]][PC[3:2]];
            Predict_Ready=`True;
        end
    end
endmodule
