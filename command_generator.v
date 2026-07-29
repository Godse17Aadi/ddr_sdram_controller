module command_generator #(

    parameter ROW_WIDTH  = 12,
    parameter COL_WIDTH  = 10,
    parameter BANK_WIDTH = 2,
    parameter ADDR_WIDTH = ROW_WIDTH + BANK_WIDTH + COL_WIDTH
)(
    input clk,
    input rst,

    // From Arbiter
    input do_read,
    input do_write,
    input do_refresh,
    input do_load_mode,
    input do_precharge,
    input do_nop,

    //-------------------------------------------------------------------

    // From Command Timing
    input timer_done,

    //-------------------------------------------------------------------

    // Address
    input [ADDR_WIDTH-1:0] addr,
    //ADDR_WIDTH = ROW_WIDTH + BANK_WIDTH + COL_WIDTH
    //       = 13 + 2 + 10
    //       = 25 bits

    //addr[24:12]  -> Row Address (12 bits)
    //addr[11:10]  -> Bank Address (2 bits)
    //addr[9:0]    -> Column Address (10 bits)
    
    //-------------------------------------------------------------------
    
    // To Command Timing
    output reg timer_start,
    output reg [2:0] timer_select,

    //For decision of WAIT
    //output reg after_exe;
      
    //-------------------------------------------------------------------

    // To SDRAM
    output reg cs_n,
    output reg cke,
    output reg ras_n,
    output reg cas_n,
    output reg we_n,

    output reg [11:0] sa,
    output reg [1:0] ba,

    //To Arbiter
    output reg done

    

);
    //-------------------------------------------------------------------
   
    
    assign row_addr  = addr[23:12] ; // 12 bits
    assign bank_addr = addr[11:10] ; // 2  bits
    assign col_addr  = addr[9:0]   ; // 10 bits   
    
    //  State Encoding
    localparam IDLE       = 4'd0;
    localparam ACTIVATE   = 4'd1;
    localparam WAIT_TRCD  = 4'd2;
    localparam READ       = 4'd3;
    localparam WRITE      = 4'd4;
    localparam WAIT_CL    = 4'd5;
    localparam WAIT_TWR   = 4'd6;
    localparam REFRESH    = 4'd7;
    localparam WAIT_TRFC  = 4'd8;
    localparam LOAD_MODE  = 4'd9;
    localparam WAIT_TMRD  = 4'd10;
    localparam PRECHARGE  = 4'd11;
    localparam WAIT_TRP   = 4'd12;

    // Timer  State Encoding
    
    localparam TIMER_TRCD = 3'd0;
    localparam TIMER_CL   = 3'd1;
    localparam TIMER_TWR  = 3'd2;
    localparam TIMER_TRP  = 3'd3;
    localparam TIMER_TRFC = 3'd4;
    localparam TIMER_TMRD = 3'd5;

    

    //-------------------------------------------------------------------
    //Internal Registers
    reg [3:0] current_state;
    reg [3:0] next_state;
    reg [11:0] mode_reg = 12'b000000110010;

    //-------------------------------------------------------------------
    //FSM Logic
    
    always@(posedge clk)
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    
    always@(*) begin
        case(current_state)
            
//--------------------------------------------------------------------------
            IDLE: begin
                if(do_read || do_write)
                    next_state = ACTIVATE;
                
                else if(do_refresh)
                    next_state = REFRESH;

                else if(do_load_mode)
                    next_state = LOAD_MODE;
                
                else if(do_precharge)
                    next_state = PRECHARGE;

                else
                    next_state = IDLE;
            end
            
//--------------------------------------------------------------------------

            REFRESH:begin
                next_state = WAIT_TRFC;
            end
//--------------------------------------------------------------------------
            ACTIVATE:begin
                next_state = WAIT_TRCD;
            end
//--------------------------------------------------------------------------

            LOAD_MODE:begin
                next_state = WAIT_TMRD;  
            end
//--------------------------------------------------------------------------
            PRECHARGE:begin
                next_state = WAIT_TRP;
            end
//--------------------------------------------------------------------------

            WAIT_TRCD:begin 
                if(timer_done && do_read)
                    next_state = READ;
                else if(timer_done && do_write)
                    next_state = WRITE;
                else
                    next_state=WAIT_TRCD;
            end
//--------------------------------------------------------------------------
            
            READ:begin
                
                next_state = WAIT_CL;
            end  
//--------------------------------------------------------------------------    
            
            WRITE:begin
                next_state = WAIT_TWR;
            end
