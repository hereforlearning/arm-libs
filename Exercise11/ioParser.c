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
		if (input[i] == 0) {
			PutStringSB("Found null pointer\r\n", MAX_STRING);
		}
		switch(input[i]) {
		  case '0': 
				PutStringSB("Found a zero\r\n", MAX_STRING); break;
			default:
				PutStringSB("Character not recognized\r\n", MAX_STRING);
		}
	}
	
	/* Default placeholder for now*/
	return 1;
} 

/*********************************************************************/
/* Prints hex representation of an unsigned multi-word number of     */
/* NumWords words.                                                   */
/* Calls:  PutStringSB                                               */
/*********************************************************************/
void PutHexIntMulti (UInt32 *Number, int NumWords) {

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
