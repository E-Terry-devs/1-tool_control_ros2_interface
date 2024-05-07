/*********************************************************************
** StateMachine Main File
**
** This is the main file of the state machine. Various parts of the
** state machine, such as the running state, are stored in other documents.
**
** The error handling and various functions which must work in each state
** are processed here.
**
*********************************************************************/


/*********************************************************************
** Include SDK
*********************************************************************/
#include "SDK\SDK_ApossC.mc"

/*********************************************************************
** State Definitions
*********************************************************************/

SmState ETerryMain
{
    SIG_INIT =
    {

		print("SM: MainState - Init");

		sprint(printArray, "");
		sprint(printArray, "Enable Eterry");
		sprint(printArray, "Hardware Time ", Time() ," ms");
		readAndPrintActualTemp();
		sprint(printArray, "*********************************************************************");
		gHomeDone		= 0;
		gMotorRCEnable 	= 0;
		gMotorManEnable = 0;
		gMotorSlowModeOn= 0;
		SmPublish(SIG_LED_OFF, 0,0,0);
		//SmPublish(SIG_LED_ON, LED_PERIOD_STOP, 1, 1, 1);

		#if REMOTE_ON
			SmPost(SMID_REMOTECONTROL,SIG_ETHERNET_INIT);
		#endif
		return(SmTrans(->CheckConfiguration));
    }
	SIG_ERROR =
    {
    	long axeNbr 	= ErrorAxis();
    	long errNbr		= ErrorNo();
    	long errInfoNbr	= ErrorInfo();

    	sprint(printArray, "Error - Hardware Time: ", Time(), " ms");
    	readAndPrintActualTemp();
		switch(errNbr)
		{
		case F_GRENZE:	print("ErrorNo: ",errNbr," info: ",errInfoNbr, " AxisNo: ", axeNbr);
						print("Axis Limit Reached Axis: ", axeNbr);
						print("NEGLIMIT: ", AXE_PARAM(axeNbr,NEGLIMIT), " POSLIMIT: ", AXE_PARAM(axeNbr,POSLIMIT), " ActPos: ", Apos(axeNbr));
						sprint(printArray, "Axis Limit Reached Axis: ", axeNbr);
						SmPublish(SIG_LED_ON, LED_PERIOD_STOP, 1, 1, 1);

						break;
		case F_UMIN:	print("ErrorNo: ",errNbr," info: ",errInfoNbr, " AxisNo: ", axeNbr);
						print("Minimum voltage of the amplifier has been undershot: ", HWAMP_PROCESS(axeNbr,PO_HWAMP_VOLT1)*4);
						sprint(printArray,"ErrorNo: ",errNbr," info: ",errInfoNbr, " AxisNo: ", axeNbr, " Voltage: ",  HWAMP_PROCESS(axeNbr,PO_HWAMP_VOLT1)*4);
						SmPublish(SIG_LED_ON, LED_PERIOD_STOP, 1, 1, 1);

						break;
		case F_AMP:		/*if(	axeNbr==WHEEL_DRIVE_1)
						{
							print("EPOS4 Error");
							print("Error Axis: ", axeNbr ," ErrorCode: ", radixstr(SdoRead(WHEEL_DRIVE_BUSID_1,0x603F,0x00),16));
							sprint(printArray,"Error Axis: ", axeNbr ," ErrorCode: ", radixstr(SdoRead(WHEEL_DRIVE_BUSID_1,0x603F,0x00),16));
						}
						else if(axeNbr==WHEEL_DRIVE_2)
						{
							print("EPOS4 Error");
							print("Error Axis: ", axeNbr ," ErrorCode: ", radixstr(SdoRead(WHEEL_DRIVE_BUSID_2,0x603F,0x00),16));
							sprint(printArray,"Error Axis: ", axeNbr ," ErrorCode: ", radixstr(SdoRead(WHEEL_DRIVE_BUSID_2,0x603F,0x00),16));
						}
						else if(axeNbr==WHEEL_DRIVE_3 )
						{
							print("EPOS4 Error");
							print("Error Axis: ", axeNbr ," ErrorCode: ", radixstr(SdoRead(WHEEL_DRIVE_BUSID_3,0x603F,0x00),16));
							sprint(printArray,"Error Axis: ", axeNbr ," ErrorCode: ", radixstr(SdoRead(WHEEL_DRIVE_BUSID_3,0x603F,0x00),16));
						}
						else
						{
							print("ErrorNo: ",errNbr," info: ",errInfoNbr, " AxisNo: ", axeNbr);
							sprint(printArray,"ErrorNo: ",errNbr," info: ",errInfoNbr, " AxisNo: ", axeNbr);
						}

						SmPublish(SIG_LED_ON, LED_PERIOD_STOP, 1, 1, 1);

						break;*/

		default:		{
							print("ErrorNo: ",errNbr," info: ",errInfoNbr, " AxisNo: ", axeNbr);
							sprint(printArray,"ErrorNo: ",errNbr," info: ",errInfoNbr, " AxisNo: ", axeNbr);
							SmPublish(SIG_LED_ON, LED_PERIOD_STOP, 1, 1, 1);
						}
		}

		AmpErrorClear(AXALL);
		ErrorClear();
		return(SmTrans(->MotorsOff));
	}

    SIG_MOTOR_OFF  		= SmTrans(->MotorsOff);
    SIG_VEHICLE_ENABLE	= {
    						gMotorRCEnable=1;
    						return(SmTrans(->CheckConfiguration));
    						}
    SIG_HOME    		= {gHomeDone=0; return(SmTrans(->CheckConfiguration));}
    SIG_USER_ERROR		= SmTrans(->UserError);
	SIG_EMG_BUTTON		= SmTrans(->MotorsOff);
	SIG_MANUAL_TRAV_3_1	= motorManualOn;
	SIG_MANUAL_TRAV_3_2	= motorManualOn;
	//SIG_MANUAL_MODE  	= motorManualOn;
	SIG_MANUAL_EBOX_1	= actBreakManual;
	SIG_MANUAL_EBOX_2	= actBreakManual;
	SIG_SLOW_MODE 		= setSlowMode;

	// Actual not used
    SIG_SLEEPMODE 		=
   	{
		if(!DI_SLEEPMODE)
		{
			print("SleepMode: On");
			// Do some stuff
		}
		else
		{
			print("SleepMode: Off");
			// Do some stuff
		}
    }

    SIG_DATA_LOGGING 	=
   	{
		if(DI_DATA_LOGGING)
		{
			print("DataLogging: Start");

		}
		else
		{
			print("DataLogging: Stop");

		}
    }
    SIG_EXTERNAL_INPUT		=
		{
			if(DI_EXTERNAL_INPUT)
			{
				print("ExternalInput: On");
			}
			else
			{
				print("ExternalInput: Off");
			}
		}


 	SmState UserError
	{
		SIG_INIT =
		{

			sprint(printArray, "UserError - Hardware Time: ", Time(), " ms");
			sprint(printArray,"User Error ID: ", USER_PARAM(USER_ERROR_ID)," Hardware Time: ", Time(), " ms");

			switch(USER_PARAM(USER_ERROR_ID))
			{
				case ERR_LOGICSUPPLY:	{
											printf("User Error ID: %d", USER_PARAM(USER_ERROR_ID));
											print(" - Minimum logic voltage undershot ", HWAMP_PROCESS(0,PO_HWAMP_VOLT2) *4, " mV");
											break;
										}

				default:				{
											print("User Error ID: ", USER_PARAM(USER_ERROR_ID));
										}
			}
			SmPublish(SIG_LED_ON, LED_PERIOD_STOP, 1, 1, 1);
			SmPost(id,SIG_MOTOR_OFF);
		}

	}
	/*
	** Check and set the actual configurations
	*/
	#include "04_StateMachine_Main_CheckConfiguration.mh"

    SmState MotorsOff
	{
        SIG_ENTRY =
        {
			print("SM: MotorsOff - Entry");
			sprint(printArray, "MotorOff, Hardware Time: ", Time(), " ms");
			USER_PARAM(USER_MONITOR_COMMAND) 	= CMD_IDLE;
			USER_PARAM(USR_MONITOR_DSP_STATUS)	= DSP_MOTOFF;

			if(ACTUATING_DRIVE_NO_MOVE && WHEEL_DRIVE_NO_MOVE)
			{
				AxisControl(ACTUATING_DRIVE_1, OFF,ACTUATING_DRIVE_2, OFF,ACTUATING_DRIVE_3, OFF);
				// Break On - wait until velocity act drive → < Stand still window velocity
				SmPublish(SIG_WHEEL_BRAKE,0,0,0);
				SmPublish(SIG_ACT_BREAK,0,0,0);
			}
			else
			{
				// If the actuating drives still moves do en emergency Stop and start an TimeOut for motorsOff
				Dec(ACTUATING_DRIVE_1,ACT_DRIVE_VEHICLE_EXIT_DEC,ACTUATING_DRIVE_2,ACT_DRIVE_VEHICLE_EXIT_DEC,ACTUATING_DRIVE_3,ACT_DRIVE_VEHICLE_EXIT_DEC);
				AxisStop(ACTUATING_DRIVE_1,ACTUATING_DRIVE_2,ACTUATING_DRIVE_3);
				Dec(WHEEL_DRIVE_1,WHEEL_DRIVE_VEHICLE_EXIT_DEC,WHEEL_DRIVE_2,WHEEL_DRIVE_VEHICLE_EXIT_DEC,WHEEL_DRIVE_3,WHEEL_DRIVE_VEHICLE_EXIT_DEC);
				AxisCvelStop(WHEEL_DRIVE_1,WHEEL_DRIVE_2,WHEEL_DRIVE_3);

				SmTimer(ACT_TIMEOUT_MOTOROFF, id, SIG_TIMER_MOTOROFF);
			}


			//Disable wheel drive (they use slowdownramp after drive disable)
			AxisControl(WHEEL_DRIVE_1,OFF,WHEEL_DRIVE_2,OFF,WHEEL_DRIVE_3,OFF);

			// Application controll off
			DO_APP_CONTROL(0);

			if(DI_EMG_STOP_TRAV_1)
			{
				print("Emergency button traverse 1");
				sprint(printArray,"Emergency button traverse 1, Hardware Time: ", Time(), " ms");
				SmPublish(SIG_LED_ON, LED_PERIOD_EMG, 1, 0, 0);
			}
			else if(DI_EMG_STOP_TRAV_2)
			{
				print("Emergency button traverse 2");
				sprint(printArray,"Emergency button traverse , Hardware Time: ", Time(), " ms");
				SmPublish(SIG_LED_ON, LED_PERIOD_EMG,  0, 1, 0);
			}
			else if(DI_EMG_STOP_TRAV_3)
			{
				print("Emergency button traverse 3");
				sprint(printArray,"Emergency button traverse 3, Hardware Time: ", Time(), " ms");
				SmPublish(SIG_LED_ON, LED_PERIOD_EMG, 0, 0, 1);
			}
			readAndPrintActualTemp();

			if(SYS_INFO(SYS_SD_CARD_STATUS))
			{
				MemoryDump(0x2212, 2, FILENAME);

				while (MemoryDumpStatus() == 1)
				{
					// wait here while the task is processing
				}
				print("MemoryDumpStatus = ", MemoryDumpStatus());
			}
			else
			{
				print("No USB Stick for save log Data");
			}

		}
   		SIG_EXIT =
   		{
   			// Delete the Timer
   			SmTimer(0, id, SIG_TIMER_MOTOROFF);
   		}


   		SIG_TIMER_MOTOROFF =
   		{
   			print("MotorOff Actuating Drive Delay");
			AxisControl(ACTUATING_DRIVE_1, OFF,ACTUATING_DRIVE_2, OFF,ACTUATING_DRIVE_3, OFF);
			// Break On - wait until velocity act drive → < Stand still window velocity
			SmPublish(SIG_ACT_BREAK,0,0,0);
			SmPublish(SIG_WHEEL_BRAKE,0,0,0);
		}
    }

    SmState VehicleEnable
	{
		SIG_ENTRY =
		{
			print("SM: VehicleEnable - Entry");
			sprint(printArray, "VehicleEnable, Hardware Time: ", Time(), " ms");
			USER_PARAM(USER_MONITOR_COMMAND) 	= CMD_IDLE;
			USER_PARAM(USR_MONITOR_DSP_STATUS)	= DSP_VEHICLEON;
		}


        SIG_IDLE =
        {
        	if(DI_EMG_STOP_TRAV_1||DI_EMG_STOP_TRAV_2||DI_EMG_STOP_TRAV_3)
        	{
        		return(SmTrans(MotorsOff));
        	}
        	else if(((!(gHomeDone)&&!(gMotorManEnable)))&&(gConfigTyp!=MECH_CONFIG_FOLD))
        	{
        		print("Motor not ready jet - MotorOn after homing");
        		return(SmTrans(->Homing));
        	}
        	else if(gMotorManEnable==1 || gMotorRCEnable ==1)
        	{
        	    print("I am in state machine main");
        		// Application controll On
				DO_APP_CONTROL(1);

				// Wheel drives are sometimes disabled in the applikation (better for rotation)
        		AxisControl(WHEEL_DRIVE_1,ON,WHEEL_DRIVE_2,ON,WHEEL_DRIVE_3,ON);
        		AxisControl(ACTUATING_DRIVE_1,ON,ACTUATING_DRIVE_2,ON,ACTUATING_DRIVE_3,ON);
        		return(SmTrans(->Running->RemoteControl));
        	}
        	/*else if(gMotorManEnable==1 || gMotorRCEnable ==1)
        	{
        	    print("I am in state machine main");
        		// Application controll On
				DO_APP_CONTROL(1);

				// Wheel drives are sometimes disabled in the applikation (better for rotation)
        		AxisControl(WHEEL_DRIVE_1,ON,WHEEL_DRIVE_2,ON,WHEEL_DRIVE_3,ON);
        		AxisControl(ACTUATING_DRIVE_1,ON,ACTUATING_DRIVE_2,ON,ACTUATING_DRIVE_3,ON);
        		return(SmTrans(->Running->RemoteControl));
        	}*/
        }

        SIG_EXIT  =
		{
			SmPublish(SIG_LED_OFF, 0, 0, 0);
			print("SM: VehicleEnable - Exit");
		}

		SIG_CHANGE_CONFIG_1 =
		{
			if (!gFoldingActive)
			{
				USER_PARAM(USER_ERROR_ID) = ERR_CONFIG_CHANGE_1;
			}
		}

		SIG_CHANGE_CONFIG_2 =
		{
			if (!gFoldingActive)
			{
				USER_PARAM(USER_ERROR_ID) = ERR_CONFIG_CHANGE_1;
			}
		}

		SIG_CHANGE_CONFIG_3 =
		{
			if (!gFoldingActive)
			{
				USER_PARAM(USER_ERROR_ID) = ERR_CONFIG_CHANGE_1;
			}
		}

		SIG_CHANGE_CONFIG_4 =
		{
			if (!gFoldingActive)
			{
				USER_PARAM(USER_ERROR_ID) = ERR_CONFIG_CHANGE_1;
			}
		}





		/*
        ** The "Homing" is entered if the homing is not complete jet.
        */
		#include "02_StateMachine_Main_Homing.mh"


        /*
        ** The "Running" state is entered once homing is complete.
        */
        #include "03_StateMachine_Main_Running.mh"

	} // Motors on

} //  ETerryMainState

