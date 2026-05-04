`timescale 1ns / 10ps
module rflp1024x8mx2(
    output  [8-1:0]     DO,
    input   [8-1:0]     DIN,
    input   [8-1:0]     RA,
    input   [2-1:0]     CA,
    input               NWRT,
    input               NCE,
    input               CLK);
   
    reg     [8-1:0]     array[1024-1:0];
    reg     [8-1:0]     r_din;
    reg     [10-1:0]    r_addr;
    reg                 r_nwrt, r_nce;
    
    event write, read;
    integer i;
    
    reg     [8-1:0]     temp_reg;
    reg     [8-1:0]     write_data;
    reg     [8-1:0]     do_reg;
    wire    [10-1:0]    A;
    
    //assign DO = (1'b1)? do_reg: 44'hz;
    wire    [8-1:0]     BDO;
    
         buf(BDO[0], do_reg[0]);
         buf(BDO[1], do_reg[1]);
         buf(BDO[2], do_reg[2]);
         buf(BDO[3], do_reg[3]);
         buf(BDO[4], do_reg[4]);
         buf(BDO[5], do_reg[5]);
         buf(BDO[6], do_reg[6]);
         buf(BDO[7], do_reg[7]);

         bufif1(DO[0], BDO[0], 1'b1);
         bufif1(DO[1], BDO[1], 1'b1);
         bufif1(DO[2], BDO[2], 1'b1);
         bufif1(DO[3], BDO[3], 1'b1);
         bufif1(DO[4], BDO[4], 1'b1);
         bufif1(DO[5], BDO[5], 1'b1);
         bufif1(DO[6], BDO[6], 1'b1);
         bufif1(DO[7], BDO[7], 1'b1);
         
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
                  
                  $setuphold(posedge CLK, posedge DIN[0], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[1], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[2], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[3], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[4], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[5], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[6], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[7], tDS, tDH);

                  
                  
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
                          
                
                  $setuphold(posedge CLK, negedge DIN[0], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[1], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[2], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[3], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[4], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[5], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[6], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[7], tDS, tDH);
                  
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
