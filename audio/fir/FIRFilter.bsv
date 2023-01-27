import FIFO::*;
import FixedPoint::*;
import Vector::*;

import AudioProcessorTypes::*;
import Multiplier::*;

module mkFIRFilter (Vector#(tnp1, FixedPoint#(16, 16)) coeffs, AudioProcessor ifc);
    FIFO#(Sample) infifo <- mkFIFO();
    FIFO#(Sample) outfifo <- mkFIFO();
    Vector#(TSub#(tnp1, 1), Reg#(Sample)) r <- replicateM(mkReg(0));
    Vector#(tnp1, Multiplier) m <- replicateM(mkMultiplier());
    Integer num = valueOf(tnp1);
    
    rule init_mul(True);
        infifo.deq();
        let sample = infifo.first();

        r[0] <= sample;
        for (Integer i = 0; i < num-2; i = i+1) begin
            r[i+1] <= r[i];
        end

        m[0].putOperands(coeffs[0], sample);
        for (Integer i = 0; i < num-1; i = i+1) begin
            m[i+1].putOperands(coeffs[i+1], r[i]);
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
