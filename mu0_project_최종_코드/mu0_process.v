module mu0_process(clk, rst, mem_rq, rnw, a_out, databus);

	//
	// Extended Mu0 Process
	// Digital System Design 2019-2 
	// Electronic Engineering IT
	// 20160458, 20160521, 20170629
	//

	parameter ADDR = 12;
	parameter DATA = 16 ; 

	parameter EX = 1'b0, FT=1'b1;
	parameter LDA=4'b0000, STO=4'b0001, ADD=4'b0010, SUB=4'b0011, JMP=4'b0100, JGE=4'b0101, JNE=4'b0110, STP=4'b0111;
	//additional instruction
	parameter LDSA=4'b1000, LDN=4'b1001, SUM=4'b1010, JLT=4'b1011, STS=4'b1100;

	input clk, rst;
	output reg mem_rq, rnw;
	output reg[ADDR-1 : 0] a_out; //address
	inout [DATA -1 :0] databus;

	reg[DATA-1 : 0] alu, acc, b_out, ir;
	reg[ADDR-1 : 0] pc;
	reg ps, ns;
	reg[3:0] opcode; //wire
	reg[2:0] alu_fs;
	reg a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe;
	reg acc_msb, acc_z;

	reg[DATA-1:0] s,n,sum;
	reg s_en , n_en, inc_en, sum_rst, sum_en, sum_oe;
	wire comp_sn;

	assign databus = acc_oe ? acc : 16'bz;
	assign databus = sum_oe ? sum : 16'bz;
	assign comp_sn = (s == n); // 1 if all s bit equal n bit


	always @(posedge clk, posedge rst) begin

		if(rst) ps<=EX;
		else ps<=ns;

	end

	always @(*) begin

		case(ps)
			EX : begin
				casex(opcode)
					4'b00xx : ns<=FT; //LDA~SUB
					4'b01xx : ns<=EX; //JMP, STP
					4'b100x : ns<=FT; //LDSA, LDN
					4'b1010 : ns<=EX; //SUM => change to EX
					4'b1011 : ns<=EX; //JLT
					4'b1100 : ns<=FT; //STS
					default : ns<=EX;
				endcase
			end

			FT : ns<=EX;
			default : ns<=EX;
		endcase

	end

	//11bit
	always @(*) begin
		
		case(ps)
			EX : begin
				case(opcode)
					LDA : {a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b1_1_1_0_0_0_011_1_1;
					STO : {a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b1_x_0_0_0_1_xxx_1_0;
					ADD : {a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b1_1_1_0_0_0_001_1_1;
					SUB : {a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b1_1_1_0_0_0_010_1_1;
					
					//JMP
					JMP : {a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b1_0_0_1_1_0_100_1_1;
					JGE : begin
						if(acc_msb) a_sel<=0;
						else a_sel<=1;
						{b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 10'b0_0_1_1_0_100_1_1;
						end
					JNE : begin
						if(acc_z) a_sel<=0;
						else  a_sel<=1;
						{b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 10'b0_0_1_1_0_100_1_1;
						end
					
					//STP
					STP : {a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b1_x_0_0_0_0_xxx_0_1;

					//additional
					LDSA : {a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b1_1_0_0_0_0_011_1_1;
					LDN : {a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b1_1_0_0_0_0_011_1_1;
					SUM :  begin
						if(comp_sn) a_sel<=0; //NEXT
						else  a_sel<=1; //JMP
						{b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 10'b0_0_1_1_0_100_1_1;
						end	 
					
					JLT : begin
						if(comp_sn) a_sel<=0; //NEXT
						else  a_sel<=1; //JMP
						{b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 10'b0_0_1_1_0_100_1_1;
						end	
					
					STS : {a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b1_x_0_0_0_0_xxx_1_0;	
					//reset 
					default : {a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b0_0_1_1_1_0_000_1_1;
				endcase
			end

			FT : begin
				{a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b0_0_0_1_1_0_100_1_1;
			end
			default : {a_sel, b_sel, acc_ce, pc_ce, ir_ce, acc_oe, alu_fs, mem_rq, rnw} <= 11'b0_0_1_1_1_0_000_1_1; //equal reset 
		endcase
		
	end

	//additional 6bit
	always @(*) begin
		
		case(ps)
			EX : begin
				case(opcode)
					LDSA : {s_en , n_en, inc_en, sum_rst, sum_en, sum_oe}<=6'b100100;
					LDN : {s_en , n_en, inc_en,sum_rst, sum_en, sum_oe}<=6'b010000;
					SUM : {s_en , n_en, inc_en,sum_rst, sum_en, sum_oe}<=6'b001010;
					STS : {s_en , n_en, inc_en,sum_rst, sum_en, sum_oe}<=6'b000001;
					default : {s_en , n_en, inc_en,sum_rst, sum_en, sum_oe}<=6'b000000; //include JLT
				endcase
			end

			FT : begin
				{s_en , n_en, inc_en,sum_rst, sum_en, sum_oe}<=6'b000000;
			end
			default : {s_en , n_en, inc_en,sum_rst, sum_en, sum_oe}<=6'b000000;
		endcase
		
	end

	//IR
	always @ (posedge clk) begin
		
		if(rst)	ir<=0;
		else begin
			if(ir_ce) begin ir<=databus; opcode<=databus[15:12];end
			else ir<=ir;
		end

	end

	//PC
	always @ (posedge clk) begin
		if(rst) pc<=0;
		else begin
			if(pc_ce) pc<=alu[11:0];
			else pc<=pc;
		end
	end

	//ACC
	always @ (posedge clk) begin
		if(rst) acc<=0;
		else begin
			if(acc_ce) begin
				acc<=alu;
				acc_msb<=alu[15];

				if(alu==0) acc_z<=1;
				else acc_z<=0;
			end
			else acc<=acc;
		end
	end	

	//LDSA
	always @ (posedge clk) begin
		if(rst) s<=0;
		else begin
			if(!inc_en) begin
				if(s_en) begin
					s<=alu;
				end
				else s<=s;
			end
			else s<=s+16'h0001;
		end
	end	

	//SUM
	always @ (posedge clk) begin
		if(sum_rst) sum<=0;
		else begin
			if(sum_en) sum<=sum+s;
			else sum<=sum;
		end
	end
	
	//LDN
	always @ (posedge clk) begin
		if(rst) n<=0;
		else begin
			if(n_en) begin
				n<=alu;
			end
			else n<=n;
		end
	end

	//ALU
	always @ (*) begin
		case(alu_fs)
			3'b000 : alu<=0; //0
			3'b001 : alu<=acc+b_out; //A+B
			3'b010 : alu<=acc-b_out; //A-B
			3'b011 : alu<=b_out; //B
			3'b100 : alu<=b_out+16'b0000_0000_0000_0001; //B+1
			default : alu<=0;
		endcase
	end

	//A-MUX
	always @ (*) begin
		if(a_sel) a_out<=ir[11:0];
		else a_out<=pc;
	end

	//B-MUX
	always @ (*) begin
		if(b_sel) b_out<=databus;
		else b_out<={4'b0000, a_out}; //later test except 0000
	end

endmodule
