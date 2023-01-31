import ClientServer::*;
import Complex::*;
import ComplexMP::*;
import FixedPoint::*;
import FIFO::*;
import Vector::*;
import Cordic::*;
import GetPut::*;

typedef Server#(
    Vector#(nbins, ComplexMP#(isize, fsize, psize)),
    Vector#(nbins, Complex#(FixedPoint#(isize, fsize)))
) FromMP#(numeric type nbins, numeric type isize, numeric type fsize, numeric type psize);

typedef Server#(
    Vector#(nbins, Complex#(FixedPoint#(isize, fsize))),
    Vector#(nbins, ComplexMP#(isize, fsize, psize))
) ToMP#(numeric type nbins, numeric type isize, numeric type fsize, numeric type psize);

module mkFromMP(FromMP#(nbins, isize, fsize, psize) ifc);
    FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) inputFIFO <- mkFIFO();
    FIFO#(Vector#(nbins, Complex#(FixedPoint#(isize, fsize)))) outputFIFO <- mkFIFO();
    Vector#(nbins, FromMagnitudePhase#(isize, fsize, psize)) fromConverters <- replicateM(mkCordicFromMagnitudePhase());

    rule input_data;
        for(Integer i = 0; i < valueOf(nbins); i = i+1) begin
        fromConverters[i].request.put(inputFIFO.first[i]);
        end
        inputFIFO.deq;
    endrule

    rule output_data;
        Vector#(nbins, Complex#(FixedPoint#(isize, fsize))) res;
        for(Integer i = 0; i < valueOf(nbins); i = i+1) begin
            res[i] <- fromConverters[i].response.get();
        end
        outputFIFO.enq(res);
    endrule

    interface Put request = toPut(inputFIFO);
    interface Get response = toGet(outputFIFO);

endmodule

module mkToMP(ToMP#(nbins, isize, fsize, psize) ifc);
    FIFO#(Vector#(nbins, Complex#(FixedPoint#(isize, fsize)))) inputFIFO <- mkFIFO();
    FIFO#(Vector#(nbins, ComplexMP#(isize, fsize, psize))) outputFIFO <- mkFIFO();
    Vector#(nbins, ToMagnitudePhase#(isize, fsize, psize)) toConverters <- replicateM(mkCordicToMagnitudePhase());

    rule input_data;
        for(Integer i = 0; i < valueOf(nbins); i = i+1) begin
            toConverters[i].request.put(inputFIFO.first[i]);
        end
        inputFIFO.deq;
    endrule

    rule output_data;
        Vector#(nbins, ComplexMP#(isize, fsize, psize)) res;
        for(Integer i = 0; i < valueOf(nbins); i = i+1) begin
            res[i] <- toConverters[i].response.get();
        end
        outputFIFO.enq(res);
    endrule

    interface Put request = toPut(inputFIFO);
    interface Get response = toGet(outputFIFO);

endmodule
