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
#define SIMULATOR_ACT_DRIVE		1
#define SIMULATOR_WHEELDRIVE	1

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
#include "32_Setup_Remote_Control.mh"
#include "35_Achermann_Steering.mh"

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
	print("Ai Boost: ", AnalogInput(1), " Ai Steering: ", AnalogInput(2));
	Delay(1000);

	}

    return(1);
}




//$X {gAchSteering_fakt,8,2,0,32,0,50,1,(0,3),1},0x2000,52,3
//$X {gAchSteering_fakt,8,2,0,32,0,50,1,(1,3),1},0x2000,54,3
//$X {gAchSteering_fakt,8,2,0,32,0,50,1,(2,3),1},0x2000,56,3
//$X {gAchSteering_angle_actuator,8,2,0,33,0,57,1,(0,3),1},0x2000,59,3
//$X {gAchSteering_angle_actuator,8,2,0,33,0,57,1,(1,3),1},0x2000,61,3
//$X {gAchSteering_angle_actuator,8,2,0,33,0,57,1,(2,3),1},0x2000,63,3
//$X {gAchSteering_alphaTraverse1_3,8,2,0,29,0,46,0,(-1),1},0x2000,47,3
