#!/usr/bin/perl -I../lib/ -Ilib -I/home/phil/perl/cpan/ZeroEmulatorLowLevel/lib/
#-------------------------------------------------------------------------------
# Zero assembler language implemention of a generic N-Way tree.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
#-------------------------------------------------------------------------------
# Key compression in each node by eliminating any common prefix present in each key in each node especially useful if we were to add attributes like userid, process, string position, rwx etc to front of each key.  Data does does not need this additional information.
# Use resize on keys, not on data or down.  Can we use the implicit size of keys to avoid having a size in field the Node?
# Change Sequential back to parallel - it was too difficult to debug the code with parallel in effect because it kept reordering the code in different ways
use v5.30;
package Zero::BTree;
our $VERSION = 20230519;                                                        # Version
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Zero::Emulator qw(:all);
eval "use Test::More tests=>115" unless caller;

makeDieConfess;

my sub MaxIterations{99};                                                       # The maximum number of levels in an N-Way tree

my $Tree = sub                                                                  # The structure of an N-Way tree
 {my $t = Zero::Emulator::AreaStructure("Structure");
     $t->name(q(keys));                                                         # Number of keys in tree
     $t->name(q(nodes));                                                        # Number of nodes in tree
     $t->name(q(MaximumNumberOfKeys));                                          # The maximum number of keys in any node of this tree
     $t->name(q(root));                                                         # Root node
     $t
 }->();

my $Node = sub                                                                  # The structure of a node in an N-Way tree node
 {my $n = Zero::Emulator::AreaStructure("Node_Structure");
     $n->name(q(length));                                                       # The current number of keys in the node
     $n->name(q(id));                                                           # A number identifying this node within this tree
     $n->name(q(up));                                                           # Parent node unless at the root node
     $n->name(q(tree));                                                         # The definition of the containing tree
     $n->name(q(keys));                                                         # Keys associated with this node
     $n->name(q(data));                                                         # Data associated with each key associated with this node
     $n->name(q(down));                                                         # Next layer of nodes down from this node
     $n
 }->();

my $FindResult = sub                                                            # The structure of a find result
 {my $f = Zero::Emulator::AreaStructure("FindResult");
  $f->name(q(node));                                                            # Node found
  $f->name(q(cmp));                                                             # Result of the last comparison
  $f->name(q(index));                                                           # Index in the node of located element
  $f
 }->();

my sub FindResult_lower   {0}                                                   # Comparison result
my sub FindResult_found   {1}
my sub FindResult_higher  {2}
my sub FindResult_notFound{3}

#D1 Constructor                                                                 # Create a new N-Way tree.

sub New($)                                                                      # Create a variable referring to a new tree descriptor.
 {my ($n) = @_;                                                                 # Constant indicating the maximum number of keys per node in this tree

  $n > 2 && $n % 2 or confess "Number of key/data elements per node must be > 2 and odd";

  my $t = Array "Tree";                                                         # Allocate tree descriptor

  Sequential
    sub {Mov [$t, $Tree->address(q(MaximumNumberOfKeys)), 'Tree'], $n},         # Save maximum number of keys per node
    sub {Mov [$t, $Tree->address(q(root)),                'Tree'],  0},         # Clear root
    sub {Mov [$t, $Tree->address(q(keys)),                'Tree'],  0},         # Clear keys
    sub {Mov [$t, $Tree->address(q(nodes)),               'Tree'],  0},         # Clear nodes
  ;
  $t
 }

my sub Tree_getField($$)                                                        # Get a field from a tree descriptor
 {my ($tree, $field) = @_;                                                      # Tree, field name
  Mov [$tree, $Tree->address($field), 'Tree']                                   # Get attribute from tree descriptor
 }

my sub maximumNumberOfKeys($)                                                   # Get the maximum number of keys per node for a tree
 {my ($tree) = @_;                                                              # Tree to examine
  Tree_getField($tree, q(MaximumNumberOfKeys));                                 # Get attribute from tree descriptor
 };

my sub root($)                                                                  # Get the root node of a tree
 {my ($tree) = @_;                                                              # Tree to examine
  Tree_getField($tree, q(root));                                                # Get attribute from tree descriptor
 };

my sub setRoot($$)                                                              # Set the root node of a tree
 {my ($tree, $root) = @_;                                                       # Tree, root
  Mov [$tree, $Tree->address(q(root)), 'Tree'], $root;                          # Set root attribute
 };

sub Keys($)                                                                     # Get the number of keys in the tree..
 {my ($tree) = @_;                                                              # Tree to examine
  Tree_getField($tree, q(keys));                                                # Keys
 };

my sub incKeys($)                                                               # Increment the number of keys in a tree
 {my ($tree) = @_;                                                              # Tree
  Inc [$tree, $Tree->address(q(keys)), 'Tree'];                                 # Number of keys
 };

my sub nodes($)                                                                 # Get the number of nodes in the tree
 {my ($tree) = @_;                                                              # Tree to examine
  Tree_getField($tree, q(nodes));                                               # Nodes
 };

my sub incNodes($)                                                              # Increment the number of nodes n a tree
 {my ($tree) = @_;                                                              # Tree
  Inc [$tree, $Tree->address(q(nodes)), 'Tree'];                                # Number of nodes
 };

my sub Node_getField($$)                                                        # Get a field from a node descriptor
 {my ($node, $field) = @_;                                                      # Node, field name
  Mov [$node, $Node->address($field), 'Node'];                                  # Get attribute from node descriptor
 }

my sub Node_length($)                                                           # Get number of keys in a node
 {my ($node) = @_;                                                              # Node
  Node_getField($node, q(length));                                              # Get length
 }

my sub Node_lengthM1($)                                                         # Get number of keys in a node minus 1
 {my ($node) = @_;                                                              # Node
  Subtract [$node, $Node->address(q(length)), 'Node'], 1;                       # Get attribute from node descriptor
 }

my sub Node_setLength($$%)                                                      # Set the length of a node
 {my ($node, $length, %options) = @_;                                           # Node, length, options
  if (my $d = $options{add})
   {Add [$node, $Node->address(q(length)), 'Node'], $length, $d;                # Set length attribute
   }
  else
   {Mov [$node, $Node->address(q(length)), 'Node'], $length;                    # Set length attribute
   }
 }

my sub Node_incLength($)                                                        # Increment the length of a node
 {my ($node) = @_;                                                              # Node
  Inc [$node, $Node->address(q(length)), 'Node'];                               # Increment length attribute
 }

my sub Node_up($)                                                               # Get parent node from this node
 {my ($node) = @_;                                                              # Node
  Node_getField($node, q(up));                                                  # Get up
 }

my sub Node_setUp($$)                                                           # Set the parent of a node
 {my ($node, $parent) = @_;                                                     # Node, parent node, area containing parent node reference
  Mov [$node, $Node->address(q(up)), 'Node'], $parent;                          # Set parent
 }

my sub Node_tree($)                                                             # Get tree containing a node
 {my ($node) = @_;                                                              # Node
  Node_getField($node, q(tree));                                                # Get tree
 }

my sub Node_field($$)                                                           # Get the value of a field in a node
 {my ($node, $field) = @_;                                                      # Node, field name
  Mov [$node, $Node->address($field), 'Node'];                                  # Fields
 }

my sub Node_fieldKeys($)                                                        # Get the keys for a node
 {my ($node) = @_;                                                              # Node
  Mov [$node, $Node->address(q(keys)), 'Node'];                                 # Fields
 }

my sub Node_fieldData($)                                                        # Get the data for a node
 {my ($node) = @_;                                                              # Node
  Mov [$node, $Node->address(q(data)), 'Node'];                                 # Fields
 }

my sub Node_fieldDown($)                                                        # Get the children for a node
 {my ($node) = @_;                                                              # Node
  Mov [$node, $Node->address(q(down)), 'Node'];                                 # Fields
 }

my sub Node_getIndex($$$)                                                       # Get the indexed field from a node
 {my ($node, $index, $field) = @_;                                              # Node, index of field, field name
  my $F = Node_field($node, $field);                                            # Array
  Mov [$F, \$index, ucfirst $field];                                            # Field
 }

my sub Node_setIndex($$$$)                                                      # Set an indexed field to a specified value
 {my ($node, $index, $field, $value) = @_;                                      # Node, index, field name, value
  my $F = Node_field($node, $field);                                            # Array
  Mov [$F, \$index, ucfirst $field], $value;                                    # Set field to value
 }

my sub Node_keys($$)                                                            # Get the indexed key from a node
 {my ($node, $index) = @_;                                                      # Node, index of key
  Node_getIndex($node, $index, q(keys));                                        # Keys
 }

