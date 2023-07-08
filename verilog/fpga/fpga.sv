//-----------------------------------------------------------------------------
// Fpga test
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module fpga                                                                     // Run test programs
 (input  wire clock,                                                            // Execute the next instruction
  input  wire run,                                                              // Run - clock at lest once to allow code to be loaded
  output reg  finished,                                                         // Goes high when the program has finished
  output reg  success);                                                         // Goes high on finish if all the tests passed

  parameter integer InstructionNWidth  = 256;                                   // Number of bits in an instruction
  parameter integer MemoryElementWidth =  12;                                   // Memory element width

  `ifdef TEST
    `include "test.sv"
  `else
    `include "tests/Add_test/test.sv"
  `endif

  parameter integer NArea          =   2;  // 40s                               // Size of each area on the heap
  parameter integer NArrays        =   2;  // long AAAA                         // Maximum number of arrays
  parameter integer NHeap          =   2;  //NArea*NArrays;                     // Amount of heap memory
  parameter integer NLocal         =   2;                                       // Size of local memory
  parameter integer NIn            =   2;  // 40                                // Size of input area
  parameter integer NOut           =   2;  // 40                                // Size of output area
  parameter integer NFreedArrays   =   2;  // 40                                // Size of output area

  reg runnable;                                                                 // Goes high when the program has been loaded and we are ready to run
  reg signed [ InstructionNWidth-1:0]         code[NInstructions-1:0];          // Code memory
  reg signed [MemoryElementWidth-1:0]   arraySizes[NArrays-1      :0];          // Size of each array
  reg signed [MemoryElementWidth-1:0]      heapMem[NHeap-1        :0];          // Heap memory
  reg signed [MemoryElementWidth-1:0]     localMem[NLocal-1       :0];          // Local memory
  reg signed [MemoryElementWidth-1:0]       outMem[NOut-1         :0];          // Out channel
  reg signed [MemoryElementWidth-1:0]        inMem[NIn-1          :0];          // In channel
  reg signed [MemoryElementWidth-1:0]  freedArrays[NFreedArrays-1 :0];          // Freed arrays list implemented as a stack
  reg signed [MemoryElementWidth-1:0]   arrayShift[NArea-1        :0];          // Array shift area

  integer signed         inMemPos;                                              // Current position in input channel
  integer signed         inMemEnd;                                              // End of input channel, this is the next element that would have been added.
  integer signed        outMemPos;                                              // Position in output channel
  integer signed           result;                                              // Result of an instruction execution
  integer signed           allocs;                                              // Maximum number of array allocations in use at any one time
  integer signed   freedArraysTop;                                              // Position in freed arrays stack
  integer signed i, j, k, l, p, q;                                              // Useful integers

//Layout of each instruction

  integer ip = 0;                                                               // Instruction pointer

  wire signed [255:0] instruction = code[ip];
  wire signed [31:0]  operator    = instruction[255:224];
  wire signed [63:0]  source2     = instruction[ 63:  0];
  wire signed [63:0]  source      = instruction[127: 64];
  wire signed [63:0]  target      = instruction[191:128];

  wire signed [31: 0] source2Area     = source2[63:32];                         // Source 2
  wire signed [15: 0] source2Address  = source2[31:16];
  wire signed [ 2: 0] source2Arena    = source2[13:12];
  wire signed [ 2: 0] source2DArea    = source2[11:10];
  wire signed [ 2: 0] source2DAddress = source2[ 9: 8];
  wire signed [ 7: 0] source2Delta    = source2[ 7: 0];
  wire signed [31: 0] source2Value    =                                         // Source 2 as value
    source2Arena      == 0 ? 0 :
    source2Arena      == 1 ?
     (                        source2DAddress == 0 ? source2Address :
      source2DArea    == 0 && source2DAddress == 1 ? heapMem [source2Delta + source2Area*NArea           + source2Address]           :
      source2DArea    == 0 && source2DAddress == 2 ? heapMem [source2Delta + source2Area*NArea           + localMem[source2Address]] :
      source2DArea    == 1 && source2DAddress == 1 ? heapMem [source2Delta + localMem[source2Area]*NArea + source2Address]           :
      source2DArea    == 1 && source2DAddress == 2 ? heapMem [source2Delta + localMem[source2Area]*NArea + localMem[source2Address]] : 0) :
    source2Arena      == 2 ?
     (source2DAddress == 0 ? source2Address :
      source2DAddress == 1 ? localMem[source2Delta + source2Address]           :
      source2DAddress == 2 ? localMem[source2Delta + localMem[source2Address]] : 0) : 0;

  wire signed [31: 0] source1Area     = source[63:32];                          // Source 1
  wire signed [15: 0] source1Address  = source[31:16];
  wire signed [ 2: 0] source1Arena    = source[13:12];
  wire signed [ 2: 0] source1DArea    = source[11:10];
  wire signed [ 2: 0] source1DAddress = source[ 9: 8];
  wire signed [ 7: 0] source1Delta    = source[ 7: 0];
  wire signed [31: 0] source1Value    =                                         // Source 1 as value
    source1Arena      == 0 ? 0 :
    source1Arena      == 1 ?
     (                        source1DAddress == 0 ? source1Address :
      source1DArea    == 0 && source1DAddress == 1 ? heapMem [source1Delta + source1Area*NArea           + source1Address]           :
      source1DArea    == 0 && source1DAddress == 2 ? heapMem [source1Delta + source1Area*NArea           + localMem[source1Address]] :
      source1DArea    == 1 && source1DAddress == 1 ? heapMem [source1Delta + localMem[source1Area]*NArea + source1Address]           :
      source1DArea    == 1 && source1DAddress == 2 ? heapMem [source1Delta + localMem[source1Area]*NArea + localMem[source1Address]] : 0) :
    source1Arena      == 2 ?
     (source1DAddress == 0 ? source1Address :
      source1DAddress == 1 ? localMem[source1Delta + source1Address]           :
      source1DAddress == 2 ? localMem[source1Delta + localMem[source1Address]] : 0) : 0;
  wire signed [31: 0] sourceLocation  =                                         // Source 1 as a location
    source1Arena      == 0 ? 0 :
    source1Arena      == 1 ?
     (                        source1DAddress == 0 ? source1Address :
      source1DArea    == 0 && source1DAddress == 1 ? source1Delta + source1Area*NArea           + source1Address           :
      source1DArea    == 0 && source1DAddress == 2 ? source1Delta + source1Area*NArea           + localMem[source1Address] :
      source1DArea    == 1 && source1DAddress == 1 ? source1Delta + localMem[source1Area]*NArea + source1Address           :
      source1DArea    == 1 && source1DAddress == 2 ? source1Delta + localMem[source1Area]*NArea + localMem[source1Address] : 0) :
    source1Arena      == 2 ?
     (source1DAddress == 0 ? source1Address :
      source1DAddress == 1 ? source1Delta + localMem[source1Address]           :
      source1DAddress == 2 ? source1Delta + localMem[localMem[source1Address]] : 0) : 0;

  wire signed [31: 0] targetArea      = target[63:32];                          // Target
  wire signed [15: 0] targetAddress   = target[31:16];
  wire signed [ 2: 0] targetArena     = target[13:12];
  wire signed [ 2: 0] targetDArea     = target[11:10];
  wire signed [ 2: 0] targetDAddress  = target[ 9: 8];
  wire signed [ 7: 0] targetDelta     = target[ 7: 0];
  wire signed [31: 0] targetLocation  =                                         // Target as a location
    targetArena      == 0 ? 0 :                                                 // Invalid
    targetArena      == 1 ?                                                     // Heap
     (targetDArea    == 0 && targetDAddress == 1 ? targetDelta + targetArea*NArea           + targetAddress           :
      targetDArea    == 0 && targetDAddress == 2 ? targetDelta + targetArea*NArea           + localMem[targetAddress] :
      targetDArea    == 1 && targetDAddress == 1 ? targetDelta + localMem[targetArea]*NArea + targetAddress           :
      targetDArea    == 1 && targetDAddress == 2 ? targetDelta + localMem[targetArea]*NArea + localMem[targetAddress] : 0) :
    targetArena      == 2 ?                                                     // Local
     (targetDAddress == 1 ?  targetDelta + targetAddress           :
      targetDAddress == 2 ?  targetDelta + localMem[targetAddress] : 0) : 0;

  wire signed [31: 0] targetIndex  =                                            // Target index within array
    targetArena      == 1 ?                                                     // Heap
     (targetDAddress == 1 ? targetDelta + targetAddress           :
      targetDAddress == 2 ? targetDelta + localMem[targetAddress] : 0)  : 0;

  wire signed [31: 0] targetLocationArea =                                      // Number of array containing target
      targetArena    == 1 && targetDArea == 0 ? targetArea :
      targetArena    == 1 && targetDArea == 1 ? localMem[targetArea]    : 0;

  wire signed [31: 0] targetValue    =                                          // Target as value
    targetArena      == 0 ? 0 :
    targetArena      == 1 ?
     (                       targetDAddress == 0 ? targetAddress :
      targetDArea    == 0 && targetDAddress == 1 ? heapMem [targetDelta + targetArea*NArea           + targetAddress]           :
      targetDArea    == 0 && targetDAddress == 2 ? heapMem [targetDelta + targetArea*NArea           + localMem[targetAddress]] :
      targetDArea    == 1 && targetDAddress == 1 ? heapMem [targetDelta + localMem[targetArea]*NArea + targetAddress]           :
      targetDArea    == 1 && targetDAddress == 2 ? heapMem [targetDelta + localMem[targetArea]*NArea + localMem[targetAddress]] : 0) :
    targetArena      == 2 ?
     (targetDAddress == 0 ? targetAddress :
      targetDAddress == 1 ? localMem[targetDelta + targetAddress]           :
      targetDAddress == 2 ? localMem[targetDelta + localMem[targetAddress]] : 0) : 0;

// Execute each test progam

  always @(posedge clock) begin                                                 // Execute instruction
    if (run) begin
      if (ip >= 0 && ip < NInstructions) begin                                  // Ip in range
        executeInstruction();
        ip = ip + 1;
      end
      else begin;                                                               // Finished
        runnable = 0;
        endTest();
        finished = 1;
      end
    end
    else begin                                                                  // Initialize if not running
      runnable       = 0;
      ip             = 0;
      finished       = 0;
      success        = 0;
      inMemPos       = 0;
      inMemEnd       = 0;
      outMemPos      = 0;
      result         = 0;
      allocs         = 0;
      freedArraysTop = 0;

      startTest();
      runnable       = 1;
    end
  end

//Single instruction execution

  task executeInstruction();                                                    // Execute an instruction
    begin
      result = 'bx;
      case(operator)
         0: begin; add_instruction();                                       end // add_instruction
         1: begin; array_instruction();                                     end // array_instruction
         2: begin; arrayCountGreater_instruction();                         end // arrayCountGreater_instruction
         3: begin; arrayCountLess_instruction();                            end // arrayCountLess_instruction
         4: begin; arrayDump_instruction();                                 end // arrayDump_instruction
         5: begin; arrayIndex_instruction();                                end // arrayIndex_instruction
         6: begin; arrayOut_instruction();                                  end // arrayOut_instruction
         7: begin; arraySize_instruction();                                 end // arraySize_instruction
         8: begin; assert_instruction();                                    end // assert_instruction
         9: begin; assertEq_instruction();                                  end // assertEq_instruction
        10: begin; assertFalse_instruction();                               end // assertFalse_instruction
        11: begin; assertGe_instruction();                                  end // assertGe_instruction
        12: begin; assertGt_instruction();                                  end // assertGt_instruction
        13: begin; assertLe_instruction();                                  end // assertLe_instruction
        14: begin; assertLt_instruction();                                  end // assertLt_instruction
        15: begin; assertNe_instruction();                                  end // assertNe_instruction
        16: begin; assertTrue_instruction();                                end // assertTrue_instruction
        17: begin; call_instruction();                                      end // call_instruction
        18: begin; confess_instruction();                                   end // confess_instruction
        19: begin; dump_instruction();                                      end // dump_instruction
        20: begin; free_instruction();                                      end // free_instruction
        21: begin; in_instruction();                                        end // in_instruction
        22: begin; inSize_instruction();                                    end // inSize_instruction
        23: begin; jEq_instruction();                                       end // jEq_instruction
        24: begin; jFalse_instruction();                                    end // jFalse_instruction
        25: begin; jGe_instruction();                                       end // jGe_instruction
        26: begin; jGt_instruction();                                       end // jGt_instruction
        27: begin; jLe_instruction();                                       end // jLe_instruction
        28: begin; jLt_instruction();                                       end // jLt_instruction
        29: begin; jNe_instruction();                                       end // jNe_instruction
        30: begin; jTrue_instruction();                                     end // jTrue_instruction
        31: begin; jmp_instruction();                                       end // jmp_instruction
        32: begin; label_instruction();                                     end // label_instruction
        33: begin; loadAddress_instruction();                               end // loadAddress_instruction
        34: begin; loadArea_instruction();                                  end // loadArea_instruction
        35: begin; mov_instruction();                                       end // mov_instruction
        36: begin; moveLong_instruction();                                  end // moveLong_instruction
        37: begin; nop_instruction();                                       end // nop_instruction
        38: begin; not_instruction();                                       end // not_instruction
        39: begin; out_instruction();                                       end // out_instruction
        40: begin; parallelContinue_instruction();                          end // parallelContinue_instruction
        41: begin; parallelStart_instruction();                             end // parallelStart_instruction
        42: begin; parallelStop_instruction();                              end // parallelStop_instruction
        43: begin; paramsGet_instruction();                                 end // paramsGet_instruction
        44: begin; paramsPut_instruction();                                 end // paramsPut_instruction
        45: begin; pop_instruction();                                       end // pop_instruction
        46: begin; push_instruction();                                      end // push_instruction
        47: begin; random_instruction();                                    end // random_instruction
        48: begin; randomSeed_instruction();                                end // randomSeed_instruction
        49: begin; resize_instruction();                                    end // resize_instruction
        50: begin; return_instruction();                                    end // return_instruction
        51: begin; returnGet_instruction();                                 end // returnGet_instruction
        52: begin; returnPut_instruction();                                 end // returnPut_instruction
        53: begin; shiftDown_instruction();                                 end // shiftDown_instruction
        54: begin; shiftLeft_instruction();                                 end // shiftLeft_instruction
        55: begin; shiftRight_instruction();                                end // shiftRight_instruction
        56: begin; shiftUp_instruction();                                   end // shiftUp_instruction
        57: begin; subtract_instruction();                                  end // subtract_instruction
        58: begin; tally_instruction();                                     end // tally_instruction
        59: begin; trace_instruction();                                     end // trace_instruction
        60: begin; traceLabels_instruction();                               end // traceLabels_instruction
        61: begin; watch_instruction();                                     end // watch_instruction
      endcase
    end
  endtask
  task arrayDump_instruction();
    begin                                                                       // arrayDump
    end
  endtask
  task arrayOut_instruction();
    begin                                                                       // arrayOut
    end
  endtask
  task assert_instruction();
    begin                                                                       // assert
    end
  endtask
  task assertEq_instruction();
    begin                                                                       // assertEq
    end
  endtask
  task assertFalse_instruction();
    begin                                                                       // assertFalse
    end
  endtask
  task assertGe_instruction();
    begin                                                                       // assertGe
    end
  endtask
  task assertGt_instruction();
    begin                                                                       // assertGt
    end
  endtask
  task assertLe_instruction();
    begin                                                                       // assertLe
    end
  endtask
  task assertLt_instruction();
    begin                                                                       // assertLt
    end
  endtask
  task assertNe_instruction();
    begin                                                                       // assertNe
    end
  endtask
  task assertTrue_instruction();
    begin                                                                       // assertTrue
    end
  endtask
  task call_instruction();
    begin                                                                       // call
    end
  endtask
  task confess_instruction();
    begin                                                                       // confess
    end
  endtask
  task dump_instruction();
    begin                                                                       // dump
    end
  endtask
  task label_instruction();
    begin                                                                       // label
    end
  endtask
  task loadAddress_instruction();
    begin                                                                       // loadAddress
    end
  endtask
  task loadArea_instruction();
    begin                                                                       // loadArea
    end
  endtask
  task nop_instruction();
    begin                                                                       // nop
    end
  endtask
  task parallelContinue_instruction();
    begin                                                                       // parallelContinue
    end
  endtask
  task parallelStart_instruction();
    begin                                                                       // parallelStart
    end
  endtask
  task parallelStop_instruction();
    begin                                                                       // parallelStop
    end
  endtask
  task paramsGet_instruction();
    begin                                                                       // paramsGet
    end
  endtask
  task paramsPut_instruction();
    begin                                                                       // paramsPut
    end
  endtask
  task random_instruction();
    begin                                                                       // random
    end
  endtask
  task randomSeed_instruction();
    begin                                                                       // randomSeed
    end
  endtask
  task return_instruction();
    begin                                                                       // return
    end
  endtask
  task returnGet_instruction();
    begin                                                                       // returnGet
    end
  endtask
  task returnPut_instruction();
    begin                                                                       // returnPut
    end
  endtask
  task shiftDown_instruction();
    begin                                                                       // shiftDown
    end
  endtask
  task tally_instruction();
    begin                                                                       // tally
    end
  endtask
  task trace_instruction();
    begin                                                                       // trace
    end
  endtask
  task traceLabels_instruction();
    begin                                                                       // traceLabels
    end
  endtask
  task watch_instruction();
    begin                                                                       // watch
    end
  endtask

//Memory access functions for instruction execution

  reg signed [MemoryElementWidth-1:0] targetArraySize1 = 0;
  reg signed [MemoryElementWidth-1:0] targetArraySize2 = 0;

  task setMemory();                                                             // Set the target memory location updating the containing array size if necessary
    begin
      case(targetArena)
        1: begin                                                                // Update array
          heapMem[targetLocation] = result;
          targetArraySize1 = arraySizes[targetLocationArea];
          targetArraySize2 = targetArraySize1 > targetIndex ? targetArraySize1 : targetIndex + 1;
          arraySizes[targetLocationArea] = targetArraySize2;
        end
        2: localMem[targetLocation] = result;                                   // Local memory
      endcase
    end
  endtask

//Implementation of each instruction

  task add_instruction();                                                       // add
    begin
      result = source1Value + source2Value;
      setMemory();
    end
  endtask

  task array_instruction();                                                     // array
    begin
      if (freedArraysTop > 0) begin                                             // Reuse an array
        freedArraysTop = freedArraysTop - 1;
        result = freedArrays[freedArraysTop];
      end
      else begin
        result = allocs;                                                        // Array zero means undefined
        allocs = allocs + 1;                                                    // Array zero means undefined
      end
      arraySizes[result] = 0;                                                   // Zero array length
      setMemory();                                                              // Save address of array
    end
  endtask

  task free_instruction();
    begin                                                                       // Free
      freedArrays[freedArraysTop] = targetValue;                                // Allocate
      freedArraysTop = freedArraysTop + 1;                                      // Push
      arraySizes[targetValue] = 0; //**                                            // Zero array length
    end
  endtask

  task mov_instruction();                                                       // mov
    begin
      result = source1Value;
      setMemory();                                                              // Save result in target
    end
  endtask


  task not_instruction();                                                       // not
    begin
      result = source1Value ? 0 : 1;
      setMemory();                                                              // Save result in target
    end
  endtask

  task resize_instruction();                                                    // resize
    begin
      result = source1Value;
      arraySizes[targetLocationArea] = result;
    end
  endtask

  task subtract_instruction();                                                  // subtract
    begin
      result = source1Value - source2Value;
      setMemory();                                                              // Save result in target
    end
  endtask

  task out_instruction();                                                       // Out
    begin
      outMem[outMemPos] = source1Value;
      outMemPos = (outMemPos + 1) % NOut;
    end
  endtask

  task arrayIndex_instruction();
    begin                                                                       // arrayIndex
      begin
        q <= source1Value * NArea;                                              // Array location
        p <= arraySizes[source1Value];                                          // Length of array
        result <= 0;
      end
      for(i = 0; i < NArea; i = i + 1) begin                                    // We can do this by doing all the comparisons in parallel then doing one ghot to binary by using and/or gates to syhntheisze the appropriate index for each possibility
        result = i < p && heapMem[q+i] == source2Value ? i+1 : result;
      end
      setMemory();
    end
  endtask

  task arrayCountGreater_instruction();                                         // arrayCountGreater
    begin
      begin
        q <= source1Value * NArea;                                              // Array location
        p <= arraySizes[source1Value];                                          // Length of array
        result <= 0;
      end;
      for(i = 0; i < NArea; i = i + 1) begin                                    // We can do this by doing all the comparison in parallel then doing one ghot to binary by using and/or gates to syhntheisze the appropriate index for each possibility
        result = result + (i < p && heapMem[q+i] > source2Value) ? 1 : 0;
      end
      setMemory();
    end
  endtask

  task arrayCountLess_instruction();
    begin                                                                       // arrayCountLess
      begin
        q <= source1Value * NArea;                                              // Array location
        p <= arraySizes[source1Value];                                          // Length of array
        result <= 0;
      end;
      for(i = 0; i < NArea; i = i + 1) begin                                    // We can do this by doing all the comparison in parallel then doing one ghot to binary by using and/or gates to syhntheisze the appropriate index for each possibility
        result = result + (i < p && heapMem[q+i] < source2Value) ? 1 : 0;
      end
      setMemory();
    end
  endtask

  task shiftLeft_instruction();
    begin                                                                       // shiftLeft
      result = targetValue << source1Value;
      setMemory();
    end
  endtask

  task shiftRight_instruction();
    begin                                                                       // shiftLeft
      result = targetValue >> source1Value;
      setMemory();
    end
  endtask

  task jEq_instruction();
    begin                                                                       // jeq
      if (source1Value == source2Value) begin
        ip = ip + targetArea - 1;
      end
    end
  endtask

  task jFalse_instruction();
    begin                                                                       // jFalse
      if (source1Value == 0) begin
        ip = ip + targetArea - 1;
      end
    end
  endtask

  task jGe_instruction();
    begin                                                                       // jGe
      if (source1Value >= source2Value) begin
        ip = ip + targetArea - 1;
      end
    end
  endtask

  task jGt_instruction();
    begin                                                                       // jGt
      if (source1Value >  source2Value) begin
        ip = ip + targetArea - 1;
      end
    end
  endtask

  task jLe_instruction();
    begin                                                                       // jLe
      if (source1Value <= source2Value) begin
        ip = ip + targetArea - 1;
      end
    end
  endtask

  task jLt_instruction();
    begin                                                                       // jLt
      if (source1Value <  source2Value) begin
        ip = ip + targetArea - 1;
      end
    end
  endtask

  task jNe_instruction();
    begin                                                                       // jNe
      if (source1Value != source2Value) begin
        ip = ip + targetArea - 1;
      end
    end
  endtask

  task jTrue_instruction();
    begin                                                                       // jTrue
      if (source1Value != 0) begin
        ip = ip + targetArea - 1;
      end
    end
  endtask

  task jmp_instruction();
    begin                                                                       // jmp
      ip = ip + targetArea - 1;
    end
  endtask

  task push_instruction();                                                      // push
    begin
      p = arraySizes[targetValue];
      if (p + 1 < NArea) begin
        heapMem[p] = source1Value;
        arraySizes[targetValue] = p + 1;
        result = source1Value;
      end
    end
  endtask

  task pop_instruction();                                                       // pop
    begin
      p = arraySizes[source1Value];
      if (p > 0) begin
        p = p - 1;
        arraySizes[source1Value] = p;
        result = heapMem[p];
        setMemory();
        result = source1Value;
      end
    end
  endtask

  task arraySize_instruction();                                                 // arraySize
    begin
      result = arraySizes[source1Value];
      setMemory();
    end
  endtask

  task shiftUp_instruction();                                                   // shiftUp - shift an array up in parallel by first copying every element in parallel then copying back just the elements we need into their new positions
    begin
      if (targetIndex < NArea) begin
        p = targetLocationArea * NArea;                                         // Array Start
        begin
          arraySizes[targetLocationArea] = arraySizes[targetLocationArea] + 1;  // New size of array
          for(i = 0; i < NArea; i = i + 1) begin
            arrayShift[i] = heapMem[p+i];
          end
          heapMem[p + targetIndex] = source1Value;                              // Move up
          for(i = 0; i < NArea; i = i + 1) begin
            heapMem[p+i] = i > targetIndex ? arrayShift[i-targetIndex] : heapMem[p+i] ;
          end
        end
      end
    end
  endtask

  task moveLong_instruction();                                                  // moveLong - we assume there is no overlap between source and destination
    begin
      for(i = 0; i < NArea; i = i + 1) begin
        if (i < source2Value) begin
          heapMem[targetLocation+i] = heapMem[sourceLocation+i];
        end
      end
    end
  endtask

  task in_instruction();                                                        // in
    begin
     result = inMem[inMemPos];
     setMemory();
     inMemPos = (inMemPos + 1) % NIn;
    end
  endtask

  task inSize_instruction();                                                    // inSize
    begin
     if (inMemEnd > inMemPos) result =       inMemEnd - inMemPos;
     else                     result = NIn + inMemEnd - inMemPos;
     setMemory();
    end
  endtask
endmodule
