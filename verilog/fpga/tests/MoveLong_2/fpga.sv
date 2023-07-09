//-----------------------------------------------------------------------------
// Fpga test
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module fpga                                                                     // Run test programs
 (input  wire clock,                                                            // Driving clock
  input  wire reset,                                                            // Restart program
  output reg  finished,                                                         // Goes high when the program has finished
  output reg  success);                                                         // Goes high on finish if all the tests passed

  parameter integer MemoryElementWidth =  12;                                   // Memory element width

  parameter integer NArea   =        8;                                         // Size of each area on the heap
  parameter integer NArrays =        2;                                         // Maximum number of arrays
  parameter integer NHeap   =       16;                                         // Amount of heap memory
  parameter integer NLocal  =       30;                                         // Size of local memory
  parameter integer NOut    =       20;                                         // Size of output area

  heapMemory heap(                                                              // Create heap memory
    .clk    (heapClock),
    .write  (heapWrite),
    .address(heapAddress),
    .in     (heapIn),
    .out    (heapOut)
  );

  defparam heap.MEM_SIZE   = NHeap;                                             // Size of heap
  defparam heap.DATA_WIDTH = MemoryElementWidth;

  reg                         heapClock;                                        // Heap ports
  reg                         heapWrite;
  reg[NHeap-1:0]              heapAddress;
  reg[MemoryElementWidth-1:0] heapIn;
  reg[MemoryElementWidth-1:0] heapOut;

  parameter integer NIn     =        0;                                         // Size of input area
  reg [MemoryElementWidth-1:0]   arraySizes[NArrays-1:0];                       // Size of each array
//reg [MemoryElementWidth-1:0]      heapMem[NHeap-1  :0];                       // Heap memory
  reg [MemoryElementWidth-1:0]     localMem[NLocal-1 :0];                       // Local memory
  reg [MemoryElementWidth-1:0]       outMem[NOut-1   :0];                       // Out channel
  reg [MemoryElementWidth-1:0]        inMem[NIn-1    :0];                       // In channel
  reg [MemoryElementWidth-1:0]  freedArrays[NArrays-1:0];                       // Freed arrays list implemented as a stack
  reg [MemoryElementWidth-1:0]   arrayShift[NArea-1  :0];                       // Array shift area

  integer inMemPos;                                                             // Current position in input channel
  integer outMemPos;                                                            // Position in output channel
  integer allocs;                                                               // Maximum number of array allocations in use at any one time
  integer freedArraysTop;                                                       // Position in freed arrays stack

  integer ip;                                                                   // Instruction pointer
  integer steps;                                                                // Number of steps executed so far
  integer i, j, k;                                                              // A useful counter

  task updateArrayLength(input integer arena, input integer array, input integer index); // Update array length if we are updating an array
    begin
      if (arena == 1 && arraySizes[array] < index + 1) arraySizes[array] = index + 1;
    end
  endtask

  always @(posedge clock) begin                                                 // Each instruction
    if (reset) begin
      ip             = 0;
      steps          = 0;
      inMemPos       = 0;
      outMemPos      = 0;
      allocs         = 0;
      freedArraysTop = 0;
      finished       = 0;
      success        = 0;

      if (0) begin                                                  // Clear memory
        for(i = 0; i < NHeap;   i = i + 1)    heapMem[i] = 0;
        for(i = 0; i < NLocal;  i = i + 1)   localMem[i] = 0;
        for(i = 0; i < NArrays; i = i + 1) arraySizes[i] = 0;
      end
    end
    else begin
      steps = steps + 1;
      case(ip)

          0 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[0] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[0] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[0]] = 0;
              ip = 1;
        end

          1 :
        begin                                                                   // array
if (0) begin
  $display("AAAA %4d %4d array", steps, ip);
end
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                localMem[1] = freedArrays[freedArraysTop];
              end
              else begin
                localMem[1] = allocs;
                allocs = allocs + 1;

              end
              arraySizes[localMem[1]] = 0;
              ip = 2;
        end

          2 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[14] = 11;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 3;
        end

          3 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[0]*8 + 0;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[14];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 4;                                                          // Next instruction
        end

          4 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 5;                                                          // Next instruction
        end

          5 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[15] = 22;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 6;
        end

          6 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[0]*8 + 1;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[15];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 7;                                                          // Next instruction
        end

          7 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 8;                                                          // Next instruction
        end

          8 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[16] = 33;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 9;
        end

          9 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[0]*8 + 2;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[16];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 10;                                                          // Next instruction
        end

         10 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 11;                                                          // Next instruction
        end

         11 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[17] = 44;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 12;
        end

         12 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[0]*8 + 3;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[17];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 13;                                                          // Next instruction
        end

         13 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 14;                                                          // Next instruction
        end

         14 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[18] = 55;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 15;
        end

         15 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[0]*8 + 4;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[18];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 16;                                                          // Next instruction
        end

         16 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 17;                                                          // Next instruction
        end

         17 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[19] = 66;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 18;
        end

         18 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[1]*8 + 0;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[19];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 19;                                                          // Next instruction
        end

         19 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 20;                                                          // Next instruction
        end

         20 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[20] = 77;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 21;
        end

         21 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[1]*8 + 1;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[20];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 22;                                                          // Next instruction
        end

         22 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 23;                                                          // Next instruction
        end

         23 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[21] = 88;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 24;
        end

         24 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[1]*8 + 2;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[21];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 25;                                                          // Next instruction
        end

         25 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 26;                                                          // Next instruction
        end

         26 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[22] = 99;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 27;
        end

         27 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[1]*8 + 3;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[22];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 28;                                                          // Next instruction
        end

         28 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 29;                                                          // Next instruction
        end

         29 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[23] = 101;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 30;
        end

         30 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[1]*8 + 4;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[23];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 31;                                                          // Next instruction
        end

         31 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 32;                                                          // Next instruction
        end

         32 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[0]] = 5;
              ip = 33;
        end

         33 :
        begin                                                                   // resize
