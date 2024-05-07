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
*********************************************************************/
#define SIMULATOR				0
#define VEHICLE					1

#define MACHINE					SIMULATOR

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
#include "10_StateMachines_Defines.mh"
#include "11_User_Interface_Defines.mh"
#include "12_Mechanical_Defines.mh"
#include "13_IO_Port_Defines.mh"
#include "14_Actuating_Drive_Defines.mh"
#include "15_Wheel_Drive_Defines.mh"
#include "19_Global_Defines.mh"

/*********************************************************************
** Global Variables
*********************************************************************/
#include "20_Global_Variables.mh"

/*********************************************************************
** Global Functions
*********************************************************************/
#include "30_Setup_Actuating_Drive.mh"
#include "31_Setup_Wheel_Drive.mh"
#include "35_Achermann_Steering.mh"

/*********************************************************************
** StateMachines
*********************************************************************/
#include "01_StateMachine_Main.mc"
#include "05_StateMachine_LED.mc"

/*********************************************************************
** Local Functions
*********************************************************************/
void UserParamInit(void);

/*********************************************************************
** Main Application Program
*********************************************************************/


long main(void)
{
	gConfigTyp=1;
	 print(AchermannSteering(3000,3000*0.25, 90));

    return(1);
}

/*********************************************************************
** Local Functions
*********************************************************************/

void UserParamInit(void)
{
    /*
    ** Initialize all user parameters used by the user dialog.
    */
    long scale = USER_FACTOR_SCALE;

	print("User Param Init");
    USER_PARAM(USER_MONITOR_COMMAND) 	= CMD_IDLE;
    USER_PARAM(USR_MONITOR_DSP_STATUS)	= DSP_MOTOFF;

	USER_PARAM(USER_SETVEL) 			= 500;
	USER_PARAM(USER_SETACC) 			= 1000;
	USER_PARAM(USER_SETDEC) 			= 1000;
	USER_PARAM(USER_SETJERK) 			= 1000;


	USER_PARAM(USER_MONITOR_SENSOR) 	= SENS_CONFIGURATION_1;
}


//$X {gAchSteering_fakt,8,2,0,35,0,47,1,(0,3),1},0x2000,49,3
//$X {gAchSteering_fakt,8,2,0,35,0,47,1,(1,3),1},0x2000,51,3
//$X {gAchSteering_fakt,8,2,0,35,0,47,1,(2,3),1},0x2000,53,3
//$X {gAchSteering_angle_actuator,8,2,0,36,0,54,1,(0,3),1},0x2000,56,3
//$X {gAchSteering_angle_actuator,8,2,0,36,0,54,1,(1,3),1},0x2000,58,3
//$X {gAchSteering_angle_actuator,8,2,0,36,0,54,1,(2,3),1},0x2000,60,3
//$X {gAchSteering_alphaTraverse1_3,8,2,0,32,0,43,0,(-1),1},0x2000,44,3
