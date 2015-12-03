/*********************************************************************/
/* <Your program description here>                                   */
/* Name:  <Your name here>                                           */
/* Date:  <Date completed>                                           */
/* Class:  CMPE 250                                                  */
/* Section:  <Your section here>                                     */
/*-------------------------------------------------------------------*/
/* Template:  R. W. Melton                                           */
/*            November 16, 2015                                      */
/*********************************************************************/
#include "MKL46Z4.h"
#include "Exercise13_C.h"

#define FALSE      (0)
#define TRUE       (1)

#define MAX_STRING (79)

/* ADC0 */
#define ADC_MAX (0x3FFu)
/* ------------------------------------------------------------------*/
/* ADC0_CFG1:  ADC0 configuration register 1                         */
/*  0-->31-8:(reserved):read-only:0                                  */
/*  1-->   7:ADLPC=ADC low-power configuration                       */
/* 10--> 6-5:ADIV=ADC clock divide select                            */
/*           Internal ADC clock = input clock / 2^ADIV               */
/*  1-->   4:ADLSMP=ADC long sample time configuration               */
/* 10--> 3-2:MODE=conversion mode selection                          */
/*           00=(DIFF'):single-ended 8-bit conversion                */
/*              (DIFF):differential 9-bit 2's complement conversion  */
/*           01=(DIFF'):single-ended 12-bit conversion               */
/*              (DIFF):differential 13-bit 2's complement conversion */
/*           10=(DIFF'):single-ended 10-bit conversion               */
/*              (DIFF):differential 11-bit 2's complement conversion */
/*           11=(DIFF'):single-ended 16-bit conversion               */
/*              (DIFF):differential 16-bit 2's complement conversion */
/* 01--> 1-0:ADICLK=ADC input clock select                           */
/*           00=bus clock                                            */
/*           01=bus clock / 2                                        */
/*           10=alternate clock (ALTCLK)                             */
/*           11=asynchronous clock (ADACK)                           */
/* BUSCLK = CORECLK / 2 = PLLCLK / 4                                 */
/* PLLCLK is 96 MHz                                                  */
/* BUSCLK is 24 MHz                                                  */
/* ADCinCLK is BUSCLK / 2 = 12 MHz                                   */
/* ADCCLK is ADCinCLK / 4 = 3 MHz                                    */
#define ADC0_CFG1_ADIV_BY2 (2u)
#define ADC0_CFG1_MODE_SGL10 (2u)
#define ADC0_CFG1_ADICLK_BUSCLK_DIV2 (1u)
#define ADC0_CFG1_LP_LONG_SGL10_3MHZ (ADC_CFG1_ADLPC_MASK | \
              (ADC0_CFG1_ADIV_BY2 << ADC_CFG1_ADIV_SHIFT) | \
                                     ADC_CFG1_ADLSMP_MASK | \
            (ADC0_CFG1_MODE_SGL10 << ADC_CFG1_MODE_SHIFT) | \
                               ADC0_CFG1_ADICLK_BUSCLK_DIV2)
