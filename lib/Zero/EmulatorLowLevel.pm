#!/usr/bin/perl -I../lib/ -Ilib
#-------------------------------------------------------------------------------
# Assemble and execute code written in the Zero assembler programming language.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
# Pointless adds and subtracts by 0. Perhaps we should flag adds and subtracts by 1 as well so we can have an instruction optimized for these variants.
# Assign needs to know from whence we got the value so we can write a better error message when it is no good
# Count number of ways an if statement actually goes.
# doubleWrite, not read, rewrite need make-over
# Initially array dimensions were set automatically by assignment to and array - now we require the resize operation or push/pop; to set the array size
# Check whether the array being accessed is actually allocated
# Setting the array size on Mov means that we probably do not need all the resizes
# Check wether iverilog supports multi dimensional arrays and if so can we use this in the string model ?
# Area size must be a power of 2 to avoid multiplication **see containingPowerOfTwo
use v5.30;
package Zero::Emulator;
our $VERSION = 20230519;                                                        # Version
use warnings FATAL=>qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Time::HiRes qw(time);
eval "use Test::More tests=>210" unless caller;

makeDieConfess;

my $traceExecution               =   0;                                         # Trace execution step by step printing memory at each step
my $memoryPrintWidth             = 200;                                         # How much memory to print
my $maximumInstructionsToExecute = 1e6;                                         # Maximum number of subroutines to execute

our $memoryTechnique;                                                           # Undef or the address of a sub that loads the memory handlers into an execution environment.

sub ExecutionEnvironment(%)                                                     # Execution environment for a block of code.
 {my (%options) = @_;                                                           # Execution options

  my $errors = setDifference(\%options, q(checkArrayNames code doubleWrite in maximumArraySize NotRead pointlessAssign sequentialTime stopOnError stringMemory suppressOutput trace lowLevel));
  keys %$errors and confess "Invalid options: ".dump($errors);

  my $exec=                 genHash(q(Zero::Emulator),                          # Emulator execution environment
    AllocMemoryArea=>      \&allocMemoryArea,                                   # Low level memory access - allocate new area
    assembly=>              $options{code},                                     # Block of code to be executed
    calls=>                 [],                                                 # Call stack
    checkArrayNames=>      ($options{checkArrayNames} // 1),                    # Check array names to confirm we are accessing the expected data
    count=>                 0,                                                  # Executed instructions count
    counts=>                {},                                                 # Executed instructions by name counts
    doubleWrite=>           {},                                                 # Source of double writes {instruction number} to count - an existing value was overwritten before it was used
    freedArrays=>           [],                                                 # Arrays that have been recently freed and can thus be reused
    FreeMemoryArea=>       \&freeMemoryArea,                                    # Low level memory access - free an area
    GetMemoryArea=>        \&getMemoryArea,                                     # Low level memory access - area
    GetMemoryArrays=>       \&getMemoryArrays,                                  # Low level memory access - arenas in use
    GetMemoryLocation=>    \&getMemoryLocation,                                 # Low level memory access - location
    Heap=>                 \&heap,                                              # Get the contents of the specified array
    in=>                    $options{in}//[],                                   # The input channel.  the L<In> instruction reads one element at a time from this array.
    inOriginally=>          [($options{in}//[])->@*],                           # A copy of the input channel that does not get consumed by the execution of  the program so that we can use it to construct tests
    instructionCounts=>     {},                                                 # The number of times each actual instruction is executed
    instructionPointer=>    0,                                                  # Current instruction
    lastAssignAddress=>     undef,                                              # Last assignment performed - address
    lastAssignArea=>        undef,                                              # Last assignment performed - area
    lastAssignArena=>       undef,                                              # Last assignment performed - arena
    lastAssignBefore=>      undef,                                              # Prior value of memory area before assignment
    lastAssignType=>        undef,                                              # Last assignment performed - name of area assigned into
    lastAssignValue=>       undef,                                              # Last assignment performed - value
    memory=>                [],                                                 # Memory contents at the end of execution
    memoryStringElementWidth=> 0,                                               # Width in bytes of a memory area element
    memoryString=>          '',                                                 # Memory packed into one string
    memoryStringLengths=>   [],                                                 # Lengths of each array
    memoryStringElements=>   0,                                                 # Maximum number of elements in an array on the heap
    memoryType=>            [],                                                 # Memory contents at the end of execution
    mostArrays=>            [],                                                 # The maximum number of arrays active at any point during the execution in each arena
    namesOfWidestArrays=>   [],                                                 # The name of the widest arrays in each arena
    notExecuted=>           [],                                                 # Instructions not executed
    out=>                   '',                                                 # The out channel. L<Out> writes an array of items to this followed by a new line.  L<out> does the same but without the new line.
    parallelLastStart=>     [],                                                 # Point in time at which last parallel section started
    parallelLongest=>       [],                                                 # Longest paralle section so far
    pointlessAssign=>       {},                                                 # Location already has the specified value
    PopMemoryArea=>        \&popMemoryArea,                                     # Low level memory access - pop from area
    printDoubleWrite=>      $options{doubleWrite},                              # Double writes: earlier instruction number to later instruction number
    PrintHeap=>            \&printHeap,                                         # Print heap memory
    PrintLocal=>           \&printLocal,                                        # Print local memory
    printPointlessAssign=>  $options{pointlessAssign},                          # Pointless assigns {instruction number} to count - address already has the specified value
    PushMemoryArea=>       \&pushMemoryArea,                                    # Low level memory access - push onto area
    read=>                  [],                                                 # Records whether a memory address was ever read allowing us to find all the unused locations
    ResizeMemoryArea=>     \&resizeMemoryArea,                                  # Low level memory access - resize an area
    rw=>                    [],                                                 # Read / write access to memory
    stopOnError=>           $options{stopOnError},                              # Stop on non fatal errors if true
    suppressOutput=>        $options{suppressOutput},                           # If true the Out instruction will only write to the execution out array but not to stdout as well.
    tally=>                 0,                                                  # Tally executed instructions in a bin of this name
    tallyCount=>            0,                                                  # Executed instructions tally count
    tallyCounts=>           {},                                                 # Executed instructions by name tally counts
    tallyTotal=>            {},                                                 # Total instructions executed in each tally
    timeParallel=>          0,                                                  # Notional time elapsed since start with parallelism taken into account
    timeSequential=>        0,                                                  # Notional time elapsed since start without parellelism
    timeDelta=>             undef,                                              # Time for last instruction if something other than 1
    totalInstructions=>     0,                                                  # Count of every instruction executed
    totalLabels=>           0,                                                  # Count of every label instruction executed
    trace=>                 $options{trace},                                    # Trace all statements
    traceLabels=>           undef,                                              # Trace changes in execution flow
    watch=>                 [],                                                 # Addresses to watch for changes
    widestAreaInArena=>     [],                                                 # Track highest array access in each arena
    latestLeftTarget=>      undef,                                              # The most recent value of the target operand evaluated as a left operand
    latestRightSource=>     undef,                                              # The most recent value of the source operand evaluated as a right operand
    compileToVerilogTests=> {},                                                 # Make sure that all the compile to verilog tests have distinct names
    movReadAddress=>undef,                                                      # The address we wish to read during a read memory operation
   );

  $memoryTechnique->($exec)       if $memoryTechnique;                          # Load memory handlers if a different memory handling system has been requested
  $exec->setOriginalMemoryTechnique;                                            # Standard memory handlers
  $exec->setStringMemoryTechnique if $options{stringMemory};                    # Optionally override memory handlers if a different memory handling system has been requested

  if (defined(my $n = $options{maximumArraySize}))                              # Override the maximum number of elements in an array from the default setting if requested
   {$exec->memoryStringElements  = $n;
   }

  $exec
 }

my sub stackFrame(%)                                                            # Describe an entry on the call stack: the return address, the parameter list length, the parameter list address, the line of code from which the call was made, the file number of the file from which the call was made
 {my (%options) = @_;                                                           # Parameters

  genHash(q(Zero::Emulator::StackFrame),                                        # Description of a stack frame. A stack frame provides the context in which a method runs.
    target=>       $options{target},                                            # The address of the subroutine being called
    instruction=>  $options{call},                                              # The address of the instruction making the call
    stackArea=>    $options{stackArea},                                         # Memory area containing data for this method
    params=>       $options{params},                                            # Memory area containing parameter list
    return=>       $options{return},                                            # Memory area containing returned result
    line=>         $options{line},                                              # The line number from which the call was made
    file=>         $options{file},                                              # The file number from which the call was made - this could be folded into the line number but for reasons best known to themselves people who cannot program very well often scatter projects across several files a practice that is completely pointless in this day of git and so can only lead to chaos and confusion
    variables=>    $options{variables},                                         # Variables local to this stack frame
  );
 }

sub Instruction(%)                                                              #P Create a new instruction.
 {my (%options) = @_;                                                           # Options

  my ($package, $fileName, $line) = caller($options{level} // 1);

  my sub stackTrace()                                                           # File numbers and line numbers of callers
   {my @s;
    for my $c(1..99)
     {my @c = caller($c);
      last unless @c;
      push @s, [$c[1], $c[2]];
     }
    \@s
   };

  genHash(q(Zero::Emulator::Assembly::Instruction),                             # Instruction details
    action=>    $options{action },                                              # Instruction name
    number=>    $options{number },                                              # Instruction sequence number
    source=>    $options{source },                                              # Source memory address
    source2=>   $options{source2},                                              # Secondary source memory address
    target=>    $options{target },                                              # Target memory address
    jump=>      $options{jump   },                                              # Jump target
    line=>      $line,                                                          # Line in source file at which this instruction was encoded
    file=>      fne $fileName,                                                  # Source file in which instruction was encoded
    context=>   stackTrace(),                                                   # The call context in which this instruction was created
    executed=>  0,                                                              # The number of times this instruction was executed
    step=>      0,                                                              # The last time (in steps from the start) that this instruction was executed
    entry=>     0,                                                              # An entry point into the code
  );
 }

sub Zero::Emulator::Assembly::instruction($%)                                   #P Create a new instruction and add it to the specified assembly
 {my ($block, %options) = @_;                                                   # Block of code descriptor, options

  if ($options{action} !~ m(\Avariable\Z)i)                                     # Non variable instruction - variable instructions create data not code
   {my $i = Instruction(%options);                                              # Instruction
    push $block->code->@*, $i;                                                  # Add to assembly
    return $i;                                                                  # Return new instruction
   }
 }

sub Zero::Emulator::Assembly::codeToString($)                                   #P Code as a string.
 {my ($assembly) = @_;                                                          # Block of code
  @_ == 1 or confess "One parameter";
  my @T;
  my @code = $assembly->code->@*;

  for my $i(@code)
   {my $n = $i->number//-1;
    my $a = $i->action;
    my $t = $assembly->referenceToString($i->{target},  0);
    my $s = $assembly->referenceToString($i->{source},  1);
    my $S = $assembly->referenceToString($i->{source2}, 2);
    my $T = sprintf "%04d  %8s %12s  %12s  %12s", $n, $a, $t, $s, $S;
    push @T, $T =~ s(\s+\Z) ()sr;
   }
  join "\n", @T, '';
 }

my sub contextString($$$)                                                       #P Stack trace back for this instruction.
 {my ($exec, $i, $title) = @_;                                                  # Execution environment, Instruction, title
  @_ == 3 or confess "Three parameters";
  my @s = $title;
  if (! $exec->suppressOutput)
   {for my $c($i->context->@*)
     {push @s, sprintf "    at %s line %d", $$c[0], $$c[1];
     }
   }
  join "\n", @s
 }

sub Zero::Emulator::Assembly::Instruction::contextString($)                     #P Stack trace back for this instruction.
 {my ($i) = @_;                                                                 # Instruction
  @_ == 1 or confess "One parameter";
  my @s;
  for my $c($i->context->@*)
   {push @s, sprintf "    at %s line %d", $$c[0], $$c[1];
   }
  @s;
 }

sub AreaStructure($@)                                                           # Describe a data structure mapping a memory area.
 {my ($structureName, @names) = @_;                                             # Structure name, fields names

  my $d = genHash(q(Zero::Emulator::AreaStructure),                             # Description of a data structure mapping a memory area
    structureName=>  $structureName,                                            # Name of the structure
    fieldOrder=>     [],                                                        # Order of the elements in the structure, in effect, giving the offset of each element in the data structure
    fieldNames=>     {},                                                        # Maps the names of the fields to their offsets in the structure
   );
  $d->field($_) for @names;                                                     # Add the field descriptions
  $d
 }

sub Zero::Emulator::AreaStructure::count($)                                     #P Number of fields in a data structure.
 {my ($d) = @_;                                                                 # Area structure
  scalar $d->fieldOrder->@*
 }

sub Zero::Emulator::AreaStructure::name($$)                                     #P Add a field to a data structure.
 {my ($d, $name) = @_;                                                          # Parameters
  @_ == 2 or confess "Two parameters";
  if (!defined $d->fieldNames->{$name})
   {$d->fieldNames->{$name} = $d->fieldOrder->@*;
    push $d->fieldOrder->@*, $name;
   }
  else
   {confess "Duplicate name: $name in structure: ".$d->name;
   }
  \($d->fieldNames->{$name})
 }

sub Zero::Emulator::AreaStructure::registers($)                                 #P Create one or more temporary variables. Need to reuse registers no longer in use.
 {my ($d, $count) = @_;                                                         # Parameters
  @_ == 1 or confess "One parameter";
  if (!defined($count))
   {my $o = $d->fieldOrder->@*;
    push $d->fieldOrder->@*, undef;
    return \$o;                                                                 # One temporary
   }
  map {__SUB__->($d)} 1..$count;                                                # Array of temporaries
 }

sub Zero::Emulator::AreaStructure::offset($$)                                   #P Offset of a field in a data structure.
 {my ($d, $name) = @_;                                                          # Parameters
  @_ == 2 or confess "Two parameters";
  if (defined(my $n = $d->fieldNames->{$name})){return $n}
  confess "No such name: '$name' in structure: ".$d->structureName;
 }

sub Zero::Emulator::AreaStructure::address($$)                                  #P Address of a field in a data structure.
 {my ($d, $name) = @_;                                                          # Parameters
  @_ == 2 or confess "Two parameters";
  if (defined(my $n = $d->fieldNames->{$name})){return \$n}
  confess "No such name: '$name' in structure: ".$d->structureName;
 }

sub Zero::Emulator::Procedure::registers($)                                     #P Allocate a register within a procedure.
 {my ($procedure) = @_;                                                         # Procedure description
  @_ == 1 or confess "One parameter";
  $procedure->variables->registers();
 }

my sub isScalar($)                                                              # Check whether an element is a scalar or an array
 {my ($value) = @_;                                                             # Parameters
  ! ref $value;
 }

my sub refDepth($)                                                              #P The depth of a reference.
 {my ($ref) = @_;                                                               # Reference to pack
  return 0 if isScalar(  $ref);
  return 1 if isScalar( $$ref);
  return 2 if isScalar($$$ref);
  confess "Reference too deep".dump($ref);
 }

my sub refValue($)                                                              #P The value of a reference after dereferencing.
 {my ($ref) = @_;                                                               # Reference to pack
  return   $ref if isScalar($ref);
  return  $$ref if isScalar($$ref);
  return $$$ref if isScalar($$$ref);
  confess "Reference too deep".dump($ref);
 }

# Memory is subdivided into arenas that hold items of similar types, sizes, access orders etc. in an attempt to minimize memory fragmentation
my sub arenaNull  {0}                                                           # A reference to this arena indicates tht the address has not been supplied
my sub arenaHeap  {1}                                                           # Allocations whose location is dynamically allocated as the program runs
my sub arenaLocal {2}                                                           # Variables whose location is fixed at compile time
my sub arenaParms {3}                                                           # Parameter areas
my sub arenaReturn{4}                                                           # Return areas

sub Zero::Emulator::Assembly::referenceToString($$$)                            #P Reference as a string.
 {my ($block, $r, $operand) = @_;                                               # Block of code, reference, operand type : 0-Target 1-Source 2-Source2
  @_ == 3 or confess "Three parameters";

  return "" unless defined $r;
  ref($r) =~ m(Reference) or confess "Must be a reference, not: ".dump($r);
  return "" if $r->arena == arenaNull;                                          # Empty reference

  if ($operand == 0)
   {if ($r->arena == arenaLocal)
     {my  $a = $r->address; my $da = $r->dAddress;
      return dump \\$a if $da == 2;
      return dump   $a
     }
    else
     {my $A = $r->area;    my $dA = $r->dArea;
      my $a = $r->address; my $da = $r->dAddress;
      my $n = $r->name;    my $d  = $r->delta;

      return dump [\$A, \\$a, $n, $d] if $dA == 1 && $da == 2;
      return dump [\$A,   $a, $n, $d] if $dA == 1 && $da == 1;
      return dump [ $A, \\$a, $n, $d] if $dA == 0 && $da == 2;
      return dump [ $A,   $a, $n, $d] if $dA == 0 && $da == 1;
      confess "Area depth: $dA, address $da";
     }
   }
  else
   {if ($r->arena == arenaLocal)
     {return "" unless my $a = $r->address;
      return dump \\$a if $r->dAddress == 2;
      return dump  \$a if $r->dAddress == 1;
      return dump   $a
     }
    else
     {my $A = $r->area;    my $dA = $r->dArea;
      my $a = $r->address; my $da = $r->dAddress;
      my $n = $r->name;    my $d  = $r->delta;

      return dump [\$A, \\$a, $n, $d] if $dA == 1 && $da == 2;
      return dump [\$A,  \$a, $n, $d] if $dA == 1 && $da == 1;
      return dump [\$A,   $a, $n, $d] if $dA == 1 && $da == 0;
      return dump [ $A, \\$a, $n, $d] if $dA == 0 && $da == 2;
      return dump [ $A,  \$a, $n, $d] if $dA == 0 && $da == 1;
      return dump [ $A,   $a, $n, $d] if $dA == 0 && $da == 0;
      confess "Area depth: $dA, address $da";
     }
   }
  confess "ReferenceToString, operand: $operand ".dump($r);
 }

sub Zero::Emulator::Assembly::ArrayNameToNumber($$)                             #P Generate a unique number for this array name.
 {my ($code, $name) = @_;                                                       # Code block, array name

  if (defined(my $n = $code->arrayNames->{$name}))                              # Name already exists
   {return $n;
   }

  my $n = $code->arrayNames->{$name} = $code->arrayNumbers->@*;                 # Assign a number to this name
  push $code->arrayNumbers->@*, $name;                                          # Save new name
  $n
 }

sub Zero::Emulator::Assembly::ArrayNumberToName($$)                             #P Return the array name associated with an array number.
 {my ($code, $number) = @_;                                                     # Code block, array name

  $code->arrayNumbers->[$number] // $number
 }

my sub Reference($$$$$)                                                         # Create a new reference
 {my ($arena, $area, $address, $name, $delta) = @_;                             # Arena, array, address, name of area, delta if any to be applied to address.
  confess "Area too deep: ".    dump($area)    if refDepth($area)    > 1;       # Areas that are too deep represent programmer error
  confess "Address too deep: ". dump($address) if refDepth($address) > 2;       # Addresses that are too deep represent programmer error

  genHash(q(Zero::Emulator::Reference),
    arena=>     $arena,                                                         # Arrays are allocated in arenas in the hope of facilitating the reuse of freed memory
    area=>      refValue($area),                                                # The array number
    address=>   refValue($address),                                             # The index with in the array
    name=>      $name,                                                          # The name of the array. Naming the array allows a check to be performed to ensure that the expected type of array is being manipulated
    delta=>     $delta,                                                         # An constant increment or decrement to the address which sometimes allows the elimination of extra L<Add> and L<Subtract> instructions.
    dArea=>     refDepth($area),                                                # Depth of area reference
    dAddress=>  refDepth($address),                                             # Depth of address reference
   );
 }

sub Zero::Emulator::Assembly::Reference($$$)                                    # convert an array rfernce or scalar into a reference
 {my ($code, $r, $operand) = @_;                                                # Code block, reference, type of reference: 0-Target 1-Source 2-Source2
  @_ == 3 or confess "Three parameters";
  ref($r) and ref($r) !~ m(\A(array|scalar|ref)\Z)i and confess "Scalar or scalar reference or array reference required, not: ".dump($r);
  my $arena = ref($r) =~ m(\Aarray\Z)i ? arenaHeap : arenaLocal;                # Local variables are variables that are not on the heap

  if (ref($r) =~ m(array)i)                                                     # Reference represented as [area, address, name, delta]
   {my ($area, $Address, $name, $delta) = @$r;                                  # Delta is oddly useful, as illustrated by examples/*Sort, in that it enables us to avoid adding or subtracting one with a separate instruction that does not achieve very much in one clock but that which, is otherwise necessary.
    defined($area) and !defined($name) and confess "Name required for address specification: in [Area, address, name]";
    my $address = isScalar($Address) ? \$Address : $Address;                    # A heap array reference can never be a constant
    return Reference($arena, $area, $address,
      $code->ArrayNameToNumber($name), $delta//0)
   }
  else                                                                          # Reference represented as an address
   {my $R = $operand == 0 && isScalar($r) ? \$r : $r;                           # A non heap item can be a constant depending if it is on the right hand side
    return Reference($arena, undef, $R, $code->ArrayNameToNumber('stackArea'),0);
   }
 }

sub Zero::Emulator::Procedure::call($)                                          #P Call a procedure.  Arguments are supplied by the L<ParamsPut> and L<ParamsGet> commands, return values are supplied by the L<ReturnPut> and L<ReturnGet> commands.
 {my ($procedure) = @_;                                                         # Procedure description
  @_ == 1 or confess "One parameter";
  Zero::Emulator::Call($procedure->target);
 }

sub Zero::Emulator::Assembly::lowLevelReplaceSource($$$)                        #P Convert a memory read from a source heap array into a move operation so that we can use a separate heap memory on the fpga. The instruction under consideration is at the top of the supplied instruction list. Add the move instruction and modify the original instruction if the source field can be replaced
 {my ($assembly, $block, $source) = @_;                                         # Assembly options, instructions, source field
  return unless my $i = $$block[-1];
  if (my $s = $$i{$source})                                                     # Source field to check
   {if (ref($s) =~ m(Reference) and $s->arena == arenaHeap)                     # Heap is source so replace
     {pop @$block;
      my $v = $assembly->variables->registers;                                  # Intermediate local source copy of heap
      my $m = Instruction(action=>"movRead1", target=>$$i{$source});            # Fetch from memory
      my $M = Instruction(action=>"movRead2", target=>$assembly->Reference($v, 0)); # Fetch from memory
      $$i{$source} = $assembly->Reference($v, 0);                               # Pick up retrieved result
      push @$block, $m, $M, $i;                                                 # New instruction sequence
     }
   }
 }

sub step()                                                                      # Create a step instruction
 {Instruction(action=>"step")
 }

sub Zero::Emulator::Assembly::lowLevelReplaceTarget($$)                         #P Convert a memory write to a target heap array into a move operation so that we can use a separate heap memory on the fpga. The instruction under consideration is at the top of the supplied instruction list. Add the move instruction and modify the original instruction if the source field can be replaced
 {my ($assembly, $instructions) = @_;                                           # Assembly options, instructions
  return unless my $i = $$instructions[-1];
  if (my $t = $$i{target})                                                      # Target field to check
   {if (ref($t) =~ m(Reference) and $t->arena == arenaHeap)                     # Heap is target so replace
     {my $v = $assembly->variables->registers;                                  # Intermediate local source copy of heap
      $$i{target} = $assembly->Reference($v, 0);                                # Update original instruction with new target
      my $m = Instruction(action=>"movWrite1",                                  # Put data into heap
        target=>$t, source=>$assembly->Reference($v, 1));
      push @$instructions, $m, step();                                          # New instruction sequence
     }
   }
 }

sub Zero::Emulator::Assembly::lowLevelReplace($$)                               #P Convert all heap memory operations in a scalar operation into moves so that we can use a separate heap memory on the fpga
 {my ($assembly, $instructions) = @_;                                           # Code block, array of instructions
  my $i = $$instructions[-1];
  my $a = $i->action;
  $assembly->lowLevelReplaceSource($instructions, q(source))  if $i->source;
  $assembly->lowLevelReplaceSource($instructions, q(source2)) if $i->source2;
  $assembly->lowLevelReplaceTarget($instructions)             if $i->target;
 }

sub Zero::Emulator::Assembly::lowLevel($)                                       #P Translate high level assember into low level assembler
 {my ($assembly) = @_;                                                          # Assembly
  my @l;                                                                        # The equivalent low level instruction sequence
  my $code = $assembly->code;                                                   # The code to be assembled

  for my $c(keys @$code)                                                        # Labels
   {my $i = $$code[$c];
    my $a = $i->action;
    push @l, $i;

    my $translations =                                                          # Translation of some high level instructions into actions on memory
     {push=> sub
       {$assembly->lowLevelReplaceSource(\@l, q(source));                       # Source might come from the heap
        push @l, Instruction(action=>"step");                                   # Step the clock
       },
     };

    if (my $translate = $$translations{$a})
     {&$translate;
     }
    else
     {$assembly->lowLevelReplace(\@l);
     }
   }

  $assembly->code = [@l];
 }

sub Zero::Emulator::Assembly::assemble($%)                                      #P Assemble a block of code to prepare it for execution.  This modifies the jump targets and so once assembled we cannot assembled again.
 {my ($assembly, %options) = @_;                                                # Code block, assembly options

  if (1 or $options{lowLevel})                                                  # Convert all heap memory operations into  mov's so that we can use a separate heap memory on the fpga
   {$assembly->lowLevelOps = 1;                                                 # Mark assembly for low level operations
    $assembly->lowLevel(%options);
   }

  my $code = $assembly->code;                                                   # The code to be assembled
  my $vars = $assembly->variables;                                              # The variables referenced by the code

  my %labels;                                                                   # Load labels
  my $stackFrame = AreaStructure("Stack");                                      # The current stack frame we are creating variables in

  for my $c(keys @$code)                                                        # Labels
   {my $i = $$code[$c];
    $i->number = $c;
    next unless $i->action eq "label";
    $labels{$i->source->address} = $c;                                          # Point label to instruction
   }

  for my $c(keys @$code)                                                        # Target jump and call instructions
   {my $i = $$code[$c];
    next unless $i->action =~ m(\A(j|call))i;
    if (my $l = $i->target->address)                                            # Label
     {if (defined(my $t = $labels{$l}))                                         # Found label
       {$i->jump = $assembly->Reference($t - $c, 1);                            # Relative jump.
        $$code[$t]->entry = $t - $c < 0  ? 1 : 0;                               # Such a jump could be negative which would make the target the start of an executable sub sequence
       }
      else
       {my $a = $i->action;
        confess "No target for $a to label: $l";
       }
     }
   }

  $$code[0]->entry = 1;                                                         # Execution starts at the first instruction
  $assembly->labels = {%labels};                                                # Labels created during assembly
  $assembly
 }

my sub currentStackFrame($)                                                     #P Address of current stack frame.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $calls = $exec->calls;
  @$calls > 0 or confess "No current stack frame";
  $$calls[-1]->stackArea;
 }

my sub currentParamsGet($)                                                      #P Address of current parameters to get from.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $calls = $exec->calls;
  @$calls > 1 or confess "No current parameters to get";
  $$calls[-2]->params;
 }

my sub currentParamsPut($)                                                      #P Address of current parameters to put to.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $calls = $exec->calls;
  @$calls > 0 or confess "No current parameters to put";
  $$calls[-1]->params;
 }

my sub currentReturnGet($)                                                      #P Address of current return to get from.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $calls = $exec->calls;
  @$calls > 0 or confess "No current return to get";
  $$calls[-1]->return;
 }

my sub currentReturnPut($)                                                      #P Address of current return to put to.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $calls = $exec->calls;
  @$calls > 1 or confess "No current return to put";
  $$calls[-2]->return;
 }

