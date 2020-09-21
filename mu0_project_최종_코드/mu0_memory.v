module mu0_memory(clk, rst, mem_rq, rnw, addr, databus);

	//
	// Mu0 Memory
	// Digital System Design 2019-2 
	// Electronic Engineering IT
	// 20160458, 20160521, 20170629
	//

	parameter ADDR = 12;
	parameter DATA = 16 ; 
	parameter MEM = 32;

	input clk, rst, mem_rq, rnw;
	input [ADDR-1 : 0] addr;
	inout [DATA -1 :0] databus;

	//memory 
   	reg [DATA-1:0] memory[MEM-1:0]; //left - data size , right - array size

	//rnw=1 => read
	//rnw=0 => write

 	 assign databus = (mem_rq && rnw) ? memory[addr] : 16'bz;


  	 always@(posedge clk) begin
   
    		if(mem_rq) begin
			if(!rnw) memory[addr] <= databus;
			else  memory[addr] <= memory[addr];
		end
     		else memory[addr] <= memory[addr];
   	end

endmodule

