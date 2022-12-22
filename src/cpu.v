// RISCV32I CPU top module
// port modification allowed for debugging purposes
`include "constants.v"
module cpu (
    input wire clk_in,  // system clock signal
    input wire rst_in,  // reset signal
    input wire rdy_in,  // ready signal, pause cpu when low

    input  wire [ 7:0] mem_din,   // data input bus
    output wire [ 7:0] mem_dout,  // data output bus
    output wire [31:0] mem_a,     // address bus (only 17:0 is used)
    output wire        mem_wr,    // write/read signal (1 for write)

    input wire io_buffer_full,  // 1 if uart buffer is full

    output wire [31:0] dbgreg_dout  // cpu register output (debugging demo)
);

    // implementation goes here

    // Specifications:
    // - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
    // - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
    // - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
    // - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
    // - 0x30000 read: read a byte from input
    // - 0x30000 write: write a byte to output (write 0x00 is ignored)
    // - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
    // - 0x30004 write: indicates program stop (will output '\0' through uart tx)
    wire True_Wire = 1;
    wire                                   IC_rn;
    wire                [      `Data_Bus]  IC_addr;
    wire                [      `Data_Bus]  IC_value;
    wire                                   IC_ready;
    wire                [      `Data_Bus]  addr;
    wire                                   LSB_rn;
    wire                                   LSB_wn;
    wire                [      `Data_Bus]  LSB_Wvalue;
    wire                [      `Data_Bus]  LSB_addr;
    wire                                   LSB_ready;
    wire                [      `Data_Bus]  LSB_value;
    wire                [           16:0 ] Inst_Name;

    wire                                   rn;
    wire                [      `Data_Bus]  Inst;
    wire                                   Read_ready;
    wire                                   CurrentAddr;

    wire                                   Predict_Ready;
    wire                                   Predict_Jump_Bool;
    wire                [      `Data_Bus]  Predict_Jump;
    wire                [      `Data_Bus]  Target_PC;
    wire                [      `Data_Bus]  CurrentInst;
    wire                                   Fetcher_Ready;
    wire                                   received;


    wire                [      `Data_Bus]  Out_PC;
    wire                                   Processor_ready;
    wire                [      `Data_Bus]  rd;
    wire                [      `Data_Bus]  vj;
    wire                [      `Data_Bus]  vk;
    wire                [      `Data_Bus]  qj;
    wire                [      `Data_Bus]  qk;
    wire                [           16:0 ] name;
    wire                [      `Data_Bus]  Imm;
    wire                                   success;
    wire                [     `ROB_Width]  ROB_Tail;
    wire                                   ROB_Ready;
    wire                [      `Data_Bus]  ROB_Value;
    wire                [`Register_Width]  ROB_Addr;

    wire                                   ROB_TO_RS_ready;
    wire                                   ROB_Ready_RS;
    wire                [     `ROB_Width]  ROB_Addr_RS;
    wire                [      `Data_Bus]  ROB_Rd_RS;
    wire                [      `Data_Bus]  ROB_A_RS;
    wire                [     `ROB_Width]  ROB_Tag;
    wire                [      `Data_Bus]  ROB_A;
    wire                [      `ROB_Size]  ROB_Valid_Exposed;
    wire                [          511:0 ] ROB_Value_Exposed;
    wire                                   ALU_ready;
    wire                                   ALU_success;
    wire                [      `Data_Bus]  LV;
    wire                [      `Data_Bus]  RV;
    wire                [            3:0 ] Op;
    wire                [      `Data_Bus]  result;

    wire                                   Train_Ready;
    wire                                   Train_Result;
    wire                [      `Data_Bus]  Train_PC;

    wire                [      `Data_Bus]  Clr_PC;
    wire                [     `ROB_Width]  Tag;
    wire                                   clear;
    mem_ctrl u_mem_ctrl (
        .clk       (clk_in & rdy_in),
        .rst       (rst_in),
        .rdy       (True_Wire),
        .mem_din   (mem_dout),
        .mem_dout  (mem_din),
        .mem_a     (mem_a),
        .mem_wr    (mem_wr),
        .IC_rn     (IC_rn),
        .IC_addr   (IC_addr),
        .IC_ready  (IC_ready),
        .IC_value  (IC_value),
        .LSB_rn    (LSB_rn),
        .LSB_wn    (LSB_wn),
        .LSB_Wvalue(LSB_Wvalue),
        .LSB_addr  (LSB_addr),
        .LSB_ready (LSB_ready),
        .LSB_value (LSB_value),
        .Inst_Name (Inst_Name)
    );
    ICache u_ICache (
        .clk          (clk_in & rdy_in),
        .rst          (rst_in),
        .rdy          (True_Wire),
        .IC_rn        (IC_rn),
        .IC_addr      (IC_addr),
        .IC_ready     (IC_ready),
        .IC_value     (IC_value),
        .addr         (addr),
        .rn           (rn),
        .Inst         (Inst),
        .ready        (Read_ready),
        .Predict_Ready(Predict_Ready)
    );
    Fetcher u_Fetcher (
        .clk         (clk_in & rdy_in),
        .rst         (rst_in),
        .rdy         (True_Wire),
        .Predict_Jump(Predict_Jump),
        .clr         (clear),
        .Clr_PC      (Clr_PC),
        .addr        (addr),
        .rn          (rn),
        .Inst        (Inst),
        .Read_ready  (Read_ready),
        .CurrentInst (CurrentInst),
        .ready       (Fetcher_Ready),
        .success     (received),
        .Out_PC      (Out_PC)
    );
    Predictor u_Predictor (
        .clk              (clk_in & rdy_in),
        .rst              (rst_in),
        .rdy              (True_Wire),
        .PC               (addr),              //GAN
        .clr              (clear),
        .Target_PC        (Clr_PC),
        .Inst             (Inst),
        .Ready            (Predict_Ready),
        .Predict_Jump     (Predict_Jump),
        .Train_Ready      (Train_Ready),
        .Train_Result     (Train_Result),
        .Train_PC         (Train_PC),
        .Predict_Jump_Bool(Predict_Jump_Bool)
    );
    Processor u_Processor (
        .clk              (clk_in & rdy_in),
        .rst              (rst_in),
        .rdy              (True_Wire),
        .PC               (Out_PC),
        .Inst             (CurrentInst),
        .Inst_Ready       (Fetcher_Ready),
        .received         (received),
        .clr              (clear),
        .ready            (Processor_ready),
        .rd               (rd),
        .vj               (vj),
        .vk               (vk),
        .qj               (qj),
        .qk               (qk),
        .name             (name),
        .Imm              (Imm),
        .success          (success),
        .ROB_Tail         (ROB_Tail),
        .ROB_Ready        (ROB_Ready),
        .ROB_Value        (ROB_Value),
        .ROB_Addr         (ROB_Addr),
        .ROB_Tag          (ROB_Tag),
        .Predict_Jump_Bool(Predict_Jump_Bool)
    );
    RS u_RS (
        .clk         (clk_in & rdy_in),
        .rst         (rst_in),
        .rdy         (True_Wire),
        .clr         (clear),
        .ready       (ROB_TO_RS_ready),
        .rd          (rd),
        .vj          (vj),
        .vk          (vk),
        .qj          (qj),
        .qk          (qk),
        .name        (name),
        .Imm         (Imm),
        .tag         (Tag),
        .ROB_Ready   (ROB_Ready_RS),
        .ROB_Addr    (ROB_Addr_RS),
        .ROB_A       (ROB_A_RS),
        .ROB_Rd      (ROB_Rd_RS),
        .ROB_Valid   (ROB_Valid_Exposed),
        .ROB_Value   (ROB_Value_Exposed),
        .ALU_ready   (ALU_ready),
        .ALU_success (ALU_success),
        .LV          (LV),
        .RV          (RV),
        .Op          (Op),
        .result      (result),
        .Train_Ready (Train_Ready),
        .Train_Result(Train_Result),
        .Train_PC    (Train_PC)
    );

    Alu u_Alu (
        .clk        (clk_in & rdy_in),
        .rst        (rst_in),
        .rdy        (True_Wire),
        .ALU_ready  (ALU_ready),
        .ALU_success(ALU_success),
        .LV         (LV),
        .RV         (RV),
        .Op         (Op),
        .result     (result)
    );

    Rob u_Rob (
        .clk            (clk_in & rdy_in),
        .rst            (rst_in),
        .rdy            (True_Wire),
        .clr            (clear),
        .Clr_PC         (Clr_PC),
        .ready          (Processor_ready),
        .Inst_Name      (Inst_Name),
        .rd             (rd),
        .name           (name),
        .Imm            (Imm),
        .PC             (vk),
        .success        (success),
        .tail           (ROB_Tail),
        .ROB_TO_RS_ready(ROB_TO_RS_ready),
        .ROB_Valid      (ROB_Valid_Exposed),
        .ROB_Imm        (ROB_Value_Exposed),
        .RS_Ready       (ROB_Ready_RS),
        .RS_A           (ROB_A_RS),
        .RS_Tag         (ROB_Addr_RS),
        .RS_Rd          (ROB_Rd_RS),
        .ROB_TO_RS_Tag  (Tag),
        .ROB_Ready      (ROB_Ready),
        .ROB_Value      (ROB_Value),
        .ROB_Addr       (ROB_Addr),
        .ROB_Tag        (ROB_Tag),
        .RN             (LSB_rn),
        .WN             (LSB_wn),
        .Wvalue         (LSB_Wvalue),
        .Addr           (LSB_addr),
        .Mem_Success    (LSB_ready),
        .Read_Value     (LSB_value)
    );

    always @(posedge clk_in) begin
        if (rst_in) begin
        end else
        if (!rdy_in) begin

        end else begin

        end
    end

endmodule