my sub dumpMemory($)                                                            #P Dump heap memory.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my @m;
  my $m = $exec->GetMemoryArrays->($exec);                                      # Memory areas
  for my $area(1..$m)                                                           # Each memory area except memory area 0 - which might once have been reserved for some purpose
   {my $h = $exec->heap($area);
    next unless defined $h and @$h;
    my $l = dump $exec->heap($area);
       $l = substr($l, 0, 100) if length($l) > 100;
       $l =~ s(\n) ( )gs;
    push @m, "$area=$l";
   }

  join "\n", @m, '';
 }

my sub getMemory($$$$$)                                                         #P Get from memory.
 {my ($exec, $arena, $area, $address, $name) = @_;                              # Execution environment, arena, area, address, expected name of area
  @_ == 5 or confess "Five parameters";
  $exec->checkArrayName($arena, $area, $name);
  my $v = $exec->GetMemoryLocation->($exec, $arena, $area, $address);
  if (!defined($$v))                                                            # Check we are getting a defined value.  If undefined values are acceptable use L<getMemoryAddress> and dereference the result.
   {my $n = $name // 'unknown';
    $exec->stackTraceAndExit
     ("Undefined memory accessed in arena: $arena, at area: $area ($n), address: $address\n");
   }
  $$v
 }

# These methods provide the original unlimited memory mechanism using multidimensional arrays

sub heap($$)                                                                    #P Return a heap entry.
 {my ($exec, $area) = @_;                                                       # Execution environment, area
  $exec->GetMemoryArea->($exec, arenaHeap, $area);
 }

sub getMemoryArrays($)                                                          #P Heaps.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  scalar($exec->memory->[arenaHeap]->@*)
 }

sub getMemoryArea($$$)                                                          #P Lowest level memory access to an area.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena, area
  @_ == 3 or confess "Three parameters";
  $exec->memory->[$arena][$area]
 }

sub getMemoryLocation($$$$)                                                     #P Lowest level memory access to an array: get the address of the indicated location in memory to enable a write to that location.   This method is replaceable to model different memory structures.
 {my ($exec, $arena, $area, $address) = @_;                                     # Execution environment, arena, area, address, expected name of area
  @_ == 4 or confess "Four parameters";

  $exec->trackWidestAreaInArena($arena, $address);                              # Track size of widest array

  \$exec->memory->[$arena][$area][$address];
 }

sub allocMemoryArea($$$$)                                                       #P Allocate a memory area.
 {my ($exec, $number, $arena, $area) = @_;                                      # Execution environment, name of allocation to bless result, arena to use, area to use
  @_ == 4 or confess "Four parameters";
  $exec->memory->[$arena][$area] = $number ? bless [], $number : [];            # Blessing with 0 is a very bad idea!
 }

sub freeMemoryArea($$$)                                                         #P Free a memory area.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena to use, area to use
  @_ == 3 or confess "Three parameters";
  $exec->memory->[$arena][$area] = [];
 }

sub resizeMemoryArea($$$)                                                       #P Resize an area in the heap.
 {my ($exec, $area, $size) = @_;                                                # Execution environment, area to use, new size
  @_ == 3 or confess "Three parameters";
  my $a = $exec->memory->[arenaHeap][$area];
  $#$a = $size-1;
 }

sub pushMemoryArea($$$)                                                         #P Push a value onto the specified array.
 {my ($exec, $area, $value) = @_;                                               # Execution environment, arena, array, value to assign
  @_ == 3 or confess "Three parameters";
  push $exec->memory->[arenaHeap][$area]->@*, $value;                           # Push
 }

sub popMemoryArea($$)                                                           #P Pop a value from the specified memory area if possible else confess.
 {my ($exec, $area) = @_;                                                       # Execution environment, arena, array,
  @_ == 2 or confess "Two parameters";
  my $a = $exec->memory->[arenaHeap][$area];
  if (!defined($a) or !$a->@*)                                                  # Area does not exists or has zero elements
   {stackTraceAndExit($exec, "Cannot pop array: $area");
   }
  pop @$a;                                                                      # Pop
 }

sub printLocal($)                                                               #P Print local memory
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my @p = join ' ', "Memory", map {sprintf "%4d", $_} 0..31;

  if (my $l = $exec->memory->[arenaLocal]->[0])                                 # Local storage
   {my @l = map {defined($_) ? sprintf "%4d", $_ : "****"} @$l;
    push @p, join " ", "Local:", @l;
   }

  join "\n", @p, '';
 }

sub printHeap($)                                                                #P Print memory
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my @p = join ' ', "Heap: |", map {sprintf "%2d", $_} 0..20;

  if (my $h = $exec->memory->[arenaHeap])                                       # Heap storage
   {my @heap = @$h;
    for my $area(0..$#heap)
     {my @area = $heap[$area]->@*;
      next unless @area;
      my @q = sprintf "%2d %2d |", $area, scalar(@area);
      for my $address(keys @area)
       {my $v = $area[$address];
        push @q, sprintf "%2d", $v if defined $v;
        push @q, q(**)         unless defined $v;
       }
      push @p, join(' ', @q);
     }
   }
  join "\n", @p, '';
 }

sub setOriginalMemoryTechnique($)                                               #P Set the handlers for the original memory allocation technique.
 {my ($exec) = @_;                                                              # Execution environment
  $exec->Heap              = \&heap;                                            # Low level memory access - content of an array
  #$exec->SetMemory         = \&setMemory;                                       # Low level memory access - set memory
  $exec->GetMemoryArrays    = \&getMemoryArrays;                                # Low level memory access - arena
  $exec->GetMemoryArea     = \&getMemoryArea;                                   # Low level memory access - area
  $exec->GetMemoryLocation = \&getMemoryLocation;                               # Low level memory access - location
  $exec->AllocMemoryArea   = \&allocMemoryArea;                                 # Low level memory access - allocate new area
  $exec->FreeMemoryArea    = \&freeMemoryArea;                                  # Low level memory access - free area
  $exec->ResizeMemoryArea  = \&resizeMemoryArea;                                # Low level memory access - resize a memory area
  $exec->PushMemoryArea    = \&pushMemoryArea;                                  # Low level memory access - push onto area
  $exec->PopMemoryArea     = \&popMemoryArea;                                   # Low level memory access - pop from area
  $exec->PrintHeap         = \&printHeap;                                       # Low level memory access - print heap memory
  $exec->PrintLocal        = \&printLocal;                                      # Low level memory access - print local memory
 }

# These methods place the heap arena in a vector string. Each area is up to a prespecified width wide. The current length of each such array is held in the first element.

sub stringHeap($$)                                                              #P Return a heap entry.
 {my ($exec, $area) = @_;                                                       # Execution environment, area
  my @p;
  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $t = $exec->memoryStringElements;                                          # User width of a heap area
  my $l = vec($exec->memoryStringLengths, $area, $w);
  for my $address(0..$l-1)
   {push @p, vec($exec->memoryString, $area * $t + $address, $w)                # Memory containing one element
   }
  \@p
 }

sub stringGetMemoryArrays($)                                                    #P Get number of arrays allocated in heap memory.
 {my ($exec) = @_;                                                              # Execution environment, arena
  @_ == 1 or confess "One parameter";

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  length($exec->memoryStringLengths) / ($w >> 3);                               # Number of arrays allocted in heap memory
 }

sub stringAreaSize($$)                                                          #P Current size of array
 {my ($exec, $area) = @_;                                                       # Execution environment, area
  @_ == 2 or confess "Two parameters";
  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  vec $exec->memoryStringLengths, $area, $w;                                    # Size array
 }

sub stringGetMemoryArea($$$$)                                                   #P Lowest level memory access to an area.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena, area
  @_ == 3 or confess "Three parameters";
  return getMemoryArea($exec, $arena, $area) if $arena != arenaHeap;            # Non heap objects continue as normal because the number of local variables and subroutines a human can produce in one lifetime are limited,

  my $l = stringAreaSize $exec, $area;                                          # Size of array
  my @o;
  for my $i(0..$l-1)                                                            # Check we are within the area
   {push @o, ${$exec->stringGetMemoryLocation($arena, $area, $i)};
   }
  [@o]
 }

sub stringGetMemoryLocation($$$$)                                               #P Lowest level memory access to an array: get the address of the indicated location in memory.   This method is replaceable to model different memory structures.
 {my ($exec, $arena, $area, $address) = @_;                                     # Execution environment, arena, area, address, expected name of area
  @_ == 4 or confess "Four parameters";
  if ($arena != arenaHeap)                                                      # Non heap  objects continue as normal because the number of local variables and subroutines a human can produce in one lifetime are limited,
   {return getMemoryLocation($exec, $arena, $area, $address);
   }

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $t = $exec->memoryStringElements;                                          # User width of a heap area
  $address < $t or confess "Address $address >= $t";                            # Check we are within the area

  if ($address+1 > vec($exec->memoryStringLengths, $area, $w))                  # Extend length of array if necessary
   {vec($exec->memoryStringLengths, $area, $w) = $address+1;
   }
  \vec($exec->memoryString, $area * $t + $address, $w)                          # Memory containing one element
 }

sub stringAllocMemoryArea($$$$)                                                 #P Allocate a memory area.
 {my ($exec, $number, $arena, $area) = @_;                                      # Execution environment, name of allocation to bless result, arena to use, area to use
  @_ == 4 or confess "Four parameters";
  return allocMemoryArea($exec, $number, $arena, $area) if $arena != arenaHeap; # Non heap objects continue as normal because the number of local variables and subroutines a human can produce in one lifetime are limited,

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an area
  vec($exec->memoryStringLengths, $area, $w) = 0;                               # Zero current length of area
 }

sub stringFreeMemoryArea($$$)                                                   #P Free a memory area.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena to use, area to use
  @_ == 3 or confess "Three parameters";
  return freeMemoryArea($exec, $arena, $area) if $arena != arenaHeap;           # Non heap  objects continue as normal because the number of local variables and subroutines a human can produce in one lifetime are limited,

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  vec($exec->memoryStringLengths, $area, $w) = 0;                               # Zero current length of area
 }

sub stringResizeMemoryArea($$$)                                                 #P Resize a heap memory area.
 {my ($exec, $area, $size) = @_;                                                # Execution environment, area to resize, new size
  @_ == 3 or confess "Three parameters";

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  vec($exec->memoryStringLengths, $area, $w) = $size;                           # Set new size
 }

sub stringPushMemoryArea($$$)                                                   #P Push a value onto the specified array.
 {my ($exec, $area, $value) = @_;                                               # Execution environment, arena, array, value to assign
  @_ == 3 or confess "Three parameters";

  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $t = $exec->memoryStringElements;                                          # User width of a heap area
  my $l = vec($exec->memoryStringLengths, $area, $w);                           # Length of area
  $l < $t-1 or                                                                  # Check there is enough space available
    confess "Area overflow, area: $area, "
    ."position: $l, value: $value";
  vec($exec->memoryString, $area*$t + $l, $w) = $value;                         # Push element
  vec($exec->memoryStringLengths, $area,  $w) = $l + 1;                         # Increase size of area
 }

sub stringPopMemoryArea($$)                                                     #P Pop a value from the specified memory area if possible else confess.
 {my ($exec, $area) = @_;                                                       # Execution environment, arena, array,
  @_ == 2 or confess "Two parameters";
  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $t = $exec->memoryStringElements;                                          # User width of a heap area
  my $l = vec($exec->memoryStringLengths, $area, $w);                           # Length of area
     $l-- > 0 or confess "Array underflow, array: $area";                       # Check we are within the area and pop
  my $v = vec($exec->memoryString,        $area*$t+$l, $w);                     # Pop element
          vec($exec->memoryStringLengths, $area,       $w) = $l;                # Decrease size of area
  $v
 }

sub stringPrintLocal($)                                                         #P Print string local memory
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $t = $exec->memoryStringElements;                                          # User width of a heap area

  my @p = join ' ', "Memory", map {sprintf "%4d", $_} 0..31;

  if (my $l = $exec->memory->[arenaLocal]->[0])
   {my @l = map {defined($_) ? sprintf "%4d", $_ : "****"} @$l;
    push @p, join " ", "Local:", @l;
   }

  join "\n", @p, '';
 }

sub printBlocksOfNumbers(@)                                                     #P Print blocks of numbers dumped from memory
 {my (@n) = @_;                                                              # Execution environment
  push @n, 0 while @n <= $memoryPrintWidth;
  pop  @n    while @n >  $memoryPrintWidth;
  my $s = join '', map {sprintf("%2d", ($_//0))} @n;
  say STDERR $s;
 }

sub stringPrintLocalSimple($)                                                   #P Print string local memory assimply as possible
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  return unless $w;                                                             # Detect whether we are in string memory mode or not
  my $s = $exec->memory->[arenaLocal]->[0];
  printBlocksOfNumbers @$s;
 }

sub stringPrintHeap($)                                                          #P Print string heap memory
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  my $t = $exec->memoryStringElements;                                          # User width of a heap area
  my $s = $exec->memoryString;

  my @p = join ' ', "Heap: |", map {sprintf "%2d", $_} 0..20;

  my $nArea = stringGetMemoryArrays $exec;                                      # Number of arrays in heap memory
  for my $a(0..$nArea-1)                                                        # Each array
   {my $l = stringAreaSize $exec, $a;                                           # Number of integers in array

    my @q = sprintf "%2d %2d |", $a, $l;
    for my $address(0..$l-1)                                                    # Active elements
     {push @q, sprintf "%2d", vec($s, $a*$t+$address, $w);
     }
    push @p, join ' ', @q;
   }

  join "\n", @p, '';
 }

sub stringPrintHeapSimple($)                                                    #P Print string heap memory as simply as possible
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  return unless $w;                                                             # Detect whether we are in string memory mode or not
  my $s = $exec->memoryString;
  my $l = length($s);
  my @v;
  for my $i(0..$l/4)
   {push @v, vec($s, $i, $w);
   }
  printBlocksOfNumbers @v;
 }

sub stringPrintHeapSizesSimple($)                                               #P Print the sizes of the arrays on the heap as simply as possible
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  my $w = $exec->memoryStringElementWidth;                                      # Width of each element in an an area
  return unless $w;                                                             # Detect whether we are in string memory mode or not
  my $s = $exec->memoryStringLengths;
  my $l = length($s);
  my @v;
  for my $i(0..$l/4)
   {push @v, vec($s, $i, $w);
   }

  printBlocksOfNumbers @v;
 }

sub setStringMemoryTechnique($)                                                 #P Set the handlers for the string memory allocation technique.
 {my ($exec) = @_;                                                              # Execution environment
  $exec->Heap              = \&stringHeap;                                      # Low level memory access - content of an array
  $exec->GetMemoryArrays   = \&stringGetMemoryArrays;                           # Low level memory access - arena
  $exec->GetMemoryArea     = \&stringGetMemoryArea;                             # Low level memory access - area
  $exec->GetMemoryLocation = \&stringGetMemoryLocation;                         # Low level memory access - location
  $exec->AllocMemoryArea   = \&stringAllocMemoryArea;                           # Low level memory access - allocate new area
  $exec->FreeMemoryArea    = \&stringFreeMemoryArea;                            # Low level memory access - free area
  $exec->ResizeMemoryArea  = \&stringResizeMemoryArea;                          # Low level memory access - resize a memory area
  $exec->PushMemoryArea    = \&stringPushMemoryArea;                            # Low level memory access - push onto area
  $exec->PopMemoryArea     = \&stringPopMemoryArea;                             # Low level memory access - pop from area
  $exec->memoryStringElementWidth = 32;                                         # Each element is 32 bits wide
  $exec->memoryStringElements     = 10;                                         # Number of elements on heap
  $exec->PrintHeap         = \&stringPrintHeap;                                 # Low level memory access - print heap memory
  $exec->PrintLocal        = \&stringPrintLocal;                                # Low level memory access - print local memory
  $exec->memoryString        = '';                                              # Low level memory access - array memory
  $exec->memoryStringLengths = '';                                              # Low level memory access - array lengths
 }

# End of memory implementation

