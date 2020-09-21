`timescale 1ns/1ns
module mu0_tb;

	//
	// Extended Mu0 Process Testbench
	// Digital System Design 2019-2 
	// Electronic Engineering IT
	// 20160458, 20160521, 20170629
	//


	//opcode
	parameter LDA = 4'b0000, STO = 4'b0001, ADD = 4'b0010, SUB = 4'b0011;
	parameter JMP=4'b0100, JGE = 4'b0101, JNE = 4'b0110, STP = 16'b0111_0000_0000_0000;

	parameter LDSA=4'b1000, LDN=4'b1001, SUM=4'b1010, JLT=4'b1011, STS=4'b1100;

	//S, N, RESULT, I(i), V1(v1)	
	parameter S = 12'h010, N=12'h011, RESULT=12'h012;

	//LOOP1 address
	parameter LOOP1=12'h003; //3

	parameter ADDR =12;
	parameter DATA =16;

	reg clk, rst;
	wire mem_rq, rnw;
	wire [ADDR-1:0]addr;
	wire [DATA-1:0]databus;

	integer cycle; //cycle


	//memory(clk, rst, mem_rq, rnw, addr, databus);
	mu0_memory MU0_MEM_UUT(.clk(clk), .rst(rst), .mem_rq(mem_rq), .rnw(rnw), .addr(addr), .databus(databus));
	//mu0_process(clk, rst, mem_rq, rnw, a_out, databus);
	mu0_process MU0_FSM_UUT(.clk(clk),.rst(rst), .mem_rq(mem_rq), .rnw(rnw), .a_out(addr), .databus(databus));

	initial begin
 		clk=0; rst=1; cycle=0;
		#200 rst=0;
	end

	initial begin  
		force databus =  {LDSA, S}; force addr=0; force rnw=0; force mem_rq=1;
		#10 release databus; release addr; 
		force databus =  {LDN, N}; force addr=1;
		#10 release databus; release addr;
		force databus =  {JLT, LOOP1}; force addr=2;
		#10 release databus; release addr;

		//LOOP1
		force databus =  {SUM, LOOP1}; force addr=3;
		#10 release databus; release addr;
		force databus =  {STS, RESULT}; force addr=4;
		#10 release databus; release addr;
		force databus =  STP; force addr=5;
		#10 release databus; release addr;

		//S, N, data input
		force databus = 16'h0001; force addr=S;
		#10 release databus; release addr;
		force databus = 16'h000A; force addr=N;
		#10 release databus; release addr; release rnw; release mem_rq; 
	end

	always begin #5 clk = ~clk; end

	always @(posedge clk) begin
		if(!rst) cycle=cycle+1;
		else cycle=cycle;
	end
	

endmodule

