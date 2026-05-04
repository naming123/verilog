`timescale 1ns / 10ps
module rflp1024x21mx2(
    output  [21-1:0]    DO,
    input   [21-1:0]    DIN,
    input   [8-1:0]     RA,
    input   [2-1:0]     CA,
    input               NWRT,
    input               NCE,
    input               CLK);
   
    reg     [21-1:0]    array[1024-1:0];
    reg     [21-1:0]    r_din;
    reg     [10-1:0]    r_addr;
    reg                 r_nwrt, r_nce;
    
    event write, read;
    integer i;
    
    reg     [21-1:0]    temp_reg;
    reg     [21-1:0]    write_data;
    reg     [21-1:0]    do_reg;
    wire    [10-1:0]    A;
    
    //assign DO = (1'b1)? do_reg: 44'hz;
    wire    [21-1:0]     BDO;
    
         buf(BDO[ 0], do_reg[ 0]);
         buf(BDO[ 1], do_reg[ 1]);
         buf(BDO[ 2], do_reg[ 2]);
         buf(BDO[ 3], do_reg[ 3]);
         buf(BDO[ 4], do_reg[ 4]);
         buf(BDO[ 5], do_reg[ 5]);
         buf(BDO[ 6], do_reg[ 6]);
         buf(BDO[ 7], do_reg[ 7]);
         buf(BDO[ 8], do_reg[ 8]);
         buf(BDO[ 9], do_reg[ 9]);
         buf(BDO[10], do_reg[10]);
         buf(BDO[11], do_reg[11]);
         buf(BDO[12], do_reg[12]);
         buf(BDO[13], do_reg[13]);
         buf(BDO[14], do_reg[14]);
         buf(BDO[15], do_reg[15]);
         buf(BDO[16], do_reg[16]);
         buf(BDO[17], do_reg[17]);
         buf(BDO[18], do_reg[18]);
         buf(BDO[19], do_reg[19]);
         buf(BDO[20], do_reg[20]);

         bufif1(DO[ 0], BDO[ 0], 1'b1);
         bufif1(DO[ 1], BDO[ 1], 1'b1);
         bufif1(DO[ 2], BDO[ 2], 1'b1);
         bufif1(DO[ 3], BDO[ 3], 1'b1);
         bufif1(DO[ 4], BDO[ 4], 1'b1);
         bufif1(DO[ 5], BDO[ 5], 1'b1);
         bufif1(DO[ 6], BDO[ 6], 1'b1);
         bufif1(DO[ 7], BDO[ 7], 1'b1);
         bufif1(DO[ 8], BDO[ 8], 1'b1);
         bufif1(DO[ 9], BDO[ 9], 1'b1);
         bufif1(DO[10], BDO[10], 1'b1);
         bufif1(DO[11], BDO[11], 1'b1);
         bufif1(DO[12], BDO[12], 1'b1);
         bufif1(DO[13], BDO[13], 1'b1);
         bufif1(DO[14], BDO[14], 1'b1);
         bufif1(DO[15], BDO[15], 1'b1);
         bufif1(DO[16], BDO[16], 1'b1);
         bufif1(DO[17], BDO[17], 1'b1);
         bufif1(DO[18], BDO[18], 1'b1);
         bufif1(DO[19], BDO[19], 1'b1);
         bufif1(DO[20], BDO[20], 1'b1);
         
         assign A = {RA, CA};
         
         always@(posedge CLK)
                begin
                     r_nwrt <= NWRT;
                     r_nce <= NCE;
                     r_din <= DIN;
                     r_addr <= A;
                     
                #0.1
                      if(!r_nce && !r_nwrt)
                        -> write;
                      if(!r_nce && r_nwrt)
                        -> read;
                        
                    end
                    
         always@(write)
                begin
                      temp_reg = array[r_addr];
                      write_data = r_din;
                array[r_addr] = write_data;
            end
          
            
         always@(read)
                begin
                     #0.1
                     do_reg = array[r_addr];
                 end
                 
         reg FLAG_X;
         initial FLAG_X = 1'b0;
         always@(FLAG_X)
         begin
             for(i=0; i<(1024); i=i+1)
              begin
                  //array[i] = {40{1'bx}};
              end
              $display("INSUFFICIENT SETUP/HOLD TIME - POTENTIAL MEMORY DATA CORRUPTION");
              
          end
          
          specify
                  specparam
                            tCLK = 3,              // Clock Cycle Time
                            tCH = 0.4*tCLK,        // Clock High-Level Width
                            tCL = 0.4*tCLK,        // Clock Low-level Width
                            tDH = 0.0,             // Data-in Hold Time
                            tDS = 0.40,            // Data-in Setup Time
                            tAH = 0.0,             // address Hold Time
                            tAS = 0.60,            // address Setup Time
                            tPHL = 0.8,            
                            tPLH = 0.8,        
                            tEH = 0.0, 
                            tES = 0.40;            // control signal Hold Time
                  $width(posedge CLK, tCH);        // control signal Setup Time
                  
                  $width(negedge CLK, tCL); 
                  
                  $period(negedge CLK, tCLK);
                  
                  $period(posedge CLK, tCLK);
                  
                  $setuphold(posedge CLK, posedge NWRT, tES, tEH);
                  $setuphold(posedge CLK, posedge NCE, tES, tEH);
                  
                  $setuphold(posedge CLK, posedge DIN[ 0], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[ 1], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[ 2], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[ 3], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[ 4], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[ 5], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[ 6], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[ 7], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[ 8], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[ 9], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[10], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[11], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[12], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[13], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[14], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[15], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[16], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[17], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[18], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[19], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[20], tDS, tDH);

                  
                  
                  (CLK => DO[0]) = (tPLH, tPHL);
                  (CLK => DO[1]) = (tPLH, tPHL);
                  (CLK => DO[2]) = (tPLH, tPHL);
                  (CLK => DO[3]) = (tPLH, tPHL);
                  (CLK => DO[4]) = (tPLH, tPHL);
                  (CLK => DO[5]) = (tPLH, tPHL);
                  (CLK => DO[6]) = (tPLH, tPHL);
                  (CLK => DO[7]) = (tPLH, tPHL);
                  
                   $setuphold(posedge CLK, posedge RA[0], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge RA[1], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge RA[2], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge RA[3], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge RA[4], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge RA[5], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge RA[6], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge RA[7], tDS, tDH, FLAG_X);
                   
                   
                   $setuphold(posedge CLK, posedge CA[0], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge CA[1], tDS, tDH, FLAG_X);

                   
                  $setuphold(posedge CLK, negedge NWRT, tES, tEH);
                  $setuphold(posedge CLK, negedge NCE, tES, tEH);
                          
                
                  $setuphold(posedge CLK, negedge DIN[ 0], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[ 1], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[ 2], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[ 3], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[ 4], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[ 5], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[ 6], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[ 7], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[ 8], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[ 9], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[10], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[11], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[12], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[13], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[14], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[15], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[16], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[17], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[18], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[19], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[20], tDS, tDH);
                  
                  $setuphold(posedge CLK, negedge RA[0], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[1], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[2], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[3], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[4], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[5], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[6], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[7], tDS, tDH, FLAG_X);
                  
                  $setuphold(posedge CLK, negedge CA[0], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge CA[1], tDS, tDH, FLAG_X);

              endspecify
              
      endmodule