my sub Address($$$$$$)                                                          #P Record a reference to memory.
 {my ($exec, $arena, $area, $address, $name, $delta) = @_;                      # Execution environment, arena, area, address in area, name of area, delta from specified address
  $exec =~ m(Emulator) or confess "Emulator execution environment required not: ".dump($exec);
  my $r = genHash(q(Zero::Emulator::Address),                                   # Address memory
    exec=>    $exec,                                                            # Execution environment for address
    arena=>   $arena,                                                           # Arena in memory
    area=>    $area,                                                            # Area in memory, either a number or a reference to a number indicating the level of indirection
    address=> $address,                                                         # Address within area, either a number or a reference to a number indicating the level of indirection
    name=>    $name // 'stackArea',                                             # Name of area
    delta=>  ($delta//0),                                                       # Offset from indicated address
   );
  $r
 }

sub Zero::Emulator::Address::dump($)                                            # Dump an address
 {my ($address) = @_;                                                           # Address
  my $r = $address->arena;
  my $a = $address->area;
  my $A = $address->address;
  my $n = $address->name;
  my $d = $address->delta;
  my $v = $address->getMemoryValue;

  say STDERR "arena: $r, area: $a, address: $A, name: $n, delta: $d, value: $v";
 }

sub Zero::Emulator::Address::getMemoryValue($)                                  #P Get the current value of a memory location identified by an address.
 {my ($a) = @_;                                                                 # Address
  @_ == 1 or confess "One parameter";
  getMemory($a->exec, $a->arena, $a->area, $a->address, $a->name);
 }

sub trackWidestAreaInArena($$$)                                                 # Track the width of the widest array in an area
 {my ($exec, $arena, $address) = @_;                                            # Execution environment, arena, address in arena
  $exec->widestAreaInArena->[$arena] =                                          # Track the widest area in each arena
    max($exec->widestAreaInArena->[$arena]//0, $address+1);                     # Addresses are zero based
 }

sub Zero::Emulator::Address::getMemoryAddress($)                                #P Get address of memory location from an address.
 {my ($a) = @_;                                                                 # Address
  @_ == 1 or confess "One parameter";

  my $exec    = $a->exec;                                                       # Execution environment
  my $arena   = $a->arena;                                                      # Arena
  my $area    = $a->area;                                                       # Area
  my $address = $a->address;                                                    # Address
  my $name    = $a->name;                                                       # Name

  $exec->trackWidestAreaInArena($arena, $address);                              # Track widest array in arena

  if ($exec->widestAreaInArena->[$arena] == $address)
   {$exec->namesOfWidestArrays->[$arena] = $exec->assembly->ArrayNumberToName($name);
   }

  $exec->checkArrayName($arena, $area, $name);                                  # Check area name
  $exec->GetMemoryLocation->($exec, $arena, $area, $address);                   # Read from memory
 }

my sub currentInstruction($)                                                    #P Locate current instruction.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  ref($exec) =~ m(Zero::Emulator) or confess "Zero::Emulator required, not: ".dump($exec);
  $exec->calls->[-1]->instruction;
 }

my sub stackTrace($;$)                                                          #P Create a stack trace.
 {my ($exec, $title) = @_;                                                      # Execution environment, title
  my $i = currentInstruction $exec;
  my $s = $exec->suppressOutput;                                                # Suppress file and line numbers in dump to facilitate automated testing
  my @t = contextString($exec, $i, $title//"Stack trace:");

  for my $j(reverse keys $exec->calls->@*)
   {my $c = $exec->calls->[$j];
    my $i = $c->instruction;
    push @t, sprintf "%5d  %4d %s", $j+1, $i->number+1, $i->action if $s;
    push @t, sprintf "%5d  %4d %-16s at %s line %d",
      $j+1, $i->number+1, $i->action, $i->file, $i->line       unless $s;
   }
  join "\n", @t, '';
 }

sub stackTraceAndExit($$%)                                                      #P Create a stack trace and exit from the emulated program.
 {my ($exec, $title, %options) = @_;                                            # Execution environment, title, options
  @_ >= 2 or confess "At least two parameters";

  my $t = stackTrace($exec, $title);
  $exec->output($t);
  confess $t unless $exec->suppressOutput;                                      # Confess if requested - presumably because this indicates an error in programming and thus nothing can be done about it within the program

  $exec->instructionPointer = undef;                                            # Execution terminates as soon as undefined instruction is encountered
  $t
 }

my $allocs = [];                                                                # Allocations

my sub allocMemory($$$)                                                         #P Create the name of a new memory area.
 {my ($exec, $number, $arena) = @_;                                             # Execution environment, name of allocation, arena to use
  @_ == 3 or confess "Three parameters";
  $number =~ m(\A\d+\Z) or confess "Array name must be numeric not : $number";
  my $f = $exec->freedArrays->[$arena];                                         # Reuse recently freed array if possible
  my $a = $f && @$f ? pop @$f : $$allocs[$arena]++;                             # Area id to reuse or use for the first time
  my $n = $exec->assembly->ArrayNumberToName($number);                             # Convert array name to number if possible
  $exec->AllocMemoryArea->($exec, $n, $arena, $a);                              # Create new area
  $exec->memoryType->[$arena][$a] = $number;
  $exec->mostArrays->[$arena] =                                                 # Track maximum size of each arena
    max $exec->mostArrays->[$arena]//0, scalar $allocs->[$arena];

  $a
 }

my sub freeArea($$$$)                                                           #P Free a heap memory area.
 {my ($exec, $arena, $area, $number) = @_;                                      # Execution environment, arena, array, name of allocation
  @_ == 4 or confess "Four parameters";
  $number =~ m(\A\d+\Z) or confess "Array name must be numeric not : $number";
  $exec->checkArrayName($arena, $area, $number);

  $exec->FreeMemoryArea->($exec, $arena, $area);

  push $exec->freedArrays->[$arena]->@*, $area;                                 # Save array for reuse
  $exec->memoryType->[$arena][$area] = undef;                                   # Mark the array as not in use
 }

my sub pushArea($$$$)                                                           #P Push a value onto the specified heap array.
 {my ($exec, $area, $name, $value) = @_;                                        # Execution environment, array, name of allocation, value to assign
  @_ == 4 or confess "Four parameters";
  $exec->checkArrayName(arenaHeap, $area, $name);                               # Confirm we are accessing the right kind of array
  $exec->PushMemoryArea->($exec, $area, $value);                                # Push value
  $exec->trackWidestAreaInArena(arenaHeap, $exec->areaLength($area));           # Track maximum width of the array
 }

my sub popArea($$$$)                                                            # Pop a value from the specified memory area if possible else confess.
 {my ($exec, $arena, $area, $name) = @_;                                        # Execution environment, arena, array, name of allocation, value to assign
  $exec->checkArrayName($arena, $area, $name);                                  # Check stack name
  $exec->PopMemoryArea->($exec, $area);
 }

sub getMemoryType($$$)                                                          #P Get the type of an area.
 {my ($exec, $arena, $area) = @_;                                               # Execution environment, arena, area
  @_ == 3 or confess "Three parameters";
  $exec->memoryType->[$arena][$area];
 }

sub rwWrite($$$$)                                                               #P Observe write to memory.
 {my ($exec, $arena, $area, $address) = @_;                                     # Execution environment, arena, area, address within area
  my $P = $exec->rw->[$arena][$area][$address];
  if (defined($P))
   {my $T = $exec->getMemoryType($arena, $area);
    my $M = getMemoryAddress($exec, $arena, $area, $address, $T);
    if ($$M)
     {my $Q = currentInstruction $exec;
      my $p = contextString($exec, $P, "Previous write");
      my $q = contextString($exec, $Q, "Current  write");
      $exec->doubleWrite->{$p}{$q}++;                                           # Writing the same thing into memory again - pointless
     }
   }
  $exec->rw->[$arena][$area][$address] = currentInstruction $exec;
 }

sub markAsRead($$$$)                                                            #P Mark a memory address as having been read from.
 {my ($exec, $arena, $area, $address) = @_;                                     # Execution environment, arena, area in memory, address within area
  @_ == 4 or confess "Four parameters";
  delete $exec->rw->[$arena][$area][$address];                                  # Clear last write operation
 }

sub rwRead($$$$)                                                                #P Observe read from memory.
 {my ($exec, $arena, $area, $address) = @_;                                     # Execution environment, arena, area in memory, address within area
  @_ == 4 or confess "Four parameters";
  if (defined(my $a = $exec->rw->[$arena][$area][$address]))                    # Can only read from locations that actually have something in them
   {$exec->markAsRead($arena, $area, $address);                                 # Clear last write operation
   $exec->read->[$arena][$area][$address]++;                                    # Track reads
   }
 }

my sub stackAreaNameNumber($)                                                   # Number of name representing stack area.
 {my ($exec) = @_;                                                              # Execution environment
  $exec->assembly->ArrayNameToNumber("stackArea");
 }

my sub left($$)                                                                 #P Address of a location in memory.
 {my ($exec, $ref) = @_;                                                        # Execution environment, reference
  @_ == 2 or confess "Two parameters";
  ref($ref)     =~ m(Reference) or confess "Reference required, not: ".dump($ref);
  my $address   = $ref->address;
  my $dAddress  = $ref->dAddress;
  my $arena     = $ref->arena;
  my $area      = $ref->area;
  my $delta     = $ref->delta;
  my $S         = currentStackFrame($exec);                                     # Current stack frame
  my $stackArea = stackAreaNameNumber($exec);

  my $M;                                                                        # Memory address
  if ($dAddress == 1)                                                           # Direct address
   {$M = $address + $delta;
   }
  elsif ($dAddress == 2)                                                        # Indirect address
   {$M = getMemory($exec, arenaLocal, $S, $address, $stackArea) + $delta;
   }
  else
   {confess "Address depth must be 1 or 2, not: ".dump($dAddress)
   };

  if (!$ref->dArea)                                                             # Current stack frame
   {my $a = Address($exec, arenaLocal, $S, $M, $ref->name, 0);                  # Stack frame
    return $a;
   }
  else                                                                          # Indirect area
   {my $A = getMemory($exec, arenaLocal, $S, $area, $stackArea);
    my $a = Address($exec, $arena, $A, $M, $ref->name, 0);
    return $a;
   }
 }

my sub right($$)                                                                #P Get a constant or a value from memory.
 {my ($exec, $ref) = @_;                                                        # Location, optional area
  @_ == 2 or confess "Two parameters";
  ref($ref) =~ m(Reference) or confess "Reference required, not:".dump($ref);
  my $address   = $ref->address;
  my $arena     = $ref->arena;
  my $area      = $ref->area;
  my $stackArea = currentStackFrame($exec);
  my $name      = $ref->name;
  my $delta     = $ref->delta;
  my $stackAN   = stackAreaNameNumber($exec);

  my $r;

  my sub invalid()                                                              # Invalid address
   {my $i = currentInstruction $exec;
    my $l = $i->line;
    my $f = $i->file;
    stackTraceAndExit($exec,
     "Undefined right hand value"
     ." arena: "  .dump($arena)
     ." area: "   .dump($area)
     ." address: ".dump($a)
     ." stack: ".currentStackFrame($exec));
   }

  if ($arena == arenaNull)                                                      # Empty reference
   {return 0;
   }

  if ($ref->dAddress == 0)                                                      # Constant
   {return $address if defined $address;                                        # Attempting to read an address that has never been set is an error
    invalid;
   }

  my $m;
  my $memory = $exec->memory;

  if ($ref->dAddress == 1)                                                      # Direct
   {$m = $address + $delta;
   }
  else                                                                          # Indirect
   {my $d = getMemory($exec, arenaLocal, $stackArea, $address, $stackAN);
       $m = $d + $delta;
   }

  if (!$ref->dArea)                                                             # Stack frame
   {$r = getMemory($exec, arenaLocal, $stackArea, $m, $stackAN);                # Direct from stack area
   }
  else                                                                          # Indirect from stack area
   {my $j = getMemory($exec, arenaLocal, $stackArea, $area, $stackAN);
    if (defined $j)
     {$r = getMemory($exec, $arena, $j, $m, $ref->name);
     }
   }

  invalid() unless defined $r;
  $r
 }

my sub jumpOp($$$)                                                              #P Jump to the target address if the tested memory area if the condition is matched.
 {my ($exec, $i, $check) = @_;                                                  # Execution environment, Instruction, check
  @_ == 3 or confess "Three parameters";
  $exec->instructionPointer = $i->number + right($exec, $i->jump) if &$check;   # Check if condition is met
 }

my sub assert1($$$)                                                             #P Assert true or false.
 {my ($exec, $test, $sub) = @_;                                                 # Execution environment, Text of test, subroutine of test
  @_ == 3 or confess "Three parameters";
  my $i = currentInstruction $exec;
  my $a = right $exec, $i->source;
  unless($sub->($a))
   {stackTraceAndExit($exec, "Assert$test $a failed");
   }
  $exec->timeDelta = 0;
 }

my sub assert2($$$)                                                             #P Assert generically.
 {my ($exec, $test, $sub) = @_;                                                 # Execution environment, Text of test, subroutine of test
  @_ == 3 or confess "Three parameters";
  my $i = currentInstruction $exec;
  my ($a, $b) = (right($exec, $i->source), right($exec, $i->source2));
  unless($sub->($a, $b))
   {stackTraceAndExit($exec, "Assert $a $test $b failed");
   }
  $exec->timeDelta = 0;
 }

my sub assign($$$)                                                              #P Assign - check for pointless assignments.
 {my ($exec, $target, $value) = @_;                                             # Execution environment, Target of assign, value to assign
  @_ == 3 or confess "Three parameters";
  ref($target) =~ m(Address)i or confess "Not an address: ".dump($target);
  !ref($value) or confess "Not a  scalar value".dump($value);

  my $arena   = $target->arena;
  my $area    = $target->area;
  my $address = $target->address;
  my $name    = $target->name;
  $exec->checkArrayName($arena, $area, $name);

  if (!defined($value))                                                         # Check that the assign is not pointless
   {stackTraceAndExit($exec,
    "Cannot assign an undefined value to arena: $arena, area: $area($name),"
    ." address: $address");
   }
  else
   {my $currently = $target->getMemoryAddress;
    if (defined $$currently)
     {if ($$currently == $value)
       {$exec->pointlessAssign->{currentInstruction($exec)->number}++;          # Record the pointless assign
        if ($exec->stopOnError)
         {stackTraceAndExit($exec, "Pointless assign of: $$currently "
          ."to arena: $arena, area: $area($name), at: $address");
         }
       }
     }
   }

  if (defined $exec->watch->[$area][$address])                                  # Watch for specified changes
   {my $n = $exec->assembly->ArrayNumberToName($name) // "unknown";
    my @s = stackTrace($exec, "Change at watched "
     ."arena: $arena, area: $area($n), address: $address");
    $s[-1] .= join ' ', "Current value:", getMemory($exec, $arena, $area, $address, $name),
                        "New value:", $value;
    my $s = join "", @s;
    say STDERR $s unless $exec->suppressOutput;
    $exec->output("$s\n");
   }

  $exec->lastAssignArena   = $arena;
  $exec->lastAssignArea    = $area;
  $exec->lastAssignAddress = $address;
  $exec->lastAssignType    = $exec->getMemoryType($arena, $area);
  $exec->lastAssignValue   = $value;
  $exec->lastAssignBefore  = $target->getMemoryAddress->$*;

  my $a = $exec->GetMemoryLocation->($exec, $arena, $area, $address);
  $$a = $value;
 }

my sub stackAreaNumber($)                                                       #P Number for type of stack area array.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  $exec->assembly->ArrayNameToNumber("stackArea")
 }

my sub paramsNumber($)                                                          #P Number for type of parameters array.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  $exec->assembly->ArrayNameToNumber("params")
 }

my sub returnNumber($)                                                          #P Number for type of return area array.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  $exec->assembly->ArrayNameToNumber("return")
 }

my sub allocateSystemAreas($)                                                   #P Allocate system areas for a new stack frame.
 {my ($exec) = @_;                                                              # Execution environment
  @_ == 1 or confess "One parameter";
  (stackArea=> allocMemory($exec, stackAreaNameNumber($exec), arenaLocal),
   params=>    allocMemory($exec, paramsNumber($exec),        arenaParms),
   return=>    allocMemory($exec, returnNumber($exec),        arenaReturn));
 }

my sub freeSystemAreas($$)                                                      #P Free system areas for the specified stack frame.
 {my ($exec, $c) = @_;                                                          # Execution environment, stack frame
  @_ == 2 or confess "Two parameters";
  freeArea($exec, arenaLocal,  $c->stackArea, stackAreaNumber($exec));
  freeArea($exec, arenaParms,  $c->params,    paramsNumber($exec));
  freeArea($exec, arenaReturn, $c->return,    returnNumber($exec));
 }

my sub createInitialStackEntry($)                                               #P Create the initial stack frame.
 {my ($exec) = @_;                                                              # Execution environment
  my $variables = $exec->assembly->variables;
  my $nVariables = $variables->fieldOrder->@*;                                  # Number of variables in this stack frame

  push $exec->calls->@*,                                                        # Variables in initial stack frame
    stackFrame(
     $exec->assembly ? (variables=>  $variables) : (),
     allocateSystemAreas($exec));
  $exec
 }

sub checkArrayName($$$$)                                                        #P Check the name of an array.
 {my ($exec, $arena, $area, $number) = @_;                                      # Execution environment, arena, array, array name
  @_ == 4 or confess "Four parameters";

  return 1 unless $exec->checkArrayNames;                                       # Check the names of arrays if requested

  if (!defined($number))                                                        # A name is required
   {stackTraceAndExit($exec, "Array name required to size array: $area in arena $arena");
    return 0;
   }

  my $Number = $exec->getMemoryType($arena, $area);                             # Area has a name
  if (!defined($Number))
   {stackTraceAndExit($exec, "No such with array: $area in arena $arena");
    return 0;
   }
  if ($number != $Number)                                                       # Name does not match supplied name
   {my $n = $exec->assembly->ArrayNumberToName($number);
    my $N = $exec->assembly->ArrayNumberToName($Number);
    stackTraceAndExit($exec, "Wrong name: $n for array with name: $N");
    return 0;
   }

  1
 }

my sub areaContent($$)                                                          #P Content of an area containing a specified address in memory in the specified execution.
 {my ($exec, $ref) = @_;                                                        # Execution environment, reference to array
  @_ == 2 or confess "Two parameters";
  my $array = right($exec, $ref);
  my $a = $exec->heap($array);
  stackTraceAndExit($exec, "Invalid area: ".dump($array)) unless defined $a;
  @$a
 }

sub areaLength($$)                                                              #P Content of an area containing a specified address in memory in the specified execution.
 {my ($exec, $array) = @_;                                                      # Execution environment, reference to array
  @_ == 2 or confess "Two parameters";
  my $a = $exec->heap($array);
  return 0 unless defined $a;                                                   # Its entirely possible that the memory location has not yet been created
  stackTraceAndExit($exec, "Invalid area: ".dump($array)) unless defined $a;
  scalar @$a
 }

my sub locateAreaElement($$$)                                                   #P Locate an element in an array.  If there are multiple elements with the specified value the last such element is indexed
 {my ($exec, $ref, $op) = @_;                                                   # Execution environment, reference naming the array, operation

  my @a = areaContent($exec, $ref);
  for my $a(keys @a)                                                            # Check each element of the array
   {if ($op->($a[$a]))
     {return $a + 1;
     }
   }
  0
 }

my sub countAreaElement($$$)                                                    #P Count the number of elements in array that meet some specification.
 {my ($exec, $ref, $op) = @_;                                                   # Execution environment, reference naming the array, operation
  my @a = areaContent($exec, $ref);
  my $n = 0;

  for my $a(keys @a)                                                            # Check each element of the array
   {if ($op->($a[$a]))
     {++$n;
     }
   }

  $n
 }

sub output($$)                                                                  #P Write an item to the output channel. Items are separated with one blank each unless the caller has provided formatting with new lines.
 {my ($exec, $item) = @_;                                                       # Execution environment, item to write
  if ($exec->out and $exec->out !~ m(\n\Z) and $item !~ m(\A\n)s)
   {$exec->out .= " $item";
   }
  else
   {$exec->out .= $item;
   }
 }

sub outLines($)                                                                 #P Turn the output channel into an array of lines.
 {my ($exec) = @_;                                                              # Execution environment
  [split /\n/, $exec->out]
 }

sub analyzeExecutionResultsLeast($%)                                            #P Analyze execution results for least used code.
 {my ($exec, %options) = @_;                                                    # Execution results, options

  my @c = $exec->assembly->code->@*;
  my %l;
  for my $i(@c)                                                                 # Count executions of each instruction
   {$l{$i->file}{$i->line} += $i->executed unless $i->action =~ m(\Aassert)i;
   }

  my @L;
  for   my $f(keys %l)
   {for my $l(keys $l{$f}->%*)
     {push @L, [$l{$f}{$l}, $f, $l];
     }
   }
  my @l = sort {$$a[0] <=> $$b[0]}                                              # By frequency
          sort {$$a[2] <=> $$b[2]} @L;                                          # By line number

  my $N = $options{least}//1;
  $#l = $N if @l > $N;
  map {sprintf "%4d at %s line %4d", $$_[0], $$_[1], $$_[2]} @l;
 }

sub analyzeExecutionResultsMost($%)                                             #P Analyze execution results for most used code.
 {my ($exec, %options) = @_;                                                    # Execution results, options

  my @c = $exec->assembly->code->@*;
  my %m;
  for my $i(@c)                                                                 # Count executions of each instruction
   {my $t =                                                                     # Traceback
     join "\n", map {sprintf "    at %s line %4d", $$_[0], $$_[1]} $i->context->@*;
    $m{$t} += $i->executed;
   }
  my @m = reverse sort {$$a[1] <=> $$b[1]} map {[$_, $m{$_}]} keys %m;          # Sort a hash into value order
  my $N = $options{most}//1;
  $#m = $N if @m > $N;
  map{sprintf "%4d\n%s", $m[$_][1], $m[$_][0]} keys @m;
 }

sub analyzeExecutionResultsDoubleWrite($%)                                      #P Analyze execution results - double writes.
 {my ($exec, %options) = @_;                                                    # Execution results, options

  my @r;

  my $W = $exec->doubleWrite;
  if (keys %$W)
   {for my $p(sort keys %$W)
     {for my $q(keys $$W{$p}->%*)
       {push @r, sprintf "Double write occured %d  times. ", $$W{$p}{$q};
        if ($p eq $q)
         {push @r, "First  and second write\n$p\n";
         }
        else
         {push @r, "First  write:\n$p\n";
          push @r, "Second write:\n$q\n";
         }
       }
     }
   }
  @r
 }

sub analyzeExecutionResults($%)                                                 #P Analyze execution results.
 {my ($exec, %options) = @_;                                                    # Execution results, options

  my @r;

  if (1)
   {my @l = $exec->analyzeExecutionResultsLeast(%options);                      # Least/most executed
    my @m = $exec->analyzeExecutionResultsMost (%options);
    if (@l and $options{leastExecuted})
     {push @r, "Least executed:";
      push @r, @l;
     }
    if (@m and $options{mostExecuted})
     {push @r, "Most executed:";
      push @r, @m;
     }
   }

  if (my @d = $exec->analyzeExecutionResultsDoubleWrite(%options))              # Analyze execution results - double writes
   {my $d = @d;
    @d = () unless $options{doubleWrite};
    push @r, @d;
    push @r, sprintf "# %8d double writes", $d/2;
   }

  push @r,   sprintf "# %8d instructions executed", $exec->count;
  join "\n", @r;
 }