my sub Node_data($$)                                                            # Get the indexed data from a node
 {my ($node, $index) = @_;                                                      # Node, index of data
  Node_getIndex($node, $index, q(data));                                        # Data
 }

my sub Node_down($$)                                                            # Get the indexed child node from a node.
 {my ($node, $index) = @_;                                                      # Node, index of child
  Node_getIndex($node, $index, q(down));                                        # Child
 }

my sub Node_isLeaf($)                                                           # Put 1 in a temporary variable if a node is a leaf else 0.
 {my ($node) = @_;                                                              # Node
  Not [$node, $Node->address('down'), 'Node'];                                  # Whether the down field is present or not . 0 is never a user allocated memory area
 }

my sub Node_setKeys($$$)                                                        # Set a key by index.
 {my ($node, $index, $value) = @_;                                              # Node, index, value
  Node_setIndex($node, $index, q(keys), $value)                                 # Set indexed key
 }

my sub Node_setData($$$)                                                        # Set a data field by index.
 {my ($node, $index, $value) = @_;                                              # Node, index, value
  Node_setIndex($node, $index, q(data), $value)                                 # Set indexed key
 }

my sub Node_setDown($$$)                                                        # Set a child by index.
 {my ($node, $index, $value) = @_;                                              # Node, index, value
  Node_setIndex($node, $index, q(down), $value)                                 # Set indexed key
 }

my sub Node_new($%)                                                             # Create a variable referring to a new node descriptor.
 {my ($tree, %options) = @_;                                                    # Tree node is being created in, options
  my $n = Array "Node";                                                         # Allocate node

  Node_setLength $n, $options{length} // 0;                                     # Length
  Node_setUp $n, 0;                                                             # Parent

  my $k = Array "Keys";                                                         # Allocate keys
  Mov [$n, $Node->address(q(keys)), 'Node'], $k;                                # Keys area

  my $d = Array "Data";                                                         # Allocate data
  Mov [$n, $Node->address(q(data)), 'Node'], $d;                                # Data area

  Mov [$n, $Node->address(q(down)), 'Node'], 0;                                 # Down area

  Mov [$n, $Node->address(q(tree)), 'Node'], $tree;                             # Containing tree

  incNodes($tree);
  Mov [$n,    $Node->address(q(id)),    'Node'],                                # Assign an id to this node within the tree
      [$tree, $Tree->address(q(nodes)), 'Tree'];

  $n                                                                            # Return reference to new node
 }

my sub Node_allocDown($%)                                                       # Upgrade a leaf node to an internal node.
 {my ($node, %options) = @_;                                                    # Node to upgrade, options
  my $d = Array "Down";                                                         # Allocate down
  Mov [$node, $Node->address(q(down)), 'Node'], $d;                             # Down area
 }

my sub Node_openLeaf($$$$)                                                      # Open a gap in a leaf node
 {my ($node, $offset, $K, $D) = @_;                                             # Node

  Sequential
    sub {my $k = Node_fieldKeys $node; ShiftUp [$k, \$offset, 'Keys'], $K},
    sub {my $d = Node_fieldData $node; ShiftUp [$d, \$offset, 'Data'], $D};
  Node_incLength $node;
 }

my sub Node_open($$$$$)                                                         # Open a gap in an interior node
 {my ($node, $offset, $K, $D, $N) = @_;                                         # Node, offset of open, new key, new data, new right node

  Sequential
    sub {my $k = Node_fieldKeys $node; ShiftUp [$k, \$offset, 'Keys'], $K},
    sub {my $d = Node_fieldData $node; ShiftUp [$d, \$offset, 'Data'], $D},
    sub
     {my $n = Node_fieldDown $node;
      my $o1 = Add $offset, 1;
      ShiftUp [$n, \$o1,     'Down'], $N;
     };

  Node_incLength $node;
 }

my sub Node_copy_leaf($$$$)                                                     # Copy part of one leaf node into another node.
 {my ($t, $s, $so, $length) = @_;                                               # Target node, source node, source offset, length

  Sequential
    sub
     {my $sk = Node_fieldKeys $s;
      my $tk = Node_fieldKeys $t;
      MoveLong [$tk, \0, "Keys"], [$sk, \$so, "Keys"], $length;                 # Each key, data, down
     },
    sub
     {my $sd = Node_fieldData $s;
      my $td = Node_fieldData $t;
      MoveLong [$td, \0, "Data"], [$sd, \$so, "Data"], $length;                 # Each key, data, down
     };
 }

my sub Node_copy($$$$)                                                          # Copy part of one interior node into another node.
 {my ($t, $s, $so, $length) = @_;                                               # Target node, source node, source offset, length

  Sequential
    sub {&Node_copy_leaf($t, $s, $so, $length)},                                # Keys and data
    sub
     {my $sn = Node_fieldDown $s;                                               # Child nodes
      my $tn = Node_fieldDown $t;
      my $L  = Add $length, 1;
      MoveLong [$tn, \0, "Down"], [$sn, \$so, "Down"], $L;
     };
 }

my sub Node_free($)                                                             # Free a node
 {my ($node) = @_;                                                              # Node to free

  Sequential
    sub {my $K = Node_fieldKeys $node; Free $K, "Keys"},
    sub {my $D = Node_fieldData $node; Free $D, "Data"},
    sub
     {IfFalse Node_isLeaf($node),
      Then
       {my $N = Node_fieldDown $node; Free $N, "Down";
       };
     };

  Free $node, "Node";
 }

#D1 Find                                                                        # Find a key in a tree.

my sub FindResult_getField($$)                                                  # Get a field from a find result.
 {my ($findResult, $field) = @_;                                                # Find result, name of field
  Mov [$findResult, $FindResult->address($field), q(FindResult)];               # Fields
 }

sub FindResult_copy($$)                                                         #P Copy a find result
 {my ($F, $f) = @_;                                                             # Target find result, source find result
  MoveLong [$F, \0, "FindResult"], [$f, \0, "FindResult"], $FindResult->count;
 }

sub FindResult_cmp($)                                                           # Get comparison from find result.
 {my ($f) = @_;                                                                 # Find result
  FindResult_getField($f, q(cmp))                                               # Comparison
 }

my sub FindResult_index($)                                                      # Get index from find result
 {my ($f) = @_;                                                                 # Find result
  FindResult_getField($f, q(index))                                             # Index
 }

my sub FindResult_indexP1($)                                                    # Get index+1 from find result
 {my ($f) = @_;                                                                 # Find result
  Add [$f, $FindResult->address(q(index)), q(FindResult)], 1;                   # Fields
 }

my sub FindResult_node($)                                                       # Get node from find result
 {my ($f) = @_;                                                                 # Find result
  FindResult_getField($f, q(node))                                              # Node
 }

sub FindResult_data($)                                                          # Get data field from find results.
 {my ($f) = @_;                                                                 # Find result

  my $n; my $i;
  Sequential
    sub {$n = FindResult_node ($f)},
    sub {$i = FindResult_index($f)};
  my $d = Node_data($n, $i);
  $d
 }

sub FindResult_key($)                                                           # Get key field from find results.
 {my ($f) = @_;                                                                 # Find result

  my $n; my $i;
  Sequential
    sub {$n = FindResult_node ($f)},
    sub {$i = FindResult_index($f)};
  my $k = Node_keys($n, $i);
  $k
 }

my sub FindResult($$)                                                           # Convert a symbolic name for a find result comparison to an integer
 {my ($f, $cmp) = @_;                                                           # Find result, comparison result name
  return 0 if $cmp eq q(lower);
  return 1 if $cmp eq q(equal);
  return 2 if $cmp eq q(higher);
  return 3 if $cmp eq q(notFound);
 }

my sub FindResult_renew($$$$%)                                                  # Reuse an existing find result
 {my ($find, $node, $cmp, $index, %options) = @_;                               # Find result, node, comparison result, index, options

  Sequential
    sub {Mov [$find, $FindResult->address(q(node)) , 'FindResult'], $node},
    sub {Mov [$find, $FindResult->address(q(cmp))  , 'FindResult'], $cmp};

  if (my $d = $options{subtract})                                               # Adjust index if necessary
   {Subtract [$find, $FindResult->address(q(index)), 'FindResult'], $index, $d;
   }
  elsif (my $D = $options{add})                                                 # Adjust index if necessary
   {Add      [$find, $FindResult->address(q(index)), 'FindResult'], $index, $D;
   }
  else
   {Mov      [$find, $FindResult->address(q(index)), 'FindResult'], $index;
   }
  $find
 }

my sub FindResult_new()                                                         # Create an empty find result ready for use
 {Array "FindResult";                                                           # Find result
 }

my sub FindResult_free($)                                                       # Free a find result
 {my ($find) = @_;                                                              # Find result
  Free $find, "FindResult";                                                     # Free find result
 }

