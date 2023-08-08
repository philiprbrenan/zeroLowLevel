//-----------------------------------------------------------------------------
// Find the data associated with a key in a next using just boolean operations
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2023
//------------------------------------------------------------------------------
module Index                                                                    // Find index of a key on a next
 #(parameter pAddressActual,                                                    // The block address we want for this next
   parameter pKey1,                                                             // Key 1 in this block
   parameter pKey2,                                                             // Key 2 in this block
   parameter pKey3,                                                             // Key 3 in this block
   parameter pData1,                                                            // Data 1 in this block
   parameter pData2,                                                            // Data 2 in this block
   parameter pData3,                                                            // Data 3 in this block
   parameter pNext0,                                                            // Next 0 in this block
   parameter pNext1,                                                            // Next 1 in this block
   parameter pNext2,                                                            // Next 2 in this block
   parameter pNext3)                                                            // Next 3 in this block
 (input  wire[  7:0] key,                                                       // Key to look for
  input  wire [ 7:0] address,                                                   // Address of block to search
  output reg         found,                                                     // Key has been found, data output is valid
  output reg[   7:0] data,                                                      // Data - valid if found is high
  output reg[   7:0] next);                                                     // Address of next next to search - valid if next is high

  reg[7:0]addressActual; assign addressActual = pAddressActual;

  reg[7:0]key1;  assign key1  = pKey1;
  reg[7:0]key2;  assign key2  = pKey2;
  reg[7:0]key3;  assign key3  = pKey3;

  reg[7:0]data1; assign data1 = pData1;
  reg[7:0]data2; assign data2 = pData2;
  reg[7:0]data3; assign data3 = pData3;

  reg[7:0]next0; assign next0 = pNext0;
  reg[7:0]next1; assign next1 = pNext1;
  reg[7:0]next2; assign next2 = pNext2;
  reg[7:0]next3; assign next3 = pNext3;

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
  assign data  = data1 & {8{key1_equals}} | data2 & {8{key2_equals}} |data3 & {8{key3_equals}};

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

  reg[7:0] gt1_8; assign gt1_8 = {8{gt_key1}};
  reg[7:0] gt2_8; assign gt2_8 = {8{gt_key2}};
  reg[7:0] gt3_8; assign gt3_8 = {8{gt_key3}};

  assign next  = {8{address == addressActual}} &                                // Confirm that this is the block we want
                 {8{!found}}                   &                                // Zero the next block address if we have found the key to indicate that further processing is not required
                ((next0 & ~ gt1_8 &  ~gt2_8 &  ~gt3_8) |                        // Pick next next
                 (next1 &   gt1_8 &  ~gt2_8 &  ~gt3_8) |
                 (next2 &   gt1_8 &   gt2_8 &  ~gt3_8) |
                 (next3 &   gt1_8 &   gt2_8 &   gt3_8));
endmodule