sub Zero::Emulator::Assembly::execute($%)                                       #P Execute a block of code.
 {my ($assembly, %options) = @_;                                                # Block of code, execution options

  $assembly->assemble(%options) if $assembly;                                   # Assemble unless we just want the instructions

  my $exec = ExecutionEnvironment(code=>$assembly, %options);                   # Create the execution environment

  my %instructions =                                                            # Instruction definitions
   (add=> sub                                                                   # Add the two source operands and store the result in the target
     {my $i = currentInstruction $exec;
      my $t = $exec->latestLeftTarget;
      my $a = $exec->latestRightSource;
      my $b = right $exec, $i->source2;
      assign($exec, $t, $a + $b);
     },

    subtract=> sub                                                              # Subtract the second source operand from the first and store the result in the target
     {my $i = currentInstruction $exec;
      my $t = $exec->latestLeftTarget;
      my $a = $exec->latestRightSource;
      my $b = right $exec, $i->source2;
      assign($exec, $t, $a - $b);
     },

    assert=> sub                                                                # Assert
     {my $i = currentInstruction $exec;
      stackTraceAndExit($exec, "Assert failed");
     },

    assertEq=> sub                                                              # Assert equals
     {assert2($exec, "==", sub {my ($a, $b) = @_; $a == $b})
     },

    assertNe=> sub                                                              # Assert not equals
     {assert2($exec, "!=", sub {my ($a, $b) = @_; $a != $b})
     },

    assertLt=> sub                                                              # Assert less than
     {assert2($exec, "< ", sub {my ($a, $b) = @_; $a <  $b})
     },

    assertLe=> sub                                                              # Assert less than or equal
     {assert2($exec, "<=", sub {my ($a, $b) = @_; $a <= $b})
     },

    assertGt=> sub                                                              # Assert greater than
     {assert2($exec, "> ", sub {my ($a, $b) = @_; $a >  $b})
     },

    assertGe=> sub                                                              # Assert greater
     {assert2($exec, ">=", sub {my ($a, $b) = @_; $a >= $b})
     },

    assertFalse=> sub                                                           # Assert false
     {assert1($exec, "False", sub {my ($a) = @_; $a == 0})
     },

    assertTrue=> sub                                                            # Assert true
     {assert1($exec, "True", sub {my ($a) = @_; $a != 0})
     },

    array=> sub                                                                 # Create a new memory area and write its number into the address named by the target operand
     {my $i = currentInstruction $exec;
      my $s = $exec->latestRightSource;
      my $a = allocMemory $exec, $s, arenaHeap;                                 # Allocate
      my $t = $exec->latestLeftTarget;                                          # Target in which to save array number
      assign $exec, $t, $a;                                                     # Save array number in target#
      $a
     },

    free=> sub                                                                  # Free the memory area named by the source operand
     {my $i = currentInstruction $exec;
      my $area = right $exec, $i->target;                                       # Area
      my $name = $exec->latestRightSource;
      freeArea($exec, arenaHeap, $area, $name);                                 # Free the area
     },

    arraySize=> sub                                                             # Get the size of the specified area
     {my $i = currentInstruction $exec;
      my $size = $exec->latestLeftTarget;                                       # Location to store size in
      my $area = $exec->latestRightSource;                                      # Location of area
      my $name = $i->source2;                                                   # Name of area

      $exec->checkArrayName(arenaHeap, $area, $name);                           # Check that the supplied array name matches what is actually in memory

      assign($exec, $size, areaLength($exec, $area))                            # Size of area
     },

    arrayIndex=> sub                                                            # Place the 1 based index of the second source operand in the array referenced by the first source operand in the target location
     {my $i = currentInstruction $exec;
      my $x = $exec->latestLeftTarget;                                          # Location to store index in
      my $e = right $exec, $i->source2;                                         # Location of element

      assign($exec, $x, locateAreaElement($exec, $i->source, sub{$_[0] == $e})) # Index of element
     },

    arrayCountGreater=> sub                                                     # Count the number of elements in the array specified by the first source operand that are greater than the element supplied by the second source operand and place the result in the target location
     {my $i = currentInstruction $exec;
      my $x = $exec->latestLeftTarget;                                          # Location to store index in
      my $e = right $exec, $i->source2;                                         # Location of element

      assign($exec, $x, countAreaElement($exec, $i->source, sub{$_[0] > $e}))   # Index of element
     },

    arrayCountLess=> sub                                                        # Count the number of elements in the array specified by the first source operand that are less than the element supplied by the second source operand and place the result in the target location
     {my $i = currentInstruction $exec;
      my $x = $exec->latestLeftTarget;                                          # Location to store index in
      my $e = right $exec, $i->source2;                                         # Location of element

      assign($exec, $x, countAreaElement($exec, $i->source, sub{$_[0] < $e}))   # Index of element
     },

    resize=> sub                                                                # Resize an array
     {my $i = currentInstruction $exec;
      my $size = $exec->latestRightSource;                                      # New size
      my $name = right $exec, $i->source2;                                      # Array name
      my $area = right $exec, $i->target;                                       # Array to resize
      $exec->checkArrayName(arenaHeap, $area, $name);
      $exec->ResizeMemoryArea->($exec, $area, $size);
     },

    call=> sub                                                                  # Call a subroutine
     {my $i = currentInstruction $exec;
      my $t = $i->jump->address;                                                # Subroutine to call

      if (isScalar($t))
       {$exec->instructionPointer = $i->number + $t;                            # Relative call if we know where the subroutine is relative to the call instruction
       }
      else
       {$exec->instructionPointer = $t;                                         # Absolute call
       }
      push $exec->calls->@*,
        stackFrame(target=>$assembly->code->[$exec->instructionPointer],        # Create a new call stack entry
        instruction=>$i, #variables=>$i->procedure->variables,
        allocateSystemAreas($exec));
     },

    return=> sub                                                                # Return from a subroutine call via the call stack
     {my $i = currentInstruction $exec;
      $exec->calls or stackTraceAndExit($exec, "The call stack is empty so I do not know where to return to");
      freeSystemAreas($exec, pop $exec->calls->@* );
      if ($exec->calls)
       {my $c = $exec->calls->[-1];
        $exec->instructionPointer = $c->instruction->number+1;
       }
      else
       {$exec->instructionPointer = undef;
       }
     },

    confess=> sub                                                               # Print the current call stack and stop
     {stackTraceAndExit($exec, "Confess at:", confess=>1);
     },

    trace=> sub                                                                 # Start/stop/change tracing status from a program. A trace writes out which instructions have been executed and how they affected memory
     {my $i = currentInstruction $exec;
      my $s = !!$exec->latestRightSource;
      $exec->trace = $s;
      my $m = "Trace: $s";
      say STDERR           $m unless $exec->suppressOutput;
      $exec->output("$m\n");
      $exec->timeDelta = 0;
     },

    traceLabels=> sub                                                           # Start trace points
     {my $i = currentInstruction $exec;
      my $s = !!$exec->latestRightSource;
      $exec->traceLabels = $s;
      my $m = "TraceLabels: $s";
      say STDERR           $m unless $exec->suppressOutput;
      $exec->output("$m\n");
      $exec->timeDelta = 0;
     },

    dump=> sub                                                                  # Dump memory
     {my $i = currentInstruction $exec;
      my   @m= dumpMemory $exec;
      push @m, stackTrace($exec);
      my $m = join '', @m;
      say STDERR $m unless $exec->suppressOutput;
      $exec->output($m);
      $exec->timeDelta = 0;
     },

    arrayDump=> sub                                                             # Dump array in memory
     {my $i = currentInstruction $exec;
      my $a = right $exec, $i->target;
      my $m = dump($exec->GetMemoryArea->($exec, arenaHeap, $a)) =~ s(\n) ()gsr;
      say STDERR $m unless $exec->suppressOutput;
      $exec->output("$m\n");
      $exec->timeDelta = 0;
     },

    arrayOut=> sub                                                              # Write array to the output channel
     {my $i = currentInstruction $exec;
      my $a = right $exec, $i->target;
      my $m = $exec->GetMemoryArea->($exec, arenaHeap, $a);
      $exec->output("$_\n") for @$m;
      $exec->timeDelta = 0;
     },

    in=> sub                                                                    # Read the next value from the input channel
     {my $i = currentInstruction $exec;
      my $t = $exec->latestLeftTarget;
      if ($exec->in->@*)
       {assign($exec, $t, shift $exec->in->@*);
       }
      else
       {stackTraceAndExit($exec, "Attempting to read beyond the end of the input channel")
       }
     },

    inSize=> sub                                                                # Number of items remining in the input channel
     {my $i = currentInstruction $exec;
      my $t = $exec->latestLeftTarget;
      assign($exec, $t, scalar $exec->in->@*);
     },

    jmp=> sub                                                                   # Jump to the target address
     {my $i = currentInstruction $exec;
      my $n = $i->number;
      #my $r = right $exec, $i->target;
      my $r = right($exec, $i->jump);
      $exec->instructionPointer = $n + $r;
     },
                                                                                # Conditional jumps
    jEq=>    sub {my $i = currentInstruction $exec; jumpOp($exec, $i, sub{$exec->latestRightSource == right($exec, $i->source2)})},
    jNe=>    sub {my $i = currentInstruction $exec; jumpOp($exec, $i, sub{$exec->latestRightSource != right($exec, $i->source2)})},
    jLe=>    sub {my $i = currentInstruction $exec; jumpOp($exec, $i, sub{$exec->latestRightSource <= right($exec, $i->source2)})},
    jLt=>    sub {my $i = currentInstruction $exec; jumpOp($exec, $i, sub{$exec->latestRightSource <  right($exec, $i->source2)})},
    jGe=>    sub {my $i = currentInstruction $exec; jumpOp($exec, $i, sub{$exec->latestRightSource >= right($exec, $i->source2)})},
    jGt=>    sub {my $i = currentInstruction $exec; jumpOp($exec, $i, sub{$exec->latestRightSource >  right($exec, $i->source2)})},
    jFalse=> sub {my $i = currentInstruction $exec; jumpOp($exec, $i, sub{$exec->latestRightSource == 0})},
    jTrue=>  sub {my $i = currentInstruction $exec; jumpOp($exec, $i, sub{$exec->latestRightSource != 0})},

    label=> sub                                                                 # Label - no operation
     {my ($i) = @_;                                                             # Instruction
      $exec->timeDelta = 0;
      return unless $exec->traceLabels;
      my $s = stackTrace($exec, "Label");
      say STDERR $s unless $exec->suppressOutput;
      $exec->output($s);
     },

#    clear=> sub   s## source2 should become part of the target                 # Clear the first bytes of an area as specified by the target operand
#     {my $i = currentInstruction $exec;
#      my $t =  right $exec, $i->target;
#      my $N =  right $exec, $i->source;
#      my $n =  right $exec, $i->source2;
#      for my $a(0..$N-1)
#       {my $p = Address(arenaHeap, $t, $a, $N);
#        assign($exec, $p, 0);
#       }
#     },

    loadAddress=> sub                                                           # Load the address component of a reference
     {my $i = currentInstruction $exec;
      my $s = left $exec, $i->source;
      my $t = $exec->latestLeftTarget;
      assign($exec, $t, $s->address);
     },

    loadArea=> sub                                                              # Load the area component of an address
     {my $i = currentInstruction $exec;
      my $s = left $exec, $i->source;
      my $t = $exec->latestLeftTarget;
      assign($exec, $t, $s->area);
     },

    mov=> sub                                                                   # Move data moves data from one part of memory to another - "set", by contrast, sets variables from constant values
     {my $i = currentInstruction $exec;
      my $s = $exec->latestRightSource;
      my $t = $exec->latestLeftTarget;
      assign($exec, $t, $s);
     },

    movRead1=> sub                                                              # Initiate a read from heap memory operation - record the address from which we wish to read
     {my $i = currentInstruction $exec;
      my $t = $exec->latestLeftTarget;                                          # The address we wish to read presented in the target field
      $exec->movReadAddress = $t;
     },

    movRead2=> sub                                                              # Finish a read from heap memory operation - record the address from which we wish to read
     {my $i = currentInstruction $exec;
      my $t = $exec->latestLeftTarget;                                          # The local address into which we wish to write presented as  a target address
      assign($exec, $t, $exec->movReadAddress->getMemoryValue);                 # Copy data from heap to local
     },

    movWrite1=> sub                                                             # Initiate a write to heap memory operation
     {my $i = currentInstruction $exec;
      my $s = $exec->latestRightSource;
      my $t = $exec->latestLeftTarget;
      assign($exec, $t, $s);
     },

    movWrite2=> sub                                                             # Finish a write to heap memory operation
     {},

    moveLong=> sub                                                              # Copy the number of elements specified by the second source operand from the location specified by the first source operand to the target operand
     {my $i = currentInstruction $exec;
      my $s = left  $exec, $i->source;                                          # Source
      my $l = right $exec, $i->source2;                                         # Length
      my $t = $exec->latestLeftTarget;                                          # Target
      for my $j(0..$l-1)
       {my $S = Address($exec, $s->arena, $s->area, $s->address+$j, $s->name, 0);
        my $T = Address($exec, $t->arena, $t->area, $t->address+$j, $t->name, 0);
        my $v = $S->getMemoryValue;
        assign($exec, $T, $v);
       }
     },

    not=> sub                                                                   # Not in place
     {my $i = currentInstruction $exec;
      my $s = $exec->latestRightSource;
      my $t = $exec->latestLeftTarget;
      assign($exec, $t, $s ? 0 : 1);
     },

    paramsGet=> sub                                                             # Get a parameter from the previous parameter block - this means that we must always have two entries on the call stack - one representing the caller of the program, the second representing the current context of the program
     {my $i = currentInstruction $exec;
      my $t = $exec->latestLeftTarget;
      my $s = $exec->latestRightSource;
      my $S = Address($exec, arenaParms, currentParamsGet($exec), $s, paramsNumber($exec), 0);
      my $v = $S->getMemoryValue;
      assign($exec, $t, $v);
     },

    paramsPut=> sub                                                             # Place a parameter in the current parameter block
     {my $i = currentInstruction $exec;
      my $s = $exec->latestRightSource;
      my $t = $exec->latestLeftTarget;
      my $T = Address($exec, arenaParms, currentParamsPut($exec), $t->address, paramsNumber($exec), 0);
      assign($exec, $T, $s);
     },

    random=> sub                                                                # Random number in the specified range
     {my $i = currentInstruction $exec;
      my $s = $exec->latestRightSource;
      my $t = $exec->latestLeftTarget;
      assign($exec, $t, int rand($s));
     },

    randomSeed=> sub                                                            # Random number seed
     {my $i = currentInstruction $exec;
      my $s = $exec->latestRightSource;
      srand $s;
     },

    returnGet=> sub                                                             # Get a returned value
     {my $i = currentInstruction $exec;
      my $t = $exec->latestLeftTarget;
      my $s = $exec->latestRightSource;
      my $S = Address($exec, arenaReturn, currentReturnGet($exec), $s, returnNumber($exec), 0);
      my $v = $S->getMemoryValue;
      assign($exec, $t, $v);
     },

    returnPut=> sub                                                             # Place a value to be returned
     {my $i = currentInstruction $exec;
      my $s = $exec->latestRightSource;
      my $t = $exec->latestLeftTarget;
      my $T = Address($exec, arenaReturn, currentReturnPut($exec), $t->address, returnNumber($exec), 0);
      assign($exec, $T, $s);
     },

    nop=> sub                                                                   # No operation
     {my ($i) = @_;                                                             # Instruction
      $exec->timeDelta = 0;
     },

    out=> sub                                                                   # Write source as output to an array of words
     {my $i = currentInstruction $exec;
      if (ref($i->source) =~ m(array)i)
       {my @t = map {right($exec, $_)} $i->source->@*;
        my $t = join ' ', @t;
        $exec->lastAssignValue = $t;
        $exec->output("$t\n");
       }
      else
       {my $t = right $exec, $i->source;
        say STDERR $t if !$exec->suppressOutput and !$exec->trace;
        $exec->lastAssignValue = $t;
        $exec->output("$t\n");
       }
      $exec->timeDelta = 0;                                                     # Out is used only for diagnostic purposes.
     },

    pop=> sub                                                                   # Pop a value from the specified memory area if possible else confess
     {my $i = currentInstruction $exec;
      my $s = $exec->latestRightSource;
      my $S = $i->source2;
      my $t = $exec->latestLeftTarget;
      my $v = popArea($exec, arenaHeap, $s, $S);
      assign($exec, $t, $v);                                                    # Pop from memory area into indicated memory address
     },

    push=> sub                                                                  # Push a value onto the specified memory area
     {my $i = currentInstruction $exec;
      my $s = $exec->latestRightSource;
      my $S = $i->source2;
      my $t = right $exec, $i->target;
      pushArea($exec, $t, $S, $s);
     },

    shiftLeft=> sub                                                             # Shift left within an element
     {my $i = currentInstruction $exec;
      my $t = $exec->latestLeftTarget;
      my $s = $exec->latestRightSource;
      my $v = $t->getMemoryValue << $s;
      assign($exec, $t, $v);
     },

    shiftRight=> sub                                                            # Shift right within an element
     {my $i = currentInstruction $exec;
      my $t = $exec->latestLeftTarget;
      my $s = $exec->latestRightSource;
      my $v = $t->getMemoryValue >> $s;
      assign($exec, $t, $v);
     },

    shiftUp=> sub                                                               # Shift an element up in a memory area
     {my $i = currentInstruction $exec;
      my $s = $exec->latestRightSource;
      my $t = $exec->latestLeftTarget;
      my $L = areaLength($exec, $t->area);                                      # Length of target array
      my $l = $t->address;                                                      # Position of move
#say STDERR "BBBB pos, length", dump($l, $L);
      for my $j(reverse $l+1..$L)                                               # Was making one move too many?
       {my $S = Address($exec, $t->arena, $t->area, $j-1,   $t->name, 0);
        my $T = Address($exec, $t->arena, $t->area, $j,     $t->name, 0);
        my $v = $S->getMemoryValue;
#say STDERR "CCCC move index, value", dump($j, $v);
        assign($exec, $T, $v);
       }
      assign($exec, $t, $s);
     },

    shiftDown=> sub                                                             # Shift an element down in a memory area
     {my $i = currentInstruction $exec;
      my $s = left $exec, $i->source;
      my $t = $exec->latestLeftTarget;
      my $L = areaLength($exec, $s->area);                                      # Length of source array
      my $l = $s->address;
      my $v = $s->getMemoryValue;
      for my $j($l..$L-2)                                                       # Each element in specified range
       {my $S = Address($exec, $s->arena, $s->area, $j+1,   $s->name, 0);
        my $T = Address($exec, $s->arena, $s->area, $j,     $s->name, 0);
        my $v = $S->getMemoryValue;
        assign($exec, $T, $v);
       }
      popArea($exec, arenaHeap, $s->area, $s->name);
      my $T = $exec->latestLeftTarget;
      assign($exec, $T, $v);
     },

    step=> sub                                                                  # Step the clock - never used in high level assembvler, but useful in low level assembler where we must often clock an operation through a device
     {},

    tally=> sub                                                                 # Tally instruction usage
     {my $i = currentInstruction $exec;
      my $t = $exec->latestRightSource;
      $exec->tally = $t;
      $exec->timeDelta = 0;
     },

    watch=> sub                                                                 # Watch a memory location for changes
     {my $i = currentInstruction $exec;
      my $t = $exec->latestLeftTarget;
      $exec->watch->[$t->area][$t->address]++;
      $exec->timeDelta = 0;
     },

    parallelStart=> sub                                                         # Start timing a parallel section
     {push $exec->parallelLastStart->@*, $exec->timeParallel;
      push $exec->parallelLongest->@*, 0;                                       # Longest so far
      $exec->timeDelta = 0;
     },

    parallelContinue=> sub                                                      # Continue timing a parallel section
     {my $t = $exec->timeParallel - $exec->parallelLastStart->[-1];
      push $exec->parallelLongest->@*, max pop($exec->parallelLongest->@*), $t; # Find longest section
      $exec->timeParallel = $exec->parallelLastStart->[-1];                     # Reset time as if we were starting in parallel
      $exec->timeDelta = 0;
     },

    parallelStop=> sub                                                          # Stop timing a parallel section
     {my $t = $exec->timeParallel - (my $s = pop $exec->parallelLastStart->@*);
      my $l = max pop($exec->parallelLongest->@*), $t;                          # Find longest section
      $exec->timeParallel = $s + $l;
      $exec->timeDelta = 0;
     },
   );
  return {%instructions} unless $assembly;                                      # Return a list of the instructions

  $allocs = [];                                                                 # Reset all allocations
  createInitialStackEntry($exec);                                               # Variables in initial stack frame

  my $mi = $options{maximumInstructionsToExecute} //                            # Prevent run away executions
                   $maximumInstructionsToExecute;

# Instruction loop

  my %instructionMap = %{&instructionMap};                                      # Instruction name to number

  for my $step(1..$mi)                                                          # Execute each instruction in the code until we hit an undefined instruction. Track various statistics to assist in debugging and code improvement.
   {last unless defined($exec->instructionPointer);
    my $instruction = $exec->assembly->code->[$exec->instructionPointer++];     # Current instruction
    last unless $instruction;                                                   # Current instruction is undefined so we must have reached the end of the program

    $exec->calls->[-1]->instruction = $instruction;                             # Make this instruction the current instruction

    if (my $a = $instruction->action)                                           # Action
     {confess qq(No implementation for instruction: "$a")                       # Check that there is come code implementing the action for this instruction
        unless my $implementation = $instructions{$a};
      #stackTraceAndExit($exec, qq(No implementation for instruction: "$a"))    # Check that there is come code implementing the action for this instruction
      #  unless my $implementation = $instructions{$a};

      $exec->resetLastAssign;                                                   # Trace assignments
      $instruction->step = $step;                                               # Execution step number facilitates debugging
      $exec->timeDelta = undef;                                                 # Record elapsed time for instruction

      if ($traceExecution)
       {say STDERR sprintf "AAAA %4d %4d %s", $step, $exec->instructionPointer-1, $a;
       }

      $exec->latestLeftTarget  = left  $exec, $instruction->target              # Precompute these useful values if possible
        if $instruction->target;
      $exec->latestRightSource = right $exec, $instruction->source
        if $instruction->source;

#EEEE Execute
      $implementation->($instruction);                                          # Execute instruction

      if ($traceExecution)                                                      # memory trace in a form that is easy to replicate in Verilog
       {stringPrintLocalSimple($exec);
        stringPrintHeapSimple($exec);
        stringPrintHeapSizesSimple($exec);
       }

      $exec->tallyInstructionCounts($instruction);                              # Instruction counts
      $exec->traceMemory($instruction);                                         # Trace changes to memory
#say STDERR $exec->PrintMemory->($exec);
#say STDERR sprintf "%4d %4d  %2d %s", $step, $exec->instructionPointer, $instructionMap{$a}, $a;
#say STDERR "XXXX", dump($a, $exec->timeDelta, $exec->timeParallel, $exec->timeSequential, $exec->count);
     }
    if ($step >= $maximumInstructionsToExecute)
     {confess "Out of instructions after $step";
     }
   }

# freeSystemAreas($exec, $exec->calls->[0]);                                    # Free first stack frame

  $exec->completionStatistics;

  $exec
 }                                                                              # Execution results

sub completionStatistics($)                                                     #P Produce various statistics summarizing the execution of the program.
 {my ($exec) = @_;                                                              # Execution environment
  my $code = $exec->assembly->code;                                                # Instructions in code block
  my @n;
  for my $i(@$code)                                                             # Each instruction
   {push @n, $i unless $i->executed;
   }
  $exec->notExecuted = [@n];
 }

sub tallyInstructionCounts($$)                                                  #P Tally instruction counts.
 {my ($exec, $instruction) = @_;                                                # Execution environment, instruction being executed
      $exec->totalInstructions++;                                               # Total instruction count

  my $a = $instruction->action;
  $exec->totalLabels++ if $a =~ m(\Alabel\Z);                                   # Count of every label instruction executed

  if (!defined($exec->timeDelta) or $exec->timeDelta > 0)
   {if (my $t = $exec->tally)                                                   # Tally instruction counts
     {$exec->tallyCount++;
      $exec->tallyTotal->{$t}++;
      $exec->tallyCounts->{$t}{$a}++;
     }
    $exec->counts->{$a}++; $exec->count++;                                      # Execution instruction counts
    $exec->timeParallel   += $exec->timeDelta // 1;                             # Each instruction takes one step in time unless we are told otherwise
    $exec->timeSequential += $exec->timeDelta // 1;                             # Each instruction takes one step in time unless we are told otherwise

    $exec->instructionCounts->{$instruction->number}++;                         # Execution count by actual instruction

   }
  ++$instruction->executed;                                                     # Count number of times this actual instruction was executed
 }

sub resetLastAssign($)                                                          #P Reset the last assign trace fields ready for this instruction.
 {my ($exec) = @_;                                                              # Execution environment
  $exec->lastAssignArena   = $exec->lastAssignArea  =
  $exec->lastAssignAddress = $exec->lastAssignValue = undef;
 }                                                                              # Execution results

sub traceMemory($$)                                                             #P Trace memory.
 {my ($exec, $instruction) = @_;                                                # Execution environment, current instruction
  return unless $exec->trace;                                                   # Trace changes to memory if requested
  my $e = $exec->instructionCounts->{$instruction->number}//0;                  # Execution count for this instruction
  my $f = $instruction->action =~ m(\Aout\Z) ? $exec->lastAssignValue
                                             : $exec->formatTrace;
  my $s = $exec->suppressOutput;
  my $a = $instruction->action;
  my $n = $instruction->number;
  my $o = &instructionMap->{$a};
  my $F = $instruction->file;
  my $L = $instruction->line;
  my $S = $instruction->step;
  my $m  = sprintf "%5d  %4d  %4d  %4d  %12s", $S, $n, $e, $o, $a;
     $m .= sprintf "  %20s", $f;
     $m .= sprintf "  at %s line %d", $F, $L unless $s;
     $m =~ s(\s+\Z) ();
  say STDERR $m unless $s;
  $exec->output("$m\n") if $s;
 }

sub formatTrace($)                                                              #P Describe last memory assignment.
 {my ($exec) = @_;                                                              # Execution
  return "" unless defined(my $arena = $exec->lastAssignArena);
  return "" unless defined(my $area  = $exec->lastAssignArea);
  return "" unless defined(my $addr  = $exec->lastAssignAddress);
  return "" unless defined(my $type  = $exec->assembly->ArrayNumberToName($exec->lastAssignType));
  return "" unless defined(my $value = $exec->lastAssignValue);
  my $B = $exec->lastAssignBefore;
  my $b = defined($B) ? " was $B" : "";
  sprintf "[%d, %d, %s] = %d$b", $area, $addr, $type, $value;
 }

#D1 Instruction Set                                                             # The instruction set used by the Zero assembler programming language.

my $assembly;                                                                   # The current assembly

sub Assembly(%)                                                                 #P Start some assembly code.
 {my (%options) = @_;                                                           # Options
  $assembly = genHash(q(Zero::Emulator::Assembly),                              # Block of code description.
    code=>          [],                                                         # An array of instructions
    variables=>     AreaStructure("Variables"),                                 # Variables in this block of code
    labels=>        {},                                                         # Label name to instruction
    labelCounter=>  0,                                                          # Label counter used to generate unique labels
    files=>         [],                                                         # File number to file name
    procedures=>    {},                                                         # Procedures defined in this block of code
    arrayNames=>    {stackArea=>0, params=>1, return=>2},                       # Array names as strings to numbers
    arrayNumbers=>  [qw(stackArea params return)],                              # Array number to name
    lowLevelOps=>   $options{lowLevel} ? 1 : 0,                                 # Generate lower level instructions to allow heap to be placed in a separate verilog module
    %options,
   );
 }

my sub label()                                                                  # Next unique label
 {++$assembly->labelCounter;
 }

my sub setLabel(;$)                                                             # Set and return a label
 {my ($l) = @_;                                                                 # Optional preset label
  $l //= label;                                                                 # Create label if none supplied
  Label($l);                                                                    # Set label
  $l                                                                            # Return (new) label
 }

my sub xSource($)                                                               # Record a source argument
 {my ($s) = @_;                                                                 # Source expression
  (q(source), $assembly->Reference($s, 1))
 }

my sub nSource()                                                                # Record an empty source argument
 {my $r = $assembly->Reference(0, 1);
     $r->arena = arenaNull;
  (q(source), $r)
 }

my sub xSource2($)                                                              # Record a source argument
 {my ($s) = @_;                                                                 # Source expression
  (q(source2), $assembly->Reference($s, 2))
 }

my sub xTarget($)                                                               # Record a target argument
 {my ($t) = @_;                                                                 # Target expression
  (q(target), $assembly->Reference($t, 0))
 }

my sub nTarget()                                                                # Record an empty target argument
 {my $r = $assembly->Reference(0, 0);
     $r->arena = arenaNull;
  (q(target), $r)
 }

sub In(;$);
sub InSize(;$);
sub Inc($);
sub Jge($$$);
sub Jlt($$$);
sub Jmp($);
sub Mov($;$);
sub Subtract($$;$);

sub Add($$;$)                                                                   #i Add the source locations together and store the result in the target area.
 {my ($target, $s1, $s2) = @_ == 2 ? (&Var(), @_) : @_;                         # Target address, source one, source two
  $assembly->instruction(action=>"add", xTarget($target),
    xSource($s1), xSource2($s2));
  $target
 }

sub Array($)                                                                    #i Create a new memory area and write its number into the address named by the target operand.
 {my ($source) = @_;                                                            # Name of allocation
  my $t = &Var();
  my $n = $assembly->ArrayNameToNumber($source);
  my $i = $assembly->instruction(action=>"array", xTarget($t), xSource($n));    # Encode array name as a number

  $t;
 }

sub ArrayCountLess($$;$) {                                                      #i Count the number of elements in the array specified by the first source operand that are less than the element supplied by the second source operand and place the result in the target location.
  if (@_ == 2)
   {my ($area, $element) = @_;                                                  # Area, element to find
    my $t = &Var();
    $assembly->instruction(action=>"arrayCountLess",
      xTarget($t), xSource($area), xSource2($element));
    $t
   }
  else
   {my ($target, $area, $element) = @_;                                         # Target, area, element to find
    $assembly->instruction(action=>"arrayCountLess",
      xTarget($target), xSource($area), xSource2($element));
   }
 }

sub ArrayCountGreater($$;$) {                                                   #i Count the number of elements in the array specified by the first source operand that are greater than the element supplied by the second source operand and place the result in the target location.
  if (@_ == 2)
   {my ($area, $element) = @_;                                                  # Area, element to find
    my $t = &Var();
    $assembly->instruction(action=>"arrayCountGreater",
      xTarget($t), xSource($area), xSource2($element));
    $t
   }
  else
   {my ($target, $area, $element) = @_;                                         # Target, area, element to find
    $assembly->instruction(action=>"arrayCountGreater",
      xTarget($target), xSource($area), xSource2($element));
   }
 }

