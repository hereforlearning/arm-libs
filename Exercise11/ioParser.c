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
	unsigned int count = 1;
	
  for(i = 0; i < MAX_STRING; i++) {
	  if (String[i] == 0) {
		  /*Found a null, we're done here.*/
			return count - 1;
		}
		count++;
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
	
	/*Define memory location and take in user input string*/
	char input[MAX_STRING];
	GetStringSB(input, MAX_STRING);

	for (i = 0; i < len(input); i++) {
		int binaryRep;
		switch(input[i]) {
		  case '0': 
				binaryRep = 0000; break;
			case '1': 
				binaryRep = 0001; break;
			case '2': 
				binaryRep = 0010; break;
			case '3': 
				binaryRep = 0011; break;
			case '4': 
				binaryRep = 0100; break;
			case '5': 
				binaryRep = 0101; break;
			case '6': 
				binaryRep = 0110; break;
			case '7': 
				binaryRep = 0111; break;
			case '8': 
				binaryRep = 1000; break;
			case '9': 
				binaryRep = 1001; break;
			case 'A': 
				binaryRep = 1010; break;
			case 'B': 
				binaryRep = 1011; break;
			case 'C': 
				binaryRep = 1100; break;
			case 'D': 
				binaryRep = 1101; break;
			case 'E': 
				binaryRep = 1110; break;
			case 'F': 
				binaryRep = 1111; break;
			case 'a': 
				binaryRep = 1010; break;
			case 'b': 
				binaryRep = 1011; break;
			case 'c': 
				binaryRep = 1100; break;
			case 'd': 
				binaryRep = 1101; break;
			case 'e': 
				binaryRep = 1110; break;
			case 'f': 
				binaryRep = 1111; break;
			default:
				PutStringSB("Character not recognized\r\n", MAX_STRING);
			  return 1;
		}
		
		/* Write the converted value to memory.*/
	}
	
	/* String was successfully processed. Return appropriate value*/
	PutStringSB("String entered successfully!", MAX_STRING);
	return 0;
} 

/*********************************************************************/
/* Prints hex representation of an unsigned multi-word number of     */
/* NumWords words.                                                   */
/* Calls:  PutStringSB                                               */
/*********************************************************************/
void PutHexIntMulti (UInt32 *Number, int NumWords) {
	int numChars = NumWords * 16;
	char* resultString;
	
  int i, j;
	
	for (j = 0; j < NumWords; j++) {
		for (i = 0; i < 16; i++) {
      /*Read each byte of each word provided */
			int byteValue = ((UInt8 *) Number) [i];
			
			/*Split byte values to sets of half bytes for each char */
			int leastSigByteMsk = 00001111;
			int leastSigByte = byteValue & leastSigByteMsk; 
			
			/*Split byte values to sets of half bytes for each char */
			int mostSigByteMsk = 11110000;
			int mostSigByte = byteValue & mostSigByteMsk;
			
			char leastSigChar;
			char mostSigChar;
			
			/*Going to get ugly here...
			Check against byte masks for appropriate
			Characters at each byte*/
			switch(leastSigByte) {
		    case 00000000: 
				  leastSigChar = '0'; break;
				case 00000001:
					leastSigChar = '1'; break;
				case 00000010:
					leastSigChar = '2'; break;
				case 00000011:
					leastSigChar = '3'; break;
				case 00000100:
					leastSigChar = '4'; break;
				case 00000101:
					leastSigChar = '5'; break;
				case 00000110:
					leastSigChar = '6'; break;
				case 00000111:
					leastSigChar = '7'; break;
				case 00001000:
					leastSigChar = '8'; break;
				case 00001001:
					leastSigChar = '9'; break;
				case 00001010:
					leastSigChar = 'A'; break;
				case 00001011:
					leastSigChar = 'B'; break;
				case 00001100:
					leastSigChar = 'C'; break;
				case 00001101:
					leastSigChar = 'D'; break;
				case 00001110:
					leastSigChar = 'E'; break;
				case 00001111:
					leastSigChar = 'F'; break;
			  default:
				  PutStringSB("Character from memory not recognized\r\n", MAX_STRING);
	  	}
			
			/*TODO: Switch to lookup table to avoid repetition*/
			switch(mostSigByte) {
		    case 00000000: 
				  mostSigChar = '0'; break;
				case 00010000:
					mostSigChar = '1'; break;
				case 00100000:
					mostSigChar = '2'; break;
				case 00110000:
					mostSigChar = '3'; break;
				case 01000000:
					mostSigChar = '4'; break;
				case 01010000:
					mostSigChar = '5'; break;
				case 01100000:
					mostSigChar = '6'; break;
				case 01110000:
					mostSigChar = '7'; break;
				case 10000000:
					mostSigChar = '8'; break;
				case 10010000:
					mostSigChar = '9'; break;
				case 10100000:
					mostSigChar = 'A'; break;
				case 10110000:
					mostSigChar = 'B'; break;
				case 11000000:
					mostSigChar = 'C'; break;
				case 11010000:
					mostSigChar = 'D'; break;
				case 11100000:
					mostSigChar = 'E'; break;
				case 11110000:
					mostSigChar = 'F'; break;
			  default:
				  PutStringSB("Character from memory not recognized\r\n", MAX_STRING);
	  	}
			
			/* Rebuild the result string */
			resultString[sizeof(resultString) - i + 1] = mostSigChar;
			resultString[sizeof(resultString) - i] = leastSigChar;
		}
  }
	
	/*Print result string to the console. */
	PutStringSB(resultString, MAX_STRING);
}

int main (void) {
  UInt32* number;

  __asm("CPSID   I");  /* mask interrupts */
  Startup ();
  Init_UART0_IRQ ();
	
	PutStringSB("Enter first 128 bit hex number: ", MAX_STRING);
	
	GetHexIntMulti(number, 2);
	
  return (0);
} 
