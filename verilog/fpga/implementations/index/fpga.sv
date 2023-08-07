//-----------------------------------------------------------------------------
// Find the data associated with a key in a node using just boolean operations
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module Index                                                                    // Find index of a key on a node
 #(parameter pAddressActual,                                                    // The block address we want for this node
   parameter pKey1,                                                             // Key 1 in this block
   parameter pKey2,                                                             // Key 2 in this block
   parameter pKey3,                                                             // Key 3 in this block
   parameter pData1,                                                            // Data 1 in this block
   parameter pData2,                                                            // Data 2 in this block
   parameter pData3,                                                            // Data 3 in this block
   parameter pNode0,                                                            // Node 0 in this block
   parameter pNode1,                                                            // Node 1 in this block
   parameter pNode2,                                                            // Node 2 in this block
   parameter pNode3)                                                            // Node 3 in this block
 (input  wire[  3:0] key,                                                       // Key to look for
  input  wire [15:0] address,                                                   // Address of block to search
  output reg         found,                                                     // Key has been found, data output is valid
  output reg[   3:0] data,                                                      // Data - valid if found is high
  output reg[   7:0] node);                                                     // Address of next node to search - valid if next is high

  reg[7:0]addressActual; assign addressActual = pAddressActual;

  reg[3:0]key1;  assign key1  = pKey1;
  reg[3:0]key2;  assign key2  = pKey2;
  reg[3:0]key3;  assign key3  = pKey3;

  reg[3:0]data1; assign data1 = pData1;
  reg[3:0]data2; assign data2 = pData2;
  reg[3:0]data3; assign data3 = pData3;

  reg[7:0]node0; assign node0 = pNode0;
  reg[7:0]node1; assign node1 = pNode1;
  reg[7:0]node2; assign node2 = pNode2;
  reg[7:0]node3; assign node3 = pNode3;

  assign key1_xor_key_0 = key[0] ^ key1[0];
  assign key1_xor_key_1 = key[1] ^ key1[1];
  assign key1_xor_key_2 = key[2] ^ key1[2];
  assign key1_xor_key_3 = key[3] ^ key1[3];
  assign key1_equals = ~(key1_xor_key_0 | key1_xor_key_1 | key1_xor_key_2 | key1_xor_key_3);

  assign key2_xor_key_0 = key[0] ^ key2[0];
  assign key2_xor_key_1 = key[1] ^ key2[1];
  assign key2_xor_key_2 = key[2] ^ key2[2];
  assign key2_xor_key_3 = key[3] ^ key2[3];
  assign key2_equals = ~(key2_xor_key_0 | key2_xor_key_1 | key2_xor_key_2 | key2_xor_key_3);

  assign key3_xor_key_0 = key[0] ^ key3[0];
  assign key3_xor_key_1 = key[1] ^ key3[1];
  assign key3_xor_key_2 = key[2] ^ key3[2];
  assign key3_xor_key_3 = key[3] ^ key3[3];
  assign key3_equals = ~(key3_xor_key_0 | key3_xor_key_1 | key3_xor_key_2 | key3_xor_key_3);

  assign found = key1_equals | key2_equals | key3_equals;                       // Whether the search key is equal to any existing key
  assign data  = data1 & {4{key1_equals}} | data2 & {4{key2_equals}} |data3 & {4{key3_equals}};

  assign gt_key1 =                                         (key[3] & !key1[3])  | // Greater than key1
  (!key1_xor_key_3 &                                       (key[2] & !key1[2])) |
  (!key1_xor_key_3 & !key1_xor_key_2  &                    (key[1] & !key1[1])) |
  (!key1_xor_key_3 & !key1_xor_key_2  & !key1_xor_key_1  & (key[0] & !key1[0]));

  assign gt_key2 =                                         (key[3] & !key2[3])  | // Greater than key2
  (!key2_xor_key_3 &                                       (key[2] & !key2[2])) |
  (!key2_xor_key_3 & !key2_xor_key_2  &                    (key[1] & !key2[1])) |
  (!key2_xor_key_3 & !key2_xor_key_2  & !key2_xor_key_1  & (key[0] & !key2[0]));

  assign gt_key3 =                                         (key[3] & !key3[3])  | // Greater than key3
  (!key3_xor_key_3 &                                       (key[2] & !key3[2])) |
  (!key3_xor_key_3 & !key3_xor_key_2  &                    (key[1] & !key3[1])) |
  (!key3_xor_key_3 & !key3_xor_key_2  & !key3_xor_key_1  & (key[0] & !key3[0]));

  reg[3:0] gt1_4; assign gt1_4 = {4{gt_key1}};
  reg[3:0] gt2_4; assign gt2_4 = {4{gt_key2}};
  reg[3:0] gt3_4; assign gt3_4 = {4{gt_key3}};

  assign node  = {8{address == addressActual}} &                                // Confirm that this is the block we want
                ((node0 & ~ gt1_4 &  ~gt2_4 &  ~gt3_4) |                        // Pick next node
                 (node1 &   gt1_4 &  ~gt2_4 &  ~gt3_4) |
                 (node2 &   gt1_4 &   gt2_4 &  ~gt3_4) |
                 (node3 &   gt1_4 &   gt2_4 &   gt3_4));
endmodule