my sub ReUp($)                                                                  # Reconnect the children to their new parent.
 {my ($node) = @_;                                                              # Parameters
  my $l = Node_length($node);
  my $L = Add $l, 1;

  my $D = Node_fieldDown($node);
  For
   {my ($i, $check, $next, $end) = @_;                                          # Parameters
    my $d = Mov [$D, \$i, 'Down'];
            Node_setUp($d, $node);
   } $L;
 }

my sub Node_indexInParent($%)                                                   # Get the index of a node in its parent
 {my ($node, %options) = @_;                                                    # Node, options
  my $p = $options{parent} // Node_up($node);                                   # Parent
  AssertNe($p, 0);                                                              # Number of children as opposed to the number of keys
  my $d = Node_fieldDown($p);
  my $r = ArrayIndex $d, $node;
  Dec $r;
  $r
 }

my sub Node_indexInParentP1($%)                                                 # Get the index of a node in its parent
 {my ($node, %options) = @_;                                                    # Node, options
  my $p = $options{parent} // Node_up($node);                                   # Parent
  AssertNe($p, 0);                                                              # Number of children as opposed to the number of keys
  my $d = Node_fieldDown($p);
  ArrayIndex $d, $node;
 }

my sub Node_SplitIfFull($%)                                                     # Split a node if it is full. Return true if the node was split else false
 {my ($node, %options) = @_;                                                    # Node to split, options
  my $split = Var;

  Block                                                                         # Various splitting scenarios
   {my ($start, $good, $bad, $end) = @_;
    my $nl = Node_length($node);

    my $m = $options{maximumNumberOfKeys};                                      # Maximum number of keys supplied by caller
    Jlt $bad, $nl, $m if defined $m;                                            # Must be a full node

    my $t = Node_tree($node);                                                   # Tree we are splitting in
    my $N = $m // maximumNumberOfKeys($t);                                      # Maximum size of a node
    Jlt $bad, $nl, $N unless defined $m;                                        # Must be a full node

    my $n = $options{splitPoint};                                               # Split point supplied
    if (!defined $n)                                                            # Calculate split point
     {$n = Mov $N;
      ShiftRight $n, 1;
     }

    my $R = $options{rightStart} // Add $n, 1;                                  # Start of right hand side in a node

    my $p = Node_up($node);                                                     # Existing parent node

    IfTrue $p,
    Then                                                                        # Not a root node
     {my $r = Node_new($t, length=>$n);

      IfFalse Node_isLeaf($node),                                               # Not a leaf
      Then
       {Node_allocDown $r;                                                      # Add down area on right
        Node_copy($r, $node, $R, $n);                                           # New right node
        ReUp($r) unless $options{test};                                         # Simplify test set up
        my $N = Node_fieldDown $node; Resize $N, $R, "Down";
       },
      Else
       {Node_copy_leaf($r, $node, $R, $n);                                      # New right leaf
       };

      my $pl;
      Sequential
        sub {Node_setLength($node, $n)},
        sub {Node_setUp($r, $p)},
        sub {$pl = Node_length($p)};

      IfEq Node_down($p, $pl), $node,                                           # Splitting the last child - just add it on the end
      Then
       {Sequential
          sub {my $pk = Node_keys($node, $n); Node_setKeys($p, $pl, $pk)},
          sub {my $nd = Node_data($node, $n); Node_setData($p, $pl, $nd)};

        Sequential
          sub {my $K = Node_fieldKeys $node; Resize $K, $n, "Keys"},
          sub {my $D = Node_fieldData $node; Resize $D, $n, "Data"},
          sub {my $pl1 = Add $pl, 1;
               Node_setLength($p, $pl1);
               Node_setDown  ($p, $pl1, $r);
              };
        Jmp $good;
       },
      Else                                                                      # Splitting elsewhere in the node
       {my $i; my $pk; my $pd; my $K; my $D;
        Sequential
          sub {$i  = Node_indexInParent($node, parent=>$p, children=>$pl)},     # Index of the node being split in its parent
          sub {$pk = Node_keys($node, $n)},
          sub {$pd = Node_data($node, $n)};

        Sequential
          sub {$K  = Node_fieldKeys $node; Resize $K, $n, "Keys"},
          sub {$D  = Node_fieldData $node; Resize $D, $n, "Data"},
          sub {Node_open($p, $i, $pk, $pd, $r)};

        Jmp $good;
       };
     };

    my $l = Node_new($t, length=>$n);                                           # Split root node into two children
    my $r = Node_new($t, length=>$n);

    IfFalse Node_isLeaf($node),                                                 # Not a leaf
    Then
     {Node_allocDown $l;                                                        # Add down area on left
      Node_allocDown $r;                                                        # Add down area on right
      Sequential
        sub {Node_copy($l, $node, 0,  $n)},                                     # New left  node
        sub {Node_copy($r, $node, $R, $n)};                                     # New right node
      Sequential
        sub {ReUp($l) unless $options{test}},                                   # Simplify testing
        sub {ReUp($r) unless $options{test}};
     },
    Else
     {Sequential
        sub {Node_allocDown $node},                                             # Add down area
        sub {Node_copy_leaf($l, $node, 0,  $n)},                                # New left  leaf
        sub {Node_copy_leaf($r, $node, $R, $n)};                                # New right leaf
     };

    my $pk; my $pd;
    Sequential
      sub {Node_setUp($l, $node)},                                              # Root node with single key after split
      sub {Node_setUp($r, $node)},                                              # Connect children to parent
      sub {$pk = Node_keys($node, $n)},                                         # Single key
      sub {$pd = Node_data($node, $n)};                                         # Data associated with single key

    Sequential
      sub {Node_setKeys  ($node, 0, $pk)},
      sub {Node_setData  ($node, 0, $pd)},
      sub {Node_setDown  ($node, 0, $l)},
      sub {Node_setDown  ($node, 1, $r)},
      sub {Node_setLength($node, 1)},
      sub {my $K = Node_fieldKeys $node; Resize $K, 1,  "Keys"},                # Resize split root node
      sub {my $D = Node_fieldData $node; Resize $D, 1,  "Data"},
      sub {my $W = Node_fieldDown $node; Resize $W, 2,  "Down"};

    Jmp $good;
   }
  Good                                                                          # Node was split
   {Mov $split, 1;
   },
  Bad                                                                           # Node was to small to split
   {Mov $split, 0;
   };
  $split
 }

my sub FindAndSplit($$%)                                                        # Find a key in a tree splitting full nodes along the path to the key
 {my ($tree, $key, %options) = @_;                                              # Tree to search, key, options
  my $node = root($tree);

  my $find = $options{findResult} // FindResult_new;                            # Find result work area

  Node_SplitIfFull($node, %options);                                            # Split the root node if necessary

  Block                                                                         # Exit this block when we have located the key
   {my ($Start, $Good, $Bad, $Found) = @_;

    For                                                                         # Step down through the tree
     {my ($j, $check, $next, $end) = @_;                                        # Parameters
      my $nl = Node_length($node);                                              # Length of node
      my $last = Subtract $nl, 1;                                               # Greater than largest key in node. Data often gets inserted in ascending order so we do this check first rather than last.
      IfGt $key, Node_keys($node, $last),                                       # Key greater than greatest key
      Then
       {IfTrue Node_isLeaf($node),                                              # Leaf
        Then
         {FindResult_renew($find, $node, FindResult_higher, $nl, subtract=>1);
          Jmp $Found;
         };
        my $n = Node_down($node, $nl);                                          # We will be heading down through the last node so split it in advance if necessary
        IfFalse Node_SplitIfFull($n, %options),                                 # No split needed
        Then
         {Mov $node, $n;
         };
        Jmp $next;
       };

      my $K = Node_fieldKeys($node);                                            # Keys arrays
      my $e = ArrayIndex $K, $key;
      IfTrue $e,
      Then
       {FindResult_renew($find, $node, FindResult_found, $e, subtract=>1);
        Jmp $Found;
       };

      my $I = ArrayCountLess $K, $key;                                          # Index at which to step down

      IfTrue Node_isLeaf($node),
      Then
       {FindResult_renew($find, $node, FindResult_lower, $I);
        Jmp $Found;
       };

      my $n = Node_down($node, $I);
      IfFalse Node_SplitIfFull($n, %options),                                   # Split the node we have stepped to if necessary - if we do we will have to restart the descent from one level up because the key might have moved to the other  node.
      Then
       {Mov $node, $n;
       };
     }  MaxIterations;
    Assert;                                                                     # Failed to descend through the tree to the key.
   };
  $find
 }

