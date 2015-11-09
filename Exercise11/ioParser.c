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

/*********************************************************************/
/* Gets user string input of hex representation of an multiword      */
/* unsigned number of NumWords words, and converts it to a binary    */
/* unsigned NumWords-word number.                                    */
/* If user input is invalid, returns 1; otherwise returns 0.         */  
/* Calls:  GetStringSB                                               */
/*********************************************************************/
int GetHexIntMulti (UInt32 *Number, int NumWords) {
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
  /* >>>>> Variable declarations here <<<<< */    

  __asm("CPSID   I");  /* mask interrupts */
  Startup ();
  Init_UART0_IRQ ();
	
	PutStringSB("Hello World\r\n", MAX_STRING);
	PutStringSB("Hello World\r\n", MAX_STRING);
	PutStringSB("Hello World\r\n", MAX_STRING);
	
  return (0);
} 
