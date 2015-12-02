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
#include "Exercise13_H.h"  

#define FALSE      (0)
#define TRUE       (1)
#define MAX_HEX_STRING ((sizeof(UInt128) << 1) + 1)
#define MAX_STRING (79)
#define NUMBER_BITS (128)
#define NUMBER_WORDS (4)
#define NUM_CHARS ((NUMBER_WORDS * 8) + 1)

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

int convToAscii(int numericRep) {
  if(numericRep >= 0 && numericRep <= 9) {
    return numericRep + '0'; 
  }
  else {
    return numericRep + 55;
  }
}

/*
* Fetch the status of the current PIT timer count
* value to seed a pseudo random number. The number
* is then divided by 4 to generate a remainder of 0
* or 3, inclusive. 
*
* @return int - random number between 0 and 3 based on timer state
*/
int getRandom(){
  UInt32 *count;
  GetCount(count); //Update count variable
  return *count % 4;
}

int main (void) {
  char selection = 0;
	int keyPressInd;

  __asm("CPSID I");  /* mask interrupts */

  Init_UART0_IRQ ();
  Init_PIT_IRQ ();

  while(1) {
		//get a new random number
    //selection = getRandom(); 
		
		//Check if key is pressed without collecting character
		keyPressInd = IsKeyPressed();
  }
} 
