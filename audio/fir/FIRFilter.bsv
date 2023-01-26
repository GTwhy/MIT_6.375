
import FIFO::*;
import FixedPoint::*;
import Vector::*;

import AudioProcessorTypes::*;
import FilterCoefficients::*;
import Multiplier::*;

module mkFIRFilter (AudioProcessor);
    FIFO#(Sample) infifo <- mkFIFO();
    FIFO#(Sample) outfifo <- mkFIFO();
    Vector#(8, Reg#(Sample)) r <- replicateM(mkReg(0));
    Vector#(9, Multiplier) m <- replicateM(mkMultiplier());

    rule init_mul(True);
        infifo.deq();
        let sample = infifo.first();
        r[0] <= sample;
        for (Integer i = 0; i < 7; i = i+1) begin
            r[i+1] <= r[i];
        end
        m[0].putOperands(c[0], sample);
        for (Integer i = 0; i < 8; i = i+1) begin
            m[i+1].putOperands(c[i+1], r[i]);
        end
    endrule

    rule add_out(True);
        Vector#(9, FixedPoint#(16, 16)) res;
        res[0] <- m[0].getResult();
        for (Integer i = 1; i < 9; i = i+1) begin
            let x <- m[i].getResult();
            res[i] = res[i-1]+x;
        end
        outfifo.enq(fxptGetInt(res[8]));
    endrule

    method Action putSampleInput(Sample in);
        infifo.enq(in);
    endmethod

    method ActionValue#(Sample) getSampleOutput();
        outfifo.deq();
        return outfifo.first();
    endmethod

endmodule