sub Find($$%)                                                                   # Find a key in a tree returning a L<FindResult> describing the outcome of the search.  To avoid allocating a new find result area for each individual request a preallocated find result area may be supplied via the findResult option.
 {my ($tree, $key, %options) = @_;                                              # Tree to search, key to find, options

  my $find = $options{findResult} // FindResult_new;                            # Find result work area

  Block                                                                         # Block
   {my ($Start, $Good, $Bad, $End) = @_;                                        # Block locations

    my $node = root($tree);                                                     # Current node we are searching

    IfFalse $node,                                                              # Empty tree
    Then
     {FindResult_renew($find, $node, FindResult_notFound, 0);                   # Was -1
      Jmp $End;
     };

    For                                                                         # Step down through tree
     {my ($j, $check, $next, $end) = @_;                                        # Parameters
      my $nl1 = Node_lengthM1($node);
      my $K = Node_fieldKeys($node);                                            # Keys

      IfGt $key, [$K, \$nl1, 'Keys'],                                           # Bigger than every key
      Then
       {my $nl = Add $nl1, 1;
        IfTrue Node_isLeaf($node),                                              # Leaf
        Then
         {FindResult_renew($find, $node, FindResult_higher, $nl);
          Jmp $End;
         };
        Mov $node, Node_down($node, $nl);
        Jmp $next;
       };

      my $e = ArrayIndex $K, $key;                                              # Check for equal keys
      IfTrue $e,                                                                # Found a matching key
      Then
       {FindResult_renew($find, $node, FindResult_found, $e, subtract=>1);      # Find result
        Jmp $End;
       };

      my $i = ArrayCountLess $K, $key;                                          # Check for smaller keys
      IfTrue Node_isLeaf($node),                                                # Leaf
      Then
       {FindResult_renew($find, $node, FindResult_lower, $i);
        Jmp $End;
       };
      Mov $node, Node_down($node, $i);
     } MaxIterations;
    Assert;
   };
  $find
 }

#D1 Insert                                                                      # Create a new entry in a tree to connect a key to data.

sub Insert($$$%)                                                                # Insert a key and its associated data into a tree.
 {my ($tree, $key, $data, %options) = @_;                                       # Tree, key, data

  my $find = $options{findResult} // FindResult_new;                            # Find result work area

  Block
   {my ($Start, $Good, $Bad, $Finish) = @_;                                     # Parameters
    my $n = root($tree);                                                        # Root node of tree

    IfFalse $n,                                                                 # Empty tree
    Then
     {my $n = Node_new($tree, length=>1);
      Sequential
        sub {Node_setKeys  ($n, 0, $key)},
        sub {Node_setData  ($n, 0, $data)},
        sub {incKeys($tree)},
        sub {setRoot($tree, $n)};
      my $K = Node_fieldKeys($n);                                               # Keys array
      Resize $K, 1, 'Keys';                                                     # Size of keys array
      my $D = Node_fieldData($n);                                               # Data array
      Resize $D, 1, 'Data';                                                     # Size of data array
      Jmp $Finish;
     };

    my $nl; my $mk;
    Sequential
      sub {$nl = Node_length($n)},                                              # Current length of node
      sub {$mk = maximumNumberOfKeys($tree)};                                   # Node has room for another key

    IfLt $nl, $mk,                                                              # Node has room for another key
    Then
     {IfFalse Node_up($n),                                                      # Root node
      Then
       {IfTrue Node_isLeaf($n),                                                 # Leaf root node
        Then
         {my $K = Node_fieldKeys($n);                                           # Keys array
          my $e = ArrayIndex $K, $key;
          IfTrue $e,                                                            # Key already exists in leaf root node
          Then
           {Dec $e;
            Node_setData($n, $e, $data);  ## Needs -1
            Jmp $Finish;
           };

          Resize $K, $nl, "Keys";
          my $D = Node_fieldData($n);                                           # Data array
          Resize $D, $nl, "Data";
          my $I = ArrayCountGreater $K, $key;                                   # Greater than all keys in leaf root node
          IfFalse $I,
          Then
           {Sequential
              sub {Node_setKeys($n, $nl, $key)},                                # Append the key at the end of the leaf root node because it is greater than all the other keys in the block and there is room for it
              sub {Node_setData($n, $nl, $data)},
              sub {Node_setLength($n, $nl, add=>1)},
              sub {incKeys($tree)};
            Jmp $Finish;
           };

          Sequential
            sub
              {my $i = ArrayCountLess $K, $key;                                 # Insert position
               Node_openLeaf($n, $i, $key, $data);                              # Insert into the root leaf node
              },
            sub {incKeys($tree)};
          Jmp $Finish;
         };
       };
     };
                                                                                # Insert node
    my $r = FindAndSplit($tree, $key, %options, findResult=>$find);             # Check for existing key

    my $N; my $c; my $i;
    Sequential
      sub {$N = FindResult_node($r)},
      sub {$c = FindResult_cmp($r)},
      sub {$i = FindResult_index($r)};

    IfEq $c, FindResult_found,                                                  # Found an equal key whose data we can update
    Then
     {Node_setData($N, $i, $data);
      Jmp $Finish;
     };

    IfEq $c, FindResult_higher,                                                 # Found a key that is greater than the one being inserted
    Then
     {my $i1 = Add $i, 1;
      Node_openLeaf($N, $i1, $key, $data);
     },
    Else
     {Node_openLeaf($N, $i,  $key, $data);
     };

    incKeys($tree);
    Node_SplitIfFull($N, %options);                                             # Split if the leaf is full to force keys up the tree
   };
  FindResult_free($find) unless $options{findResult};                           # Free the find result now we are finished with it unless we are using a global one
 }

#D1 Iteration                                                                   # Iterate over the keys and their associated data held in a tree.

my sub GoAllTheWayLeft($$)                                                      # Go as left as possible from the current node
 {my ($find, $node) = @_;                                                       # Find result, Node

  IfFalse $node,                                                                # Empty tree
  Then
   {FindResult_renew($find, $node, FindResult_notFound, 0);
   },
  Else
   {For                                                                         # Step down through tree
     {my ($i, $check, $next, $end) = @_;                                        # Parameters
      JTrue $end, Node_isLeaf($node);                                           # Reached leaf
      Mov $node, Node_down($node, 0);
     } MaxIterations;
    FindResult_renew($find, $node, FindResult_found, 0);                        # Leaf - place us on the first key
   };
  $find
 }

my sub GoUpAndAround($)                                                         # Go up until it is possible to go right or we can go no further
 {my ($find) = @_;                                                              # Find

  Block
   {my ($Start, $Good, $Bad, $Finish) = @_;                                     # Parameters
    my $node = FindResult_node($find);

    IfTrue Node_isLeaf($node),                                                  # Leaf
    Then
     {my $I = FindResult_indexP1($find);
      my $L = Node_length($node);
      IfLt $I, $L,                                                              # More keys in leaf
      Then
       {FindResult_renew($find, $node, FindResult_found, $I);
        Jmp $Finish;
       };

      my $parent = Node_up($node);                                              # Parent
      IfTrue $parent,
      Then
       {For                                                                     # Go up until we can go right
         {my ($j, $check, $next, $end) = @_;                                    # Parameters
          my $pl = Node_length($parent);                                        # Number of children
          my $i = Node_indexInParent($node, parent=>$parent, children=>$pl);    # Index in parent

          IfEq $i, $pl,                                                         # Last key - continue up
          Then
           {Mov $node, $parent;
            Mov $parent, [$node, $Node->address(q(up)), 'Node'];                # Parent
            JFalse $end, $parent;
           },
          Else
           {FindResult_renew($find, $parent,  FindResult_found, $i);            # Not the last key
            Jmp $Finish;
           };
         } MaxIterations;
       };
      FindResult_renew($find, $node, FindResult_notFound, 0);                   # Last key of root
      Jmp $Finish;
     };

    my $i = FindResult_indexP1($find);                                          # Not a leaf so on an interior key so we can go right then all the way left
    my $d = Node_down($node, $i);
    GoAllTheWayLeft($find, $d);
   };
  $find
 }

sub Iterate(&$)                                                                 # Iterate over a tree.
 {my ($block, $tree) = @_;                                                      # Block of code to execute for each key in tree, tree

  my $n; my $f; my $F;
  my $l = Mov 1;
  ShiftLeft $l, 31;
  Sequential
    sub {$n = root($tree)},
    sub {$f = FindResult_new},
    sub {$F = FindResult_new};

  GoAllTheWayLeft($f, $n);

  Block                                                                         # Visit each element sequentially
   {my ($Start, $Good, $Bad, $End) = @_;
    Jeq $End, FindResult_cmp($f), FindResult_notFound;

    FindResult_copy($F, $f);                                                    # Copying the find result allows for parallel processing

    Sequential
      sub {&$block($F)},
      sub {GoUpAndAround($f)};
    Jmp $Start;
   };

  Sequential
    sub{FindResult_free($f)},
    sub{FindResult_free($F)};
 }

