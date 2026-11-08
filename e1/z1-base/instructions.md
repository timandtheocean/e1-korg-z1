# base

This folder will contain lua and preset.json for the base and utility functions.

- handshake routine and Z1 ID
- patch request current edit buffer 
- lua code for patch parsing: 
  we start with 

|1~16|Program Name|   |20H~7FH  |16       |

This should create the patchname in the preset. 
We test if we start after the header then 16bytes should be the patchname. 
We make an object displaying the patchname and test it on the E1.

What are all utility midi functions we have not covered? 



