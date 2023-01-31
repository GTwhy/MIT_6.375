
import ClientServer::*;
import FIFO::*;
import GetPut::*;

import FixedPoint::*;
import Vector::*;

import ComplexMP::*;


typedef Server#(
    Vector#(nbins, ComplexMP#(isize, fsize, psize)),
    Vector#(nbins, ComplexMP#(isize, fsize, psize))
) PitchAdjust#(numeric type nbins, numeric type isize, numeric type fsize, numeric type psize);


// s - the amount each window is shifted from the previous window.
//
// factor - the amount to adjust the pitch.
//  1.0 makes no change. 2.0 goes up an octave, 0.5 goes down an octave, etc...
module mkPitchAdjust(Integer s, FixedPoint#(isize, fsize) factor, PitchAdjust#(nbins, isize, fsize, psize) ifc)
provisos(Add#(a__, psize, TAdd#(isize, isize)), Add#(psize, b__, isize), Add#(c__, TLog#(nbins), isize));

    Vector#(nbins, Reg#(Phase#(psize))) inphases <- replicateM(mkReg(0));
    Vector#(nbins, Reg#(Phase#(psize))) outphases <- replicateM(mkReg(0));

    Reg#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) in <- mkRegU;
    Reg#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) out <- mkRegU;

    Reg#(Bit#(TLog#(nbins))) i <- mkReg(0);
    
    let phase = in[i].phase;
    let mag = in[i].magnitude;
    let dphase = phase - inphases[i];
    let nbins_sub1_int = fromInteger(valueOf(nbins)-1);

    Reg#(FixedPoint#(isize, fsize)) bin <- mkReg(0);
    FixedPoint#(isize, fsize) nbin = factor + bin;
    
    Reg#(Bool) done <- mkReg(True);
    FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) inputFIFO <- mkFIFO();
    FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) outputFIFO <- mkFIFO();
    
    let bin_int = fxptGetInt(bin);
    let nbin_int = fxptGetInt(nbin);
    let nbins_int = fromInteger(valueOf(nbins));
    Bit#(TLog#(nbins)) bin_idx = pack(truncate(bin_int));
    
    FixedPoint#(isize, fsize) dphaseFxpt = fromInt(dphase);
    let shiftedFxpt = fxptMult(factor, dphaseFxpt);
    Phase#(psize) shifted = truncate(fxptGetInt(shiftedFxpt));
    Phase#(psize) phase_out = truncate(outphases[bin_idx] + shifted);

    Reg#(Bit#(2)) stage_cnt <- mkReg(0);

    rule input_new (i == 0 && done);
        in <= inputFIFO.first;
        inputFIFO.deq;
        out <= replicate(cmplxmp(0, 0));
        bin <= 0;
        done <= False;
    endrule

    rule process (!done);
        inphases[i] <= phase;
        bin <= nbin;
        
        if (nbin_int != bin_int && bin_int >= 0 && bin_int < nbins_int) begin
            outphases[bin_idx] <= phase_out;
            out[bin_idx] <= cmplxmp(mag, phase_out);
        end

        if (i == nbins_sub1_int) begin
            done <= True;
        end else begin
            i <= i+1;
        end
    endrule
    
    rule process_done (done && i == nbins_sub1_int);
        i <= 0;
        outputFIFO.enq(out);
    endrule

    interface Put request;
        method Action put(Vector#(nbins, ComplexMP#(isize, fsize, psize)) x);
            inputFIFO.enq(x);
        endmethod
    endinterface

    interface Get response = toGet(outputFIFO);
endmodule