#D1 Print                                                                       # Print trees horizontally.

my sub printNode($$$$$)                                                         # Print the keys or data in a node in memory
 {my ($memory, $node, $indent, $out, $keyNotData) = @_;
  #ref($node) =~ m(Node) or confess "Not a node: ".dump($node);
  my $k = $$node[$Node->offset(q(keys))];
  my $d = $$node[$Node->offset(q(data))];
  my $n = $$node[$Node->offset(q(down))];

  if ($n)                                                                       # Interior node
   {my $K = $$memory[$k];
    my $D = $$memory[$d];
    my $N = $$memory[$n];
    my $l = $$node[$Node->offset(q(length))];

    for my $i(0..$l-1)
     {my $c = $$memory[$$N[$i]];                                                # Child node
      my $p = $$memory[$$c[$Node->offset(q(up))]];

      __SUB__->($memory, $c, $indent+1, $out, $keyNotData);
      push @$out, [$indent, $keyNotData ? $$K[$i] : $$D[$i]];
     }

    __SUB__->($memory,   $$memory[$$N[$l]], $indent+1, $out, $keyNotData);
   }

  else                                                                          # Leaf node
   {my $K = $$memory[$k];
    my $D = $$memory[$d];
    my $l = $$node[$Node->offset(q(length))];

    for my $i(0..$l-1)
     {my $k = $$K[$i];
      my $d = $$D[$i];
      push @$out, [$indent, $keyNotData ? $k : $d];
     }
   }
  $out
 }

my sub printTree($$)                                                            # Print a tree
 {my ($m, $keyNotData) = @_;                                                    # Memory, key or data
  my $t = $$m[0];
  my $r = $$m[$$t[$Tree->offset(q(root))]];
  my $o = printNode($m, $r, 0, [], $keyNotData);

  my $C = $#$o;                                                                 # Number of columns
  my $R = max(map {$$o[$_][0]} keys @$o);                                       # Number of rows

  my $W = 3;                                                                    # Field width for each key
  my @o;                                                                        # Output area
  for   my $r(0..$R)
   {for my $c(0..$C)
     {$o[$r][$c] = ' ' x $W;
     }
   }

  for   my $p(keys @$o)                                                         # Write tree horizontally
   {next unless defined(my $v = $$o[$p][1]);
    my $r = $$o[$p][0];
    my $c = $p;

    $o[$r][$c] = sprintf("%${W}d", $v);
   }

  join "\n", (map { (join "", $o[$_]->@*) =~ s(\s+\Z) ()r;} keys @o), '';       # As a single string after removing trailing spaces on each line
 }

sub printTreeKeys($)                                                            # Print the keys held in a tree.
 {my ($e) = @_;                                                                 # Memory
  printTree($e->memory->[1], 1);
 }

sub printTreeData($)                                                            # Print the data held in a tree.
 {my ($e) = @_;                                                                 # Memory
  printTree($e->memory->[1], 0);
 }

#D1 Utilities                                                                   # Utility functions.

sub randomArray($)                                                              #P Create a random array.
 {my ($N) = @_;                                                                 # Size of array

  my @r = 1..$N;
  srand(1);

  for my $i(keys @r)                                                            # Disarrange the array
   {my $s = int rand @r;
    my $t = int rand @r;
    ($r[$t], $r[$s]) = ($r[$s], $r[$t]);
   }
  @r
 }

use Exporter qw(import);
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA         = qw(Exporter);
@EXPORT      = qw();
@EXPORT_OK   = qw(Find FindResult_cmp FindResult_data FindResult_key Insert Iterate New printTreeKeys printTreeData randomArray);
#say STDERR '@EXPORT_OK   = qw(', (join ' ', sort @EXPORT_OK), ');'; exit;
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

return 1 if caller;

# Tests

Test::More->builder->output("/dev/null");                                       # Reduce number of confirmation messages during testing

my $debug = -e q(/home/phil/);                                                  # Assume debugging if testing locally
eval {goto latest if $debug};

sub is_deeply;
sub ok($;$);
sub done_testing;
sub x {exit if $debug}                                                          # Stop if debugging.

#latest:;
if (1)                                                                          ##New
 {Start 1;
  Out New(3);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
0
END
  is_deeply $e->heap(0), [ 0, 0, 3, 0];
  $e->compileToVerilog("BTree/basic/1");
 }

#latest:;
if (1)                                                                          ##New
 {Start 1;
  my $t = New(3);
  my $r = root($t);

  setRoot($t, 1);
  my $R = root($t);

  my $n = maximumNumberOfKeys($t);

  incKeys($t) for 1..3;
  Out [$t, $Tree->address(q(keys)), 'Tree'];

  incNodes($t) for 1..5;
  Out nodes($t);

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, <<END;
3
5
END
  is_deeply $e->heap(0), [ 3, 5, 3, 1];
  $e->compileToVerilog("BTree/basic/2");
 }

#latest:;
if (1)                                                                          ##Node_new
 {Start 1;
  my $t = New(7);                                                               # Create tree
  my $n = Node_new($t);                                                         # Create node
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->heap(0), [0, 1, 7, 0];
  is_deeply $e->heap(1), [0, 1, 0, 0, 2, 3, 0];
  is_deeply $e->heap(2), [];
  is_deeply $e->heap(3), [];
  #$e->compileToVerilog("BTree/basic/3");
 }

#latest:;
if (1)                                                                          # Set up to test Node_open
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t);                                                         # Create node

  Node_allocDown $n;
  Node_setLength $n, $N;

  for my $i(0..$N-1)
   {my $I = $i + 1;
    Node_setKeys($n, $i,  10*$I);
    Node_setData($n, $i,  10*$I);
    Node_setDown($n, $i,  10*$i+5);
   }

  Node_setDown($n, $N, 75);

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->heap(0), bless([0, 1, 7, 0], "Tree");
  is_deeply $e->heap(1), bless([7, 1, 0, 0, 2, 3, 4], "Node");
  is_deeply $e->heap(2), bless([10, 20, 30, 40, 50, 60, 70], "Keys");
  is_deeply $e->heap(3), bless([10, 20, 30, 40, 50, 60, 70], "Data");
  is_deeply $e->heap(4), bless([5, 15, 25, 35, 45, 55, 65, 75], "Down");
  #$e->compileToVerilog("BTree/basic/4");
 }

#latest:;
if (1)                                                                          ##Node_open
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t);                                                         # Create node

  Node_allocDown $n;
  Node_setLength $n, $N;

  for my $i(0..$N-1)
   {my $I = $i + 1;
    Node_setKeys($n, $i,  10*$I);
    Node_setData($n, $i,  10*$I);
    Node_setDown($n, $i,  10*$i+5);
   }

  Node_setDown($n, $N, 75);

  Node_open($n, 2, 26, 26, 26);
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->heap(0), bless([0, 1, 7, 0], "Tree");
  is_deeply $e->heap(1), bless([8, 1, 0, 0, 2, 3, 4], "Node");
  is_deeply $e->heap(2), bless([10, 20, 26, 30, 40, 50, 60, 70], "Keys");
  is_deeply $e->heap(3), bless([10, 20, 26, 30, 40, 50, 60, 70], "Data");
  is_deeply $e->heap(4), bless([5, 15, 25, 26, 35, 45, 55, 65, 75], "Down");
  #$e->compileToVerilog("BTree/basic/5");
 }

#latest:;
if (1)                                                                          # Set up for Node_SplitIfFull at start non root
 {Start 1;
  my $N = 7;
  my $t = New($N);                                                              # Create tree
  my $n = Node_new($t);                                                         # Create node
          Node_allocDown $n;
  my $o = Node_new($t);                                                         # Create node
          Node_allocDown $o;

  Node_setLength $_, $N for $n, $o;

  for my $i(0..$N-1)
   {my $I = $i + 1;
    Node_setKeys($n, $i, 1000*$I);     Node_setKeys($o, $i, 2000+10*$I);
    Node_setData($n, $i, 1000*$I);     Node_setData($o, $i, 2000+10*$I);
    Node_setDown($n, $i, 1000*$i+50);  Node_setDown($o, $i, 2000+10*$i+5);
   }

  Node_setUp  ($o, $n);
  Node_setDown($n, $N, 7500); Node_setDown($n, 0, 6);
  Node_setDown($o, $N, 2075);

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->heap(0), bless([0, 2, 7, 0], "Tree");
  is_deeply $e->heap(1), bless([7, 1, 0, 0, 2, 3, 4], "Node");
  is_deeply $e->heap(2), bless([1000, 2000, 3000, 4000, 5000, 6000, 7000], "Keys");
  is_deeply $e->heap(3), bless([1000, 2000, 3000, 4000, 5000, 6000, 7000], "Data");
  is_deeply $e->heap(4), bless([6, 1050, 2050, 3050, 4050, 5050, 6050, 7500], "Down");
  is_deeply $e->heap(5), bless([7, 2, 1, 0, 6, 7, 8], "Node");
  is_deeply $e->heap(6), bless([2010, 2020, 2030, 2040, 2050, 2060, 2070], "Keys");
  is_deeply $e->heap(7), bless([2010, 2020, 2030, 2040, 2050, 2060, 2070], "Data");
  is_deeply $e->heap(8), bless([2005, 2015, 2025, 2035, 2045, 2055, 2065, 2075], "Down");
  #$e->compileToVerilog("BTree/basic/6");
 }