sub ArrayDump($)                                                                #i Dump an array.
 {my ($target) = @_;                                                            # Array to dump, title of dump
  $assembly->instruction(action=>"arrayDump", xTarget($target), nSource);
 }

sub ArrayOut($)                                                                 #I Write an array to out
 {my ($target) = @_;                                                            # Array to dump, title of dump
  $assembly->instruction(action=>"arrayOut", xTarget($target), nSource);
 }

sub ArrayIndex($$;$) {                                                          #i Store in the target location the 1 based index of the second source operand in the array referenced by the first source operand if the secound source operand is present somwhere in the array else store 0 into the target location.  If the sought element appears in multiple locations, any one of these locations can be chosen.  The business of returning a zero based result with -1 signalling an error would have led to the confusion of "try catch" and we certainly do not want that.
  if (@_ == 2)
   {my ($area, $element) = @_;                                                  # Area, element to find
    my $t = &Var();
    $assembly->instruction(action=>"arrayIndex",
      xTarget($t), xSource($area), xSource2($element));
    $t
   }
  else
   {my ($target, $area, $element) = @_;                                         # Target, area, element to find
    $assembly->instruction(action=>"arrayIndex",
      xTarget($target), xSource($area), xSource2($element));
   }
 }

sub ArraySize($$)                                                               #i The current size of an array.
 {my ($area, $name) = @_;                                                       # Location of area, name of area
  my $t = &Var();
  $assembly->instruction(action=>"arraySize",                                   # Target - location to place the size in, source - address of the area, source2 - the name of the area which cannot be taken from the area of the first source operand because that area name is the name of the area that contains the location of the area we wish to work on.
    xTarget($t), xSource($area), source2=>$assembly->ArrayNameToNumber($name));
  $t
 }
sub Assert1($$)                                                                 #P Assert operation.
 {my ($op, $a) = @_;                                                            # Operation, Source operand
  $assembly->instruction(action=>"assert$op", nTarget, xSource($a), level=>2);
 }

sub Assert2($$$)                                                                #P Assert operation.
 {my ($op, $a, $b) = @_;                                                        # Operation, First memory address, second memory address
  $assembly->instruction(action=>"assert$op",
    nTarget, xSource($a), xSource2($b), level=>2);
 }

sub Assert(%)                                                                   #i Assert regardless.
 {my (%options) = @_;                                                           # Options
  $assembly->instruction(action=>"assert", nTarget, nSource);
 }

sub AssertEq($$%)                                                               #i Assert two memory locations are equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Eq", $a, $b);
 }

sub AssertFalse($%)                                                             #i Assert false.
 {my ($a, %options) = @_;                                                       # Source operand
  Assert1("False", $a);
 }

sub AssertGe($$%)                                                               #i Assert that the first value is greater than or equal to the second value.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Ge", $a, $b);
 }

sub AssertGt($$%)                                                               #i Assert that the first value is greater than the second value.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Gt", $a, $b);
 }

sub AssertLe($$%)                                                               #i Assert that the first value is less than or equal to the second value.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Le", $a, $b);
 }

sub AssertLt($$%)                                                               # Assert that the first value is less than  the second value.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Lt", $a, $b);
 }

sub AssertNe($$%)                                                               #i Assert two memory locations are not equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address
  Assert2("Ne", $a, $b);
 }

sub AssertTrue($%)                                                              #i Assert true.
 {my ($a, %options) = @_;                                                       # Source operand
  Assert1("True", $a);
 }

sub Bad(&)                                                                      #i A bad ending to a block of code.
 {my ($bad) = @_;                                                               # What to do on a bad ending
  @_ == 1 or confess "One parameter";
  (bad=>  $bad)
 }

sub Block(&%)                                                                   #i Block of code that can either be restarted or come to a good or a bad ending.
 {my ($block, %options) = @_;                                                   # Block, options
  my ($Start, $Good, $Bad, $End) = (label, label, label, label);

  my $g = $options{good};
  my $b = $options{bad};

  setLabel($Start);                                                             # Start

  &$block($Start, $Good, $Bad, $End);                                           # Code of block

  if ($g)                                                                       # Good
   {Jmp $End;
    setLabel($Good);
    &$g($Start, $Good, $Bad, $End);
   }

  if ($b)                                                                       # Bad
   {Jmp $End;
    setLabel($Bad);
    &$b($Start, $Good, $Bad, $End);
   }
  setLabel($Good) unless $g;                                                    # Default positions for Good and Bad if not specified
  setLabel($Bad)  unless $b;
  setLabel($End);                                                               # End
 }

sub Call($)                                                                     #i Call the subroutine at the target address.
 {my ($p) = @_;                                                                 # Procedure description.
  $assembly->instruction(action=>"call", xTarget($p->target), nSource);
 }

#sub Clear($$$) ## Source2 must beciome part of the array reference             #i Clear the first bytes of an area.  The area is specified by the first element of the address, the number of locations to clear is specified by the second element of the target address.
# {my ($target, $source, $source2) = @_;                                        # Target address to clear, number of bytes to clear, name of target
#  my $i = $assembly->instruction(action=>"clear", xTarget($target),
#            xSource($source), xSource2($source2));
#  $i;
# }

sub Confess()                                                                   #i Confess with a stack trace showing the location both in the emulated code and in the code that produced the emulated code.
 {$assembly->instruction(action=>"confess", nTarget, nSource);
 }

sub Dec($)                                                                      #i Decrement the target.
 {my ($target) = @_;                                                            # Target address
  $assembly->instruction(action=>"subtract", xTarget($target), xSource($target), xSource2(1))
 }

sub Dump()                                                                      #i Dump all the arrays currently in memory.
 {$assembly->instruction(action=>"dump", nTarget, nSource);
 }

sub Else(&)                                                                     #i Else block.
 {my ($e) = @_;                                                                 # Else block subroutine
  @_ == 1 or confess "One parameter";
  (else=>  $e)
 }

sub Execute(%)                                                                  #i Execute the current assembly.
 {my (%options) = @_;                                                           # Options
  $assembly->execute(%options);                                                 # Execute the code in the current assembly
 }

sub For(&$%)                                                                    #i For loop 0..range-1 or in reverse.
 {my ($block, $range, %options) = @_;                                           # Block, limit, options
  if (!exists $options{reverse})                                                # Ascending order
   {my $s = 0; my $e = $range;                                                  # Start, end
    ($s, $e) = @$range if ref($e) =~ m(ARRAY);                                  # Start, end as a reference

    my ($Start, $Check, $Next, $End) = (label, label, label, label);

    setLabel($Start);                                                           # Start
    my $i = Mov $s;
      setLabel($Check);                                                         # Check
      Jge  $End, $i, $e;
        &$block($i, $Check, $Next, $End);                                       # Block
      setLabel($Next);
      Inc $i;                                                                   # Next
      Jmp $Check;
    setLabel($End);                                                             # End
   }
  else                                                                          # THIS CODE REQUIRES SIGNED ARITHMETIC
   {my $s = $range; my $e = 0;                                                  # Start, end
    ($e, $s) = @$range if ref($s) =~ m(ARRAY);                                  # End, start as a reference

    my ($Start, $Check, $Next, $End) = (label, label, label, label);

    setLabel($Start);                                                           # Start
    my $i = Subtract $s, 1;
    Subtract $i, $s;
      setLabel($Check);                                                         # Check
      Jlt  $End, $i, $e;
        &$block($i, $Check, $Next, $End);                                       # Block
      setLabel($Next);
      Dec $i;                                                                   # Next
      Jmp $Check;
    setLabel($End);                                                             # End
   }
 }

sub ForArray(&$$%)                                                              #i For loop to process each element of the named area.
 {my ($block, $area, $name, %options) = @_;                                     # Block of code, area, area name, options
  my $e = ArraySize $area, $name;                                               # End
  my $s = 0;                                                                    # Start

  my ($Start, $Check, $Next, $End) = (label, label, label, label);

  setLabel($Start);                                                             # Start
  my $i = Mov $s;
    setLabel($Check);                                                           # Check
    Jge  $End, $i, $e;
      my $a = Mov [$area, \$i, $name];
      &$block($i, $a, $Check, $Next, $End);                                     # Block
    setLabel($Next);
    Inc $i;                                                                     # Next
    Jmp $Check;
  setLabel($End);                                                               # End
 }

sub ForIn(&%)                                                                   #i For loop to process each element remaining in the input channel
 {my ($block, %options) = @_;                                                   # Block of code, area, area name, options
  my ($Check, $Next, $End) = (label, label, label);
  setLabel($Check);                                                             # Check
    my $s = InSize;
    JFalse($End, $s);
     my $a = In;
      &$block($s, $a, $Check, $Next, $End);                                     # Block
    setLabel($Next);
    Jmp $Check;
  setLabel($End);                                                               # End
 }

sub Free($$)                                                                    #i Free the memory area named by the target operand after confirming that it has the name specified on the source operand.
 {my ($target, $source) = @_;                                                   # Target area yielding the id of the area to be freed, source area yielding the name of the area to be freed
  my $n = $assembly->ArrayNameToNumber($source);
  $assembly->instruction(action=>"free", xTarget($target), xSource($n));
 }

sub Good(&)                                                                     #i A good ending to a block of code.
 {my ($good) = @_;                                                              # What to do on a good ending
  @_ == 1 or confess "One parameter";
  (good=>  $good)
 }

sub Ifx($$$%)                                                                   #P Execute then or else clause depending on whether two memory locations are equal.
 {my ($cmp, $a, $b, %options) = @_;                                             # Comparison, first memory address, second memory address, then block, else block
  confess "Then required" unless $options{then};
  if ($options{else})
   {my $else = label;
    my $end  = label;
    &$cmp($else, $a, $b);
      &{$options{then}};
      Jmp $end;
    setLabel($else);
      &{$options{else}};
    setLabel($end);
   }
  else
   {my $end  = label;
    &$cmp($end, $a, $b);
      &{$options{then}};
    setLabel($end);
   }
 }

sub IfEq($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jne, $a, $b, %options);
 }

sub IfFalse($%)                                                                 #i Execute then clause if the specified memory address is zero thus representing false.
 {my ($a, %options) = @_;                                                       # Memory address, then block, else block
  Ifx(\&Jne, $a, 0, %options);
 }

sub IfGe($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are greater than or equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jlt, $a, $b, %options);
 }

sub IfGt($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are greater than.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jle, $a, $b, %options);
 }

sub IfNe($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are not equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jeq, $a, $b, %options);
 }

sub IfLe($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are less than or equal.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jgt, $a, $b, %options);
 }

sub IfLt($$%)                                                                   #i Execute then or else clause depending on whether two memory locations are less than.
 {my ($a, $b, %options) = @_;                                                   # First memory address, second memory address, then block, else block
  Ifx(\&Jge, $a, $b, %options);
 }

sub IfTrue($%)                                                                  #i Execute then clause if the specified memory address is not zero thus representing true.
 {my ($a, %options) = @_;                                                       # Memory address, then block, else block
  Ifx(\&Jeq, $a, 0, %options);
 }

sub In(;$) {                                                                    #i Read a value from the input channel
  if (@_ == 0)                                                                  # Create a new stack frame variable to hold the value read from input
   {my $t = &Var();
    $assembly->instruction(action=>"in", xTarget($t), nSource);
    return $t;
   }
  if (@_ == 1)
   {my ($target) = @_;                                                          # Target location into which to store the value read
    $assembly->instruction(action=>"in", xTarget($target), nSource)
   }
 }

sub InSize(;$) {                                                                #i Number of elements remining in the input channel
  if (@_ == 0)                                                                  # Create a new stack frame variable to hold the value read from input
   {my $t = &Var();
    $assembly->instruction(action=>"inSize", xTarget($t), nSource);
    return $t;
   }
  if (@_ == 1)
   {my ($target) = @_;                                                          # Target location into which to store the value read
    $assembly->instruction(action=>"inSize", xTarget($target), nSource)
   }
 }

sub Inc($)                                                                      #i Increment the target.
 {my ($target) = @_;                                                            # Target address
  $assembly->instruction(action=>"add", xTarget($target), xSource($target), xSource2(1))
 }

sub Jeq($$$)                                                                    #i Jump to a target label if the first source field is equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jEq",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub JFalse($$)                                                                  #i Jump to a target label if the first source field is equal to zero.
 {my ($target, $source) = @_;                                                   # Target label, source to test
  $assembly->instruction(action=>"jFalse", xTarget($target), xSource($source));
 }

sub Jge($$$)                                                                    #i Jump to a target label if the first source field is greater than or equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jGe",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jgt($$$)                                                                    #i Jump to a target label if the first source field is greater than the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jGt",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jle($$$)                                                                    #i Jump to a target label if the first source field is less than or equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jLe",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jlt($$$)                                                                    #i Jump to a target label if the first source field is less than the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jLt",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub Jmp($)                                                                      #i Jump to a label.
 {my ($target) = @_;                                                            # Target address
  $assembly->instruction(action=>"jmp", xTarget($target), nSource);
 }

sub Jne($$$)                                                                    #i Jump to a target label if the first source field is not equal to the second source field.
 {my ($target, $source, $source2) = @_;                                         # Target label, source to test
  $assembly->instruction(action=>"jNe",
    xTarget($target), xSource($source), xSource2($source2));
 }

sub JTrue($$)                                                                   #i Jump to a target label if the first source field is not equal to zero.
 {my ($target, $source) = @_;                                                   # Target label, source to test
  $assembly->instruction(action=>"jTrue", xTarget($target), xSource($source));
 }

sub Label($)                                                                    #P Create a label.
 {my ($source) = @_;                                                            # Name of label
  $assembly->instruction(action=>"label", nTarget, xSource($source));
 }