/*********************************************************************
** State Machine Definitions
*********************************************************************/

SmMachine ETerry { 	SMID_ETERRY,    	// State machine ID.
                    ETerryMainInit,     // Initialization function.
                    ETerryMain, 		// Top-most state.
                    20,             	// Event queue size.
                    ETERRY_DATA}    	// Private data array size.

/*********************************************************************
** State Machine Initialization Functions
*********************************************************************/

long ETerryMainInit(long id, long data[])
{
	print("SM: ETerry init");

	printcontrol(RINGBUF, printArray);

	// set all slaves to PREOPERATIONAL by sending an NMT.
	SYS_PROCESS(SYS_CANOM_MASTERSTATE) = 0;

	setupAnalogInput();
	setup_MiniMACS6_DS402_Slave();

    /*
    ** Set the axis parameters.
    */
	setupActDrive();
	setupWheelDrive();

	// start all slaves commanding them into OPERATIONAL.
	SYS_PROCESS(SYS_CANOM_MASTERSTATE) = 1;

	// Error Handler
    SmSubscribe(ETerry, SIG_ERROR);

    // Command control only if the monitor file is used
	#if CONTROL_METHODE==MONITOR
		SmParam(USER_PARAM_INDEX(USER_MONITOR_COMMAND), CMD_JOYSTICK_BOOST_UP, 		SM_PARAM_EQUAL, ETerry, SIG_JOYSTICK_BOOST_UP);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_COMMAND), CMD_JOYSTICK_BOOST_DOWN,   	SM_PARAM_EQUAL, ETerry, SIG_JOYSTICK_BOOST_DOWN);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_COMMAND), CMD_JOYSTICK_STEERING_LEFT,	SM_PARAM_EQUAL, ETerry, SIG_JOYSTICK_STEERING_LEFT);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_COMMAND), CMD_JOYSTICK_STEERING_RIGHT,SM_PARAM_EQUAL, ETerry, SIG_JOYSTICK_STEERING_RIGHT);

		SmParam(USER_PARAM_INDEX(USER_MONITOR_COMMAND), CMD_MOTOFF,   				SM_PARAM_EQUAL, ETerry, SIG_MOTOR_OFF);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_COMMAND), CMD_VEHICLE_ENB,			SM_PARAM_EQUAL, ETerry, SIG_VEHICLE_ENABLE);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_COMMAND), CMD_HOMING,   				SM_PARAM_EQUAL, ETerry, SIG_HOME);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_COMMAND), CMD_STOP,   				SM_PARAM_EQUAL, ETerry, SIG_STOP);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_COMMAND), CMD_CHANGEVEL,   			SM_PARAM_EQUAL, ETerry, SIG_CHANGEVEL);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_COMMAND), CMD_SAVEVEL,   				SM_PARAM_EQUAL, ETerry, SIG_SAVEVEL);

		SmParam(USER_PARAM_INDEX(USER_MONITOR_REMOTE), REMOTE_ROT_CENTRALPOINT, 	SM_PARAM_MASK , ETerry, SIG_ROT_CENTRALPOINT);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_REMOTE), REMOTE_SLOW_MODE,			SM_PARAM_MASK , ETerry, SIG_SLOW_MODE);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_REMOTE), REMOTE_CURVE_DRIVE,   		SM_PARAM_MASK , ETerry, SIG_CURVE_DRIVE);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_REMOTE), REMOTE_SET_CONST_SPEED,		SM_PARAM_MASK , ETerry, SIG_SET_CONST_SPEED);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_REMOTE), REMOTE_DATA_LOGGING,   		SM_PARAM_MASK , ETerry, SIG_DATA_LOGGING);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_REMOTE), REMOTE_SEMI_AUTO_ON,   		SM_PARAM_MASK , ETerry, SIG_SEMI_AUTO_ON);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_REMOTE), REMOTE_SEMI_AUTO_CURVE, 		SM_PARAM_MASK, ETerry, SIG_SEMI_AUTO_CURVE);

		// Not use at the moment
		//SmParam(USER_PARAM_INDEX(USER_MONITOR_REMOTE), REMOTE_SLEEPMODE,			SM_PARAM_MASK , ETerry, SIG_SLEEPMODE);
		//SmParam(USER_PARAM_INDEX(USER_MONITOR_REMOTE), REMOTE_ERROR_RADIO,		SM_PARAM_MASK , ETerry, SIG_ERROR_RADIO);
		//SmParam(USER_PARAM_INDEX(USER_MONITOR_REMOTE), REMOTE_EXTERNAL_INPUT,		SM_PARAM_MASK , ETerry, SIG_EXTERNAL_INPUT);

		SmParam(USER_PARAM_INDEX(USER_MONITOR_SENSOR), SENS_CONFIGURATION_1,  		SM_PARAM_MASK, ETerry, SIG_CHANGE_CONFIG_1);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_SENSOR), SENS_CONFIGURATION_2,  		SM_PARAM_MASK, ETerry, SIG_CHANGE_CONFIG_2);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_SENSOR), SENS_MANUAL_EBOX_1,  		SM_PARAM_MASK | SM_PARAM_RISING, ETerry, SIG_MANUAL_EBOX_1);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_SENSOR), SENS_MANUAL_EBOX_2,  		SM_PARAM_MASK | SM_PARAM_RISING, ETerry, SIG_MANUAL_EBOX_2);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_SENSOR), SENS_MANUAL_TRAV_3_1,  		SM_PARAM_MASK | SM_PARAM_RISING, ETerry, SIG_MANUAL_TRAV_3_1);
		SmParam(USER_PARAM_INDEX(USER_MONITOR_SENSOR), SENS_MANUAL_TRAV_3_2,  		SM_PARAM_MASK | SM_PARAM_RISING, ETerry, SIG_MANUAL_TRAV_3_2);
	#endif

	SmParam(USER_PARAM_INDEX(USER_ERROR_ID), ERR_NO_ERROR,	SM_PARAM_NOTEQUAL, ETerry, SIG_USER_ERROR);

	// Detecting digital input changes of the RC control

	SmInput(DI_CURVE_DRIVE_NBR,			SM_INPUT_RISING, ETerry, SIG_CURVE_DRIVE);
	SmInput(DI_ROT_CENTRALPOINT_NBR,	SM_INPUT_RISING, ETerry, SIG_ROT_CENTRALPOINT);
	SmInput(DI_SET_CONST_SPEED_NBR,		SM_INPUT_RISING, ETerry, SIG_SET_CONST_SPEED);
	SmInput(DI_DATA_LOGGING_NBR,		SM_INPUT_RISING, ETerry, SIG_DATA_LOGGING);
	SmInput(DI_VEHICLE_ON_NBR,			SM_INPUT_RISING, ETerry, SIG_VEHICLE_ENABLE);
	SmInput(DI_SLOW_MODE_NBR,			SM_INPUT_RISING, ETerry, SIG_SLOW_MODE);
	SmInput(DI_SEMI_AUTO_ON_NBR,		SM_INPUT_CHANGE, ETerry, SIG_SEMI_AUTO_ON);
	SmInput(DI_SEMI_AUTO_CURVE_NBR,		SM_INPUT_CHANGE, ETerry, SIG_SEMI_AUTO_CURVE);

	// Not use at the moment
	//SmInput(DI_SLEEPMODE_NBR,			SM_INPUT_RISING, ETerry, SIG_SLEEPMODE);
	//SmInput(DI_ERROR_RADIO_NBR,			SM_INPUT_FALLING, ETerry,SIG_ERROR_RADIO);
	//SmInput(DI_EXTERNAL_INPUT_NBR,		SM_INPUT_RISING, ETerry, SIG_EXTERNAL_INPUT);

	// Detecting digital input changes of the standard IO's
	#if (CONFIG_RUN_ERROR_ON==1)
		SmInput(DI_CONFIGURATION_1_NBR,			SM_INPUT_CHANGE,  ETerry, SIG_CHANGE_CONFIG_1);
		SmInput(DI_CONFIGURATION_2_NBR,			SM_INPUT_CHANGE,  ETerry, SIG_CHANGE_CONFIG_2);
	#endif

	SmInput(DI_MANUAL_EBOX_1_NBR,					SM_INPUT_RISING,  ETerry, SIG_MANUAL_EBOX_1);
	SmInput(DI_MANUAL_EBOX_2_NBR,					SM_INPUT_RISING,  ETerry, SIG_MANUAL_EBOX_2);
	SmInput(DI_HMI_1_TRAV_1_NBR,		SM_INPUT_RISING,  ETerry, SIG_MANUAL_TRAV_3_1);
	SmInput(DI_HMI_2_TRAV_1_NBR,		SM_INPUT_RISING,  ETerry, SIG_MANUAL_TRAV_3_1);
	//SmInput(DI_HMI_MODE_NBR,		SM_INPUT_CHANGE,  ETerry, SIG_MANUAL_MODE);


	SmInput(DI_EMG_STOP_TRAV_1_NBR,			SM_INPUT_RISING,  ETerry, SIG_EMG_BUTTON);
	SmInput(DI_EMG_STOP_TRAV_2_NBR,			SM_INPUT_RISING,  ETerry, SIG_EMG_BUTTON);
	SmInput(DI_EMG_STOP_TRAV_3_NBR,			SM_INPUT_RISING,  ETerry, SIG_EMG_BUTTON);

	return(SmHandled);
}