#latest:;
if (1)                                                                          ##Node_copy
 {Start 1;
  my $t = New(7);                                                               # Create tree
  my $p = Node_new($t); Node_allocDown($p);                                     # Create a node
  my $q = Node_new($t); Node_allocDown($q);                                     # Create a node

  for my $i(0..6)
   {Node_setKeys($p, $i, 11+$i);
    Node_setData($p, $i, 21+$i);
    Node_setDown($p, $i, 31+$i);
    Node_setKeys($q, $i, 41+$i);
    Node_setData($q, $i, 51+$i);
    Node_setDown($q, $i, 61+$i);
   }

  Node_setDown($p, 7, 97);
  Node_setDown($q, 7, 99);

  Node_copy($q, $p, 3, 2);

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->heap(0), bless([0, 2, 7, 0], "Tree");
  is_deeply $e->heap(1), bless([0, 1, 0, 0, 2, 3, 4], "Node");
  is_deeply $e->heap(2), bless([11 .. 17], "Keys");
  is_deeply $e->heap(3), bless([21 .. 27], "Data");
  is_deeply $e->heap(4), bless([31 .. 37, 97], "Down");
  is_deeply $e->heap(5), bless([0, 2, 0, 0, 6, 7, 8], "Node");
  is_deeply $e->heap(6), bless([14, 15, 43 .. 47], "Keys");
  is_deeply $e->heap(7), bless([24, 25, 53 .. 57], "Data");
  is_deeply $e->heap(8), bless([34, 35, 36, 64 .. 67, 99], "Down");
  #$e->compileToVerilog("BTree/basic/7");
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);                                                               # Create tree
  my $f = Find($t, 1);
  my $c = FindResult_cmp($f);
  AssertEq($c, FindResult_notFound);
  my $e = Execute(suppressOutput=>1);
  is_deeply $e->out, "";
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, 1, 11);
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->heap(0), bless([1, 1, 3, 2], "Tree");
  is_deeply $e->heap(2), bless([1, 1, 0, 0, 3, 4, 0], "Node");
  is_deeply $e->heap(3), bless([1], "Keys");
  is_deeply $e->heap(4), bless([11], "Data");
  #$e->compileToVerilog("BTree/insert/01");
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, 1, 11);
  Insert($t, 2, 22);
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->heap(0), bless([2, 1, 3, 2], "Tree");
  is_deeply $e->heap(2), bless([2, 1, 0, 0, 3, 4, 0], "Node");
  is_deeply $e->heap(3), bless([1, 2], "Keys");
  is_deeply $e->heap(4), bless([11, 22], "Data");
  #$e->compileToVerilog("BTree/insert/02");
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..3;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->heap(0), bless([3, 1, 3, 2], "Tree");
  is_deeply $e->heap(2), bless([3, 1, 0, 0, 3, 4, 0], "Node");
  is_deeply $e->heap(3), bless([1, 2, 3], "Keys");
  is_deeply $e->heap(4), bless([11, 22, 33], "Data");
  #$e->compileToVerilog("BTree/insert/03");
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..4;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->heap(0 ), bless([4, 3, 3, 2], "Tree");
  is_deeply $e->heap(2 ), bless([1, 1, 0, 0, 3, 4, 11], "Node");
  is_deeply $e->heap(3 ), bless([2], "Keys");
  is_deeply $e->heap(4 ), bless([22], "Data");
  is_deeply $e->heap(5 ), bless([1, 2, 2, 0, 6, 7, 0], "Node");
  is_deeply $e->heap(6 ), bless([1], "Keys");
  is_deeply $e->heap(7 ), bless([11], "Data");
  is_deeply $e->heap(8 ), bless([2, 3, 2, 0, 9, 10, 0], "Node");
  is_deeply $e->heap(9 ), bless([3, 4], "Keys");
  is_deeply $e->heap(10), bless([33, 44], "Data");
  is_deeply $e->heap(11), bless([5, 8], "Down");
  #$e->compileToVerilog("BTree/insert/04");
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..5;

  my $e = Execute(suppressOutput=>1);

  is_deeply $e->heap(0 ), bless([5, 4, 3, 2], "Tree");
  is_deeply $e->heap(2 ), bless([2, 1, 0, 0, 3, 4, 11], "Node");
  is_deeply $e->heap(3 ), bless([2, 4], "Keys");
  is_deeply $e->heap(4 ), bless([22, 44], "Data");
  is_deeply $e->heap(5 ), bless([1, 2, 2, 0, 6, 7, 0], "Node");
  is_deeply $e->heap(6 ), bless([1], "Keys");
  is_deeply $e->heap(7 ), bless([11], "Data");
  is_deeply $e->heap(8 ), bless([1, 3, 2, 0, 9, 10, 0], "Node");
  is_deeply $e->heap(9 ), bless([3], "Keys");
  is_deeply $e->heap(10), bless([33], "Data");
  is_deeply $e->heap(11), bless([5, 8, 12], "Down");
  is_deeply $e->heap(12), bless([1, 4, 2, 0, 13, 14, 0], "Node");
  is_deeply $e->heap(13), bless([5], "Keys");
  is_deeply $e->heap(14), bless([55], "Data");
  #$e->compileToVerilog("BTree/insert/05");
 }

#latest:;
if (1)                                                                          ##Insert
 {Start 1;
  my $t = New(3);
  Insert($t, $_, "$_$_") for 1..6;
  my $e = Execute(suppressOutput=>1);

  is_deeply $e->heap(0 ), bless([6, 4, 3, 2], "Tree");
  is_deeply $e->heap(2 ), bless([2, 1, 0, 0, 3, 4, 11], "Node");
  is_deeply $e->heap(3 ), bless([2, 4], "Keys");
  is_deeply $e->heap(4 ), bless([22, 44], "Data");
  is_deeply $e->heap(5 ), bless([1, 2, 2, 0, 6, 7, 0], "Node");
  is_deeply $e->heap(6 ), bless([1], "Keys");
  is_deeply $e->heap(7 ), bless([11], "Data");
  is_deeply $e->heap(8 ), bless([1, 3, 2, 0, 9, 10, 0], "Node");
  is_deeply $e->heap(9 ), bless([3], "Keys");
  is_deeply $e->heap(10), bless([33], "Data");
  is_deeply $e->heap(11), bless([5, 8, 12], "Down");
  is_deeply $e->heap(12), bless([2, 4, 2, 0, 13, 14, 0], "Node");
  is_deeply $e->heap(13), bless([5, 6], "Keys");
  is_deeply $e->heap(14), bless([55, 66], "Data");
  #$e->compileToVerilog("BTree/insert/06");
 }

#latest:;
if (1)                                                                          ##Insert
 {my $N = 6;
  Start 1;
  my $t = New(3);
  For
   {my ($i, $Check, $Next, $End) = @_;
    Insert($t, $i, $i);
   } $N, reverse=>1;

  Iterate
   {my ($find) = @_;
    Out FindResult_key($find);
   } $t;

  my $e = Execute(suppressOutput=>1, stringMemory=>1);
  #$e->generateVerilogMachineCode("BTree/insert/06R");                          # Requires signed arithmetic which we are proposing to avoid on the fpga
  is_deeply $e->outLines, [0..5];

  is_deeply $e->count,  609 unless $e->assembly->lowLevelOps or  1;
  is_deeply $e->count, 1898 if     $e->assembly->lowLevelOps and 0;

  is_deeply $e->heap(0 ), bless([6, 4, 3, 2], "Tree");
  is_deeply $e->heap(2 ), bless([2, 1, 0, 0, 3, 4, 11], "Node");
  is_deeply $e->heap(3 ), bless([2, 4], "Keys");
  is_deeply $e->heap(4 ), bless([2, 4], "Data");
  is_deeply $e->heap(5 ), bless([2, 2, 2, 0, 6, 7, 0], "Node");
  is_deeply $e->heap(6 ), bless([0, 1], "Keys");
  is_deeply $e->heap(7 ), bless([0, 1], "Data");
  is_deeply $e->heap(8 ), bless([1, 3, 2, 0, 9, 10, 0], "Node");
  is_deeply $e->heap(9 ), bless([5], "Keys");
  is_deeply $e->heap(10), bless([5], "Data");
  is_deeply $e->heap(11), bless([5, 12, 8], "Down");
  is_deeply $e->heap(12), bless([1, 4, 2, 0, 13, 14, 0], "Node");
  is_deeply $e->heap(13), bless([3], "Keys");
  is_deeply $e->heap(14), bless([3], "Data");
 }

