/*

Copyright (C) 2012 Muralidaran Vijayaraghavan <vmurali@csail.mit.edu>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/


import Types::*;
import ProcTypes::*;
import MemTypes::*;
import RFile::*;
import IMemory::*;
import DMemory::*;
import Decode::*;
import Exec::*;
import Cop::*;
import Fifo::*;
import AddrPred::*;
import Scoreboard::*;

typedef struct {
  Addr pc;
  Addr ppc;
  Data inst;
  Bool epoch;
} Fetch2Execute deriving (Bits, Eq);

typedef struct {
  Addr pc;
  Addr ppc;
  Data inst;
  Bool epoch;
  DecodedInst dInst;
  Data rVal1;
  Data rVal2;
} MyFetch2Execute deriving (Bits, Eq);

typedef struct {
  Data inst;
  Maybe#(FullIndx) dst;
  Data data;
} MyExecute2WriteBack deriving (Bits, Eq);


interface Proc;
   method ActionValue#(Tuple2#(RIndx, Data)) cpuToHost;
   method Action hostToCpu(Bit#(32) startpc);
endinterface

(* synthesize *)
module [Module] mkProc(Proc);
  Reg#(Addr) pc <- mkRegU;
  RFile      rf <- mkRFile;
  IMemory  iMem <- mkIMemory;
  DMemory  dMem <- mkDMemory;
  Cop       cop <- mkCop;
  AddrPred pcPred <- mkBtb;

  //Fifo#(1, Fetch2Execute) ir <- mkPipelineFifo;
  Fifo#(2, MyFetch2Execute) ifr <- mkPipelineFifo;
  Fifo#(2, MyExecute2WriteBack) iwr <- mkPipelineFifo;
  // Fifo#(1, MyExecute2WriteBack) dataBypass <- mkBypassFifo;
  Fifo#(1, Redirect) execRedirect <- mkBypassFifo;
  //Fifo#(2, Redirect)   execRedirect <- mkCFFifo;

  Scoreboard#(2) myScoreboard <- mkCFScoreboard;

  //This design uses two epoch registers, one for each stage of the pipeline. Execute sets the eEpoch and discards any instruction that doesn't match it. It passes the information about change of epoch to fetch stage indirectly by passing a valid execRedirect using a Fifo. Fetch changes fEpoch everytime it gets a execRedirect and tags every instruction with its epoch

  Reg#(Bool) fEpoch <- mkReg(False);
  Reg#(Bool) eEpoch <- mkReg(False);

  rule doFetch(cop.started);
    let inst = iMem.req(pc);

    $display("Fetch: pc: %h inst: (%h) expanded: ", pc, inst, showInst(inst));
    let dInst = decode(inst);
    let src_writing = myScoreboard.search2(dInst.src1) || myScoreboard.search2(dInst.src2);

    // if(dataBypass.notEmpty)
    // begin
    //   dataBypass.deq;
    // end

    // dequeue the incoming redirect and update the predictor whether it's a mispredict or not
    if(execRedirect.notEmpty)
    begin
      execRedirect.deq;
      pcPred.update(execRedirect.first);
    end
    // change pc and the fetch's copy of the epoch only on a mispredict
    if(execRedirect.notEmpty && execRedirect.first.mispredict)
    begin
      fEpoch <= !fEpoch;
      pc <= execRedirect.first.nextPc;
    end
    // fetch the new instruction on a non mispredict
    else
    begin
      
      if(!src_writing)//有数据冲突时阻塞
        begin
          let ppc = pcPred.predPc(pc);
          pc <= ppc;
          let rVal1 = rf.rd1(validRegValue(dInst.src1));
          let rVal2 = rf.rd2(validRegValue(dInst.src2));
          $display("enq: pc: %h inst: (%h) , epoch: %h, expanded: ", pc, inst, fEpoch, showInst(inst));
          ifr.enq(MyFetch2Execute{pc:pc , ppc:ppc , inst:inst , epoch:fEpoch , dInst:dInst , rVal1:rVal1 , rVal2: rVal2});
          if(isValid(dInst.dst))
            myScoreboard.insert(dInst.dst);
          $display("enq done: pc: %h inst: (%h) expanded: ", pc, inst, showInst(inst));
        end
      else
      begin
        // $display("stucked!");
      end
      // else
      //   begin
      //     if( (!myScoreboard.search2(dInst.src2)) && dInst.src1==dataBypass.first.dst )
      //       begin
      //         $display("get bypass!");
      //         pc <= ppc;
      //         ifr.enq(MyFetch2Execute{pc:pc , ppc:ppc , inst:inst , epoch:fEpoch , dInst:dInst , rVal1:dataBypass.first.data , rVal2: rVal2});
      //         myScoreboard.insert(dInst.dst);
      //       end
      //     else if( (!myScoreboard.search2(dInst.src1)) && dInst.src2==dataBypass.first.dst )
      //       begin
      //         $display("get bypass!");
      //         pc <= ppc;
      //         ifr.enq(MyFetch2Execute{pc:pc , ppc:ppc , inst:inst , epoch:fEpoch , dInst:dInst , rVal1: rVal1, rVal2: dataBypass.first.data});
      //         myScoreboard.insert(dInst.dst);
      //       end
      //   end
    end
    
  endrule

  rule doExecute;
    let inst  = ifr.first.inst;
    let pc    = ifr.first.pc;
    let ppc   = ifr.first.ppc;
    let epoch = ifr.first.epoch;
    let dInst = ifr.first.dInst;
    let rVal1 = ifr.first.rVal1;
    let rVal2 = ifr.first.rVal2;
    let copVal = cop.rd(validRegValue(dInst.src1));
    let eInst = exec(dInst, rVal1, rVal2, pc, ppc, copVal);
    $display("Execute get: pc: %h inst: (%h), epoch: %h, expanded: ", pc, inst, eEpoch, showInst(inst));

    // Proceed only if the epochs match
    if(epoch == eEpoch)
    begin
      $display("Execute: pc: %h inst: (%h) expanded: ", pc, inst, showInst(inst));
  
      if(eInst.iType == Unsupported)
      begin
        $fwrite(stderr, "Executing unsupported instruction at pc: %x. Exiting\n", pc);
        $finish;
      end

      if(eInst.iType == Ld)
      begin
        let data <- dMem.req(MemReq{op: Ld, addr: eInst.addr, byteEn: ?, data: ?});
        eInst.data = gatherLoad(eInst.addr, eInst.byteEn, eInst.unsignedLd, data);
      end
      else if(eInst.iType == St)
      begin
        match {.byteEn, .data} = scatterStore(eInst.addr, eInst.byteEn, eInst.data);
        let d <- dMem.req(MemReq{op: St, addr: eInst.addr, byteEn: byteEn, data: data});
      end

      if (isValid(eInst.dst) && validValue(eInst.dst).regType == Normal)
        begin
          iwr.enq(MyExecute2WriteBack{inst:inst, dst:eInst.dst , data:eInst.data});
        end
      // Send the branch resolution to fetch stage, irrespective of whether it's mispredicted or not
       // TBD: put code here that does what the comment immediately above says
      if(eInst.brTaken)
        begin
          execRedirect.enq(Redirect{nextPc: eInst.addr,mispredict:eInst.mispredict});
        end
      // On a branch mispredict, change the epoch, to throw away wrong path instructions
       // TBD: put code here that does what the comment immediately above says
      if(eInst.brTaken && eInst.mispredict)
        begin
          eEpoch <= !eEpoch;
        end 
      cop.wr(eInst.dst, eInst.data);
      if (isValid(eInst.dst) && validValue(eInst.dst).regType != Normal)
        myScoreboard.remove;
      $display("Execute done: pc: %h inst: (%h) expanded: ", pc, inst, showInst(inst));
    end
    else
    begin
      if(isValid(eInst.dst))
        myScoreboard.remove;
    end
    
    ifr.deq();
  endrule
  
  rule doWriteBack;
    let inst = iwr.first.inst;
    let dst = iwr.first.dst;
    let data = iwr.first.data;
    // dataBypass.enq(MyExecute2WriteBack{dst:iwr.first.dst , data:iwr.first.data});
    rf.wr(validRegValue(dst), data);
    myScoreboard.remove;
    iwr.deq();
    $display("write done: dst: %h inst: (%h) expanded: ", dst, inst, showInst(inst));
  endrule

  method ActionValue#(Tuple2#(RIndx, Data)) cpuToHost;
    let ret <- cop.cpuToHost;
    return ret;
  endmethod

  method Action hostToCpu(Bit#(32) startpc) if (!cop.started);
    cop.start;
    pc <= startpc;
  endmethod
endmodule

//comments
// This code also works with either (or both) Fifo replaced with CFFifo
// If both Fifos are CFFifo, then fetch and execute are also conflict free
// If either Fifo is not CFFifo, then fetch and execute can be scheduled concurrently, with execute<fetch
// If BypassFifo is used for pc-redirect, then the processor is slightly faster
// This is by far the most robust solution as we will see later