sub LoadAddress($;$) {                                                          #i Load the address component of an address.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"loadAddress", xTarget($t), xSource($source));
    return $t;
   }
  elsif (@ == 2)
   {my ($target, $source) = @_;                                                 # Target address, source address
    $assembly->instruction(action=>"loadAddress",
      xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub LoadArea($;$) {                                                             #i Load the area component of an address.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"loadArea", xTarget($t), xSource($source));
    return $t;
   }
  elsif (@ == 2)
   {my ($target, $source) = @_;                                                 # Target address, source address
    $assembly->instruction(action=>"loadArea", xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub Mov($;$) {                                                                  #i Copy a constant or memory address to the target address.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"mov", xTarget($t), xSource($source));
    return $t;
   }
  elsif (@ == 2)
   {my ($target, $source) = @_;                                                 # Target address, source address
    $assembly->instruction(action=>"mov", xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required for mov";
   }
 }

sub MoveLong($$$)                                                               #i Copy the number of elements specified by the second source operand from the location specified by the first source operand to the target operand.
 {my ($target, $source, $source2) = @_;                                         # Target of move, source of move, length of move
  $assembly->instruction(action=>"moveLong", xTarget($target),
    xSource($source), xSource2($source2));
 }

sub Not($) {                                                                    #i Move and not.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Target address, source address
    my $t = &Var();
    $assembly->instruction(action=>"not", xTarget($t), xSource($source));
    return $t;
   }
  elsif (@ == 2)
   {my ($target, $source) = @_;                                                 # Target address, source address
    $assembly->instruction(action=>"not", xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required for not";
   }
 }

sub Nop()                                                                       #i Do nothing (but do it well!).
 {$assembly->instruction(action=>"nop", nTarget, nSource);
 }

sub Out($)                                                                      #i Write memory location contents to out.
 {my ($source) = @_;                                                            # Value to write
  $assembly->instruction(action=>"out", nTarget, xSource($source));
 }

sub ParamsGet($;$) {                                                            #i Get a word from the parameters in the previous frame and store it in the current frame.
  if (@_ == 1)
   {my ($source) = @_;                                                          # Memory address to place parameter in, parameter number
    my $p = &Var();
    $assembly->instruction(action=>"paramsGet", xTarget($p), xSource($source));
    return $p;
   }
  elsif (@_ == 2)
   {my ($target, $source) = @_;                                                 # Memory address to place parameter in, parameter number
    $assembly->instruction(action=>"paramsGet",
      xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub ParamsPut($$)                                                               #i Put a word into the parameters list to make it visible in a called procedure.
 {my ($target, $source) = @_;                                                   # Parameter number, address to fetch parameter from
  $assembly->instruction(action=>"paramsPut", xTarget($target), xSource($source));
 }

sub Pop(;$$) {                                                                  #i Pop the memory area specified by the source operand into the memory address specified by the target operand.
  if (@_ == 2)                                                                  # Pop indicated area into a local variable
   {my ($source, $source2) = @_;                                                # Memory address to place return value in, return value to get
    my $p = &Var();
    my $n = $assembly->ArrayNameToNumber($source2);
    $assembly->instruction(action=>"pop", xTarget($p), xSource($source), source2=>$n);
    return $p;
   }
  elsif (@_ == 3)
   {my ($target, $source, $source2) = @_;                                       # Pop indicated area into target address
    my $n = $assembly->ArrayNameToNumber($source2);
    $assembly->instruction(action=>"pop", xTarget($target), xSource($source), source2=>$n);
   }
  else
   {confess "Two or three parameters required";
   }
 }

my sub procedure($%)                                                            # Describe a procedure
 {my ($label, %options) = @_;                                                   # Start label of procedure, options describing procedure

  genHash(q(Zero::Emulator::Procedure),                                         # Description of a procedure
    target=>        $label,                                                     # Label to call to call this procedure
    variables=>     AreaStructure("Procedure"),                                 # Registers local to this procedure
  );
 }

sub Procedure($$)                                                               #i Define a procedure.
 {my ($name, $source) = @_;                                                     # Name of procedure, source code as a subroutine
  if ($name and my $n = $assembly->procedures->{$name})                         # Reuse existing named procedure
   {return $n;
   }

  Jmp(my $end = label);                                                         # Jump over the code of the procedure body
  my $start = setLabel;
  my $p = procedure($start);                                                    # Procedure description
  my $save_registers = $assembly->variables;
  $assembly->variables = $p->variables;
  &$source($p);                                                                 # Code of procedure called with start label as a parameter
  &Return;
  $assembly->variables = $save_registers;

  setLabel $end;
  $assembly->procedures->{$name} = $p;                                          # Return the start of the procedure
 }

sub Push($$$)                                                                   #i Push the value in the current stack frame specified by the source operand onto the memory area identified by the target operand.
 {my ($target, $source, $source2) = @_;                                         # Memory area to push to, memory containing value to push
  @_ == 3 or confess "Three parameters";
    my $n = $assembly->ArrayNameToNumber($source2);
  $assembly->instruction(action=>"push", xTarget($target), xSource($source), source2=>$n);
 }

sub Resize($$$)                                                                 #i Resize the target area to the source size.
 {my ($target, $source, $source2) = @_;                                         # Target array, new size, array name
  $assembly->instruction(action=>"resize", xTarget($target),
    xSource($source), xSource2($assembly->ArrayNameToNumber($source2)));
 }

sub Random($;$) {                                                               #i Create a random number in a specified range.
  if (@_ == 1)                                                                  # Create a variable
   {my ($source) = @_;                                                          # Memory address to place return value in, return value to get
    my $p = &Var();
    $assembly->instruction(action=>"random", xTarget($p), xSource($source));
    return $p;
   }
  elsif (@_ == 2)
   {my ($target, $source) = @_;                                                 # Memory address to place return value in, return value to get
    $assembly->instruction(action=>"random",
      xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub RandomSeed($)                                                               #i Seed the random number generator.
 {my ($seed) = @_;                                                              # Parameters
  $assembly->instruction(action=>"randomSeed", nTarget, xSource($seed));
 }

sub Return()                                                                    #i Return from a procedure via the call stack.
 {$assembly->instruction(action=>"return", nTarget, nSource);
 }

sub ReturnGet($;$) {                                                            #i Get a word from the return area and save it.
  if (@_ == 1)                                                                  # Create a variable
   {my ($source) = @_;                                                          # Memory address to place return value in, return value to get
    my $p = &Var();
    $assembly->instruction(action=>"returnGet", xTarget($p), xSource($source));
    return $p;
   }
  elsif (@_ == 2)
   {my ($target, $source) = @_;                                                 # Memory address to place return value in, return value to get
    $assembly->instruction(action=>"returnGet",
      xTarget($target), xSource($source));
   }
  else
   {confess "One or two parameters required";
   }
 }

sub ReturnPut($$)                                                               #i Put a word into the return area.
 {my ($target, $source) = @_;                                                   # Offset in return area to write to, memory address whose contents are to be placed in the return area
  $assembly->instruction(action=>"returnPut",
    xTarget($target), xSource($source));
 }

sub ShiftDown($;$) {                                                            #i Shift an element down one in an area.
  if (@_ == 1)                                                                  # Create a variable
   {my ($source) = @_;                                                          # Memory address to place return value in, return value to get
    my $p = &Var();
    $assembly->instruction(action=>"shiftDown", xTarget($p), xSource($source));
    return $p;
   }
  elsif (@_ == 2)
   {my ($target, $source) = @_;                                                 # Memory address to place return value in, return value to get
    $assembly->instruction(action=>"shiftDown",
      xTarget($target), xSource($source));
    confess "Needs work";
    return $target;
   }
  else
   {confess "One or two parameters required";
   }
 }

sub ShiftLeft($;$) {                                                            #i Shift left within an element.
  my ($target, $source) = @_;                                                   # Target to shift, amount to shift
  $assembly->instruction(action=>"shiftLeft",
    xTarget($target), xSource($source));
  $target
 }

sub ShiftRight($;$) {                                                           #i Shift right with an element.
  my ($target, $source) = @_;                                                   # Target to shift, amount to shift
  $assembly->instruction(action=>"shiftRight",
    xTarget($target), xSource($source));
  $target
 }

sub ShiftUp($;$)                                                                #i Shift an element up one in an area.
 {my ($target, $source) = @_;                                                   # Target to shift, amount to shift
  $assembly->instruction(action=>"shiftUp",
    xTarget($target), xSource($source));
  $target
 }

sub Start($)                                                                    #i Start the current assembly using the specified version of the Zero language.  At  the moment only version 1 works.
 {my ($version) = @_;                                                           # Version desired - at the moment only 1
  $version == 1 or confess "Version 1 is currently the only version available";
  Assembly();
 }

sub Subtract($$;$)                                                              #i Subtract the second source operand value from the first source operand value and store the result in the target area.
 {my ($target, $s1, $s2) = @_ == 2 ? (&Var(), @_) : @_;                         # Target address, source one, source two
  $assembly->instruction(action=>"subtract", xTarget($target),
    xSource($s1), xSource2($s2));
  $target
 }

sub Tally($)                                                                    #i Counts instructions when enabled.
 {my ($source) = @_;                                                            # Tally instructions when true
  $assembly->instruction(action=>"tally", nTarget, xSource($source));
 }

sub Then(&)                                                                     #i Then block.
 {my ($t) = @_;                                                                 # Then block subroutine
  @_ == 1 or confess "One parameter";
  (then=>  $t)
 }

sub Trace($)                                                                    #i Start or stop tracing.  Tracing prints each instruction executed and its effect on memory.
 {my ($source) = @_;                                                            # Trace setting
  $assembly->instruction(action=>"trace", nTarget, xSource($source));
 }

sub TraceLabels($)                                                              #i Enable or disable label tracing.  If tracing is enabled a stack trace is printed for each label instruction executed showing the call stack at the time the instruction was generated as well as the current stack frames.
 {my ($source) = @_;                                                            # Trace points if true
  $assembly->instruction(action=>"traceLabels", nTarget, xSource($source));
 }

sub Var(;$)                                                                     #i Create a variable initialized to the specified value.
 {my ($value) = @_;                                                             # Value
  return Mov $value if @_;
  $assembly->variables->registers
 }

sub Watch($)                                                                    #i Watches for changes to the specified memory location.
 {my ($target) = @_;                                                            # Memory address to watch
  $assembly->instruction(action=>"watch", xTarget($target), nSource);
 }

sub ParallelStart()                                                             #iP Start recording the elapsed time for parallel sections.
 {$assembly->instruction(action=>"parallelStart", nTarget, nSource);
 }

sub ParallelContinue()                                                          #iP Continue recording the elapsed time for parallel sections.
 {$assembly->instruction(action=>"parallelContinue", nTarget, nSource);
 }

sub ParallelStop()                                                              #iP Stop recording the elapsed time for parallel sections.
 {$assembly->instruction(action=>"parallelStop", nTarget, nSource);
 }

sub Parallel(@)                                                                 #i Runs its sub sections in simulated parallel so that we can prove that the sections can be run in parallel.
 {my (@subs) = @_;                                                              # Subroutines containing code to be run in simulated parallel

  my @r = keys @subs;
  my $s = reverse time();                                                       # Create a somewhat random seed
  srand($s);                                                                    # Seed the random number generator
  for my $i((keys @r) x 2)                                                      # Randomize execution order
   {my $j = int(scalar(@r) * rand());
    ($r[$i], $r[$j]) = ($r[$j], $r[$i]);
   }
  ParallelStart;
  map {ParallelContinue; $subs[$_]->()} @r;                                     # Layout code in randomized order while timingeach section
  ParallelStop;
 }

sub Sequential(@)                                                               #i Runs its sub sections in sequential order
 {my (@subs) = @_;                                                              # Subroutines containing code to be run sequentially

  map {$_->()} @subs;                                                           # Layout code sequentially
 }

#D1 Instruction Set Architecture                                                # Map the instruction set into a machine architecture.

my $instructions = Zero::Emulator::Assembly::execute(undef);
my @instructions = sort keys %$instructions;
my %instructions = map {$instructions[$_]=>$_} keys @instructions;
#say STDERR "Instruction op codes\n", dump(\%instructions), formatTable(\@instructions); exit;

sub instructionMap()                                                            #P Instruction map
 {return \%instructions
 }

my sub instructionList()                                                        #P Create a list of instructions.
 {my sub parseInstruction($)                                                    # Parse an instruction definition
   {my ($line) = @_;                                                            # Line of source code
    my @parse = split /[ (){}]+/, $line, 5;
    my $name = $parse[1];
    my $sig  = $parse[2];
    my $comment = $line =~ s(\A.*?#i\s*) ()r;
    [$name, $sig, $comment];
   };
  my @i = readFile $0;                                                          # Source file
  my @j;                                                                        # Description of initial instruction
  for my $i(grep {m(\s+#i)} @i)                                                 # Initial instructions were sorted into order
   {push @j, parseInstruction($i);
   }
  [sort {$$a[0] cmp $$b[0]} @j]
}

my sub instructionListReadMe()                                                  #P List  instructions for inclusion in read me.
 {my $i = instructionList;
  my $s = '';
  for my $i(@$i)
   {my ($name, $sig, $comment) = @$i;
    $s .= sprintf("**%10s**  %s\n", $name, $comment);
   }
  $s
 }

#D1 Compile to verilog                                                          # Compile each sub sequence of instructions into equivalent verilog.  A sub sequence starts at an instruction marked as an entry point

sub CompileToVerilog(%)                                                         #P Execution environment for a block of code.
 {my (%options) = @_;                                                           # Execution options

  genHash(q(Zero::CompileToVerilog),                                            # Compile to verilog
    NArea=> 2**containingPowerOfTwo($options{NArea}   // 0),                    # The size of an array in the heap area
    NArrays=>                       $options{NArrays} // 0,                     # The number of heap arrays need
    WLocal=>                        $options{WLocal}  // 0,                     # Size of local area
    code=>                          '',                                         # Generated code
    testBench=>                     '',                                         # Test bench for generated code
    constraints=>                   '',                                         # Constraints file
   );
 }

sub Zero::CompileToVerilog::deref($$)                                           #P Compile a reference in assembler format to a corresponding verilog expression
 {my ($compile, $ref) = @_;                                                     # Compile, reference
  @_ == 2 or confess "Two parameters";

  my $NArea = $compile->NArea;                                                  # We have to fix the area size in advance to make this process efficient

  my sub heapAdr($$$)                                                           # Heap memory address
   {my ($delta, $area, $address) = @_;                                          # Delta, area, address
    return "$delta + $area*$NArea + $address" unless $delta == 0;               # Heap memory address
                    "$area*$NArea + $address"                                   # Heap memory address
   }

  my sub heapMem($$$)                                                           # Heap memory value
   {my ($delta, $area, $address) = @_;                                          # Delta, area, address
    "heapMem[".heapAdr($delta, $area, $address)."]";                            # Heap memory value
   }

  my sub localAdr($$)                                                           # Local memory address
   {my ($delta, $address) = @_;                                                 # Delta, address
    return "$delta+localMem[$address]" unless $delta == 0;
                  "localMem[$address]";
   }

  my sub localMem($$)                                                           # Local memory value
   {my ($delta, $address) = @_;                                                 # Delta, address
    return "localMem[$delta+$address]" unless $delta == 0;
           "localMem[$address]"
   }

  my $Area      = $ref->area    ;                                               # Components of a reference
  my $Address   = $ref->address ;
  my $Arena     = $ref->arena   ;
  my $DArea     = $ref->dArea   ;
  my $DAddress  = $ref->dAddress;
  my $Delta     = $ref->delta   ;

  my $Value     =                                                               # Source vlue
    $Arena      == 0 ? 0 :
    $Arena      == 1 ?
     (                  $DAddress == 0 ? $Address :
      $DArea    == 0 && $DAddress == 1 ? heapMem ($Delta, $Area,              $Address)              :
      $DArea    == 0 && $DAddress == 2 ? heapMem ($Delta, $Area,              localMem(0, $Address)) :
      $DArea    == 1 && $DAddress == 1 ? heapMem ($Delta, localMem(0, $Area), $Address)              :
      $DArea    == 1 && $DAddress == 2 ? heapMem ($Delta, localMem(0, $Area), localMem(0, $Address)) : 0) :
    $Arena      == 2 ?
     ($DAddress == 0 ? $Address :
      $DAddress == 1 ? localMem($Delta, $Address)              :
      $DAddress == 2 ? localMem($Delta, localMem(0, $Address)) : 0) : 0;

  my $Location  =                                                               # Source location
    $Arena      == 0 ? 0 :
    $Arena      == 1 ?
     (                  $DAddress == 0 ? $Address :
      $DArea    == 0 && $DAddress == 1 ? heapAdr ($Delta, $Area,              $Address)              :
      $DArea    == 0 && $DAddress == 2 ? heapAdr ($Delta, $Area,              localMem(0, $Address)) :
      $DArea    == 1 && $DAddress == 1 ? heapAdr ($Delta, localMem(0, $Area), $Address)              :
      $DArea    == 1 && $DAddress == 2 ? heapAdr ($Delta, localMem(0, $Area), localMem(0, $Address)) : 0) :
    $Arena      == 2 ?
     ($DAddress == 0 ? $Address :
      $DAddress == 1 ? localAdr($Delta, $Address)            :
      $DAddress == 2 ? localAdr($Delta, localMem(0, $Address)) : 0) : 0;

  my $targetLocation  =                                                         # Target as a location
    $Arena      == 0 ? 0 :
    $Arena      == 1 ?
     ($DArea    == 0 && $DAddress == 1 ? heapMem($Delta, $Area,              $Address)              :
      $DArea    == 0 && $DAddress == 2 ? heapMem($Delta, $Area,              localMem(0, $Address)) :
      $DArea    == 1 && $DAddress == 1 ? heapMem($Delta, localMem(0, $Area), $Address)              :
      $DArea    == 1 && $DAddress == 2 ? heapMem($Delta, localMem(0, $Area), localMem(0, $Address)) : 0) :
    $Arena      == 2 ?
     ($DAddress == 1 ?  localMem($Delta, $Address) :                            # Was stringular
      $DAddress == 2 ?  localMem($Delta, $Address) : 0) : 0;

  my $targetIndex  =                                                            # Target index within array
    $Arena      == 1 ?
     ($DAddress == 1 ? $Delta + $Address          :
      $DAddress == 2 ? localAdr($Delta, $Address) : 0)  : 0;

  my $targetLocationArea =                                                      # Number of array containing target
      $Arena    == 1 && $DArea == 0 ? $Area :
      $Arena    == 1 && $DArea == 1 ? localMem(0, $Area): 0;

  my $targetValue =                                                             # Target as value
    $Arena      == 0 ? 0 :
    $Arena      == 1 ?
     (                  $DAddress == 0 ? $Address :
      $DArea    == 0 && $DAddress == 1 ? heapMem ($Delta, $Area,              $Address)           :
      $DArea    == 0 && $DAddress == 2 ? heapMem ($Delta, $Area,              localMem(0, $Address)) :
      $DArea    == 1 && $DAddress == 1 ? heapMem ($Delta, localMem(0, $Area), $Address)           :
      $DArea    == 1 && $DAddress == 2 ? heapMem ($Delta, localMem(0, $Area), localMem(0, $Address)) : 0) :
    $Arena      == 2 ?
     ($DAddress == 0 ? $Address :
      $DAddress == 1 ? localMem($Delta, $Address)           :
      $DAddress == 2 ? localMem($Delta, localMem(0, $Address)) : 0) : 0;


  genHash(q(Zero::Emulator::Deref),                                             # Memory operations
    Value              => $Value,                                               # Source value
    Location           => $Location,                                            # Source location
    targetLocation     => $targetLocation,                                      # Target as a location
    targetIndex        => $targetIndex,                                         # Target index within array
    targetLocationArea => $targetLocationArea,                                  # Number of array containing target
    Arena              => $Arena,                                               # Arena
    Area               => $Area,                                                # Area
    targetValue        => $targetValue,                                         # Target as value
   );
 }

sub compileToVerilog($$)                                                        # Compile each sub sequence of instructions into equivalent verilog.  A sub sequence starts at an instruction marked as an entry point
 {my ($exec, $name) = @_;                                                       # Execution environment of completed run, name of subroutine to contain generated code
  @_ == 2 or confess "Two parameters";

  my $compile = CompileToVerilog
   (NArea=>   $exec->widestAreaInArena->[arenaHeap],                            # The width of arrays on the heap
    NArrays=> $exec->mostArrays       ->[arenaHeap],                            # The number of heap arrays need
    WLocal=>  $exec->widestAreaInArena->[arenaLocal]);                          # Compilation environment

  my $NArrays = $compile->NArrays;
  my $NArea   = $compile->NArea;
  my $NOut    = [split /\s+/, $exec->out]->@*;
  my $WLocal  = $compile->WLocal;

  my @c;                                                                        # Generated code

  my sub skip                                                                   # Skip this instruction and continue at the next one
   {my ($i) = @_;                                                               # Instruction
    my $n   = $i->number + 1;
    push @c, <<END;
            ip = $n;
END
   }

=pod
Constant to local
Constant to heap
Local source
Local target
Constant array constant index  - as source
Constant array variable index  - as source
Variable array constant index  - as source
Variable array variable index  - as source
Constant array constant index  - as target
Constant array variable index  - as target
Variable array constant index  - as target
Variable array variable index  - as target

Constants
Locals
Heaps
Parameters
Return

=cut

  my sub confirmLhsRef($$$)                                                     # Confirm a left hand reference is to a constant or to a local variable and to nothing else
   {my ($instruction, $ref, $type) = @_;                                        # Instruction, Reference in this instruction, the type of the reference
    my $c = join "\n", $instruction->contextString;
    $ref->arena == arenaLocal or confess "LHS $type reference must be a constant or a local variable in:\n$c";
    $ref->dAddress < 2 or confess "LHS $type reference is too deep in:\n$c";
   }

  my $gen =                                                                     # Code generation for each instruction
   {add=> sub                                                                   # Add
     {my ($i) = @_;                                                             # Instruction
      #confirmLhsRef($i, $i->source,  "source");
      #confirmLhsRef($i, $i->source2, "source2");
      #confirmLhsRef($i, $i->target,  "target");
      my $A = $compile->deref($i->target)->Arena;
      my $z = $compile->deref($i->target)->targetLocationArea;
      my $a = $compile->deref($i->source )->Value;
      my $b = $compile->deref($i->source2)->Value;
      my $t = $compile->deref($i->target)->targetLocation;
      my $I = $compile->deref($i->target)->targetIndex;
      my $n = $i->number + 1;
      push @c, <<END;
              $t = $a + $b;
              updateArrayLength($A, $z, $I);
              ip = $n;
END
     },

    subtract=> sub                                                              # Subtract
     {my ($i) = @_;                                                             # Instruction
      my $A = $compile->deref($i->target)->Arena;
      my $z = $compile->deref($i->target)->targetLocationArea;
      my $a = $compile->deref($i->source )->Value;
      my $b = $compile->deref($i->source2)->Value;
      my $t = $compile->deref($i->target)->targetLocation;
      my $I = $compile->deref($i->target)->targetIndex;
      my $n = $i->number + 1;
      push @c, <<END;
              $t = $a - $b;
              updateArrayLength($A, $z, $I);
              ip = $n;
END
     },

    array=> sub                                                                 # Array
     {my ($i) = @_;                                                             # Instruction
      my $t   = $compile->deref($i->target)->targetLocation;
      my $n   = $i->number + 1;
      push @c, <<END;
              if (freedArraysTop > 0) begin
                freedArraysTop = freedArraysTop - 1;
                $t = freedArrays[freedArraysTop];
              end
              else begin
                $t = allocs;
                allocs = allocs + 1;

              end
              arraySizes[$t] = 0;
              ip = $n;
END
     },

    arraySize=> sub                                                             # ArraySize
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source)->Value;
      my $t   = $compile->deref($i->target)->targetLocation;
      my $n   = $i->number + 1;
      push @c, <<END;
              $t = arraySizes[$s];
              ip = $n;
END
     },

    arrayCountLess=> sub                                                        # ArrayCountLess
     {my ($i) = @_;                                                             # Instruction
      my $s = $compile->deref($i->source2)->Value;
      my $a = $compile->deref($i->source) ->Value;
      my $t = $compile->deref($i->target) ->targetLocation;
      my $n = $i->number + 1;
      push @c, <<END;
              j = 0; k = arraySizes[$a];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[$a * NArea + i] < $s) j = j + 1;
              end
              $t = j;
              ip = $n;
END
     },

    arrayCountGreater=> sub                                                     # ArrayCountGreater
     {my ($i) = @_;                                                             # Instruction
      my $s = $compile->deref($i->source2)->Value;
      my $a = $compile->deref($i->source) ->Value;
      my $t = $compile->deref($i->target)->targetLocation;
      my $n = $i->number + 1;
      push @c, <<END;
              j = 0; k = arraySizes[$a];
//\$display("AAAAA k=%d  source2=%d", k, $s);
              for(i = 0; i < NArea; i = i + 1) begin
//\$display("AAAAA i=%d  value=%d", i, heapMem[$a * NArea + i]);
                if (i < k && heapMem[$a * NArea + i] > $s) j = j + 1;
              end
              $t = j;
              ip = $n;
END
     },

    arrayIndex=> sub                                                            # ArrayIndex
     {my ($i) = @_;                                                             # Instruction
      my $s = $compile->deref($i->source2)->Value;
      my $a = $compile->deref($i->source) ->Value;
      my $t = $compile->deref($i->target)->targetLocation;
      my $n = $i->number + 1;
      push @c, <<END;
              $t = 0; k = arraySizes[$a];
              for(i = 0; i < NArea; i = i + 1) begin
                if (i < k && heapMem[$a * NArea + i] == $s) $t = i + 1;
              end
              ip = $n;
END
     },

    assert=>   \&skip,                                                          # Assert
    assertEq=> \&skip,                                                          # AssertEq
    assertNe=> \&skip,                                                          # AssertNe

    free=> sub                                                                  # Free array
     {my ($i) = @_;                                                             # Instruction
      my $t   = $compile->deref($i->target)->Value;                             # Number of the array
      my $n   = $i->number + 1;
      push @c, <<END;
                                 arraySizes[$t] = 0;
              freedArrays[freedArraysTop] = $t;
              freedArraysTop = freedArraysTop + 1;
              ip = $n;
END
     },

    in=> sub                                                                    # In
     {my ($i) = @_;                                                             # Instruction
      my $t   = $compile->deref($i->target)->targetLocation;
      my $n   = $i->number + 1;
      push @c, <<END;
              if (inMemPos < NIn) begin
                $t = inMem[inMemPos];
                inMemPos = inMemPos + 1;
              end
              ip = $n;
END
     },

    inSize=> sub                                                                # InSize
     {my ($i) = @_;                                                             # Instruction
      my $t   = $compile->deref($i->target)->targetLocation;
      my $n   = $i->number + 1;
      push @c, <<END;
              $t = NIn - inMemPos;
              ip = $n;
END
     },

    jFalse=> sub                                                                # jFalse
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source)->Value;
      my $n   = $i->number + 1;
      my $j   = $i->number + $i->jump->address;
      push @c, <<END;
              ip = $s == 0 ? $j : $n;
END
     },

    jTrue=> sub                                                                 # jTrue
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source)->Value;
      my $n   = $i->number + 1;
      my $j   = $i->number + $i->jump->address;
      push @c, <<END;
              ip = $s != 0 ? $j : $n;
END
     },

    jEq=> sub                                                                   # jEq
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source )->Value;
      my $s2  = $compile->deref($i->source2)->Value;
      my $j   = $i->number + $i->jump->address;
      my $n   = $i->number + 1;
      push @c, <<END;
              ip = $s == $s2 ? $j : $n;
END
     },

    jGe=> sub                                                                   # jGe
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source )->Value;
      my $s2  = $compile->deref($i->source2)->Value;
      my $j   = $i->number + $i->jump->address;
      my $n   = $i->number + 1;
      push @c, <<END;
              ip = $s >= $s2 ? $j : $n;
END
     },

    jGt=> sub                                                                   # jGt
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source )->Value;
      my $s2  = $compile->deref($i->source2)->Value;
      my $j   = $i->number + $i->jump->address;
      my $n   = $i->number + 1;
      push @c, <<END;
              ip = $s >  $s2 ? $j : $n;
END
     },

    jLe=> sub                                                                   # jLe
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source )->Value;
      my $s2  = $compile->deref($i->source2)->Value;
      my $j   = $i->number + $i->jump->address;
      my $n   = $i->number + 1;
      push @c, <<END;
              ip = $s <= $s2 ? $j : $n;
END
     },

    jLt=> sub                                                                   # jLt
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source )->Value;
      my $s2  = $compile->deref($i->source2)->Value;
      my $j   = $i->number + $i->jump->address;
      my $n   = $i->number + 1;
      push @c, <<END;
              ip = $s <  $s2 ? $j : $n;
END
     },

    jNe=> sub                                                                   # jNe
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source )->Value;
      my $s2  = $compile->deref($i->source2)->Value;
      my $j   = $i->number + $i->jump->address;
      my $n   = $i->number + 1;
      push @c, <<END;
              ip = $s != $s2 ? $j : $n;
END
     },

    jmp=> sub                                                                   # jmp
     {my ($i) = @_;                                                             # Instruction
      my $j   = $i->number + $i->jump->address;
      push @c, <<END;
              ip = $j;
END
     },

    label=> sub                                                                 # label
     {my ($i) = @_;                                                             # Instruction
      my $n   = $i->number + 1;
      push @c, <<END;
              ip = $n;
END
     },

    mov=> sub                                                                   # Mov
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source)->Value;
      my $t   = $compile->deref($i->target)->targetLocation;
      my $A   = $compile->deref($i->target)->Arena;
      my $a   = $compile->deref($i->target)->targetLocationArea;
      my $I   = $compile->deref($i->target)->targetIndex;
      my $n   = $i->number + 1;
      push @c, <<END;
              $t = $s;
              updateArrayLength($A, $a, $I);                                   // We should do this in the heap memory module
              ip = $n;
END
     },

    movRead1=> sub                                                              # Mov start read from heap memory.
     {my ($i) = @_;                                                             # Instruction
      my $t   = $compile->deref($i->target)->Location;
      my $n   = $i->number + 1;
      push @c, <<END;
              heapAddress = $t;                                                 // Address of the item we wish to read from heap memory
              heapWrite = 0;                                                    // Request a read, not a write
              heapClock = 1;                                                    // Start read
              ip = $n;                                                          // Next instruction
END
     },

    movRead2=> sub                                                              # Mov finish read from heap memory.
     {my ($i) = @_;                                                             # Instruction
      my $t   = $compile->deref($i->target)->targetLocation;
      my $n   = $i->number + 1;
      push @c, <<END;
              $t = heapOut;                                                     // Data retrieved from heap memory
              heapClock = 0;                                                    // Ready for next operation
              ip = $n;                                                          // Next instruction
END
     },

    movWrite1=> sub                                                             # Mov start write to heap memory.
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source)->Value;
      my $t   = $compile->deref($i->target)->Location;
      my $n   = $i->number + 1;
      push @c, <<END;
              heapAddress = $t;                                                 // Address of the item we wish to read from heap memory
              heapIn      = $s;                                                 // Data to write
              heapWrite   = 1;                                                  // Request a write
              heapClock   = 1;                                                  // Start write
              ip = $n;                                                          // Next instruction
END
     },

    step=> sub                                                                  # Lower the clock to complete a memory operation.  Obviously this should be done (if possible) as part of the next step in a bettr realization
     {my ($i) = @_;                                                             # Instruction                                                                                                                                t
      my $n   = $i->number + 1;
      push @c, <<END;
              heapClock = 0;                                                    // Ready for next operation
              ip = $n;                                                          // Next instruction
END
     },

    moveLong=> sub                                                              # Move long
     {my ($i) = @_;                                                             # Instruction
      my $si  = $compile->deref($i->source )->targetIndex;
      my $sa  = $compile->deref($i->source )->targetLocationArea;
      my $ti  = $compile->deref($i->target )->targetIndex;
      my $ta  = $compile->deref($i->target )->targetLocationArea;
      my $l   = $compile->deref($i->source2)->Value;
      my $A   = $compile->deref($i->target)->Arena;
      my $n   = $i->number + 1;
      push @c, <<END;
              for(i = 0; i < NArea; i = i + 1) begin                            // Copy from source to target
                if (i < $l) begin
                  heapMem[NArea * $ta + $ti + i] = heapMem[NArea * $sa + $si + i];
                  updateArrayLength($A, $ta, $ti + i);
                end
              end
              ip = $n;
END
     },

    not=> sub                                                                   # Not
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source)->Value;
      my $t   = $compile->deref($i->target)->targetLocation;
      my $n   = $i->number + 1;
      push @c, <<END;
              $t = !$s;
              ip = $n;
END
     },

    out=> sub                                                                   # Out
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source)->Value;
      my $n   = $i->number + 1;
      push @c, <<END;
              outMem[outMemPos] = $s;
              outMemPos = outMemPos + 1;
              ip = $n;
END
     },

    pop=> sub                                                                   # Pop
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source)->Value;
      my $t   = $compile->deref($i->target)->targetLocation;
      my $n   = $i->number + 1;
      push @c, <<END;
              arraySizes[$s] = arraySizes[$s] - 1;
              $t = heapMem[$s * NArea + arraySizes[$s]];
              ip = $n;
END
     },

    push=> sub                                                                  # Push
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source)->Value;
      my $t   = $compile->deref($i->target)->Value;
      my $n   = $i->number + 1;
      push @c, <<END;
              heapMem[$t * NArea + arraySizes[$t]] = $s;
              arraySizes[$t]    = arraySizes[$t] + 1;
              ip = $n;
END
     },

    resize=> sub                                                                # Resize
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source)->Value;
      my $t   = $compile->deref($i->target)->Value;
      my $n   = $i->number + 1;
      push @c, <<END;
              arraySizes[$t] = $s;
              ip = $n;
END
     },

    shiftLeft=> sub                                                             # Shift left
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source )->Value;
      my $T   = $compile->deref($i->target)->targetValue;
      my $t   = $compile->deref($i->target)->targetLocation;
      my $n   = $i->number + 1;
      push @c, <<END;
              $t = $T << $s;
              ip = $n;
END
     },

    shiftRight=> sub                                                            # Shift right
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source )->Value;
      my $T   = $compile->deref($i->target)->targetValue;
      my $t   = $compile->deref($i->target)->targetLocation;
      my $n   = $i->number + 1;
      push @c, <<END;
              $t = $T >> $s;
              ip = $n;
