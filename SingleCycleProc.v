// Texas A&M University          //
// cpsc350 Computer Architecture //
// $Id: SingleCycleProc.v,v 1.1 2002/04/08 23:16:14 miket Exp miket $ //

// instruction opcode
//R-Type (Opcode 000000)
`define OPCODE_ADD     6'b000000
`define OPCODE_SUB     6'b000000
`define OPCODE_ADDU    6'b000000
`define OPCODE_SUBU    6'b000000
`define OPCODE_AND     6'b000000
`define OPCODE_OR      6'b000000
`define OPCODE_SLL     6'b000000
`define OPCODE_SRA     6'b000000
`define OPCODE_SRL     6'b000000
`define OPCODE_SLT     6'b000000
`define OPCODE_SLTU    6'b000000
`define OPCODE_XOR     6'b000000
`define OPCODE_JR      6'b000000
//I-Type (All opcodes except 000000, 00001x, and 0100xx)
`define OPCODE_ADDI    6'b001000
`define OPCODE_ADDIU   6'b001001
`define OPCODE_ANDI    6'b001100
`define OPCODE_BEQ     6'b000100
`define OPCODE_BNE     6'b000101
`define OPCODE_BLEZ    6'b000110
`define OPCODE_BLTZ    6'b000001
`define OPCODE_ORI     6'b001101
`define OPCODE_XORI    6'b001110
`define OPCODE_NOP     6'b110110
`define OPCODE_LUI     6'b001111
`define OPCODE_SLTI    6'b001010
`define OPCODE_SLTIU   6'b001011
`define OPCODE_LB      6'b100000
`define OPCODE_LW      6'b100011
`define OPCODE_SB      6'b101000
`define OPCODE_SW      6'b101011
// J-Type (Opcode 00001x)
`define OPCODE_J       6'b000010
`define OPCODE_JAL     6'b000011
//ALU op for secondary ALUs
`define ADD  4'b0111 // 2's compl add

// Top Level Architecture Model //

`include "IdealMemory.v"

/*-------------------------- CPU -------------------------------
 * This module implements a single-cycle
 * CPU similar to that described in the text book 
 * (for example, see Figure 5.19). 
 *
 */

//
// Input Ports
// -----------
// clock - the system clock (m555 timer).
//
// reset - when asserted by the test module, forces the processor to 
//         perform a "reset" operation.  (note: to reset the processor
//         the reset input must be held asserted across a 
//         negative clock edge).
//   
//         During a reset, the processor loads an externally supplied
//         value into the program counter (see startPC below).
//   
// startPC - during a reset, becomes the new contents of the program counter
//	     (starting address of test program).
// 
// Output Port
// -----------
// dmemOut - contains the data word read out from data memory. This is used
//           by the test module to verify the correctness of program 
//           execution.
//-------------------------------------------------------------------------

module SingleCycleProc(CLK, Reset_L, startPC, dmemOut);
   input 	Reset_L, CLK;
   input [31:0] startPC;
   output [31:0] dmemOut;

wire [31:0] PCwire,PCnext,PCbranch;
wire [31:0] IR;
wire [3:0] ALUOp;
wire [3:0] ALUfunc;
wire [4:0] Memaddr,shAmt;
wire [31:0] Reg1, Reg2, Data,ALUdata,MEMdata,RFdata;
wire [31:0] Immed,shImmed,brAddr,jAddr,shjAddr,jumpAddr,beAddr;
wire [31:0] ALUin, Result;
wire Zero,BEQ,ndZero,isBranch,ndZeroNotReset,isBrOrJ;
wire RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, Jump, SignExtend;
wire Overflow,Carry_out, void1, void2, void3;
wire ALUSrc1,ALUSrc2;

//
// INSERT YOUR CPU MODULES HERE
//
 
