
import Complex::*;
import FixedPoint::*;
import Reg6375::*;

export AudioProcessorTypes::*;
export Reg6375::*;

import Vector::*;

typedef Int#(16) Sample;

interface AudioProcessor;
    method Action putSampleInput(Sample in);
    method ActionValue#(Sample) getSampleOutput();
endinterface


typedef Complex#(FixedPoint#(16, 16)) ComplexSample;

// Turn a real Sample into a ComplexSample.
function ComplexSample tocmplx(Sample x);
    return cmplx(fromInt(x), 0);
endfunction

// Extract the real component from complex.
function Sample frcmplx(ComplexSample x);
    return unpack(truncate(x.rel.i));
endfunction

// Turn a real Sample into a ComplexSample.
function Vector#(len, ComplexSample) tocmplxVec(Vector#(len, Sample) x);
    Vector#(len, ComplexSample) res;
    for (Integer i = 0; i < valueOf(len); i = i+1) begin
        res[i] = tocmplx(x[i]);
    end
    return res;
endfunction

// Extract the real component from complex.
function Vector#(len, Sample) frcmplxVec(Vector#(len, ComplexSample) x);
    Vector#(len, Sample) res;
    for (Integer i = 0; i < valueOf(len); i = i+1) begin
        res[i] = frcmplx(x[i]);
    end
    return res;
endfunction



typedef 8 FFT_POINTS;
typedef TLog#(FFT_POINTS) FFT_LOG_POINTS;

