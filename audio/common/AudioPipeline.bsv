
import ClientServer::*;
import GetPut::*;

import AudioProcessorTypes::*;
import Chunker::*;
import FFT::*;
import FIRFilter::*;
import Splitter::*;
import FilterCoefficients::*;
import FixedPoint::*;

import OverSampler::*;
import Overlayer::*;
import Converter::*;
import PitchAdjust::*;
import Complex::*;
import Vector::*;

typedef 8 N;
typedef 2 S;
typedef 16 I_SIZE;
typedef 16 F_SIZE;
typedef 16 P_SIZE;

(*synthesize*)
module mkAudioPipeline(SettableAudioProcessor#(I_SIZE, F_SIZE));

    Vector#(N, Sample) init_val = replicate(0);
    AudioProcessor fir <- mkFIRFilter(c);
    Chunker#(S, Sample) chunker <- mkChunker();
    OverSampler#(S, N, Sample) sampler <- mkOverSampler(init_val);
    FFT#(N,FixedPoint#(I_SIZE, P_SIZE)) fft <- mkFFT();
    ToMP#(N, I_SIZE, F_SIZE, P_SIZE) toMP <- mkToMP();
    SettablePitchAdjust#(N, I_SIZE, F_SIZE, P_SIZE) pitch <- mkPitchAdjust(valueOf(S));
    PitchAdjust#(N, I_SIZE, F_SIZE, P_SIZE) adjust = pitch.adjust;
    FromMP#(N, I_SIZE, F_SIZE, P_SIZE) fromMP <- mkFromMP();
    FFT#(N,FixedPoint#(I_SIZE, P_SIZE)) ifft <- mkIFFT();
    Overlayer#(N, S, Sample) overlayer <- mkOverlayer(init_val);
    Splitter#(S, Sample) splitter <- mkSplitter();

    rule fir_to_chunker (True);
        let x <- fir.getSampleOutput();
        chunker.request.put(x);
    endrule

    rule chunker_to_sampler (True);
        let x <- chunker.response.get();
        sampler.request.put(x);
    endrule

    rule sampler_to_fft (True);
        let x <- sampler.response.get();
        fft.request.put(tocmplxVec(x));
    endrule
    
    rule fft_to_tomp (True);
        let x <- fft.response.get();
        toMP.request.put(x);
    endrule

    rule tomp_to_adjust (True);
        let x <- toMP.response.get();
        adjust.request.put(x);
    endrule

    rule adjust_to_frommp (True);
        let x <- adjust.response.get();
        fromMP.request.put(x);
    endrule

    rule frommp_to_ifft (True);
        let x <- fromMP.response.get();
        ifft.request.put(x);
    endrule

    rule ifft_to_overlayer (True);
        let x <- ifft.response.get();
        overlayer.request.put(frcmplxVec(x));
    endrule

    rule overlayer_to_splitter (True);
        let x <- overlayer.response.get();
        splitter.request.put(x);
    endrule
    
    interface AudioProcessor audioProcessor;
        method Action putSampleInput(Sample x);
            fir.putSampleInput(x);
        endmethod

        method ActionValue#(Sample) getSampleOutput();
            let x <- splitter.response.get();
            return x;
        endmethod
    endinterface

    interface Put setFactor;
        method Action put(FixedPoint#(I_SIZE, F_SIZE) x);
            pitch.setFactor.put(x);
        endmethod
    endinterface
endmodule