#latest:;
#if (1)
# {my $w = 3;
#  my @a = (1,8,5,6,3,4,7,2,9,0);
#  Start 1;
#  my $a = Array "aaa";
#  for my $i(keys @a)
#   {Mov [$a, $i, "aaa"], $a[$i];
#   }
#
#  my $t = New($w);
#  ForArray
#   {my ($i, $e, $Check, $Next, $End) = @_;
#    Insert($t, $e, $i);
#   } $a, "aaa";
#
#  Iterate
#   {my ($find) = @_;
#    Out FindResult_key($find);
#   } $t;
#
#  my $e = Execute(suppressOutput=>1);
#  is_deeply $e->outLines, [0..9];
#  is_deeply $e->count, 1334;
#  say STDERR generateVerilogMachineCode("BTree"); exit;
# }

#latest:;
if (1)
 {my $W = 3;
  Start 1;
  my $t = New($W);

  ForIn                                                                         # Create tree
   {my ($i, $k) = @_;
    my $d = Add $k, $k;

    Insert($t, $k, $d);
   };

  Iterate
   {my ($find) = @_;
    my $k = FindResult_key($find);
    Out $k;
   } $t;

  my $e = Execute(suppressOutput=>1, in=>[1,8,5,6,3,4,7,2,9,0]);
  is_deeply $e->outLines, [0..9];
  $e->compileToVerilog("BTree/in/1");
#exit;
 }

#latest:;
if (1)                                                                          ##New ##Insert ##Find ##FindResult_cmp
 {my $W = 3; my $N = 66;

  Start 1;
  my $t = New($W);

  For
   {my ($i, $check, $next, $end) = @_;                                          # Insert
    my $d = Add $i, $i;

    Insert($t, $i, $d);
   } $N;

  For                                                                           # Find each prior element
   {my ($j, $check, $next, $end) = @_;
    Out FindResult_data(Find($t, $j));
   } $N;

  Out FindResult_cmp(Find($t, $N));

  my $e = Execute(suppressOutput=>1);
  is_deeply $e->outLines,
[0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38,
  40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 60, 62, 64, 66, 68, 70, 72, 74, 76,
  78, 80, 82, 84, 86, 88, 90, 92, 94, 96, 98, 100, 102, 104, 106, 108, 110,
  112, 114, 116, 118, 120, 122, 124, 126, 128, 130, 2,
];

  $e->compileToVerilog("BTree/insert/66");
 }

#latest:;
if (1)                                                                          ##Iterate ##Keys ##FindResult_key ##FindResult_data ##Find ##printTreeKeys ##printTreeData
 {my $W = 3; my @r = randomArray 41; #107;

  Start 1;
  my $t = New($W);                                                              # Create tree at expected location in memory

  my $f = FindResult_new;                                                       # Preallocate find result

  ForIn                                                                         # Create tree
   {my ($i, $k) = @_;
    my $K = Add $k, $k;
    Insert($t, $k, $K);
   };

  Iterate                                                                       # Iterate tree
   {my ($find) = @_;                                                            # Find result
    my $k = FindResult_key($find);
    Out $k;
   } $t;

  my $e = Execute(suppressOutput=>1, stringMemory=>1, in=>[@r]);
  is_deeply $e->outLines, [1..@r];                                              # Expected sequence
  #say STDERR printTreeKeys($e);
  $e->compileToVerilog("BTree/in/2");
 }

#latest:;
# Same as the above but with more details
if (1)                                                                          ##Iterate ##Keys ##FindResult_key ##FindResult_data ##Find ##printTreeKeys ##printTreeData
 {my $W = 3; my @r = randomArray 107;

  Start 1;
  my $t = New($W);                                                              # Create tree at expected location in memory

  my $f = FindResult_new;                                                       # Preallocate find result

  ForIn                                                                         # Create tree
   {my ($i, $k) = @_;
    my $n = Keys($t);

    my $K = Add $k, $k;
    Tally 1;
    Insert($t, $k, $K,                                                          # Insert a new node
      findResult=>          $f,
      maximumNumberOfKeys=> $W,
      splitPoint=>          int($W/2),
      rightStart=>          int($W/2)+1,
    );
    Tally 0;
   };

  Iterate                                                                       # Iterate tree
   {my ($find) = @_;                                                            # Find result
    my $k = FindResult_key($find);
    Out $k;
    Tally 2;
    my $f = Find($t, $k, findResult=>$f);                                       # Find
    Tally 0;
    my $d = FindResult_data($f);
    my $K = Add $k, $k;
    AssertEq $K, $d;                                                            # Check result
   } $t;

  Tally 3;
  Iterate {} $t;                                                                # Iterate tree without doing anything in the body to see the pure iteration overhead
  Tally 0;

  my $e = Execute(suppressOutput=>1, in=>[@r]);
  is_deeply $e->outLines,            [1..@r];                                   # Expected sequence
  is_deeply $e->widestAreaInArena,   [undef, 7, 540]   unless $e->assembly->lowLevelOps;
  is_deeply $e->widestAreaInArena,   [undef, 7, 1251]  if     $e->assembly->lowLevelOps;
# is_deeply $e->namesOfWidestArrays, [undef, "Node", "stackArea"];              # Only available in original memory scheme
  is_deeply $e->mostArrays,          [undef, 251, 1, 1, 1];

  #say STDERR dump $e->tallyCount;
  is_deeply $e->tallyCount,  24407 unless $e->assembly->lowLevelOps;            # Insertion instruction counts
  is_deeply $e->tallyCount,  71725 if     $e->assembly->lowLevelOps and 0;

  #say STDERR dump $e->tallyTotal;
  if (0)
   {if ($e->assembly->lowLevelOps)
     {is_deeply $e->tallyTotal->{1}, 46073;
      is_deeply $e->tallyTotal->{2}, 18394;
      is_deeply $e->tallyTotal->{3},  7258;
     }
    else
     {is_deeply $e->tallyTotal->{1}, 15466;
      is_deeply $e->tallyTotal->{2},  6294;
      is_deeply $e->tallyTotal->{3},  2647;
     }
   }
#  is_deeply $e->tallyTotal, { 1 => 15456, 2 => 6294, 3 => 2752};
  #say STDERR formatTable($e->tallyCounts->{1}); exit;

  is_deeply formatTable($e->tallyCounts->{1}), <<END  unless $e->assembly->lowLevelOps or 1;  # Insert tally
add                 885
array               247
arrayCountGreater     2
arrayCountLess      262
arrayIndex          293
jEq                 894
jGe                 648
jLe                 461
jLt                 565
jNe                 908
jmp                 878
mov                7623
moveLong            171
not                 631
resize              167
shiftUp             300
subtract            531
END
  is_deeply formatTable($e->tallyCounts->{1}), <<END  if     $e->assembly->lowLevelOps and 0;  # Insert tally
add                  885
array                247
arrayCountGreater      2
arrayCountLess       262
arrayIndex           293
jEq                  894
jGe                  648
jLe                  461
jLt                  565
jNe                  908
jmp                  878
mov                 7623
movHeapOut           804
movRead1            6448
movRead2            6448
movWrite1           1518
moveLong1            171
moveLong2            171
not                  631
resetHeapClock     15218
resize               167
shiftUp              300
subtract             531
END

  #say STDERR formatTable $e->tallyCounts->{2}; exit;
  is_deeply formatTable($e->tallyCounts->{2}), <<END unless $e->assembly->lowLevelOps;                           # Find tally
add              497
arrayCountLess   223
arrayIndex       330
jEq              690
jGe              467
jLe              467
jNe              107
jmp              604
mov             1975
not              360
subtract         574
END

  is_deeply formatTable($e->tallyCounts->{2}), <<END if     $e->assembly->lowLevelOps and 0;                           # Find tally
add              497
arrayCountLess   223
arrayIndex       330
jEq              690
jGe              467
jLe              467
jNe              107
jmp              604
mov             1975
movHeapOut       553
movRead1        2588
movRead2        2588
movWrite1        321
not              360
resetHeapClock  6050
subtract         574
END

  #say STDERR formatTable($e->tallyCounts->{3}); exit;
  is_deeply formatTable($e->tallyCounts->{3}), <<END unless $e->assembly->lowLevelOps;                           # Iterate tally
add          162
array          2
arrayIndex    72
free           2
jEq          260
jFalse        28
jGe          208
jNe          117
jTrue         73
jmp          252
mov         1111
moveLong     107
not          180
shiftLeft      1
subtract      72
END

  is_deeply formatTable($e->tallyCounts->{3}), <<END if     $e->assembly->lowLevelOps and 0;                           # Iterate tally
add              162
array              2
arrayIndex        72
free               2
jEq              260
jFalse            28
jGe              208
jNe              117
jTrue             73
jmp              252
mov             1111
movHeapOut        74
movRead1         927
movRead2         927
movWrite1        324
moveLong1        107
moveLong2        107
not              180
resetHeapClock  2252
shiftLeft          1
subtract          72
END

  #say STDERR printTreeKeys($e); x;
  is_deeply printTreeKeys($e), <<END;
                                                                                                                38                                                                                                    72
                                                             21                                                                                                       56                                                                                                 89
                            10             15                                     28             33                                  45                   52                                     65                                     78             83                               94          98            103
        3        6     8             13          17    19          23       26             31             36          40    42             47    49             54          58    60    62             67    69                75                81             86             91             96            101         105
  1  2     4  5     7     9    11 12    14    16    18    20    22    24 25    27    29 30    32    34 35    37    39    41    43 44    46    48    50 51    53    55    57    59    61    63 64    66    68    70 71    73 74    76 77    79 80    82    84 85    87 88    90    92 93    95    97    99100   102   104   106107
END

  #say STDERR printTreeData($e); x;
  is_deeply printTreeData($e), <<END;
                                                                                                                76                                                                                                   144
                                                             42                                                                                                      112                                                                                                178
                            20             30                                     56             66                                  90                  104                                    130                                    156            166                              188         196            206
        6       12    16             26          34    38          46       52             62             72          80    84             94    98            108         116   120   124            134   138               150               162            172            182            192            202         210
  2  4     8 10    14    18    22 24    28    32    36    40    44    48 50    54    58 60    64    68 70    74    78    82    86 88    92    96   100102   106   110   114   118   122   126128   132   136   140142   146148   152154   158160   164   168170   174176   180   184186   190   194   198200   204   208   212214
END
  $e->compileToVerilog("BTree/in/3");
 }