END
     },

    shiftUp=> sub                                                               # Shift up
     {my ($i) = @_;                                                             # Instruction
      my $s   = $compile->deref($i->source)->Value;                             # Value to shift in
      my $a   = $compile->deref($i->target)->targetLocationArea;                # Number of target array
      my $o   = $compile->deref($i->target)->targetIndex;                       # Position in target array to shift from
      my $n   = $i->number + 1;
      push @c, <<END;
//\$display("AAAA %4d %4d shiftUp", steps, ip);
              for(i = 0; i < NArea; i = i + 1) arrayShift[i] = heapMem[NArea * $a + i]; // Copy source array
//\$display("BBBB pos=%d array=%d length=%d", $o, $a, arraySizes[$a]);
              for(i = 0; i < NArea; i = i + 1) begin                            // Move original array up
                if (i > $o && i <= arraySizes[$a]) begin
                  heapMem[NArea * $a + i] = arrayShift[i-1];
//\$display("CCCC index=%d value=%d", i, arrayShift[i-1]);
                end
              end
              heapMem[NArea * $a + $o] = $s;                                    // Insert new value
              arraySizes[$a] = arraySizes[$a] + 1;                              // Increase array size
              ip = $n;
END
     },
    tally=> \&skip,                                                             # Tally
   };

  my sub f8($) {my $f = sprintf "%8d", $_[0]; \$f}                              # Format a number so things line up in the generated codef =

  push @c, <<END;                                                               # A case statement to select the next sub sequence to execute
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

  parameter integer NArea   = ${&f8($NArea         )};                                         // Size of each area on the heap
  parameter integer NArrays = ${&f8($NArrays       )};                                         // Maximum number of arrays
  parameter integer NHeap   = ${&f8($NArea*$NArrays)};                                         // Amount of heap memory
  parameter integer NLocal  = ${&f8($WLocal        )};                                         // Size of local memory
  parameter integer NOut    = ${&f8($NOut          )};                                         // Size of output area

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

END

  if (my $n = sprintf "%4d", scalar $exec->inOriginally->@*)                    # Input queue length
   {push @c, <<END;
  parameter integer NIn     = ${&f8($n)};                                         // Size of input area
END
   }

  my $arenaHeap = arenaHeap;

  push @c, <<END;                                                               # A case statement to select the next sub sequence to execute
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
      if (arena == $arenaHeap && arraySizes[array] < index + 1) arraySizes[array] = index + 1;
    end
  endtask
END

  if (1)                                                                        # A case statement to select each instruction to be executed in order
   {push @c, <<END;

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

END

    my @i = $exec->inOriginally->@*;                                            # Load input queue
    for my $i(keys @i)
     {my $I = $i[$i];
      push @c, <<END;
      inMem[$i] = $I;
END
     }


    push @c, <<END;
      if ($traceExecution) begin                                                  // Clear memory
        for(i = 0; i < NHeap;   i = i + 1)    heapMem[i] = 0;
        for(i = 0; i < NLocal;  i = i + 1)   localMem[i] = 0;
        for(i = 0; i < NArrays; i = i + 1) arraySizes[i] = 0;
      end
    end
    else begin
      steps = steps + 1;
      case(ip)
END
   }

  my $code = $exec->assembly->code;                                                # Using an execution environment gives us access to sample input and output thus allowing the creation of a test for the generated code.

  for my $i(@$code)                                                             # Each instruction
   {my $action = $i->action;
    my $number = $i->number;
    my $n      = sprintf "%5d", $number;

    push @c, <<END;

      $n :
        begin                                                                   // $action
if ($traceExecution) begin
  \$display("AAAA %4d %4d $action", steps, ip);
end
END

    if (!$i->executed)                                                          # No code needed as this instruction never gets executed in this test
     {push @c, <<END;
           \$display("Should not be executed $n");
END
     }
    elsif (my $a = $$gen{$action})                                              # Action for this instruction
     {&$a($i)
     }
    else
     {confess "Need implementation of $action";
     }

    push @c, <<END;
        end
END
   }

  my $steps = sprintf "%6d", $exec->totalInstructions + 1;                      # The extra step is to allow the tests to be analyzed by the test bench
  push @c, <<END;                                                               # End of last sub sequence
      endcase
      if ($traceExecution) begin
        for(i = 0; i < $memoryPrintWidth; i = i + 1) \$write("%2d",   localMem[i]); \$display("");
        for(i = 0; i < $memoryPrintWidth; i = i + 1) \$write("%2d",    heapMem[i]); \$display("");
        for(i = 0; i < $memoryPrintWidth; i = i + 1) \$write("%2d", arraySizes[i]); \$display("");
      end
      success  = 1;
END

  if (1)                                                                        # Check output queue matches out expectations
   {my @o = $exec->outLines->@*;
    for my $o(keys @o)
     {my $O = $o[$o];
      push @c, <<END;
      success  = success && outMem[$o] == $O;
END
     }
   }

  push @c, <<END;                                                               # End of module
      finished = steps > $steps;
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
END

  $compile->code = join '', @c;

  $compile->testBench = <<'END';                                                # Test bench