PC PC1(PCwire, PCwire, Reset_L, startPC, CLK,isBranch,brAddr,Jump);
//MUX32_2to1 resetMUX(PCwire,PCnext,Reset_L,PCwire);
InstrMem IM1(PCwire, IR);
ControlUnit Ctrl(RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, Jump, SignExtend, ALUOp, IR[31:26],BEQ);
ALUControl ALUctrl(ALUfunc, ALUOp, IR[5:0]);
//assign ALUSrc=ALUSrc1|ALUSrc2;
MUX5_2to1 MUX1(IR[20:16], IR[15:11], RegDst, Memaddr);
SignExtend SE(IR[15:0], Immed);
registerFile RF(Reg1, Reg2, Data, IR[25:21], IR[20:16], Memaddr, RegWrite, CLK, Reset_L);
DataMem DM(ALUdata, CLK, MemRead, MemWrite, Reg2, MEMdata);
MUX32_2to1 MUX2(Reg2, Immed, ALUSrc, ALUin);
MUX32_2to1 MUX3(ALUdata, MEMdata, MemtoReg, Data);
MUX_2to1 MUXOFTHEGODS(~Zero,Zero,BEQ,ndZero);
assign isBranch=ndZero&Branch;
assign jAddr=IR[25:0];
LSHIFT2 myshiftson(Immed, shImmed);
LSHIFT2 jumpShift(jAddr,shjAddr);
assign jumpAddr[31:28]=PCwire[31:28];
assign jumpAddr[27:0]=shjAddr[27:0];
//assign jprocAddr=jumpAddr-4;
assign beAddr=shImmed+PCwire;
assign shAmt=IR[10:6];
//assign isBrOrJ=Jump|isBranch;
//assign ndZeroNotReset=ndZero&(~Reset_L);
MUX32_2to1 jumpMux(beAddr,jumpAddr,Jump,brAddr);
ALU_behav ALU(Reg1, ALUin, ALUfunc, ALUdata, Overflow, 1'b0, Carry_out, Zero,shAmt);

//
// Debugging threads that you may find helpful (you may have
// to change the variable names).
//
   /*  Monitor changes in the program counter
   always @(PC)
     #10 $display($time," PC=%d Instr: op=%d rs=%d rt=%d rd=%d imm16=%d funct=%d",
	PC,Instr[31:26],Instr[25:21],Instr[20:16],Instr[15:11],Instr[15:0],Instr[5:0]);
   */

   /*   Monitors memory writes
   always @(MemWrite)
	begin
	#1 $display($time," MemWrite=%b clock=%d addr=%d data=%d", 
	            MemWrite, clock, dmemaddr, rportb);
	end
   */
   
endmodule // CPU


/*module m555 (CLK);
   parameter StartTime = 0, Ton = 50, Toff = 50, Tcc = Ton+Toff; // 
 
   output CLK;
   reg 	  CLK;
   
   initial begin
      #StartTime CLK = 0;
   end
   
   // The following is correct if clock starts at LOW level at StartTime //
   always begin
      #Toff CLK = ~CLK;
      #Ton CLK = ~CLK;
   end
endmodule
*/

module m555(clock);
    parameter InitDelay = 10, Ton = 50, Toff = 50;
    output clock;
    reg clock;
 
    initial begin
        #InitDelay clock = 1;
    end
 
    always begin
        #Ton clock = ~clock;
        #Toff clock = ~clock;
    end
endmodule
   
module testCPU(Reset_L, startPC, testData);
   input [31:0] testData;
   output 	Reset_L;
   output [31:0] startPC;
   reg 		 Reset_L;
   reg [31:0] 	 startPC;
   
   initial begin
      // Your program 1
      Reset_L = 1;  startPC = 0 * 4;
      #101 // insures reset is asserted across negative clock edge
	  Reset_L = 0; 
      #15000; // allow enough time for program 1 to run to completion
      Reset_L = 0;
      
      // Your program 2
     // Reset_L = 1; startPC = 15 * 4;
      //#101
      //Reset_L = 0;
      //#10000;

         //         nop                     #
      #1 $display ("Program 2: Result: %d", testData);
      
      // etc.
      // Run other programs here
      
      
      $finish;
   end
endmodule // testCPU

module TopProcessor;
   wire reset, CLK, Reset_L;
   wire [31:0] startPC;
   wire [31:0] testData;
   
   m555 system_clock(CLK);
   SingleCycleProc SSProc(CLK, Reset_L, startPC, testData);
   testCPU tcpu(Reset_L, startPC, testData); 

endmodule // TopProcessor
