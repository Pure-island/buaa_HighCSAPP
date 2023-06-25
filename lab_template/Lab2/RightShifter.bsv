import RightShifterTypes::*;
import Gates::*;
import FIFO::*;

function Bit#(1) multiplexer1(Bit#(1) sel, Bit#(1) a, Bit#(1) b);
    // return orGate(andGate(a, sel),andGate(b, notGate(sel))); //写反了，和lab1不一样，太坑了
	return orGate(andGate(a, notGate(sel)),andGate(b, sel)); 
endfunction

function Bit#(32) multiplexer32(Bit#(1) sel, Bit#(32) a, Bit#(32) b);
	Bit#(32) res_vec = 0;
	for (Integer i = 0; i < 32; i = i+1)
	    begin
		res_vec[i] = multiplexer1(sel, a[i], b[i]);
	    end
	return res_vec; 
endfunction

function Bit#(n) multiplexerN(Bit#(1) sel, Bit#(n) a, Bit#(n) b);
	Bit#(n) res_vec = 0;
	for (Integer i = 0; i < valueof(n); i = i+1)
	    begin
		res_vec[i] = multiplexer1(sel, a[i], b[i]);
	    end
	return res_vec; 
endfunction

function Bit#(n) bitProvider(Bit#(1) sign, Integer num);
    Bit#(n) result = 0;
    for(Integer i = 0;i < num;i = i+1)
        begin
            result[i] = sign;
        end
    return result;
endfunction

module mkRightShifterPipelined (RightShifterPipelined);
    // FIFO#(Bit#(2)) c <- mkFIFO();
	FIFO#(Bit#(38)) entry <- mkFIFO();
	FIFO#(Bit#(38)) stage1_1bit <- mkFIFO();
	FIFO#(Bit#(38)) stage2_2bits <- mkFIFO();
	FIFO#(Bit#(38)) stage3_4bits <- mkFIFO();
	FIFO#(Bit#(38)) stage4_8bits <- mkFIFO();
	FIFO#(Bit#(38)) stage5_16bits <- mkFIFO();

    rule rule1 (True/*Guard*/);
	/* Write your code here */
		Bit#(32) result = entry.first()[31:0];
		Bit#(5) shamt = entry.first()[36:32];
		Bit#(1) sign = entry.first()[37];
		

		result = multiplexerN(shamt[0],result,{sign,result[31:1]});

		// $display("push into stage1", result);
		stage1_1bit.enq({sign,shamt,result});
		entry.deq();

    endrule

	rule rule2 (True/*Guard*/);
	/* Write your code here */
		Bit#(32) result = stage1_1bit.first()[31:0];
		Bit#(5) shamt = stage1_1bit.first()[36:32];
		Bit#(1) sign = stage1_1bit.first()[37];
		

		result = multiplexerN(shamt[1],result,{bitProvider(sign,2),result[31:2]});

		stage2_2bits.enq({sign,shamt,result});
		// $display("push into stage2", result);
		stage1_1bit.deq();
    endrule

	rule rule3 (True/*Guard*/);
	/* Write your code here */
		Bit#(32) result = stage2_2bits.first()[31:0];
		Bit#(5) shamt = stage2_2bits.first()[36:32];
		Bit#(1) sign = stage2_2bits.first()[37];
		

		result = multiplexerN(shamt[2],result,{bitProvider(sign,4),result[31:4]});

		stage3_4bits.enq({sign,shamt,result});
		// $display("push into stage3", result);
		stage2_2bits.deq();
    endrule

	rule rule4 (True/*Guard*/);
	/* Write your code here */
		Bit#(32) result = stage3_4bits.first()[31:0];
		Bit#(5) shamt = stage3_4bits.first()[36:32];
		Bit#(1) sign = stage3_4bits.first()[37];
		

		result = multiplexerN(shamt[3],result,{bitProvider(sign,8),result[31:8]});

		stage4_8bits.enq({sign,shamt,result});
		// $display("push into stage4", result);
		stage3_4bits.deq();
    endrule

	rule rule5 (True/*Guard*/);
	/* Write your code here */
		Bit#(32) result = stage4_8bits.first()[31:0];
		Bit#(5) shamt = stage4_8bits.first()[36:32];
		Bit#(1) sign = stage4_8bits.first()[37];
		

		result = multiplexerN(shamt[4],result,{bitProvider(sign,16),result[31:16]});

		stage5_16bits.enq({sign,shamt,result});
		// $display("push into stage5", result);
		stage4_8bits.deq();
    endrule

    method Action push(ShiftMode mode, Bit#(32) operand, Bit#(5) shamt);
	/* Write your code here */
		Bit#(1) sign = operand[31];
		if(mode == LogicalRightShift)
			begin
				sign = 1'b0;
			end
		// $display("push into entry", operand);
		entry.enq({sign,shamt,operand});
    endmethod
	
    method ActionValue#(Bit#(32)) pull();
	/* Write your code here */
		Bit#(32) result = stage5_16bits.first()[31:0];
		stage5_16bits.deq();
		return result;
    endmethod

endmodule