//-----------------------------------------------------------------------------
// Test fpga
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module fpga_tb();                                                               // Test fpga
  reg clock;                                                                    // Driving clock
  reg reset;                                                                    // Reset to start of program
  reg finished;                                                                 // Goes high when the program has finished
  reg success;                                                                  // Indicates success or failure at finish

  `include "tests.sv"                                                           // Test routines

  fpga f                                                                        // Fpga
   (.clock    (clock),
    .reset    (reset),
    .finished (finished),
    .success  (success )
   );

  initial begin                                                                 // Test the fpga
       clock = 0;
    #1 reset = 1;
    #1 clock = 1;
    #1 reset = 0;
    #1 clock = 0;
    while(!finished) begin;
      #1 clock = 1;
      #1 clock = 0;
    end
    ok(finished == 1, "Finished");
    ok(success  == 1, "Success");
    checkAllTestsPassed(2);
    $finish();
  end
endmodule
END

  $compile->constraints = <<'END';                                              # Constraints file
//Part Number: GW1NR-LV9QN88PC6/I5

IO_LOC "clk" 52;
IO_LOC "led[0]" 10;
IO_LOC "led[1]" 11;
IO_LOC "led[2]" 13;
IO_LOC "led[3]" 14;
IO_LOC "led[4]" 15;
IO_LOC "led[5]" 16;
IO_LOC "key" 3;
IO_LOC "rst" 4;

CLOCK_LOC "led[0]" BUFS;
CLOCK_LOC "led[1]" BUFS;
CLOCK_LOC "led[2]" BUFS;
CLOCK_LOC "led[3]" BUFS;
CLOCK_LOC "led[4]" BUFS;
CLOCK_LOC "led[5]" BUFS;

// true LVDS pins
IO_LOC "tlvds_p" 25,26;
END

  if (1)                                                                        # Write code
   {my $D = fpd qw(../../verilog fpga tests), $name;                            # Folder to write into
    my $S = fpe $D, qw(fpga sv);                                                # Code
    my $s = join "", $compile->code;
    owf($S, $s);

    my $T = setFileExtension $S, "tb";                                          # Test bench
    my $t = join "", $compile->testBench;
    owf($T, $t);

    my $C = fpe $D, qw(tangnano9k cst);                                         # Constraints
    my $c = join "", $compile->constraints;
    owf($C, $c);
#   say STDERR "AAAA\n$S\n$T\n$C";
   }

  $compile
 }

#D0

my sub instructionListExport()                                                  #P Create an export statementto enable isage in other Perl programs.
 {my $i = instructionList;
  say STDERR '@EXPORT_OK   = qw(', (join ' ', map {$$_[0]} @$i), ");\n";
 }
#instructionListExport; exit;

use Exporter qw(import);
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA         = qw(Exporter);
@EXPORT      = qw();
@EXPORT_OK   = qw(Add Array ArrayCountGreater ArrayCountLess ArrayDump ArrayIndex ArrayOut ArraySize Assert AssertEq AssertFalse AssertGe AssertGt AssertLe AssertNe AssertTrue Bad Block Call Clear Confess Dec Dump Else Execute For ForArray ForIn Free GenerateMachineCodeDisAssembleExecute generateVerilogMachineCode Good IfEq IfFalse IfGe IfGt IfLe IfLt IfNe IfTrue In InSize Inc JFalse JTrue Jeq Jge Jgt Jle Jlt Jmp Jne LoadAddress LoadArea Mov MoveLong Nop Not Out Parallel ParamsGet ParamsPut Pop Procedure Push Random RandomSeed Resize Return ReturnGet ReturnPut Sequential ShiftDown ShiftLeft ShiftRight ShiftUp Start Subtract Tally Then Trace TraceLabels Var Watch);
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

return 1 if caller;

# Tests

#Test::More->builder->output("/dev/null");                                      # Reduce number of confirmation messages during testing

my $debug = -e q(/home/phil/);                                                  # Assume debugging if testing locally
sub is_deeply;
sub ok($;$);
sub x {exit if $debug}                                                          # Stop if debugging.
Test::More->builder->output("/dev/null");                                       # Reduce number of confirmation messages during testing

=pod

Tests are run using different combinations of execution engine and memory
manager to prove that different implementations produce the same results.

=cut

for my $testSet(1..2) {                                                         # Select various combinations of execution engine and memory handler
say STDERR "TestSet: $testSet";
$memoryTechnique = $testSet == 1 ? undef : \&setStringMemoryTechnique;          # Set memory allocation technique

eval {goto latest if $debug};

#latest:;
if (1)                                                                          ##Out ##Start ##Execute
 {Start 1;
  Out "Hello World";
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Hello World
END
 }

#latest:;
if (1)                                                                          ##InSize ##In
 {Start 1;
  my $i2 = InSize;
  my $a = In;
  my $i1 = InSize;
  my $b = In;
  my $i0 = InSize;
  Out $a;
  Out $b;
  Out $i2;
  Out $i1;
  Out $i0;
  my $e = Execute(suppressOutput=>1, in=>[88, 44]);
  is_deeply $e->outLines, [88, 44, 2, 1, 0];
  $e->compileToVerilog("InSize") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##Var
 {Start 1;
  my $a = Var 22;
  AssertEq $a, 22;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, "";
 }

#latest:;
if (1)                                                                          ##Nop
 {Start 1;
  Nop;
  my $e = Execute;
  is_deeply $e->out, "";
 }

#latest:;
if (1)                                                                          ##Mov
 {Start 1;
  my $a = Mov 2;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [2];
 }

#latest:;
if (1)
 {Start 1;                                                                      ##Mov
  my $a = Mov  3;
  my $b = Mov  $$a;
  my $c = Mov  \$b;
  Out $c;
  my $e = Execute(suppressOutput=>1, lowLevel=>1);
  is_deeply $e->outLines, [3];
 }

#latest:;
if (1)                                                                          ##Add
 {Start 1;
  my $a = Add 3, 2;
  Out  $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [5];
  $e->compileToVerilog("Add") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##Subtract
 {Start 1;
  my $a = Subtract 4, 2;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [2];
  $e->compileToVerilog("Subtract") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##Dec
 {Start 1;
  my $a = Mov 3;
  Dec $a;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [2];
 }

#latest:;
if (1)                                                                          ##Inc
 {Start 1;
  my $a = Mov 3;
  Inc $a;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [4];
 }

#latest:;
if (1)                                                                          ##Not
 {Start 1;
  my $a = Mov 3;
  my $b = Not $a;
  my $c = Not $b;
  Out $a;
  Out $b;
  Out $c;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
3
0
1
END
  $e->compileToVerilog("Not") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##ShiftLeft  ##generateVerilogMachineCode
 {Start 1;
  my $a = Mov 1;
  ShiftLeft $a, $a;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [2];
  $e->compileToVerilog("ShiftLeft") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##ShiftRight
 {Start 1;
  my $a = Mov 4;
  ShiftRight $a, 1;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [2];
  $e->compileToVerilog("ShiftRight") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##Jmp
 {Start 1;
  Jmp (my $a = label);
    Out  1;
    Jmp (my $b = label);
  setLabel($a);
    Out  2;
  setLabel($b);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [2];
  $e->compileToVerilog("Jmp") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##JLt ##Label
 {Start 1;
  Mov 0, 1;
  my $e = Execute(suppressOutput=>1);
 }

#latest:;
if (1)                                                                          ##JLt ##Label
 {Start 1;
  Mov 0, 1;
  Jlt ((my $a = label), \0, 2);
    Out  1;
    Jmp (my $b = label);
  setLabel($a);
    Out  2;
  setLabel($b);

  Jgt ((my $c = label), \0, 3);
    Out  3;
    Jmp (my $d = label);
  setLabel($c);
    Out  4;
  setLabel($d);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [2..3];
 }

#latest:;
if (1)                                                                          ##Label
 {Start 1;
  Mov 0, 0;
  my $a = setLabel;
    Out \0;
    Inc \0;
  Jlt $a, \0, 10;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [0..9];
 }

#latest:;
if (1)                                                                          ##Mov ##Array
 {Start 1;
  my $a = Array "aaa";
  Mov     [$a,  0, "aaa"],  11;
  Mov     [$a,  1, "aaa"],  22;
  my $A = Array "aaa";
  Mov     [$A,  1, "aaa"],  33;
  my $B = Mov [$A, 1, "aaa"];
  Out     [$a,  0, "aaa"];
  Out     [$a,  1, "aaa"];
  Out     $B;

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [11, 22, 33];
  $e->compileToVerilog("Array") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##Call ##Return
 {Start 1;
  my $w = Procedure 'write', sub
   {Out 1;
    Return;
   };
  Call $w;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [1];
 }

#latest:;
if (1)                                                                          ##Call
 {Start 1;
  my $w = Procedure 'write', sub
   {my $a = ParamsGet 0;
    Out $a;
    Return;
   };
  ParamsPut 0, 999;
  Call $w;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [999];
 }

#latest:;
if (1)                                                                          ##Call ##ReturnPut ##ReturnGet
 {Start 1;
  my $w = Procedure 'write', sub
   {ReturnPut 0, 999;
    Return;
   };
  Call $w;
  ReturnGet \0, 0;
  Out \0;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [999];
 }

#latest:;
if (1)                                                                          ##Procedure
 {Start 1;
  my $add = Procedure 'add2', sub
   {my $a = ParamsGet 0;
    my $b = Add $a, 2;
    ReturnPut 0, $b;
    Return;
   };
  ParamsPut 0, 2;
  Call $add;
  my $c = ReturnGet 0;
  Out $c;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [4];
 }

#latest:;
if (1)                                                                          ##Confess
 {Start 1;
  my $c = Procedure 'confess', sub
   {Confess;
   };
  Call $c;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Confess at:
    2     3 confess
    1     6 call
END
 }

#latest:;
if (1)                                                                          ##Push
 {Start 1;
  my $a = Array   "aaa";
  Push $a, 1,     "aaa";
  Push $a, 2,     "aaa";
  my $e = Execute(suppressOutput=>1);
  #say STDERR $e->PrintHeap->($e); x;
  is_deeply $e->PrintHeap->($e), <<END;
Heap: |  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
 0  2 |  1  2
END
 }

#latest:;
if (1)                                                                          ##Pop
 {Start 1;
  my $a = Array   "aaa";
  Push $a, 1,     "aaa";
  Push $a, 2,     "aaa";
  my $c = Pop $a, "aaa";
  my $d = Pop $a, "aaa";

  Out $c;
  Out $d;
  my $e = Execute(suppressOutput=>1);

  #say STDERR $e->PrintLocal->($e); x;
  is_deeply $e->PrintLocal->($e), <<END;
Memory    0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31
Local:    0    2    1
END
  is_deeply $e->Heap->($e, 0), [];
  is_deeply $e->outLines, [2, 1];
  $e->compileToVerilog("Pop") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##Push
 {Start 1;
  my $a = Array "aaa";
  Push $a, 1, "aaa";
  Push $a, 2, "aaa";
  Push $a, 3, "aaa";
  my $b = Array "bbb";
  Push $b, 11, "bbb";
  Push $b, 22, "bbb";
  Push $b, 33, "bbb";
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->GetMemoryArrays->($e), 2;

  #say STDERR $e->PrintHeap->($e); exit;
  is_deeply $e->PrintHeap->($e), <<END;
Heap: |  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
 0  3 |  1  2  3
 1  3 | 11 22 33
END
  is_deeply $e->mostArrays, [undef, 2, 1, 1, 1];
 }

#latest:;
if (1)                                                                          ##Array ##Mov
 {Start 1;
  my $a = Array "alloc";
  my $b = Mov 99;
  my $c = Mov $a;
  Mov [$a, 0, 'alloc'], $b;
  Mov [$c, 1, 'alloc'], 2;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->Heap->($e, 0), [99, 2];
 }

#latest:;
if (1)                                                                          ##Free
 {Start 1;
  my $a = Array "node";
  Free $a, "aaa";
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Wrong name: aaa for array with name: node
    1     2 free
END
 }

#latest:;
if (1)                                                                          ##Free ##Dump
 {Start 1;
  my $a = Array "node";
  Out $a;
  Mov [$a, 1, 'node'], 1;
  Mov [$a, 2, 'node'], 2;
  Out Mov [$a, 1, 'node'];
  Out Mov [$a, 2, 'node'];
  Free $a, "node";
  my $e = Execute(suppressOutput=>1);
  #say STDERR $e->PrintHeap->($e); exit;
  is_deeply $e->PrintHeap->($e), <<END;
Heap: |  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
END
  is_deeply $e->outLines, [0..2];
 }

#latest:;
if (1)                                                                          ##IfEq  ##IfNe  ##IfLt ##IfLe  ##IfGt  ##IfGe
 {Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  IfEq $a, $a, Then {Out 111};
  IfNe $a, $a, Then {Out 222};
  IfLe $a, $a, Then {Out 333};
  IfLt $a, $a, Then {Out 444};
  IfGe $a, $a, Then {Out 555};
  IfGt $a, $a, Then {Out 666};
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
111
333
555
END
 }

#latest:;
if (1)                                                                          ##IfEq  ##IfNe  ##IfLt ##IfLe  ##IfGt  ##IfGe
 {Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  IfEq $a, $b, Then {Out "Eq"};
  IfNe $a, $b, Then {Out "Ne"};
  IfLe $a, $b, Then {Out "Le"};
  IfLt $a, $b, Then {Out "Lt"};
  IfGe $a, $b, Then {Out "Ge"};
  IfGt $a, $b, Then {Out "Gt"};
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Ne
Le
Lt
END
 }

#latest:;
if (1)                                                                          ##IfEq  ##IfNe  ##IfLt ##IfLe  ##IfGt  ##IfGe
 {Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  IfEq $b, $a, Then {Out "Eq"};
  IfNe $b, $a, Then {Out "Ne"};
  IfLe $b, $a, Then {Out "Le"};
  IfLt $b, $a, Then {Out "Lt"};
  IfGe $b, $a, Then {Out "Ge"};
  IfGt $b, $a, Then {Out "Gt"};
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Ne
Ge
Gt
END
 }

#latest:;
if (1)                                                                          ##IfTrue
 {Start 1;
  IfTrue 1,
  Then
   {Out 1
   },
  Else
   {Out 0
   };
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [1];
 }

#latest:;
if (1)                                                                          ##IfFalse ##Then ##Else
 {Start 1;
  IfFalse 1,
  Then
   {Out 1
   },
  Else
   {Out 0
   };
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [0];
 }


#latest:;
if (1)                                                                          ##For
 {Start 1;
  For
   {my ($i) = @_;
    Out $i;
   } 10;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [0..9];
 }

#latest:;
if (1)                                                                          ##For
 {Start 1;
  For
   {my ($i) = @_;
    Out $i;
   } 10, reverse=>1;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [reverse 0..9];
 }

#latest:;
if (1)                                                                          ##For
 {Start 1;
  For
   {my ($i) = @_;
    Out $i;
   } [2, 10];
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [2..9];
 }

#latest:;
if (1)                                                                          ##Assert
 {Start 1;
  Assert;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert failed
    1     1 assert
END
 }

#latest:;
if (1)                                                                          ##AssertEq
 {Start 1;
  Mov 0, 1;
  AssertEq \0, 2;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 == 2 failed
    1     2 assertEq
END
 }

#latest:;
if (1)                                                                          ##AssertNe
 {Start 1;
  Mov 0, 1;
  AssertNe \0, 1;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 != 1 failed
    1     2 assertNe
END
 }

#latest:;
if (1)                                                                          ##AssertLt
 {Start 1;
  Mov 0, 1;
  AssertLt \0, 0;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 <  0 failed
    1     2 assertLt
END
 }

#latest:;
if (1)                                                                          ##AssertLe
 {Start 1;
  Mov 0, 1;
  AssertLe \0, 0;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 <= 0 failed
    1     2 assertLe
END
 }

#latest:;
if (1)                                                                          ##AssertGt
 {Start 1;
  Mov 0, 1;
  AssertGt \0, 2;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 >  2 failed
    1     2 assertGt
END
 }

#latest:;
if (1)                                                                          ##AssertGe
 {Start 1;
  Mov 0, 1;
  AssertGe \0, 2;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Assert 1 >= 2 failed
    1     2 assertGe
END
 }

#latest:;
if (1)                                                                          ##AssertTrue
 {Start 1;
  AssertFalse 0;
  AssertTrue  0;
  my $e = Execute(suppressOutput=>1, trace=>1);
  #say STDERR dump($e->out);

  is_deeply $e->out, <<END;
    1     0     0    10   assertFalse
AssertTrue 0 failed
    1     2 assertTrue
    2     1     0    16    assertTrue
END
 }

#latest:;
if (1)                                                                          ##AssertFalse
 {Start 1;
  AssertTrue  1;
  AssertFalse 1;
  my $e = Execute(suppressOutput=>1, trace=>1);
  #say STDERR dump($e->out);

  is_deeply $e->out, <<END;
    1     0     0    16    assertTrue
AssertFalse 1 failed
    1     2 assertFalse
    2     1     0    10   assertFalse
END
 }

#latest:;
if (1)                                                                          # Temporary variable
 {my $s = Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  Out $a;
  Out $b;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
2
END
 }

#latest:;
if (1)                                                                          ##Array ##Mov ##Call
 {Start 1;
  my $a = Array "aaa";
  Dump;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Stack trace:
    1     2 dump
END
 }

#latest:;
if (1)                                                                          ##Array ##Mov ##Call ##ParamsPut ##ParamsGet
 {Start 1;
  my $a = Array "aaa";
  my $i = Mov 1;
  my $v = Mov 11;
  ParamsPut 0, $a;
  ParamsPut 1, $i;
  ParamsPut 2, $v;
  my $set = Procedure 'set', sub
   {my $a = ParamsGet 0;
    my $i = ParamsGet 1;
    my $v = ParamsGet 2;
    Mov [$a, \$i, 'aaa'], $v;
    Return;
   };
  Call $set;
  my $V = Mov [$a, \$i, 'aaa'];
  AssertEq $v, $V;
  Out [$a, \$i, 'aaa'];
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [11];
 }

#latest:;
if (0)                                                                          ##Array ##Clear
 {Start 1;
  my $a = Array "aaa";
  #Clear $a, 10, 'aaa';
  my $e = Execute(suppressOutput=>1, maximumArraySize=>10);
  is_deeply $e->Heap->($e, 0), [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
 }

#latest:;
if (1)                                                                          ##Block ##Good ##Bad
 {Start 1;
  Block
   {my ($start, $good, $bad, $end) = @_;
    Out 1;
    Jmp $good;
   }
  Good
   {Out 2;
   },
  Bad
   {Out 3;
   };
  Out 4;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
2
4
END
 }

#latest:;
if (1)                                                                          ##Block
 {Start 1;
  Block
   {my ($start, $good, $bad, $end) = @_;
    Out 1;
    Jmp $bad;
   }
  Good
   {Out 2;
   },
  Bad
   {Out 3;
   };
  Out 4;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
3
4
END
 }

#latest:;
if (1)                                                                          ##Procedure
 {Start 1;
  for my $i(1..10)
   {Out $i;
   };
  IfTrue 0,
  Then
   {Out 99;
   };
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [1..10];
  is_deeply $e->outLines, [1..10];
 }

#latest:;
if (0)                                                                          # Double write - needs rewrite of double write detection
 {Start 1;
  Mov 1, 1;
  Mov 2, 1;
  Mov 3, 1;
  Mov 3, 1;
  Mov 1, 1;
  my $e = Execute(suppressOutput=>0);
  ok keys($e->doubleWrite->%*) == 2;                                            # In area 0, variable 1 was first written by instruction 0 then again by instruction 1 once.
 }

#latest:;
if (1)                                                                          # Pointless assign
 {Start 1;
  Add 2, 1, 1;
  Add 2, 2, 0;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->pointlessAssign, { 1=>  1 };
 }

#latest:;
if (1)                                                                          ##Array ##Mov ##Call
 {Start 1;
  my $set = Procedure 'set', sub
   {my $a = ParamsGet 0;
    Out $a;
   };
  ParamsPut 0, 1;  Call $set;
  ParamsPut 0, 2;  Call $set;
  ParamsPut 0, 3;  Call $set;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
2
3
END
 }

#latest:;
if (1)                                                                          # Invalid address
 {Start 1;
  Mov 1, \0;
  my $e = Execute(suppressOutput=>1);
  ok $e->out =~ m"Cannot assign an undefined value";
 }

#latest:;
if (0)                                                                          ##LoadArea ##LoadAddress
 {Start 1;
  my $a = Array "array";
  my $b = Mov 2;
  my $c = Mov 5;
  my $d = LoadAddress $c;
  my $f = LoadArea    [$a, 0, 'array'];

  Out $d;
  Out $f;

  Mov [$a, \$b, 'array'], 22;
  Mov [$a, \$c, 'array'], 33;
  Mov [$f, \$d, 'array'], 44;

  my $e = Execute(suppressOutput=>1, maximumArraySize=>6);

  is_deeply $e->out, <<END;
2
1
END

  is_deeply $e->Heap->($e, 0), [undef, undef, 44, undef, undef, 33] if $testSet <= 2;
  is_deeply $e->Heap->($e, 0), [0,     0,     44, 0,     0,     33] if $testSet  > 2;

  is_deeply $e->widestAreaInArena, [undef, 5, 4];
  is_deeply $e->namesOfWidestArrays, [undef, "array", "stackArea"]   if $testSet % 2;
 }

#latest:;
if (1)                                                                          ##ShiftUp
 {Start 1;
  my $b = Array "array";
  my $a = Array "array";

  Mov [$a, 0, 'array'], 0;
  Mov [$a, 1, 'array'], 1;
  Mov [$a, 2, 'array'], 2;
  Resize $a, 3, 'array';

  ShiftUp [$a, 0, 'array'], 99;

  ForArray
   {my ($i, $a, $Check, $Next, $End) = @_;
    Out $a;
   } $a, "array";

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines,      [99, 0, 1, 2];
  $e->compileToVerilog("Shift_up") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##ShiftUp
 {Start 1;
  my $b = Array "array";
  my $a = Array "array";

  Mov [$a, 0, 'array'], 0;
  Mov [$a, 1, 'array'], 1;
  Mov [$a, 2, 'array'], 2;
  Resize $a, 3, 'array';
  ShiftUp [$a, 1, 'array'], 99;

  ForArray
   {my ($i, $a, $Check, $Next, $End) = @_;
    Out $a;
   } $a, "array";

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [0, 99, 1, 2];
 }

#latest:;
if (1)                                                                          ##ShiftUp ##Sequential
 {Start 1;
  my $b = Array "array";
  my $a = Array "array";

  Sequential
    sub{Mov [$a, 0, 'array'], 0},
    sub{Mov [$a, 1, 'array'], 1},
    sub{Mov [$a, 2, 'array'], 2},
    sub{Resize $a, 3, 'array'};

  ShiftUp [$a, 2, 'array'], 99;

  ForArray
   {my ($i, $a, $Check, $Next, $End) = @_;
    Out $a;
   } $a, "array";

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines,      [0, 1, 99, 2];
  $e->compileToVerilog("Shift_up_2") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##ShiftUp ##Parallel
 {Start 1;
  my $a = Array "array";

  Parallel
    sub{Mov [$a, 0, 'array'], 0},
    sub{Mov [$a, 1, 'array'], 1},
    sub{Mov [$a, 2, 'array'], 2};

  ShiftUp [$a, 3, 'array'], 99;

  my $e = Execute(suppressOutput=>0);
  is_deeply $e->Heap->($e, 0), [0, 1, 2, 99];
  is_deeply [$e->timeParallel, $e->timeSequential], [3,5];
 }

#latest:;
if (1)                                                                          ##ShiftUp
 {Start 1;
  my $a = Array "array";

  my @i;
  for my $i(1..7)
   {push @i, sub{Mov [$a, $i-1, 'array'], 10*$i};
   }
  Parallel @i;

  ShiftUp [$a, 2, 'array'], 26;
  my $e = Execute(suppressOutput=>1, maximumArraySize=>8);
  is_deeply $e->Heap->($e, 0), bless([10, 20, 26, 30, 40, 50, 60, 70], "array");
 }

#latest:;
if (1)                                                                          ##ShiftDown
 {Start 1;
  my $a = Array "array";

  Parallel
    sub{Mov [$a, 0, 'array'], 0},
    sub{Mov [$a, 1, 'array'], 99},
    sub{Mov [$a, 2, 'array'], 2};

  my $b = ShiftDown [$a, 1, 'array'];
  Out $b;

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->Heap->($e, 0), [0, 2];
  is_deeply $e->outLines, [99];
 }

#latest:;
if (1)                                                                          ##JTrue ##JFalse ##Jeq ##Jne ##Jle ##Jlt ##Jge ##Jgt
 {Start 1;
  For
   {my ($a, $check, $next, $end) = @_;
    Block
     {my ($start, $good, $bad, $end) = @_;
      JTrue $end, $a;
      Out 1;
     };
    Block
     {my ($start, $good, $bad, $end) = @_;
      JFalse $end, $a;
      Out 2;
     };
    Block
     {my ($start, $good, $bad, $end) = @_;
      JTrue $end, $a;
      Out 3;
     };
    Block
     {my ($start, $good, $bad, $end) = @_;
      JFalse $end, $a;
      Out 4;
     };
    Block
     {my ($start, $good, $bad, $end) = @_;
      Jeq $end, $a, 3;
      Out 5;
     };
    Block
     {my ($start, $good, $bad, $end) = @_;
      Jne $end, $a, 3;
      Out 6;
     };
    Block
     {my ($start, $good, $bad, $end) = @_;
      Jle $end, $a, 3;
      Out 7;
     };
    Block
     {my ($start, $good, $bad, $end) = @_;
      Jlt  $end, $a, 3;
      Out 8;
     };
    Block
     {my ($start, $good, $bad, $end) = @_;
      Jge  $end, $a, 3;
      Out 9;
     };
    Block
     {my ($start, $good, $bad, $end) = @_;
      Jgt  $end, $a, 3;
      Out 10;
     };
   } 5;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [1, 3, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 5, 9, 10, 2, 4, 6, 8, 10, 2, 4, 5, 7, 8];
  $e->compileToVerilog("JFalse") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##Array ##Mov
 {Start 1;
  my $a = Array 'aaa';
  my $b = Mov 2;                                                                # Location to move to in a
  Mov [$a,  0, 'aaa'], 1;
  Mov [$a,  1, 'aaa'], 2;
  Mov [$a,  2, 'aaa'], 3;

  For
   {my ($i, $check, $next, $end) = @_;
    Out 1;
    Jeq $next, [$a, \$i, 'aaa'], 2;
    Out 2;
   } 3;

  my $e = Execute(suppressOutput=>1);


  is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       31 instructions executed" if     $e->assembly->lowLevelOps;
  is_deeply $e->analyzeExecutionResults(doubleWrite=>3), "#       19 instructions executed" unless $e->assembly->lowLevelOps;
  is_deeply $e->outLines, [1, 2, 1, 1, 2];
  $e->compileToVerilog("Mov2") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##Array
 {Start 1;

  For                                                                           # Allocate and free several times to demonstrate area reuse
   {my ($i) = @_;
    my $a = Array 'aaaa';
    Mov [$a, 0, 'aaaa'], $i;
    Free $a, 'aaaa';
    Dump;
   } 3;

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->counts,                                                         # Several allocations and frees
   {array=>3, free=>3, add=>3, jGe=>4, jmp=>3, mov=>4
   };
  is_deeply $e->out, <<END;
Stack trace:
    1     8 dump
Stack trace:
    1     8 dump
Stack trace:
    1     8 dump
END
 }

#latest:;
if (1)                                                                          ##Resize
 {Start 1;
  my $a = Array 'aaa';
  Parallel
    sub{Mov [$a, 0, 'aaa'], 1},
    sub{Mov [$a, 1, 'aaa'], 2},
    sub{Mov [$a, 2, 'aaa'], 3};
  Resize $a, 2, "aaa";
  ArrayDump $a;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->Heap->($e, 0), [1, 2];
  is_deeply eval($e->out), [1,2];
 }

#latest:;
if (1)                                                                          ##Trace ##Then ##Else
 {Start 1;
  Trace 1;
  IfEq 1, 2,
  Then
   {Mov 1, 1;
    Mov 2, 1;
   },
  Else
   {Mov 3, 3;
    Mov 4, 4;
   };
  IfEq 2, 2,
  Then
   {Mov 1, 1;
    Mov 2, 1;
   },
  Else
   {Mov 3, 3;
    Mov 4, 4;
   };
  my $e = Execute(suppressOutput=>1);

  #say STDERR "AAAA", dump($e->assembly->lowLevelOps);
  #say STDERR $e->out; exit;

  is_deeply $e->out, <<END unless $e->assembly->lowLevelOps;
Trace: 1
    1     0     0    59         trace
    2     1     1    29           jNe
    3     5     0    32         label
    4     6     1    35           mov  [0, 3, stackArea] = 3
    5     7     1    35           mov  [0, 4, stackArea] = 4
    6     8     0    32         label
    7     9     1    29           jNe
    8    10     1    35           mov  [0, 1, stackArea] = 1
    9    11     1    35           mov  [0, 2, stackArea] = 1
   10    12     1    31           jmp
   11    16     0    32         label
END

  is_deeply $e->out, <<END if $e->assembly->lowLevelOps;
Trace: 1
    1     0     0    64         trace
    2     1     1    29           jNe
    3     5     0    32         label
    4     6     1    35           mov  [0, 3, stackArea] = 3
    5     7     1    35           mov  [0, 4, stackArea] = 4
    6     8     0    32         label
    7     9     1    29           jNe
    8    10     1    35           mov  [0, 1, stackArea] = 1
    9    11     1    35           mov  [0, 2, stackArea] = 1
   10    12     1    31           jmp
   11    16     0    32         label
END

  is_deeply scalar($e->notExecuted->@*), 6;
 }

#latest:;
if (1)                                                                          ##Watch
 {Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  my $c = Mov 3;
  Watch $b;
  Mov $a, 4;
  Mov $b, 5;
  Mov $c, 6;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
Change at watched arena: 2, area: 0(stackArea), address: 1
    1     6 mov
Current value: 2 New value: 5
END
 }

#latest:;
if (1)                                                                          ##ArraySize
 {Start 1;
  my $a = Array "aaa";
  my $b = Array "bbb";
  Out ArraySize $a, "aaa";
  Out ArraySize $b, "bbb";
  Free $b, "bbb";
  Out ArraySize $a, "aaa";
  Free $a, "aaa";
  Out ArraySize $a, "aaa";                                                      #FIX - an unalocated array should not be accessible
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
0
0
0
No such with array: 0 in arena 1
    1    11 arraySize
END
 }

#latest:;
if (1)                                                                          ##ArraySize ##ForArray ##Array ##Nop
 {Start 1;
  my $a = Array "aaa";
  Parallel
    sub{Mov [$a, 0, "aaa"], 1},
    sub{Mov [$a, 1, "aaa"], 22},
    sub{Mov [$a, 2, "aaa"], 333};

  my $n = ArraySize $a, "aaa";
  Out "Array size:";
  Out $n;
  ArrayDump $a;

  ForArray
   {my ($i, $e, $check, $next, $end) = @_;
    Out $i; Out $e;
   }  $a, "aaa";

  Nop;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->Heap->($e, 0), [1, 22, 333];
  is_deeply $e->out, <<END;
Array size:
3
bless([1, 22, 333], "aaa")
0
1
1
22
2
333
END
 }

#latest:;
if (1)                                                                          ##ForIn
 {Start 1;

  ForIn
   {my ($i, $e, $check, $next, $end) = @_;
    Out $i; Out $e;
   };

  my $e = Execute(suppressOutput=>1, trace=>0, in=>[333, 22, 1]);
  $e->compileToVerilog("ForIn") if $testSet == 1 and $debug;
  is_deeply $e->outLines, [3, 333,  2, 22, 1, 1];
 }

#latest:;
if (1)                                                                          # Small array
 {Start 1;
  my $a = Array "array";
  my @a = qw(6 8 4 2 1 3 5 7);
  Push $a, $_, "array" for @a;                                                  # Load array
  ArrayDump $a;
  my $e = Execute(suppressOutput=>1, maximumArraySize=>9);
  is_deeply $e->Heap->($e, 0),  [6, 8, 4, 2, 1, 3, 5, 7];
 }

#latest:;
if (1)                                                                          ##ArrayDump ##Mov
 {Start 1;
  my $a = Array "aaa";
  Mov [$a, 0, "aaa"], 1;
  Mov [$a, 1, "aaa"], 22;
  Mov [$a, 2, "aaa"], 333;
  ArrayDump $a;
  my $e = Execute(suppressOutput=>1);

  is_deeply eval($e->out), [1, 22, 333];

  is_deeply $e->assembly->codeToString, <<'END' unless $e->assembly->lowLevelOps;
0000     array            0             3
0001       mov [\0, 0, 3, 0]             1
0002       mov [\0, 1, 3, 0]            22
0003       mov [\0, 2, 3, 0]           333
0004  arrayDump            0
END

  is_deeply $e->assembly->codeToString, <<'END' if     $e->assembly->lowLevelOps;
0000     array            0             3
0001       mov            1             1
0002  movWrite1 [\0, 0, 3, 0]            \1
0003      step
0004       mov            2            22
0005  movWrite1 [\0, 1, 3, 0]            \2
0006      step
0007       mov            3           333
0008  movWrite1 [\0, 2, 3, 0]            \3
0009      step
0010  arrayDump            0
END

  #say STDERR $e->assembly->codeToString; exit;
 }

#latest:;
if (1)                                                                          ##MoveLong
 {my $N = 10;
  Start 1;
  my $a = Array "aaa";
  my $b = Array "bbb";
  For
   {my ($i, $Check, $Next, $End) = @_;
    Mov [$a, \$i, "aaa"], $i;
    my $j = Add $i, 100;
    Mov [$b, \$i, "bbb"], $j;
   } $N;

  MoveLong [$b, 2, 'bbb'], [$a, 4, 'aaa'], 3;

  my $e = Execute(suppressOutput=>1, maximumArraySize=>11);
  is_deeply $e->Heap->($e, 0), [0 .. 9];
  is_deeply $e->Heap->($e, 1), [100, 101, 4, 5, 6, 105 .. 109];
  $e->compileToVerilog("MoveLong_1") if $testSet == 1 and $debug;
 }

#      0     1     2
#     10    20    30
# 5=0   15=1  25=2  35=3

#latest:;
if (1)                                                                          ##ArrayIndex
 {Start 1;
  my $a = Array "aaa";
  Mov   [$a, 0, "aaa"], 10;
  Mov   [$a, 1, "aaa"], 20;
  Mov   [$a, 2, "aaa"], 30;

  Out ArrayIndex       ($a, 20);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
END
  $e->compileToVerilog("ArrayIndex") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##ArrayCountLess
 {Start 1;
  my $a = Array "aaa";
  Mov   [$a, 0, "aaa"], 10;
  Mov   [$a, 1, "aaa"], 20;
  Mov   [$a, 2, "aaa"], 30;

  Out ArrayCountLess($a, 20);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
1
END
  $e->compileToVerilog("ArrayCountLess") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##ArrayCountGreater
 {Start 1;
  my $a = Array "aaa";
  Mov   [$a, 0, "aaa"], 10;
  Mov   [$a, 1, "aaa"], 20;
  Mov   [$a, 2, "aaa"], 30;

  Out ArrayCountGreater($a, 15);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
2
END
  $e->compileToVerilog("ArrayCountGreaterIndex") if $testSet == 1 and $debug;
 }

if (1)                                                                          ##ArrayIndex ##ArrayCountLess ##ArrayCountGreater
 {Start 1;
  my $a = Array "aaa";
  Mov   [$a, 0, "aaa"], 10;
  Mov   [$a, 1, "aaa"], 20;
  Mov   [$a, 2, "aaa"], 30;
  Resize $a, 3, "aaa";

  Out ArrayIndex       ($a, 30); Out ArrayIndex       ($a, 20); Out ArrayIndex       ($a, 10); Out ArrayIndex       ($a, 15);
  Out ArrayCountLess   ($a, 35); Out ArrayCountLess   ($a, 25); Out ArrayCountLess   ($a, 15); Out ArrayCountLess   ($a,  5);
  Out ArrayCountGreater($a, 35); Out ArrayCountGreater($a, 25); Out ArrayCountGreater($a, 15); Out ArrayCountGreater($a,  5);

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [qw(3 2 1 0 3 2 1 0 0 1 2 3)];
  $e->compileToVerilog("Array_scans") if $testSet == 1 and $debug;
 }

#latest:;
if (1)                                                                          ##Tally ##For
 {my $N = 5;
  Start 1;
  For
   {Tally 1;
    my $a = Mov 1;
    Tally 2;
    Inc $a;
    Tally 0;
   } $N;
  my $e = Execute;

  is_deeply $e->tallyCount, 2 * $N;
  is_deeply $e->tallyCounts, { 1 => {mov => $N}, 2 => {add => $N}};
 }

#latest:;
if (1)                                                                          ##TraceLabels
 {my $N = 5;
  Start 1;
  TraceLabels 1;
  For
   {my $a = Mov 1;
    Inc $a;
   } $N;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->out, <<END;
TraceLabels: 1
Label
    1     2 label
Label
    1     4 label
Label
    1     8 label
Label
    1     4 label
Label
    1     8 label
Label
    1     4 label
Label
    1     8 label
Label
    1     4 label
Label
    1     8 label
Label
    1     4 label
Label
    1     8 label
Label
    1     4 label
Label
    1    11 label
END
 }

#latest:;
if (1)                                                                          ##Random ##RandomSeed
 {Start 1;
  RandomSeed 1;
  my $a = Random 10;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  ok $e->out =~ m(\A\d\Z);
 }

#latest:;
if (1)                                                                          # Local variable
 {Start 1;
  my $a = Mov 1;
  Out $a;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [1];
 }
}

#latest:;
if (1)                                                                          # String memory
 {Start 1;
  my $a = Array "aaa";
  my $b = Array "bbb";
  Parallel
    sub
     {Push $a,  1,  "aaa";
      Push $a,  2,  "aaa";
      Push $a,  3,  "aaa";
     },
    sub
     {Push $b, 11,  "bbb";
      Push $b, 22,  "bbb";
      Push $b, 33,  "bbb";
     };
  my $b3 = Pop $b, "bbb";
  my $b2 = Pop $b, "bbb";
  my $b1 = Pop $b, "bbb";
  my $a3 = Pop $a, "aaa";
  my $a2 = Pop $a, "aaa";
  my $a1 = Pop $a, "aaa";

  Out $a1;
  Out $a2;
  Out $a3;
  Out $b1;
  Out $b2;
  Out $b3;

  my $e = Execute(suppressOutput=>1, stringMemory=>1);
  is_deeply $e->outLines, [qw(1 2 3 11 22 33)];

  my $E = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [qw(1 2 3 11 22 33)];
  is_deeply $e->mostArrays, [undef, 2, 1, 1, 1];
 }

#latest:;
if (1)
 {Start 1;

  my $a = Array 'aaa';
  Out $a;
  Free $a, 'aaa';
  my $b = Array 'bbb';
  Out $b;
  Free $b, 'bbb';
  my $c = Array 'ccc';
  Out $c;
  Free $c, 'ccc';

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [0,0,0];
  $e->compileToVerilog("Free") if $debug;
 }

#latest:;
if (1)                                                                          ##Jeq
 {Start 1;
  Block
   {my ($Start, $Good, $Bad, $End) = @_;

    my $a = Mov 1;
    my $b = Mov 2;
    Jeq $Good, $a, $b;
    Out 111;
    Jeq $Good, $a, $a;
    Out 222;
   }
  Good
   {Out 333;
   };
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [111, 333];
  $e->compileToVerilog("Jeq") if $debug;
 }

#latest:;
if (1)                                                                          ##Push
 {Start 1;
  my $a = Array   "aaa";
  Push $a, 1,     "aaa";
  Push $a, 2,     "aaa";

  ForArray
   {my ($i, $a, $Check, $Next, $End) = @_;
    Out $a;
   } $a, "aaa";

  my $e = Execute(suppressOutput=>1, stringMemory=>1);
  is_deeply $e->Heap->($e, 0), [1..2];
  is_deeply $e->outLines,      [1..2];
  $e->compileToVerilog("Push") if $debug;
 }

#latest:;
if (1)                                                                          # Local variable
 {Start 1;
  my $a = Mov 1;
  my $b = Mov 2;
  my $c = Mov 3;
  Out $a;
  Out $b;
  Out $c;
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines, [1..3];
  $e->compileToVerilog("Mov") if $debug;
 }

#latest:;
if (1)                                                                          ##MoveLong
 {Start 1;
  my $a = Array "aaa";
  my $b = Array "bbb";
  Mov [$a, 0, 'aaa'],  11;
  Mov [$a, 1, 'aaa'],  22;
  Mov [$a, 2, 'aaa'],  33;
  Mov [$a, 3, 'aaa'],  44;
  Mov [$a, 4, 'aaa'],  55;
  Mov [$b, 0, 'bbb'],  66;
  Mov [$b, 1, 'bbb'],  77;
  Mov [$b, 2, 'bbb'],  88;
  Mov [$b, 3, 'bbb'],  99;
  Mov [$b, 4, 'bbb'], 101;
  Resize $a, 5, 'aaa';
  Resize $b, 5, 'bbb';

  ForArray
   {my ($i, $a, $Check, $Next, $End) = @_;
    Out $a;
   } $a, "aaa";

  ForArray
   {my ($i, $b, $Check, $Next, $End) = @_;
    Out $b;
   } $b, "bbb";

  MoveLong [$a, 1, 'aaa'], [$b, 2, 'bbb'], 2;

  ForArray
   {my ($i, $a, $Check, $Next, $End) = @_;
    Out $a;
   } $a, "aaa";

  ForArray
   {my ($i, $b, $Check, $Next, $End) = @_;
    Out $b;
   } $b, "bbb";

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->heap(0), bless([11, 88, 99, 44, 55], "aaa");
  is_deeply $e->heap(1), bless([66, 77, 88, 99, 101],"bbb");
  is_deeply $e->outLines, [11, 22, 33, 44, 55, 66, 77, 88, 99, 101, 11, 88, 99, 44, 55, 66, 77, 88, 99, 101];
  $e->compileToVerilog("MoveLong_2") if $debug;
 }

#latest:;
if (1)                                                                          ##ForIn
 {Start 1;
  ForIn
   {my ($i, $v, $Check, $Next, $End) = @_;
    Out $i;
    Out $v;
   };
  my $e = Execute(suppressOutput=>1, in => [33,22,11]);
  is_deeply $e->outLines, [3,33, 2,22, 1,11];
  $e->compileToVerilog("In") if $debug;
 }

#latest:;
if (1)                                                                          ##ArrayOut
 {Start 1;
  my $a = Array "aaa";
  ForIn
   {my ($i, $v, $Check, $Next, $End) = @_;
    Push $a, $v, "aaa";
   };
  ArrayOut $a;
  my $e = Execute(suppressOutput=>1, in => [9,88,777]);
  is_deeply $e->outLines, [9, 88, 777];
# $e->compileToVerilog("ArrayOut") if $debug;
 }

#latest:;
if (1)                                                                          ##compileToVerilog
 {Start 1;
  Out 1;
  Out 2;
  Out 3;
  ForIn
   {my ($i, $v, $Check, $Next, $End) = @_;
    Out $i;
    Out $v;
   };
  my $e = Execute(suppressOutput=>1, in => [33,22,11]);
  is_deeply $e->in, [];
  is_deeply $e->inOriginally, [33, 22, 11];
  is_deeply $e->outLines, [1,2,3, 3,33, 2,22, 1,11];
  is_deeply [map {$_->entry} $e->assembly->code->@*], [qw(1 0 0 1 0 0 0 0 0 0 0 0)]; # Sub sequence start points
  $e->compileToVerilog("ForIn") if $debug;
 }

#latest:;
if (1)                                                                          ##Add
 {Start 1;
  my $b = Array 'b';
  my $a = Array 'a';
  Mov [$a, 0, 'a'], 11;
  Mov [$a, 1, 'a'], 22;
  Add [$a, 2, 'a'], [$a, 1, 'a'], [$a, 0, 'a'];
  my $c = Mov $a;
  Out [$c, 2, 'a'];
  my $e = Execute(suppressOutput=>1, lowLevel=>1);
  is_deeply $e->outLines, [33];
  $e->compileToVerilog("ArrayAdd") if $debug;
 }

=pod
 (\A.{80})\s+(#.*\Z) \1\2
say STDERR '  is_deeply $e->out, <<END;', "\n", $e->out, "END"; exit;
=cut