/*-------------------------------------------------------------*/
/* ADC0_CFG2:  ADC0 configuration register 2                   */
/*  0-->31-8:(reserved):read-only:0                            */
/*  0--> 7-5:(reserved):read-only:0                            */
/*  0-->   4:MUXSEL=ADC mux select:  A channel                 */
/*  0-->   3:ADACKEN=ADC asynchronous clock output enable      */
/*  0-->   2:ADHSC=ADC high-speed configuration:  normal       */
/* 00--> 1-0:ADLSTS=ADC long sample time select (ADK cycles)   */
/*           default longest sample time:  24 total ADK cycles */
#define ADC0_CFG2_CHAN_A_NORMAL_LONG (0x00u)
/*---------------------------------------------------------   */
/* ADC0_SC1:  ADC0 channel status and control register 1      */
/*     0-->31-8:(reserved):read-only:0                        */
/*     0-->   7:COCO=conversion complete flag (read-only)     */
/*     0-->   6:AIEN=ADC interrupt enabled                    */
/*     0-->   5:DIFF=differential mode enable                 */
/* 10111--> 4-0:ADCH=ADC input channel select (23 = DAC0_OUT) */
#define ADC0_SC1_ADCH_AD23 (23u)
#define ADC0_SC1_SGL_DAC0 (ADC0_SC1_ADCH_AD23)
/*-----------------------------------------------------------*/
/* ADC0_SC2:  ADC0 status and control register 2             */
/*  0-->31-8:(reserved):read-only:0                          */
/*  0-->   7:ADACT=ADC conversion active                     */
/*  0-->   6:ADTRG=ADC conversion trigger select:  software  */
/*  0-->   5:ACFE=ADC compare function enable                */
/*  X-->   4:ACFGT=ADC compare function greater than enable  */
/*  0-->   3:ACREN=ADC compare function range enable         */
/*            0=disabled; only ADC0_CV1 compared             */
/*            1=enabled; both ADC0_CV1 and ADC0_CV2 compared */
/*  0-->   2:DMAEN=DMA enable                                */
/* 01--> 1-0:REFSEL=voltage reference selection:  VDDA       */
#define ADC0_SC2_REFSEL_VDDA (1u)
#define ADC0_SC2_SWTRIG_VDDA (ADC0_SC2_REFSEL_VDDA)
/*-------------------------------------------------------------*/
/* ADC0_SC3:  ADC0 status and control register 3               */
/* 31-8:(reserved):read-only:0                                 */
/*  0-->   7:CAL=calibration                                   */
/*          write:0=(no effect)                                */
/*                1=start calibration sequence                 */
/*          read:0=calibration sequence complete               */
/*               1=calibration sequence in progress            */
/*  0-->   6:CALF=calibration failed flag                      */
/* 00--> 5-4:(reserved):read-only:0                            */
/*  0-->   3:ADCO=ADC continuous conversion enable             */
/*           (if ADC0_SC3.AVGE = 1)                            */
/*  0-->   2:AVGE=hardware average enable                      */
/* XX--> 1-0:AVGS=hardware average select:  2^(2+AVGS) samples */
#define ADC0_SC3_SINGLE (0x00u)
#define ADC0_SC3_CAL (ADC_SC3_CAL_MASK | ADC_SC3_AVGE_MASK | \
                                           ADC_SC3_AVGS_MASK)
/*-------------------------------------------------------------*/
/* DAC */
#define DAC_DATH_0V   0x00u
#define DAC_DATL_0V   0x00u
/*---------------------------------------------------------------------*/
/* DAC_C0:  DAC control register 0                                   */
/* 1-->7:DACEN=DAC enabled                                             */
/* 1-->6:DACRFS=DAC reference select VDDA                              */
/* 0-->5:DACTRGSEL=DAC trigger select (X)                              */
/* 0-->4:DACSWTRG=DAC software trigger (X)                             */
/* 0-->3:LPEN=DAC low power control:high power                         */
/* 0-->2:(reserved):read-only:0                                        */
/* 0-->1:DACBTIEN=DAC buffer read pointer top flag interrupt enable    */
/* 0-->0:DACBBIEN=DAC buffer read pointer bottom flag interrupt enable */
#define DAC_C0_ENABLE  (DAC_C0_DACEN_MASK | DAC_C0_DACRFS_MASK)
/*----------------------------------------*/
/* DAC_C1:  DAC control register 1      */
/* 0-->  7:DMAEN=DMA disabled             */
/* 0-->6-3:(reserved)                     */
/* 0-->  2:DACBFMD=DAC buffer mode normal */
/* 0-->  1:(reserved)                     */
/* 0-->  0:DACBFEN=DAC buffer disabled    */
#define DAC_C1_BUFFER_DISABLED  (0x00u)
/*-------------------------------------------------------------*/
/* PORTx_PCRn                                                  */
/*     -->31-25:(reserved):read-only:0                         */
/*    1-->   24:ISF=interrupt status flag (write 1 to clear)   */
/*     -->23-20:(reserved):read-only:0                         */
/* 0000-->19-16:IRQC=interrupt configuration (IRQ/DMA diabled) */
/*     -->15-11:(reserved):read-only:0                         */
/*  ???-->10- 8:MUX=pin mux control                            */
/*     -->    7:(reserved):read-only:0                         */
/*    ?-->    6:DSE=drive strengh enable                       */
/*     -->    5:(reserved):read-only:0                         */
/*    0-->    4:PFE=passive filter enable                      */
/*     -->    3:(reserved):read-only:0                         */
/*    0-->    2:SRE=slew rate enable                           */
/*    0-->    1:PE=pull enable                                 */
/*    x-->    0:PS=pull select                                 */
/* Port E */
#define PTE30_MUX_DAC0_OUT (0u << PORT_PCR_MUX_SHIFT)
#define SET_PTE30_DAC0_OUT (PORT_PCR_ISF_MASK | PTE30_MUX_DAC0_OUT)
#define PTE31_MUX_TPM0_CH4_OUT (3u << PORT_PCR_MUX_SHIFT)
#define SET_PTE31_TPM0_CH4_OUT (PORT_PCR_ISF_MASK | \
                                PTE31_MUX_TPM0_CH4_OUT | \
                                PORT_PCR_DSE_MASK)
