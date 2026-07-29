
module arbiter (
    
    //It is a pure combinational logic, hence no need of clk and rst.
    //input  wire clk,
    //input  wire rst,

    input wire done,

    input  wire nop,
    input  wire reada,
    input  wire writea,
    input  wire refresh,
    input  wire precharge,
    input  wire load_mode,
    input  wire ref_req,

    output reg do_nop,
    output reg do_read,
    output reg do_write,
    output reg do_refresh,
    output reg do_precharge,
    output reg do_load_mode,

    output reg cm_ack,
    output reg ref_ack
);
//Whenever the controller becomes free, the arbiter first checks for a pending refresh request. 
//If one exists, it services the refresh; otherwise, it services the host command. 
//It never interrupts an operation already in progress.
    
    //basically a priority based encoder
    /*                  Start
                   ¦
                   ?
        Is a command in progress?
                   ¦
          +-----------------+
          ¦                 ¦
         Yes               No
          ¦                 ¦
          ?                 ?
Wait until current     Check REF_REQ
operation finishes          ¦
                            ¦
                  +-------------------+
                  ¦                   ¦
                REF_REQ=1          REF_REQ=0
                  ¦                   ¦
                  ?                   ?
          Issue REFRESH         Check Host Command
          REF_ACK = 1                ¦
                                     ¦
                    +---------------------------------+
                    ¦                                 ¦
                Host Command?                      No Command
                    ¦                                 ¦
                    ?                                 ?
            Issue Host Command                  Issue NOP
             CM_ACK = 1
                    ¦
                    ?
          Wait until command completes
                    ¦
                    +--------------? Back to Start */
        
    
    
    always@(*)begin
        
        do_nop        = 1'b0; //need to initilize otherwise latch will be infered
        do_read       = 1'b0;
        do_write      = 1'b0;
        do_refresh    = 1'b0;
        do_precharge  = 1'b0;
        do_load_mode  = 1'b0;
        cm_ack        = 1'b0;
        ref_ack       = 1'b0;
        
        if(!done) begin
            //do nothing
        end
        
        
        else begin
            if(ref_req) begin
                ref_ack = 1'b1;
                do_refresh=1'b1;
            end
            
            else if(refresh) begin
                cm_ack = 1'b1;
                do_refresh = 1'b1;
            end
            else if(reada) begin
                cm_ack = 1'b1;
                do_read = 1'b1;
            end
            
            else if(writea) begin
                cm_ack = 1'b1;
                do_write = 1'b1;
            end

            else if(load_mode) begin
                cm_ack = 1'b1;
                do_load_mode = 1'b1;
            end

            else if(precharge) begin
                cm_ack = 1'b1;
                do_precharge = 1'b1;
            end

            
            else begin
                
                do_nop = 1'b1;
            end
        end
    end
endmodule