#latest:;
if (1)                                                                          # Generate machine code and use string memory to emulate execution on an FPGA
 {my $W = 3; my @r = randomArray 107;

  Start 1;
  my $t = New($W);                                                              # Create tree at expected location in memory

  my $f = FindResult_new;                                                       # Preallocate find result

  ForIn                                                                         # Create tree
   {my ($i, $k) = @_;
    my $n = Keys($t);

    my $K = Add $k, $k;
    Tally 1;
    Insert($t, $k, $K,                                                          # Insert a new node
      findResult=>          $f,
      maximumNumberOfKeys=> $W,
      splitPoint=>          int($W/2),
      rightStart=>          int($W/2)+1,
    );
    Tally 0;
   };

  Iterate                                                                       # Iterate tree
   {my ($find) = @_;                                                            # Find result
    my $k = FindResult_key($find);
    Out $k;
    Tally 2;
    my $f = Find($t, $k, findResult=>$f);                                       # Find
    Tally 0;
    my $d = FindResult_data($f);
    my $K = Add $k, $k;
    AssertEq $K, $d;                                                            # Check result
   } $t;

  Tally 3;
  Iterate {} $t;                                                                # Iterate tree without doing anything in the body to see the pure iteration overhead
  Tally 0;

  my $e = Execute(suppressOutput=>1, in=>[@r],
    stringMemory=>1, maximumArraySize=>7);
  is_deeply $e->outLines,            [1..@r];                                   # Expected sequence
  is_deeply $e->mostArrays,          [undef, 251, 1, 1, 1];

  if ($e->assembly->lowLevelOps)
   {is_deeply $e->widestAreaInArena,   [undef, 7, 1251];
#   is_deeply $e->namesOfWidestArrays, [undef, "Node", "stackArea"];              # Only available in original memory scheme

    #say STDERR dump $e->tallyCount;
    is_deeply $e->tallyCount,  71725 if 0;                                             # Insertion instruction counts

    #say STDERR dump $e->tallyTotal;
    is_deeply $e->tallyTotal->{1}, 46073 if 0;
    is_deeply $e->tallyTotal->{2}, 18394 if 0;
    is_deeply $e->tallyTotal->{3},  7258 if 0;

    #is_deeply $e->timeParallel,   24260;
    is_deeply $e->timeSequential,  84463 if 0;

    #say STDERR formatTable($e->counts); exit;
    is_deeply formatTable($e->counts), <<END if 0;                              # All instruction codes used in NWay Tree
add                 1920
array                253
arrayCountGreater      2
arrayCountLess       485
arrayIndex           767
free                   4
in                   107
inSize               108
jEq                 2104
jFalse               164
jGe                 1531
jLe                  928
jLt                  565
jNe                 1249
jTrue                146
jmp                 2093
mov                12787
movHeapOut          1507
movRead1           11853
movRead2           11853
movWrite1           2491
moveLong1            385
moveLong2            385
not                 1351
resetHeapClock     27706
resize               167
shiftLeft              2
shiftUp              300
start                  1
start2                 1
subtract            1249
END
   }
  else
   {is_deeply $e->widestAreaInArena,   [undef, 7, 540];
#   is_deeply $e->namesOfWidestArrays, [undef, "Node", "stackArea"];              # Only available in original memory scheme

    #say STDERR dump $e->tallyCount;
    is_deeply $e->tallyCount,  24407;                                             # Insertion instruction counts

    #say STDERR dump $e->tallyTotal;
    is_deeply $e->tallyTotal->{1}, 15466;
    is_deeply $e->tallyTotal->{2},  6294;
    is_deeply $e->tallyTotal->{3},  2647;

    #is_deeply $e->timeParallel,   24260;
    is_deeply $e->timeSequential, 28667;

    #say STDERR formatTable($e->counts);
    is_deeply formatTable($e->counts), <<END ;                                     # All instruction codes used in NWay Tree
add                 1920
array                253
arrayCountGreater      2
arrayCountLess       485
arrayIndex           767
free                   4
in                   107
inSize               108
jEq                 2104
jFalse               164
jGe                 1531
jLe                  928
jLt                  565
jNe                 1249
jTrue                146
jmp                 2093
mov                12787
moveLong             385
not                 1351
resize               167
shiftLeft              2
shiftUp              300
subtract            1249
END
   }
 }

sub commandStart()                                                              # Start a tree
 {0}
sub commandInsert()                                                             # Insert into a tree.  Must be followed by the key and the associated data
 {1}
sub commandFind()                                                               # Find in a tree. Must be followed by the key to find
 {2}
sub commandTest()                                                               # Run test programs
 {3}

#latest:;
if (1)                                                                          # Actions on a tree driven by the input channel ##commandStart ##commandInsert ##commandFind ##commandTest
 {Start 1;
  my $W = 3;                                                                    # Width of each node
  my $F = FindResult_new;                                                       # Find area
  my $T;                                                                        # The tree

  ForIn                                                                         # Read commands from input channel
   {my ($i, $v, $Check, $Next, $End) = @_;
    IfEq $v, commandStart(),                                                    # Start a new tree
    Then
     {$T = New $W;
      Jmp $Next;
     };
    IfEq $v, commandInsert(),                                                   # Insert a key
    Then
     {my $k = In; my $d = In;
      Insert $T, $k, $d;
      Jmp $Next;
     };
    IfEq $v, commandFind(),                                                     # Find a key. Indicate whether it was found and its value on the output channel
    Then
     {my $k = In;
      Find $T, $k, findResult=>$F;
      IfEq FindResult_cmp($F), FindResult_found,
      Then
       {Out 1;
        Out FindResult_data $F;
       },
      Else
       {Out 0;
       };
      Jmp $Next;
     };
    Jmp $End;                                                                   # Invalid command terminates the command sequence
   };
  my $e = Execute(suppressOutput=>1, in => [0, 1, 3, 33, 1, 1, 11, 1, 2, 22, 1, 4, 44, 2, 5, 2, 2, 2, 6, 2, 3]);
  is_deeply $e->outLines, [0, 1, 22, 0, 1, 33];
  $e->compileToVerilog("BTree/in/4");
 }

# (\A.{80})\s+(#.*\Z) \1\2