if (0) begin
  $display("AAAA %4d %4d resize", steps, ip);
end
              arraySizes[localMem[1]] = 5;
              ip = 34;
        end

         34 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              localMem[2] = arraySizes[localMem[0]];
              ip = 35;
        end

         35 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 36;
        end

         36 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[3] = 0;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 37;
        end

         37 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 38;
        end

         38 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[3] >= localMem[2] ? 46 : 39;
        end

         39 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapAddress = localMem[0]*8 + localMem[3];                                                 // Address of the item we wish to read from heap memory
              heapWrite = 0;                                                    // Request a read, not a write
              heapClock = 1;                                                    // Start read
              ip = 40;                                                          // Next instruction
        end

         40 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[24] = heapOut;                                                     // Data retrieved from heap memory
              heapClock = 0;                                                    // Ready for next operation
              ip = 41;                                                          // Next instruction
        end

         41 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[4] = localMem[24];
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 42;
        end

         42 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[4];
              outMemPos = outMemPos + 1;
              ip = 43;
        end

         43 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 44;
        end

         44 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[3] = localMem[3] + 1;
              updateArrayLength(2, 0, 0);
              ip = 45;
        end

         45 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 37;
        end

         46 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 47;
        end

         47 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              localMem[5] = arraySizes[localMem[1]];
              ip = 48;
        end

         48 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 49;
        end

         49 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[6] = 0;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 50;
        end

         50 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 51;
        end

         51 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[6] >= localMem[5] ? 59 : 52;
        end

         52 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapAddress = localMem[1]*8 + localMem[6];                                                 // Address of the item we wish to read from heap memory
              heapWrite = 0;                                                    // Request a read, not a write
              heapClock = 1;                                                    // Start read
              ip = 53;                                                          // Next instruction
        end

         53 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[25] = heapOut;                                                     // Data retrieved from heap memory
              heapClock = 0;                                                    // Ready for next operation
              ip = 54;                                                          // Next instruction
        end

         54 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[7] = localMem[25];
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 55;
        end

         55 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[7];
              outMemPos = outMemPos + 1;
              ip = 56;
        end

         56 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 57;
        end

         57 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[6] = localMem[6] + 1;
              updateArrayLength(2, 0, 0);
              ip = 58;
        end

         58 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 50;
        end

         59 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 60;
        end

         60 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapAddress = localMem[1]*8 + 2;                                                 // Address of the item we wish to read from heap memory
              heapWrite = 0;                                                    // Request a read, not a write
              heapClock = 1;                                                    // Start read
              ip = 61;                                                          // Next instruction
        end

         61 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[26] = heapOut;                                                     // Data retrieved from heap memory
              heapClock = 0;                                                    // Ready for next operation
              ip = 62;                                                          // Next instruction
        end

         62 :
        begin                                                                   // moveLong
if (0) begin
  $display("AAAA %4d %4d moveLong", steps, ip);
end
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < 2) begin
                  heapMem[NArea * 0 + 0 + i] = heapMem[NArea * 0 + 0 + i];
                  updateArrayLength(2, 0, 0 + i);
                end
              end
              ip = 63;
        end

         63 :
        begin                                                                   // movWrite1
if (0) begin
  $display("AAAA %4d %4d movWrite1", steps, ip);
end
              heapAddress = localMem[0]*8 + 1;                                                 // Address of the item we wish to read from heap memory
              heapIn      = localMem[27];                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = 64;                                                          // Next instruction
        end

         64 :
        begin                                                                   // step
if (0) begin
  $display("AAAA %4d %4d step", steps, ip);
