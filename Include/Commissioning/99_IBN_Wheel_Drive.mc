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
#define SIMULATOR_ACT_DRIVE_NO_SEARCH		0		// Enable simulation for actuation drives homing (Manual to sensor position)
#define SIMULATOR_ACT_DRIVE_NO_ZERO			0		// Enable simulation for actuation drives homing (Manual to zero position)

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
#include "Include\40_General_Functions.mh"

/*********************************************************************
** StateMachines
*********************************************************************/
#include "Include\01_StateMachine_Main.mc"
#include "Include\05_StateMachine_LED.mc"

/*********************************************************************
** Main Application Program
*********************************************************************/
long hallTest;
long hallBit[3];
long errorcode;
long main(void)
{
	/*
	** Write debug information while powerdown safe if there was a crash.
	*/
	#ifdef FIRMWARE_DEBUG
		FIRMWARE_DEBUG;
		print("Debug: Dataset with powerdown save enabled");
	#endif
    /*
    ** Start by clearing any previous errors.
    */
    InterruptSetup(ERROR, ErrorHandler);

    ErrorClear();
    AmpErrorClear(AXALL);
    /*
    ** Initialize the user parameters.  These are used to communicate
    ** with the Monitor dialog.
    */

    initUserDialogParameter();
    initUSBParameterArray();
    initDefaultParameter();
    setUSBParameter();

	AxisControl(AXALL, OFF);

   	// set all slaves to PREOPERATIONAL by sending an NMT.
	SYS_PROCESS(SYS_CANOM_MASTERSTATE) = 0;

    /*
    ** Set the axis parameters.
    */
	setupWheelDrive();

	// start all slaves commanding them into OPERATIONAL.
	SYS_PROCESS(SYS_CANOM_MASTERSTATE) = 1;


	Delay(500);

	AxisControl(AXALL, OFF);
	Delay(500);

	while(1)
	{
		hallTest = SdoRead(WHEEL_DRIVE_BUSID_3, 0x301A,0x2);
		errorcode =  SdoRead(WHEEL_DRIVE_BUSID_3,0x603F,0x00);
		AmpErrorClear(AXALL);
		hallBit[0] = hallTest.i[0];
		hallBit[1] = hallTest.i[1];
		hallBit[2] = hallTest.i[2];
	}



//	//AxisControl(WHEEL_DRIVE_3, ON);
//	while(1);
//	print("Axis Enable");
//	Acc(WHEEL_DRIVE_1,100,WHEEL_DRIVE_2,100,WHEEL_DRIVE_3,100);
//	Cvel(WHEEL_DRIVE_1,1000,WHEEL_DRIVE_2,1000,WHEEL_DRIVE_3,1000);
//	print("Start Cvel");
//	AxisCvelStart(WHEEL_DRIVE_1);
//	AxisCvelStart(WHEEL_DRIVE_2);
//	AxisCvelStart(WHEEL_DRIVE_3);
//
//	while(1);
//	Delay(5000);
//	print("New Velocity");
//	Cvel(WHEEL_DRIVE_1,1000,WHEEL_DRIVE_2,1000,WHEEL_DRIVE_3,1000);
//	Delay(50000);
//	AxisCvelStop(AXALL);
//	AxisControl(AXALL, OFF);

    return(1);
}

void ErrorHandler(void) {

    print("Error ",ErrorNo()," errax: ",ErrorAxis() );
    if(ErrorNo() == 89) {
        printf("SDO Abort Code %lX", SYS_PROCESS(SYS_CANOM_SDOABORT) );
    }
    if (ErrorNo() == 8) {
		 print(" Trackerror   time: ",Time() );
		 print("ErrorAx: ",ErrorAxis() );
		 Delay(10);
		 RecordStop(0, 0);
    }
    if(ErrorNo() == 40) {
        print("Error Axis: ", ErrorAxis() ," ErrorCode: ", radixstr(SdoRead(WHEEL_DRIVE_BUSID_3,0x603F,0x00),16));

     /* 0s1001 / 0
	Bit | Error-Reason
	7 = Motion error        (value 128)
	6 = reserved (always 0)
	5 = Device profile-specific
	4 = Communication error
	3 = Temperature error
	2 = Voltage error
	1 = Current error
	0 = Generic error
	*/

     print("amperrclr  ax: ", ErrorAxis() );
     AmpErrorClear(AXALL);
    }
  	//  ErrorClear();
    Delay(2000);
 	//   AxisControl(ON, C_AXIS1, C_AXIS2, C_AXIS3);
}





//$X {hallBit,1,1,0,79,0,787,1,(0,3),1},0x2003,27,0
//$X {hallBit,1,1,0,79,0,787,1,(1,3),1},0x2003,28,0
//$X {hallBit,1,1,0,79,0,787,1,(2,3),1},0x2003,29,0
//$X {errorcode,1,1,0,80,0,791,0,(-1),1},0x2003,30,1