/*-------------------------------------------------------*/
/* SIM_SOPT2                                             */
/*   -->31-28:(reserved):read-only:0                     */
/*   -->27-26:UART0SRC=UART0 clock source select         */
/* 01-->25-24:TPMSRC=TPM clock source select (MCGFLLCLK) */
/*   -->23-19:(reserved):read-only:0                     */
/*   -->   18:USBSRC=USB clock source select             */
/*   -->   17:(reserved):read-only:0                     */
/*  1-->   16:PLLFLLSEL=PLL/FLL clock select (MCGFLLCLK) */
/*   -->15- 8:(reserved):read-only:0                     */
/*   --> 7- 5:CLKOUTSEL=CLKOUT select                    */
/*   -->    4:RTCCLKOUTSEL=RTC clock out select          */
/*   --> 3- 0:(reserved):read-only:0                     */
#define SIM_SOPT2_TPMSRC_MCGPLLCLK (1u << SIM_SOPT2_TPMSRC_SHIFT)
#define SIM_SOPT2_TPM_MCGPLLCLK_DIV2 (SIM_SOPT2_TPMSRC_MCGPLLCLK | \
                                            SIM_SOPT2_PLLFLLSEL_MASK)
/*------------------------------------------------------------------*/
/* TPMx_CONF:  Configuration (recommended to use default values     */
/*     -->31-28:(reserved):read-only:0                              */
/* 0000-->27-24:TRGSEL=trigger select (external pin EXTRG_IN)       */
/*     -->23-19:(reserved):read-only:0                              */
/*    0-->   18:CROT=counter reload on trigger                      */
/*    0-->   17:CSOO=counter stop on overflow                       */
/*    0-->   16:CSOT=counter stop on trigger                        */
/*     -->15-10:(reserved):read-only:0                              */
/*    0-->    9:GTBEEN=global time base enable                      */
/*     -->    8:(reserved):read-only:0                              */
/*   00-->  7-6:DBGMODE=debug mode (paused in debug)                */
/*    0-->    5:DOZEEN=doze enable                                  */
/*     -->  4-0:(reserved):read-only:0                              */
/* 15- 0:COUNT=counter value (writing any value will clear counter) */
#define TPM_CONF_DEFAULT (0u)
/*------------------------------------------------------------------*/
/* TPMx_CNT:  Counter                                               */
/* 31-16:(reserved):read-only:0                                     */
/* 15- 0:COUNT=counter value (writing any value will clear counter) */
#define TPM_CNT_INIT (0u)
/*------------------------------------------------------------------------*/
/* TPMx_MOD:  Modulo                                                      */
/* 31-16:(reserved):read-only:0                                           */
/* 15- 0:MOD=modulo value (recommended to clear TPMx_CNT before changing) */
/* Period = 3 MHz / 50 Hz */
#define TPM_MOD_PWM_PERIOD_20ms (60000u)
/*------------------------------------------------------------------*/
/* TPMx_CnSC:  Channel n Status and Control                         */
/* 0-->31-8:(reserved):read-only:0                                  */
/* 0-->   7:CHF=channel flag                                        */
/*              set on channel event                                */
/*              write 1 to clear                                    */
/* 0-->   6:CHIE=channel interrupt enable                           */
/* 1-->   5:MSB=channel mode select B (see selection table below)   */
/* 0-->   4:MSA=channel mode select A (see selection table below)   */
/* 1-->   3:ELSB=edge or level select B (see selection table below) */
/* 0-->   2:ELSA=edge or level select A (see selection table below) */
/* 0-->   1:(reserved):read-only:0                                  */
/* 0-->   0:DMA=DMA enable                                          */
#define TPM_CnSC_PWMH (TPM_CnSC_MSB_MASK | TPM_CnSC_ELSB_MASK)
/*--------------------------------------------------------*/
/* TPMx_CnV:  Channel n Value                             */
/* 31-16:(reserved):read-only:0                           */
/* 15- 0:MOD (all bytes must be written at the same time) */
/*--------------------------------------------------------------*/
/* TPMx_SC:  Status and Control                                 */
/*    -->31-9:(reserved):read-only:0                            */
/*   0-->   8:DMA=DMA enable                                    */
/*    -->   7:TOF=timer overflow flag                           */
/*   0-->   6:TOIE=timer overflow interrupt enable              */
/*   0-->   5:CPWMS=center-aligned PWM select (edge align)      */
/*  01--> 4-3:CMOD=clock mode selection (count each TPMx clock) */
/* 100--> 2-0:PS=prescale factor selection                      */
/*    -->        can be written only when counter is disabled   */
#define TPM_SC_CMOD_CLK (1u)
#define TPM_SC_PS_DIV16 (0x4u)
#define TPM_SC_CLK_DIV16 ((TPM_SC_CMOD_CLK << TPM_SC_CMOD_SHIFT) | \
                          TPM_SC_PS_DIV16)