end
              heapClock = 0;                                                    // Ready for next operation
              ip = 65;                                                          // Next instruction
        end

         65 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              localMem[8] = arraySizes[localMem[0]];
              ip = 66;
        end

         66 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 67;
        end

         67 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[9] = 0;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 68;
        end

         68 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 69;
        end

         69 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[9] >= localMem[8] ? 77 : 70;
        end

         70 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapAddress = localMem[0]*8 + localMem[9];                                                 // Address of the item we wish to read from heap memory
              heapWrite = 0;                                                    // Request a read, not a write
              heapClock = 1;                                                    // Start read
              ip = 71;                                                          // Next instruction
        end

         71 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[28] = heapOut;                                                     // Data retrieved from heap memory
              heapClock = 0;                                                    // Ready for next operation
              ip = 72;                                                          // Next instruction
        end

         72 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[10] = localMem[28];
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 73;
        end

         73 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[10];
              outMemPos = outMemPos + 1;
              ip = 74;
        end

         74 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 75;
        end

         75 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[9] = localMem[9] + 1;
              updateArrayLength(2, 0, 0);
              ip = 76;
        end

         76 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 68;
        end

         77 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 78;
        end

         78 :
        begin                                                                   // arraySize
if (0) begin
  $display("AAAA %4d %4d arraySize", steps, ip);
end
              localMem[11] = arraySizes[localMem[1]];
              ip = 79;
        end

         79 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 80;
        end

         80 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[12] = 0;
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 81;
        end

         81 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 82;
        end

         82 :
        begin                                                                   // jGe
if (0) begin
  $display("AAAA %4d %4d jGe", steps, ip);
end
              ip = localMem[12] >= localMem[11] ? 90 : 83;
        end

         83 :
        begin                                                                   // movRead1
if (0) begin
  $display("AAAA %4d %4d movRead1", steps, ip);
end
              heapAddress = localMem[1]*8 + localMem[12];                                                 // Address of the item we wish to read from heap memory
              heapWrite = 0;                                                    // Request a read, not a write
              heapClock = 1;                                                    // Start read
              ip = 84;                                                          // Next instruction
        end

         84 :
        begin                                                                   // movRead2
if (0) begin
  $display("AAAA %4d %4d movRead2", steps, ip);
end
              localMem[29] = heapOut;                                                     // Data retrieved from heap memory
              heapClock = 0;                                                    // Ready for next operation
              ip = 85;                                                          // Next instruction
        end

         85 :
        begin                                                                   // mov
if (0) begin
  $display("AAAA %4d %4d mov", steps, ip);
end
              localMem[13] = localMem[29];
              updateArrayLength(2, 0, 0);                                   // We should do this in the heap memory module
              ip = 86;
        end

         86 :
        begin                                                                   // out
if (0) begin
  $display("AAAA %4d %4d out", steps, ip);
end
              outMem[outMemPos] = localMem[13];
              outMemPos = outMemPos + 1;
              ip = 87;
        end

         87 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 88;
        end

         88 :
        begin                                                                   // add
if (0) begin
  $display("AAAA %4d %4d add", steps, ip);
end
              localMem[12] = localMem[12] + 1;
              updateArrayLength(2, 0, 0);
              ip = 89;
        end

         89 :
        begin                                                                   // jmp
if (0) begin
  $display("AAAA %4d %4d jmp", steps, ip);
end
              ip = 81;
        end

         90 :
        begin                                                                   // label
if (0) begin
  $display("AAAA %4d %4d label", steps, ip);
end
              ip = 91;
        end
      endcase
      if (0) begin
        for(i = 0; i < 200; i = i + 1) $write("%2d",   localMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d",    heapMem[i]); $display("");
        for(i = 0; i < 200; i = i + 1) $write("%2d", arraySizes[i]); $display("");
      end
      success  = 1;
      success  = success && outMem[0] == 11;
      success  = success && outMem[1] == 22;
      success  = success && outMem[2] == 33;
      success  = success && outMem[3] == 44;
      success  = success && outMem[4] == 55;
      success  = success && outMem[5] == 66;
      success  = success && outMem[6] == 77;
      success  = success && outMem[7] == 88;
      success  = success && outMem[8] == 99;
      success  = success && outMem[9] == 101;
      success  = success && outMem[10] == 11;
      success  = success && outMem[11] == 88;
      success  = success && outMem[12] == 33;
      success  = success && outMem[13] == 44;
      success  = success && outMem[14] == 55;
      success  = success && outMem[15] == 66;
      success  = success && outMem[16] == 77;
      success  = success && outMem[17] == 88;
      success  = success && outMem[18] == 99;
      success  = success && outMem[19] == 101;
      finished = steps >    244;
    end
  end

endmodule

module heapMemory
 (input wire clk,
  input wire write,
  input wire [MEM_SIZE-1:0] address,
  input wire [DATA_WIDTH-1:0] in,
  output reg [DATA_WIDTH-1:0] out);

  parameter integer MEM_SIZE   = 12;
  parameter integer DATA_WIDTH = 12;

  reg [DATA_WIDTH-1:0] memory [2**MEM_SIZE:0];

  always @(posedge clk) begin
    if (write) begin
      memory[address] = in;
      out = in;
    end
    else out = memory[address];
  end
endmodule
