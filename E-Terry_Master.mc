/*
**    User parameters are used to communicate with the Monitor
** dialog.  Please be aware of the fact that restarting the program
** DOES reinitialize the user parameters, but it does NOT update the
** user dialogue.  You must use the "Select Co$ntroller" button and
** reselect the controller to reinitialize the dialog.
*/
#include <SysDef.mh>

// Set Version
#define APP_SW_VERSION_1        2
#define APP_SW_VERSION_2        00
#define APP_SW_VERSION_3        01

/****************************************************************``*****
** Define controller | machine
** 1 == simulation enable
*********************************************************************/

#define SIMULATE_ACT_DRIVE_1				0		// Enable simulation for drive with 1
#define SIMULATE_ACT_DRIVE_2				0		// Enable simulation for drive with 1
#define SIMULATE_ACT_DRIVE_3				0		// Enable simulation for drive with 1
#define SIMULATE_WHEEL_DRIVE_1				0		// Enable simulation for drive with 1
#define SIMULATE_WHEEL_DRIVE_2				0		// Enable simulation for drive with 1
#define SIMULATE_WHEEL_DRIVE_3				0		// Enable simulation for drive with 1

#define DISABLE_MINIMACS6_TRAV_1			0		// Disable slave device (no pdo and sdo trafic)
#define DISABLE_MINIMACS6_TRAV_3			0		// Disable slave device (no pdo and sdo trafic)

#define ENABLE_COMMISSIONING				0		// Enable the commissioning routines

#define REMOTE_ON  							1 		// Enable wifi remote control

/*************************** OLD Parameter - tbd delte from eTerry If they are no longer used.  *****************************/

#define ACT_DRIVE_TANKSTEERING_ON			1		// Enable Tank Steering for straight drive


#define REMOTE_AI_ON						0		// Set to 0 == Analog input from remote are not used
#define CURVE_FUNCTION_SCALE_ON				1		// Enable curve function to scale the analoag input signal from the joysticks
#define CONFIG_RUN_ERROR_ON					0		// Set to 0 to disable runtime error of change configuration (toggled input while running)
#define SOFT_LIMIT_ERROR_ON					0		// Set to 0 to disable Softwarelimit error
#define POWER_SUPPLY_ERROR_ON				0		// Set to 0 to disable power Supply error

/*********************************************************************
** Define control methode
**
** The RC remote control can always be used. If "No-Monitor" is used the
** signals which are generated via the *.zbm monitor file are not generated.
**
*********************************************************************/
#define MONITOR					1
#define NO_MONITOR				0

#define CONTROL_METHODE			MONITOR

/******************************
***************************************
** Global Variables
*********************************************************************/
#include "Include\20_Global_Variables.mh"

/*********************************************************************
** Application Defines
*********************************************************************/
#include "Include\10_StateMachines_Defines.mh"
#include "Include\11_User_Interface_Defines.mh"
#include "Include\12_Mechanical_Defines.mh"
#include "Include\13_IO_Port_Defines.mh"
#include "Include\14_Actuating_Drive_Defines.mh"
#include "Include\15_Wheel_Drive_Defines.mh"
#include "Include\16_MiniMACS6_DS402_Slave_Defines.mh"
#include "Include\19_Global_Defines.mh"
//#include "Include\17_Remote_Defines.mh"

/*********************************************************************
** Global Functions
*********************************************************************/
#include "Include\40_General_Functions.mh"
#include "Include\30_Setup_Actuating_Drive.mh"
#include "Include\31_Setup_Wheel_Drive.mh"
#include "Include\32_Setup_Analog_Input.mh"
#include "Include\35_Achermann_Steering.mh"
#include "Include\33_Setup_MiniMACS6_DS402_Slave.mh"

#if ENABLE_COMMISSIONING

	#include "Include\Commissioning\00_commissioning.mh"
	#include "Include\08_StateMachine_RemoteControl.mc"
#endif

/*********************************************************************
** StateMachines
*********************************************************************/
#if ! ENABLE_COMMISSIONING
	#include "Include\01_StateMachine_Main.mc"
	#include "Include\05_StateMachine_LED.mc"
	#include "Include\06_StateMachine_Act_Break.mc"
	#include "Include\07_StateMachine_Wheel_Brake.mc"
	#include "Include\08_StateMachine_RemoteControl.mc"
#endif

/*********************************************************************
** Main Application Program
*********************************************************************/

long main(void)
{
    print("Initializing system parameters");
    Delay(5000);
    print("Initializion completed");
    print("");
	print("E-Terry -Application Version ",APP_SW_VERSION_1,".",APP_SW_VERSION_2,".",APP_SW_VERSION_3);

	/*
	** Write debug information while powerdown safe if there was a crash
	*/
	#ifdef FIRMWARE_DEBUG
		FIRMWARE_DEBUG;
		print("Debug: Dataset with powerdown save enabled");
	#endif

    /*
    ** Start by clearing any previous errors.
    */
	AmpErrorClear(AXALL);
    ErrorClear();

    /*
    ** Initialize the user parameters.  These are used to communicate
    ** with the Monitor dialog.
    */

    initUserDialogParameter();
    initUSBParameterArray();
    initDefaultParameter();
    setUSBParameter();
    setupAnalogInput();

    // Tbd Standard setting function with baud rate, synctime etc.
    GLB_PARAM(ESCCONDGLB)=GLB_PARAM_ESCCONDGLB_OUT_OFF;


 	#if ENABLE_COMMISSIONING
		//setup_MiniMACS6_DS402_Slave();
		//eTerry_outputs();
		startCommissioning();
		//SmRun(Sm_Ether0net);
 	#else
		print("SM: Starting ETerry State Machine" );
		SmRun(ETerry,ActuatingBreakControl, WheelBrakeControl, LedControl,Sm_Ethernet);
		print("Done.");
    #endif

    return(1);
}//$X {HWAMP_MAXCUR,1,1,0,-1,0,-1,0,(-1),-1},0x4000,43,0
//$X {HWAMP_MAXCUR,1,1,0,-1,0,-1,0,(-1),-1},0x4001,43,0
//$X {HWAMP_MAXCUR,1,1,0,-1,0,-1,0,(-1),-1},0x4004,43,0
//$X {HWAMP_MAXCUR,1,1,0,-1,0,-1,0,(-1),-1},0x4002,43,0
//$X {HWAMP_MAXCUR,1,1,0,-1,0,-1,0,(-1),-1},0x4003,43,0
//$X {HWAMP_MAXCUR,1,1,0,-1,0,-1,0,(-1),-1},0x4005,43,0
//$X {PO_VIRTAMP_CURRENT,1,1,0,-1,0,-1,0,(-1),-1},0x2CC0,10,0
//$X {PO_VIRTAMP_CURRENT,1,1,0,-1,0,-1,0,(-1),-1},0x2CC1,10,0
//$X {PO_VIRTAMP_CURRENT,1,1,0,-1,0,-1,0,(-1),-1},0x2CC4,10,0
//$X {REG_AVEL,1,1,0,-1,0,-1,0,(-1),-1},0x2500,4,0
//$X {REG_AVEL,1,1,0,-1,0,-1,0,(-1),-1},0x2501,4,0
//$X {REG_AVEL,1,1,0,-1,0,-1,0,(-1),-1},0x2504,4,0
