import RightShifterTypes::*;
import Gates::*;

function Bit#(1) multiplexer1(Bit#(1) sel, Bit#(1) a, Bit#(1) b);
	// Part 1: Re-implement this function using the gates found in the Gates.bsv file
	// return (sel == 0)?a:b; 
    // 典型的二对一多路复用器布尔表达式：out = !sel && a || sel && b
    let a_and_nots = andGate(a,notGate(sel));
    let b_and_s = andGate(b,sel);
    return orGate(a_and_nots , b_and_s);
endfunction

function Bit#(32) multiplexer32(Bit#(1) sel, Bit#(32) a, Bit#(32) b);
	// Part 2: Re-implement this function using static elaboration (for-loop and multiplexer1)
	// return (sel == 0)?a:b; 
    Bit#(32)  aggregate = 0;
    for(Integer i = 0; i < 32; i = i+1)
        begin
            aggregate[i] = multiplexer1(sel, a[i], b[i]);
        end
    return aggregate;
endfunction

function Bit#(n) multiplexerN(Bit#(1) sel, Bit#(n) a, Bit#(n) b);
	// Part 3: Re-implement this function as a polymorphic function using static elaboration
	// return (sel == 0)?a:b;
    Bit#(n) aggregate = 0;
    for(Integer i = 0; i < valueof(n); i = i + 1)
        begin
            aggregate[i] = multiplexer1(sel, a[i], b[i]);
        end
    return aggregate;  
endfunction

function Bit#(n) bitProvider(Bit#(1) sign, Integer num);
    Bit#(n) result = 0;
    for(Integer i = 0;i < num;i = i+1)
        begin
            result[i] = sign;
        end
    return result;
endfunction


module mkRightShifter (RightShifter);
    method Bit#(32) shift(ShiftMode mode, Bit#(32) operand, Bit#(5) shamt);
	// Parts 4 and 5: Implement this function with the multiplexers you implemented
        Bit#(32) result = 0;
        Bit#(1) flag = operand[31];

        if (mode == LogicalRightShift ) begin
            flag = 0;
        end

        result = multiplexerN(shamt[0], operand, {bitProvider(flag, 1), operand[31:1]});
        result = multiplexerN(shamt[1], result, {bitProvider(flag, 2), result[31:2]});
        result = multiplexerN(shamt[2], result, {bitProvider(flag, 4), result[31:4]});
        result = multiplexerN(shamt[3], result, {bitProvider(flag, 8), result[31:8]});
        result = multiplexerN(shamt[4], result, {bitProvider(flag, 16), result[31:16]});

        return result;   
    endmethod
endmodule

