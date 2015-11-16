/*********************************************************************/
/* Lab Exercise Eleven                                               */
/* Module to take input values from the user over the UART0 serial   */
/* connection, perform a multi-word addition operation, and return   */
/* the result in hexidecimal format back to the user.                */
/* Name:  Justin Peterson                                            */
/* Date:  11/09/15                                                   */
/* Class:  CMPE 250                                                  */
/* Section:  03 (TR 2-4 PM)                                          */
/*********************************************************************/
#include "ioParser.h"  

#define FALSE      (0)
#define TRUE       (1)
#define MAX_HEX_STRING ((sizeof(UInt128) << 1) + 1)
#define MAX_STRING (79)
#define NUMBER_BITS (128)

/*
* Define function to determine the length of a 
* string in C. Avoids switching the registers 
* around to use lengthstringsb
*/
int len(char String[]) {
  unsigned int i;
  unsigned int count = 0;
	
  for(i = 0; i < MAX_STRING; i++) {
    if (String[i] == 0) {
	  return count;
    }
    else {
      count++;   
    }
  }
  return count;
}

/*********************************************************************/
/* Gets user string input of hex representation of an multiword      */
/* unsigned number of NumWords words, and converts it to a binary    */
/* unsigned NumWords-word number.                                    */
/* If user input is invalid, returns 1; otherwise returns 0.         */  
/* Calls:  GetStringSB                                               */
/*********************************************************************/
int GetHexIntMulti (UInt32 *Number, int NumWords) {
	
	unsigned int i;
	
	int lowerAsciiHexConvert = 87;
	int upperAsciiHexConvert = 55;
	int decimalAsciiConvert = '0';
    
    int byteToStore = 0;
    int binaryRep;
    
	/*Define memory location and take in user input string*/
    char input[MAX_STRING];
	GetStringSB(input, NumWords * 8);
	
	if(NumWords * 8 != len(input)) {
      /*Incorrect number of characters provided.*/
      return 1;
    }		

	for (i = 0; i < len(input); i++) {
		
		/*Convert to upper case representation if lowercase hex*/
		if(input[i] >= 'a' && input[i] <= 'f') {
		  binaryRep = input[i] - lowerAsciiHexConvert;	
		}	
		
		else if(input[i] >= 'A' && input[i] <= 'F') {
		  binaryRep = input[i] - upperAsciiHexConvert;
		}
		
		else if(input[i] >= '0' && input[i] <= '9') {
			binaryRep = input[i] - decimalAsciiConvert;
		}	
		
		/*An unrecognized character was found. */
		else {
		  return 1;
		}
		
		/*First half byte is being processed,
		* Concatenate it to the next byte before storing. */
		if(i % 2 == 0) {
	      byteToStore = binaryRep << 4;
		}
		/* Combine two values into a byte to store. */
		else {
			byteToStore = byteToStore + binaryRep;
			
			/*Actually store the value to the number*/
			((UInt8 *) Number)[i / 2] = byteToStore; 
		}
	}
	
	/* String was successfully processed. Return appropriate value*/
	return 0;
} 

/*********************************************************************/
/* Prints hex representation of an unsigned multi-word number of     */
/* NumWords words.                                                   */
/* Calls:  PutStringSB                                               */
/*********************************************************************/
void PutHexIntMulti (UInt32 *Number, int NumWords) {
	int numBytes = NumWords * 8;
	unsigned int i;
	char* resultString;
	
	for(i = 0; i < numBytes; i++) {
		/*Read each byte of each word provided */
		int byteValue = ((UInt8 *) Number) [i];

		int leastSigByteMsk = 0x01;
		int leastSigChar = byteValue & leastSigByteMsk; 
		
		int mostSigByteMsk = 0x10;
		int mostSigChar = byteValue & mostSigByteMsk >> 4;
		
		/* Convert characters to their appropriate ASCII format */ 
		
		/* Rebuild the result string */
		resultString[sizeof(resultString) - i + 1] = mostSigChar;
		resultString[sizeof(resultString) - i] = leastSigChar;
	}
	
	/*Print result string to the console. */
	PutStringSB(resultString, MAX_STRING);
}

int main (void) {
  UInt128 number;
  int result = 1;

  __asm("CPSID   I");  /* mask interrupts */
  Startup ();
  Init_UART0_IRQ ();
	
	PutStringSB("Enter first 128 bit hex number: ", MAX_STRING);
    result = GetHexIntMulti(number.Word, 4);
    
    while(result != 0) {
      PutStringSB("Invalid number--try again: ", MAX_STRING);
      result = GetHexIntMulti(number.Word, 4);
    }
    
    PutStringSB("Enter 128-bit hex number to add: ", MAX_STRING);
	result = GetHexIntMulti(number.Word, 4);
    
    while(result != 0) {
      PutStringSB("Invalid number--try again: ", MAX_STRING);
      result = GetHexIntMulti(number.Word, 4);
    }
	
  return (0);
} 
