`timescale 1ns / 10ps
module rflp16384x128mx16(
    output [128-1:0] DO,
    input [128-1:0] DIN,
    input [10-1:0] RA,
    input [4-1:0] CA,
    input NWRT,
    input NCE,
    input CLK);
   
    reg [128-1:0] array[16384-1:0];
    reg [128-1:0] r_din;
    reg [14-1:0] r_addr;
    reg r_nwrt, r_nce;
    
    event write, read;
    integer i;
    
    reg [128-1:0] temp_reg;
    reg [128-1:0] write_data;
    reg [128-1:0] do_reg;
    wire [14-1:0] A;
    
    //assign DO = (1'b1)? do_reg: 44'hz;
    wire [128-1:0] BDO;
    
         buf(BDO[0], do_reg[0]);
         buf(BDO[1], do_reg[1]);
         buf(BDO[2], do_reg[2]);
         buf(BDO[3], do_reg[3]);
         buf(BDO[4], do_reg[4]);
         buf(BDO[5], do_reg[5]);
         buf(BDO[6], do_reg[6]);
         buf(BDO[7], do_reg[7]);
         buf(BDO[8], do_reg[8]);
         buf(BDO[9], do_reg[9]);
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
         buf(BDO[21], do_reg[21]);
         buf(BDO[22], do_reg[22]);
         buf(BDO[23], do_reg[23]);
         buf(BDO[24], do_reg[24]);
         buf(BDO[25], do_reg[25]);
         buf(BDO[26], do_reg[26]);
         buf(BDO[27], do_reg[27]);
         buf(BDO[28], do_reg[28]);
         buf(BDO[29], do_reg[29]);
         buf(BDO[30], do_reg[30]);
         buf(BDO[31], do_reg[31]);
         buf(BDO[32], do_reg[32]);
         buf(BDO[33], do_reg[33]);
         buf(BDO[34], do_reg[34]);
         buf(BDO[35], do_reg[35]);
         buf(BDO[36], do_reg[36]);
         buf(BDO[37], do_reg[37]);
         buf(BDO[38], do_reg[38]);
         buf(BDO[39], do_reg[39]);
         buf(BDO[40], do_reg[40]);
         buf(BDO[41], do_reg[41]);
         buf(BDO[42], do_reg[42]);
         buf(BDO[43], do_reg[43]);
         buf(BDO[44], do_reg[44]);
         buf(BDO[45], do_reg[45]);
         buf(BDO[46], do_reg[46]);
         buf(BDO[47], do_reg[47]);
         buf(BDO[48], do_reg[48]);
         buf(BDO[49], do_reg[49]);
         buf(BDO[50], do_reg[50]);
         buf(BDO[51], do_reg[51]);
         buf(BDO[52], do_reg[52]);
         buf(BDO[53], do_reg[53]);
         buf(BDO[54], do_reg[54]);
         buf(BDO[55], do_reg[55]);
         buf(BDO[56], do_reg[56]);
         buf(BDO[57], do_reg[57]);
         buf(BDO[58], do_reg[58]);
         buf(BDO[59], do_reg[59]);
         buf(BDO[60], do_reg[60]);
         buf(BDO[61], do_reg[61]);
         buf(BDO[62], do_reg[62]);
         buf(BDO[63], do_reg[63]);
         buf(BDO[64], do_reg[64]);
         buf(BDO[65], do_reg[65]);
         buf(BDO[66], do_reg[66]);
         buf(BDO[67], do_reg[67]);
         buf(BDO[68], do_reg[68]);
         buf(BDO[69], do_reg[69]);
         buf(BDO[70], do_reg[70]);
         buf(BDO[71], do_reg[71]);
         buf(BDO[72], do_reg[72]);
         buf(BDO[73], do_reg[73]);
         buf(BDO[74], do_reg[74]);
         buf(BDO[75], do_reg[75]);
         buf(BDO[76], do_reg[76]);
         buf(BDO[77], do_reg[77]);
         buf(BDO[78], do_reg[78]);
         buf(BDO[79], do_reg[79]);
         buf(BDO[80], do_reg[80]);
         buf(BDO[81], do_reg[81]);
         buf(BDO[82], do_reg[82]);
         buf(BDO[83], do_reg[83]);
         buf(BDO[84], do_reg[84]);
         buf(BDO[85], do_reg[85]);
         buf(BDO[86], do_reg[86]);
         buf(BDO[87], do_reg[87]);
         buf(BDO[88], do_reg[88]);
         buf(BDO[89], do_reg[89]);
         buf(BDO[90], do_reg[90]);
         buf(BDO[91], do_reg[91]);
         buf(BDO[92], do_reg[92]);
         buf(BDO[93], do_reg[93]);
         buf(BDO[94], do_reg[94]);
         buf(BDO[95], do_reg[95]);
         buf(BDO[96], do_reg[96]);
         buf(BDO[97], do_reg[97]);
         buf(BDO[98], do_reg[98]);
         buf(BDO[99], do_reg[99]);
         buf(BDO[100], do_reg[100]);
         buf(BDO[101], do_reg[101]);
         buf(BDO[102], do_reg[102]);
         buf(BDO[103], do_reg[103]);
         buf(BDO[104], do_reg[104]);
         buf(BDO[105], do_reg[105]);
         buf(BDO[106], do_reg[106]);
         buf(BDO[107], do_reg[107]);
         buf(BDO[108], do_reg[108]);
         buf(BDO[109], do_reg[109]);
         buf(BDO[110], do_reg[110]);
         buf(BDO[111], do_reg[111]);
         buf(BDO[112], do_reg[112]);
         buf(BDO[113], do_reg[113]);
         buf(BDO[114], do_reg[114]);
         buf(BDO[115], do_reg[115]);
         buf(BDO[116], do_reg[116]);
         buf(BDO[117], do_reg[117]);
         buf(BDO[118], do_reg[118]);
         buf(BDO[119], do_reg[119]);
         buf(BDO[120], do_reg[120]);
         buf(BDO[121], do_reg[121]);
         buf(BDO[122], do_reg[122]);
         buf(BDO[123], do_reg[123]);
         buf(BDO[124], do_reg[124]);
         buf(BDO[125], do_reg[125]);
         buf(BDO[126], do_reg[126]);
         buf(BDO[127], do_reg[127]);


         bufif1(DO[0], BDO[0], 1'b1);
         bufif1(DO[1], BDO[1], 1'b1);
         bufif1(DO[2], BDO[2], 1'b1);
         bufif1(DO[3], BDO[3], 1'b1);
         bufif1(DO[4], BDO[4], 1'b1);
         bufif1(DO[5], BDO[5], 1'b1);
         bufif1(DO[6], BDO[6], 1'b1);
         bufif1(DO[7], BDO[7], 1'b1);
         bufif1(DO[8], BDO[8], 1'b1);
         bufif1(DO[9], BDO[9], 1'b1);
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
         bufif1(DO[21], BDO[21], 1'b1);
         bufif1(DO[22], BDO[22], 1'b1);
         bufif1(DO[23], BDO[23], 1'b1);
         bufif1(DO[24], BDO[24], 1'b1);
         bufif1(DO[25], BDO[25], 1'b1);
         bufif1(DO[26], BDO[26], 1'b1);
         bufif1(DO[27], BDO[27], 1'b1);
         bufif1(DO[28], BDO[28], 1'b1);
         bufif1(DO[29], BDO[29], 1'b1);
         bufif1(DO[30], BDO[30], 1'b1);
         bufif1(DO[31], BDO[31], 1'b1);
         bufif1(DO[32], BDO[32], 1'b1);
         bufif1(DO[33], BDO[33], 1'b1);
         bufif1(DO[34], BDO[34], 1'b1);
         bufif1(DO[35], BDO[35], 1'b1);
         bufif1(DO[36], BDO[36], 1'b1);
         bufif1(DO[37], BDO[37], 1'b1);
         bufif1(DO[38], BDO[38], 1'b1);
         bufif1(DO[39], BDO[39], 1'b1);
         bufif1(DO[40], BDO[40], 1'b1);
         bufif1(DO[41], BDO[41], 1'b1);
         bufif1(DO[42], BDO[42], 1'b1);
         bufif1(DO[43], BDO[43], 1'b1);
         bufif1(DO[44], BDO[44], 1'b1);
         bufif1(DO[45], BDO[45], 1'b1);
         bufif1(DO[46], BDO[46], 1'b1);
         bufif1(DO[47], BDO[47], 1'b1);
         bufif1(DO[48], BDO[48], 1'b1);
         bufif1(DO[49], BDO[49], 1'b1);
         bufif1(DO[50], BDO[50], 1'b1);
         bufif1(DO[51], BDO[51], 1'b1);
         bufif1(DO[52], BDO[52], 1'b1);
         bufif1(DO[53], BDO[53], 1'b1);
         bufif1(DO[54], BDO[54], 1'b1);
         bufif1(DO[55], BDO[55], 1'b1);
         bufif1(DO[56], BDO[56], 1'b1);
         bufif1(DO[57], BDO[57], 1'b1);
         bufif1(DO[58], BDO[58], 1'b1);
         bufif1(DO[59], BDO[59], 1'b1);
         bufif1(DO[60], BDO[60], 1'b1);
         bufif1(DO[61], BDO[61], 1'b1);
         bufif1(DO[62], BDO[62], 1'b1);
         bufif1(DO[63], BDO[63], 1'b1);
         bufif1(DO[64], BDO[64], 1'b1);
         bufif1(DO[65], BDO[65], 1'b1);
         bufif1(DO[66], BDO[66], 1'b1);
         bufif1(DO[67], BDO[67], 1'b1);
         bufif1(DO[68], BDO[68], 1'b1);
         bufif1(DO[69], BDO[69], 1'b1);
         bufif1(DO[70], BDO[70], 1'b1);
         bufif1(DO[71], BDO[71], 1'b1);
         bufif1(DO[72], BDO[72], 1'b1);
         bufif1(DO[73], BDO[73], 1'b1);
         bufif1(DO[74], BDO[74], 1'b1);
         bufif1(DO[75], BDO[75], 1'b1);
         bufif1(DO[76], BDO[76], 1'b1);
         bufif1(DO[77], BDO[77], 1'b1);
         bufif1(DO[78], BDO[78], 1'b1);
         bufif1(DO[79], BDO[79], 1'b1);
         bufif1(DO[80], BDO[80], 1'b1);
         bufif1(DO[81], BDO[81], 1'b1);
         bufif1(DO[82], BDO[82], 1'b1);
         bufif1(DO[83], BDO[83], 1'b1);
         bufif1(DO[84], BDO[84], 1'b1);
         bufif1(DO[85], BDO[85], 1'b1);
         bufif1(DO[86], BDO[86], 1'b1);
         bufif1(DO[87], BDO[87], 1'b1);
         bufif1(DO[88], BDO[88], 1'b1);
         bufif1(DO[89], BDO[89], 1'b1);
         bufif1(DO[90], BDO[90], 1'b1);
         bufif1(DO[91], BDO[91], 1'b1);
         bufif1(DO[92], BDO[92], 1'b1);
         bufif1(DO[93], BDO[93], 1'b1);
         bufif1(DO[94], BDO[94], 1'b1);
         bufif1(DO[95], BDO[95], 1'b1);
         bufif1(DO[96], BDO[96], 1'b1);
         bufif1(DO[97], BDO[97], 1'b1);
         bufif1(DO[98], BDO[98], 1'b1);
         bufif1(DO[99], BDO[99], 1'b1);
         bufif1(DO[100], BDO[100], 1'b1);
         bufif1(DO[101], BDO[101], 1'b1);
         bufif1(DO[102], BDO[102], 1'b1);
         bufif1(DO[103], BDO[103], 1'b1);
         bufif1(DO[104], BDO[104], 1'b1);
         bufif1(DO[105], BDO[105], 1'b1);
         bufif1(DO[106], BDO[106], 1'b1);
         bufif1(DO[107], BDO[107], 1'b1);
         bufif1(DO[108], BDO[108], 1'b1);
         bufif1(DO[109], BDO[109], 1'b1);
         bufif1(DO[110], BDO[110], 1'b1);
         bufif1(DO[111], BDO[111], 1'b1);
         bufif1(DO[112], BDO[112], 1'b1);
         bufif1(DO[113], BDO[113], 1'b1);
         bufif1(DO[114], BDO[114], 1'b1);
         bufif1(DO[115], BDO[115], 1'b1);
         bufif1(DO[116], BDO[116], 1'b1);
         bufif1(DO[117], BDO[117], 1'b1);
         bufif1(DO[118], BDO[118], 1'b1);
         bufif1(DO[119], BDO[119], 1'b1);
         bufif1(DO[120], BDO[120], 1'b1);
         bufif1(DO[121], BDO[121], 1'b1);
         bufif1(DO[122], BDO[122], 1'b1);
         bufif1(DO[123], BDO[123], 1'b1);
         bufif1(DO[124], BDO[124], 1'b1);
         bufif1(DO[125], BDO[125], 1'b1);
         bufif1(DO[126], BDO[126], 1'b1);
         bufif1(DO[127], BDO[127], 1'b1);


         
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
             for(i=0; i<(16384); i=i+1)
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
                  $setuphold(posedge CLK, posedge DIN[8], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[9], tDS, tDH);
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
                  $setuphold(posedge CLK, posedge DIN[21], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[22], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[23], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[24], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[25], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[26], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[27], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[28], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[29], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[30], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[31], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[32], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[33], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[34], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[35], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[36], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[37], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[38], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[39], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[40], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[41], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[42], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[43], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[44], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[45], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[46], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[47], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[48], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[49], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[50], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[51], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[52], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[53], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[54], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[55], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[56], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[57], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[58], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[59], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[60], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[61], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[62], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[63], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[64], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[65], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[66], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[67], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[68], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[69], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[70], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[71], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[72], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[73], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[74], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[75], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[76], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[77], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[78], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[79], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[80], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[81], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[82], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[83], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[84], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[85], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[86], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[87], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[88], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[89], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[90], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[91], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[92], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[93], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[94], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[95], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[96], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[97], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[98], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[99], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[100], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[101], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[102], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[103], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[104], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[105], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[106], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[107], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[108], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[109], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[110], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[111], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[112], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[113], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[114], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[115], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[116], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[117], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[118], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[119], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[120], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[121], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[122], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[123], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[124], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[125], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[126], tDS, tDH);
                  $setuphold(posedge CLK, posedge DIN[127], tDS, tDH);

                  
                  
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
                   $setuphold(posedge CLK, posedge RA[8], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge RA[9], tDS, tDH, FLAG_X);
                   
                   
                   $setuphold(posedge CLK, posedge CA[0], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge CA[1], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge CA[2], tDS, tDH, FLAG_X);
                   $setuphold(posedge CLK, posedge CA[3], tDS, tDH, FLAG_X);

                   
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
                  $setuphold(posedge CLK, negedge DIN[8], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[9], tDS, tDH);
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
                  $setuphold(posedge CLK, negedge DIN[21], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[22], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[23], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[24], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[25], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[26], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[27], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[28], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[29], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[30], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[31], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[32], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[33], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[34], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[35], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[36], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[37], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[38], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[39], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[40], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[41], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[42], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[43], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[44], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[45], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[46], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[47], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[48], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[49], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[50], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[51], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[52], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[53], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[54], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[55], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[56], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[57], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[58], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[59], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[60], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[61], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[62], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[63], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[64], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[65], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[66], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[67], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[68], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[69], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[70], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[71], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[72], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[73], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[74], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[75], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[76], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[77], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[78], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[79], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[80], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[81], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[82], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[83], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[84], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[85], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[86], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[87], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[88], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[89], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[90], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[91], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[92], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[93], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[94], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[95], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[96], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[97], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[98], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[99], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[100], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[101], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[102], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[103], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[104], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[105], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[106], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[107], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[108], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[109], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[110], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[111], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[112], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[113], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[114], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[115], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[116], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[117], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[118], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[119], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[120], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[121], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[122], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[123], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[124], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[125], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[126], tDS, tDH);
                  $setuphold(posedge CLK, negedge DIN[127], tDS, tDH);




                  $setuphold(posedge CLK, negedge RA[0], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[1], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[2], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[3], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[4], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[5], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[6], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[7], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[8], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge RA[9], tDS, tDH, FLAG_X); 
                  
                  $setuphold(posedge CLK, negedge CA[0], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge CA[1], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge CA[2], tDS, tDH, FLAG_X);
                  $setuphold(posedge CLK, negedge CA[3], tDS, tDH, FLAG_X);

              endspecify
              
      endmodule