/*********************************************************************
** State Machine Functions
*********************************************************************/
long motorManualOn(long id, long signal, long event[], long data[])
{
	if (DI_HMI_1_TRAV_1 && DI_HMI_2_TRAV_1)
	{
		print("ManualControl -> Motor On");
		gMotorManEnable=1;

		return(SmTrans(->CheckConfiguration));
	}
    return(SmHandled);
}
long actBreakManual(long id, long signal, long event[], long data[])
{
	if (DI_MANUAL_EBOX_1 && DI_MANUAL_EBOX_2)
	{
		if(ACT_DRIVE_BREAK_OPEN)
		{
			SmPublish(SIG_ACT_BREAK,0,0,0);
			print("ManualControl -> All BreakClose");
		}
		else
		{
			SmPublish(SIG_ACT_BREAK,1,1,1);
			print("ManualControl -> All BreakOpen");
		}
	}
	else if(DI_MANUAL_EBOX_1)
	{
		if(ACT_DRIVE_1_BREAK_OPEN&&ACT_DRIVE_3_BREAK_OPEN)
		{
			SmPublish(SIG_ACT_BREAK,0,ACT_DRIVE_2_BREAK_STATE,0);
			print("ManualControl -> Trav 1 & 3 BreakClose");
		}
		else if(ACT_DRIVE_1_BREAK_CLOSE&&ACT_DRIVE_3_BREAK_CLOSE)
		{
			SmPublish(SIG_ACT_BREAK,1,ACT_DRIVE_2_BREAK_STATE,1);
			print("ManualControl -> Trav 1 & 3 BreakOpen");
		}

	}
	else if(DI_MANUAL_EBOX_2)
	{
		if(ACT_DRIVE_2_BREAK_OPEN)
		{
			SmPublish(SIG_ACT_BREAK,ACT_DRIVE_1_BREAK_STATE,0,ACT_DRIVE_3_BREAK_STATE);
			print("ManualControl -> Trav 2 BreakClose");
		}
		else if(ACT_DRIVE_2_BREAK_CLOSE)
		{
			SmPublish(SIG_ACT_BREAK,ACT_DRIVE_1_BREAK_STATE,1,ACT_DRIVE_3_BREAK_STATE);
			print("ManualControl -> Trav 2 BreakOpen");
		}

	}
    return(SmHandled);
}

long setSlowMode(long id, long signal, long event[], long data[])
{
	if(! gMotorSlowModeOn)
	{
		print("Slow Mode: On");
		gMotorSlowModeOn=1;
	}
	else
	{
		print("Slow Mode: Off");
		gMotorSlowModeOn=0;
	}
}