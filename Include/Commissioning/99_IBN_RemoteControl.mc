/*
**    User parameters are used to communicate with the Monitor
** dialog.  Please be aware of the fact that restarting the program
** DOES reinitialize the user parameters, but it does NOT update the
** user dialogue.  You must use the "Select Co$ntroller" button and
** reselect the controller to reinitialize the dialog.
*/

#include <SysDef.mh>

/*********************************************************************
** Define controller | machine
** 1 == simulation enable
*********************************************************************/

#define ACT_DRIVE_FIX_ON					0		// Enable fixx actuating drives as workaround. The Actuating drive must be use as a simulator
#define ACT_DRIVE_TANKSTEERING_ON			1		// Enable Tank Steering for straight drive
#define SIMULATOR_ACT_DRIVE					0		// Enable simulation for actuation drives
#define SIMULATOR_ACT_DRIVE_NO_SEARCH		1		// Enable simulation for actuation drives homing (Manual to sensor position)
#define SIMULATOR_ACT_DRIVE_NO_ZERO			1		// Enable simulation for actuation drives homing (Manual to zero position)

#define SIMULATOR_WHEELDRIVE				0		// Enable simulation for wheel drives
	#define WHEELDRIVE_1_ON					1 		// Just needed if SIMULATOR_WHEELDRIVE = 0, Enable Wheeld Drive
	#define WHEELDRIVE_2_ON					1		// Just needed if SIMULATOR_WHEELDRIVE = 0, Enable Wheeld Drive
	#define WHEELDRIVE_3_ON					1		// Just needed if SIMULATOR_WHEELDRIVE = 0, Enable Wheeld Drive

#define WHEELDRIVE_SLOWMODE_ON				0		// Enable wheel drive slow mode. AI Boost > WHEELDRIVE_SLOWMODE
	#define WHEELDRIVE_SLOWMODE				1000	// Just needed if WHEELDRIVE_SLOWMODE_ON==1 && SIMULATOR_WHEELDRIVE == 0 -> MAX Velocity in 1/10 procent

#define REMOTE_AI_ON						1		// Set to 0 == Analog input from remote are not used
#define CONFIG_RUN_ERROR_ON					0		// Set to 0 to disable runtime error of change configuration (toggled input while running)
#define SOFT_LIMIT_ERROR_ON					0		// Set to 0 to disable Softwarelimit error

#define TEST_ROUTINE_ON						0				// Enable SM Programm Testing "Homing" is still done !!! There is no I2T in this mode !!!
	#define TEST_ROUTINE_TORQUE_ON			0				// Enable Torque test
		#define TEST_ROUTINE_TORQUEMAX_CURRENT	4470*2.4	// Set max current for testing the actuation drive
		#define TEST_ROUTINE_TORQUEMAX_VEL		50			// Set wheeldrive velocity in 1/10 %

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

/*********************************************************************
** Application Defines
*********************************************************************/
#include "Include\10_StateMachines_Defines.mh"
#include "Include\11_User_Interface_Defines.mh"
#include "Include\12_Mechanical_Defines.mh"
#include "Include\13_IO_Port_Defines.mh"
#include "Include\14_Actuating_Drive_Defines.mh"
#include "Include\15_Wheel_Drive_Defines.mh"
#include "Include\19_Global_Defines.mh"

/*********************************************************************
** Global Variables
*********************************************************************/
#include "Include\20_Global_Variables.mh"

/*********************************************************************
** Global Functions
*********************************************************************/
#include "Include\30_Setup_Actuating_Drive.mh"
#include "Include\31_Setup_Wheel_Drive.mh"
#include "Include\32_Setup_Remote_Control.mh"
#include "Include\35_Achermann_Steering.mh"

/*********************************************************************
** Local Functions
*********************************************************************/
void UserParamInit(void);

/*********************************************************************
** Main Application Program
*********************************************************************/

long main(void)
{
	setupRemoteControl();
	while(1)
	{
	print("");
	print("DI_SLEEPMODE:               ", DI_SLEEPMODE);
	print("DI_CURVE_DRIVE:            ", DI_CURVE_DRIVE);
	print("DI_ROT_CENTRALPOINT:  ", DI_ROT_CENTRALPOINT);
	print("DI_SET_CONST_SPEED:    ", DI_SET_CONST_SPEED);
	print("DI_EXTERNAL_INPUT:       ", DI_EXTERNAL_INPUT);
	print("DI_DATA_LOGGING:       ", DI_DATA_LOGGING);
	print("AI_JOYSTICK_BOOST:      ", AI_JOYSTICK_BOOST);
	print("AI_JOYSTICK_STEERING:   ", AI_JOYSTICK_STEERING);
	Delay(2000);

	}

    return(1);
}




//$X {gMotorRCEnable,1,1,0,26,0,32,0,(-1),1},0x2000,33,0
//$X {PO_HWANIN_VALUE,1,1,0,-1,0,-1,0,(-1),-1},0x4A83,1,0
//$X {PO_HWANIN_VALUE,1,1,0,-1,0,-1,0,(-1),-1},0x4A80,1,0
//$X {PO_HWANIN_VALUE,1,1,0,-1,0,-1,0,(-1),-1},0x4A81,1,0