//--------------------------------------------------------------------------

            WAIT_TRFC:begin
                if(timer_done)
                    next_state = IDLE;
                else
                    next_state = WAIT_TRFC;
            end  

//--------------------------------------------------------------------------

            WAIT_TMRD:begin
                if(timer_done)
                    next_state = IDLE;
                else
                    next_state = WAIT_TMRD;
            end
//--------------------------------------------------------------------------

            WAIT_TRP:begin
                if(timer_done)
                    next_state = IDLE;
                else
                    next_state = WAIT_TRP; 
            end
//--------------------------------------------------------------------------

            WAIT_CL:begin
                if(timer_done)
                    next_state = IDLE;
                else
                    next_state =WAIT_CL;
            end

//--------------------------------------------------------------------------

             WAIT_TWR: begin
                if(timer_done)
                    next_state = IDLE;
                else
                    next_state =WAIT_TWR;
             end

//--------------------------------------------------------------------------

            default:begin 
                next_state = IDLE;
            end
        endcase

//--------------------------------------------------------------------------
    end

//--------------------------------------------------------------------------
//Output Logic

    always@(*)
    begin
        //Power-down mode , Self-refresh mode ,Clock disable- these are not
        //being implemented, so cke = 1 always.
        cke  = 1'b1;
        //Since we have one DDR chip, 
        //so we always want it selected whenever we are issuing commands.Hence cs_n = 1.
        cs_n = 1'b0;

        ba   = 2'b00;
        sa   = 12'b0;
        
        timer_start  = 1'b0;
        timer_select = 3'b000;

        done = 1'b0;

        //what happens if I do not initialize it?
        /*Ans : The synthesizer will infer that it needs to save the 
        previous value, and to store previous value it needs memory
        so it infers latch */
        
        //--------------------------------------------------------------- 
        case(current_state)

        IDLE: begin
            
            done = 1'b1;
            //Output Commands
            ras_n = 1;
            cas_n = 1;
            we_n  = 1;
        end

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
        
        ACTIVATE:begin
            
            //Output Commands
            ras_n = 0;
            cas_n = 1;
            we_n  = 1;

            //Address
            ba = bank_addr;
            sa = row_addr ;

            //Timer
            timer_start = 1'b1;
            timer_select = TIMER_TRCD;
        end

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        READ:begin

            //Output Commands
            ras_n = 1;
            cas_n = 0;
            we_n  = 1;

            // sa[10] = 0 -> means: Precharge Selected Banks.
            // sa[10] = 1 -> means: Precharge all banks
            
            //Address
            sa = {1'b0, 1'b1, col_addr};
            ba = bank_addr;

            //Timer
            timer_start = 1'b1;
            timer_select = TIMER_CL;
        end  
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        WRITE:begin

            //Output Commands
            ras_n = 1;
            cas_n = 0;
            we_n  = 0;
            
            //Address
            sa = {1'b0, 1'b1, col_addr};
            ba = bank_addr;

            //Timer
            timer_start = 1'b1;
            timer_select = TIMER_TWR;
        end
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        PRECHARGE:begin

            //Output Commands
            ras_n = 0;
            cas_n = 1;
            we_n  = 0;

            // For PRECHARGE, only sa[10] is significant
            // ba and remaining address bits are ignored by SDRAM.
            //Address
            ba = 2'b00;
            sa = {1'b0, 1'b1 , 10'b0};
            
            //Timer
            timer_start = 1'b1;
            timer_select = TIMER_TRP;

        end
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        REFRESH:begin

            //Output Commands
            ras_n = 0;
            cas_n = 0;
            we_n  = 1;

            //Address
            //Auto Refresh does not require address. So any value would be ignored
            ba = 2'b00;
            sa = 12'b0;
            
            //Timer
            timer_start = 1'b1;
            timer_select = TIMER_TRFC;
        end
        
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        LOAD_MODE:begin

            //Output Commands
            ras_n = 0;
            cas_n = 0;
            we_n  = 0;

            // sa is hardcoded here. During LOAD_MODE, sa is not an address
            // SDRAM interprets sa pins as configuration bits.
            // The fixed Mode Register value tells the SDRAM how it should behave after power-up
            //TODO: Replace with correct DDR1 Mode Register value.
            ba = 2'b00;
            sa = mode_reg; // sa is fixed for now

            //Timer
            timer_start = 1'b1;
            timer_select = TIMER_TMRD;
        end
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
        
        default: begin

            //Output Commands
            ras_n = 1;
            cas_n = 1;
            we_n  = 1;
        end
        endcase
    end
endmodule



    


   



