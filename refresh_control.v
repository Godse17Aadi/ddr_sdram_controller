module refresh_control(
    input clk,
    input ref_ack,

    output reg load //A procedural always block cannot drive a normal wire
);

always@(posedge clk) begin
    load <= 1'd0;
    if (ref_ack) begin
        load <= 1'd1;
    end
end

endmodule

//-------------------------------------**----------------------------

//Refresh Count
/*                 REG2
                  ¦
                  ?
             +-------------+
             ¦ Refresh     ¦
             ¦ Count       ¦
             ¦             ¦
CLK --------?¦             ¦
LOAD -------?¦             ¦
             +-------------+
                    ¦
                 Zero Decode
                    ¦
                    ?
                 REF_REQ
                 */

                 
module refresh_count(
    input wire clk,
    input wire rst,
    input wire load,
//    input wire [15:0] addr,
    input wire [15:0] reg2,

    output reg ref_req

);

reg [15:0] count_refresh;

//--------------------------------------------------------------------------------------------------------------------------
//refresh counter logic 

always@(posedge clk) begin
    
    if (rst) begin
        count_refresh <= 16'd0;
        ref_req       <= 1'd0 ;
    end
// *   *    *   *   *   *   *   *

    else if(load) begin
        count_refresh <= reg2 ;
        ref_req       <= 1'd0 ;
    end
// *   *    *   *   *   *   *   *

    else if (count_refresh > 0) begin
        count_refresh <= count_refresh - 1 ;
        ref_req       <= 1'd0 ; 
    end
// *   *    *   *   *   *   *   *

    else
        ref_req        <= 1'd1 ;
end

//--------------------------------------------------------------------------------------------------------------------------

endmodule