/*- -----*/
/* Servo */
#define SERVO_POSITIONS  (5)

/* For using GetStringSB with a buffer size of 1 */
#define SINGLE_CHAR_INPUT (1)

#define NEWLINE_BUFFER_LEN (3)

#define INTEGER_ASCII_OFFSET (48)

#define NONE  0
#define RED   1
#define GREEN 2
#define BOTH  3

#define NUM_ROUNDS 10

/*
* Fetch the status of the current PIT timer count
* value to seed a pseudo random number. The number
* is then divided by 4 to generate a remainder of 0
* or 3, inclusive. 
*
* @return int - random number between 0 and 3 based on timer state
*/
int getRandom(){
  UInt32 count;
  GetCount(&count); //Update count variable
  return count % 4;
}

/**
 * Calculates score based on the key the user pressed
 * versus which light was displayed, factored in with the current
 * round. The round value is used to scale the number of points achieved
 * based on difficulty.
 * 
 * --( 1) point for getting "BOTH" right
 * --( 2) points for getting "GREEN" or "RED" right
 * --(-1) points for out of time
 * --(-1) points for wrong key
 */
int getScore(char keyPressed, char lightShown, int round) {
	
	if(lightShown == BOTH && (keyPressed=='g' || keyPressed=='r')){
		return (round / 2) + 1;
	} else if(lightShown == NONE && keyPressed=='x'){
		return (round / 2) + 1;
	} else if((lightShown == RED && keyPressed=='r') ||
	          (lightShown == GREEN && keyPressed=='g')){
		//It is more complex to guess a specific color, so 
		//an additional point is granted each round
		return (round / 2) + 2;
	
	//No input was provided for a given round
	} else if(keyPressed == 'x'){
		return -1;
	}
	
	return -1; //wrong key must have been pressed
}

