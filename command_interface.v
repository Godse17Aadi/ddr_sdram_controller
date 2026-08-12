module command_interace#(
    parameter ROW_WIDTH  = 12,
    parameter COL_WIDTH  = 10,
    parameter BANK_WIDTH = 2,
    parameter ADDR_WIDTH = ROW_WIDTH + BANK_WIDTH + COL_WIDTH
)(
    input [2:0] cmd,
    input [ADDR_WIDTH-1:0] addr,
    input clk,

    input wire cm_ack,

    output reg cmd_ack,


    output reg  nop,
    output reg reada,
    output reg writea,
    output reg refresh,
    output reg precharge,
    output reg load_mode,
    output reg ref_req,
    
    
    //Load_Reg1 and 2 
    output reg load_reg1,
    output reg load_reg2,

    output wire [1:0] sc_cl,
    output wire [1:0] sc_rc,
    output wire [3:0] sc_rrd,
    output wire [3:0] sc_bl

);
    //Load_Reg1 and 2 
    //reg load_reg1;
    //reg load_reg2;
//------------------------------------------------------------------------------------------------------------------



//Command Decoder
always@(*) begin
    
    //default
        nop        = 1'b0;
        reada      = 1'b0;
        writea     = 1'b0;
        refresh    = 1'b0;
        precharge  = 1'b0;
        load_mode  = 1'b0;
        load_reg1  = 1'b0;
        load_reg2  = 1'b0;

        case(cmd)
        3'b000: nop        = 1'b1;
        3'b001: reada      = 1'b1;
        3'b010: writea     = 1'b1;
        3'b011: refresh    = 1'b1;
        3'b100: precharge  = 1'b1;
        3'b101: load_mode  = 1'b1;
        3'b110: load_reg1  = 1'b1;
        3'b111: load_reg2  = 1'b1;
        default:nop        = 1'b1;
        endcase
    end

//-------------------------------------------------------------------------------------------------------------------

//Load Reg 1 and Reg 2

reg [1:0] reg1_cl;
reg [1:0] reg1_rc;
reg [3:0] reg1_rrd;
reg [3:0] reg1_bl;
reg [15:0] reg2;

always @(posedge clk) begin
    if (load_reg1) begin
        reg1_cl  <= addr[1:0];
        reg1_rc  <= addr[3:2];
        reg1_rrd <= addr[7:4];
        reg1_bl  <= addr[12:9];
    end

    else if(load_reg2) begin
        reg2 <= addr[15:0];
    end
end

assign sc_cl  = reg1_cl;
assign sc_rc  = reg1_rc;
assign sc_rrd = reg1_rrd;
assign sc_bl  = reg1_bl;

//-------------------------------------------------------------------------------------------------------------
//Command acknowledge logic

always@(posedge clk) begin
    cmd_ack <= cm_ack || load_reg1 || load_reg2 ;
end
/*//refresh logic

always@(*) begin
    

end*/
endmodule