int main (void) {
	UInt32 count;
	int i, selection, result, score;
  char keyPressed;
	
	/* mask interrupts */
  __asm("CPSID   I");  
	
  /* Perform all device initialization here */
  /* Before unmasking interrupts            */
	
	/* Fire up the UART */
	Init_UART0_IRQ();
  Init_PIT_IRQ();
  InitLEDs();
	
  __asm("CPSIE   I");  /* unmask interrupts */

	for(;;) {
		
		//1: Display the instructions for the game
    PutStringSB("            Welcome to the World's Greatest Game!\r\n",MAX_STRING);
    PutStringSB("----------------------------------------------------------\r\n",MAX_STRING);
    PutStringSB("Prepare your mind and body for a challenge like you\r\n",MAX_STRING);
    PutStringSB("have never experienced.\r\n",MAX_STRING);
    PutStringSB("----------------------------------------------------------\r\n",MAX_STRING);
    PutStringSB("The game consists of 10 rounds. Each round you will\r\n",MAX_STRING);
    PutStringSB("need to press a keyboard letter matching the color of\r\n",MAX_STRING);
    PutStringSB("the LED that is shown. If you fail to do this, one of\r\n",MAX_STRING);
    PutStringSB("two things may happen. EITHER the world will explode,\r\n",MAX_STRING);
    PutStringSB("or you may lose a point. There is no way to tell which\r\n",MAX_STRING);
    PutStringSB("outcome will occur, so be very careful not to mess up - we\r\n",MAX_STRING);
    PutStringSB("are all depending on you.\r\n",MAX_STRING);
    PutStringSB("----------------------------------------------------------\r\n",MAX_STRING);
    PutStringSB("You may be shown the green or red LED, or both LEDs, or neither.\r\n",MAX_STRING);
    PutStringSB("----------------------------------------------------------\r\n",MAX_STRING);
    PutStringSB("Good luck. Countless lives may or may not be in your hands now.\r\n",MAX_STRING);
    PutStringSB("----------------------------------------------------------\r\n",MAX_STRING);
    //2: Prompt player to start game 
    PutStringSB("TO BEGIN, PRESS ANY KEY\r\n", MAX_STRING);
		
		GetChar();
		
    //3: After a key is pressed, program runs each game round "i"
		for(i = 0; i < NUM_ROUNDS; i++){
			//Start timer and reset
			StartTimer();
			
      //a: get a random number 0-3
      selection = getRandom();
      //a: light the LEDs
      if(selection == NONE){
        SetLED(0);
      } else if(selection == GREEN) {
        SetLED(1);
      } else if(selection == RED) {
        SetLED(2);
      } else if(selection == GREEN) {
        SetLED(3);
      }
      
      //b: print a ">" prompt
      PutStringSB(">", MAX_STRING);
      //c: player has 11-i seconds to press the key
      keyPressed = 'x';
      while(GetCount(&count) < (11-i)*100){
        if(IsKeyPressed()){
          keyPressed = GetChar();
          break;
        }
      }
      
      //d: echo key, print correct or wrong, show color combination of LEDs
      PutChar(keyPressed);
      PutStringSB("\r\n", MAX_STRING);
      result = getScore(keyPressed, selection, i); //get score
      
      //negative implies wrong
      if(result < 0) {
        PutStringSB("Ding dong, that was wrong.", MAX_STRING);
      } else {
        PutStringSB("Correct! We live... for now", MAX_STRING);
      }
      //Echo color combination shown
      PutStringSB("LEDs shown were: ",MAX_STRING);
      if(selection == NONE){
        PutStringSB("None", MAX_STRING);
      } else if(selection == GREEN) {
        PutStringSB("Green", MAX_STRING);
      } else if(selection == RED) {
        PutStringSB("Red", MAX_STRING);
      } else if(selection == BOTH) {
        PutStringSB("Green & Red", MAX_STRING);
      }
      
      //Then, add to score
      score += result;
      
      //e: Move to the next round when EITHER:
      //   - time for current round expires
      //   - player types character
      while(GetCount(&count) < (11-i)*100 && !IsKeyPressed());
    }
    
    //4: After last round, display score
    
    //5: At end of game, repeat whole process
	}

} /* main */

