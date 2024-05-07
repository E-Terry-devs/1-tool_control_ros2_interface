/*********************************************************************
** StateMachine Wheel Brake
**
** The statemachine for the control of the Brake's is outsourced.
** By means of publish and subscribe the control of a certain
** Brake function is requested from the main state machine.
**
*********************************************************************/

/*********************************************************************
** Local Functions
*********************************************************************/


/*********************************************************************
** State Definitions
*********************************************************************/

//#define WHEEL_BRAKE_PWM_ON

SmState WheelBrake
{
	SIG_WHEEL_BRAKE 		=
	{
		data[WHEEL_BRAKE_PWM_CNT]=0;
		data[WHEEL_BRAKE_1_OPEN]	= event[WHEEL_BRAKE_1];
		data[WHEEL_BRAKE_2_OPEN]	= event[WHEEL_BRAKE_2];
		data[WHEEL_BRAKE_3_OPEN]	= event[WHEEL_BRAKE_3];
		return(SmTrans(->ResetBrake));
	}
	SmState ResetBrake
	{
		SIG_IDLE =
		{
			return(SmTrans(ChangeBrake));
		}
	}
	SmState ChangeBrake
	{

		SIG_ENTRY =
		{
			data[WHEEL_BRAKE_PWM_CNT]=0;
			data[WHEEL_BRAKE_1_PWM] = data[WHEEL_BRAKE_1_OPEN];
			data[WHEEL_BRAKE_2_PWM] = data[WHEEL_BRAKE_2_OPEN];
			data[WHEEL_BRAKE_3_PWM] = data[WHEEL_BRAKE_3_OPEN];




		}
		SIG_IDLE =
		{
			return(SmTrans(->WaitForStandStill));
		}
		SIG_EXIT =
		{
			// Delte Timers

			#ifdef WHEEL_BRAKE_PWM_ON
				SmPeriod(0,id,SIG_WHEEL_BRAKE_PERIOD);
				SmTimer(0, id, SIG_WHEEL_BRAKE_DELAY);
			#endif
			SmTimer(0, id, SIG_WHEEL_BRAKE_REACT_TIME_RISE);
			SmTimer(0, id, SIG_WHEEL_BRAKE_REACT_TIME_FALL);
		}
		SmState WaitForStandStill
		{
			SIG_IDLE =
			{
				if( (data[WHEEL_BRAKE_1_OPEN] || (abs(Avel(WHEEL_DRIVE_1))<WHEEL_BRAKE_STANDSTILL_VEL)) && (data[WHEEL_BRAKE_2_OPEN] || (abs(Avel(WHEEL_DRIVE_2))<WHEEL_BRAKE_STANDSTILL_VEL))&&(data[WHEEL_BRAKE_3_OPEN] || (abs(Avel(WHEEL_DRIVE_3))<WHEEL_BRAKE_STANDSTILL_VEL)))
				{
					return(SmTrans(SetBrakeOutput));
				}
			}
			SIG_EXIT =
			{
				#ifdef WHEEL_BRAKE_PWM_ON
					SmTimer((WHEEL_BRAKE_PWM_DELAY-WHEEL_BRAKE_PERIOD_TIME), id, SIG_WHEEL_BRAKE_DELAY);
				#endif
				SmTimer(WHEEL_BRAKE_REACT_TIME_RISE, id, SIG_WHEEL_BRAKE_REACT_TIME_RISE);
				SmTimer(WHEEL_BRAKE_REACT_TIME_FALL, id, SIG_WHEEL_BRAKE_REACT_TIME_FALL);
			}
		}
		SmState SetBrakeOutput
		{
			SIG_ENTRY =
			{
				if(data[WHEEL_BRAKE_1_OPEN])
				{
					HWAMP_PARAM(WHEEL_DRIVE_1,HWAMP_MAXCUR)	=	WD80_754962_MAXCUR;
				}
				if(data[WHEEL_BRAKE_2_OPEN])
				{
					HWAMP_PARAM(WHEEL_DRIVE_2,HWAMP_MAXCUR)	=	WD80_754962_MAXCUR;
				}
				if(data[WHEEL_BRAKE_3_OPEN])
				{
					HWAMP_PARAM(WHEEL_DRIVE_3,HWAMP_MAXCUR)	=	WD80_754962_MAXCUR;
				}
			}

			SIG_IDLE =
			{
				#ifdef WHEEL_BRAKE_PWM_ON
					if(data[WHEEL_BRAKE_1_OPEN]==1)
						DO_BREAK_WD_DRIVE_1(data[WHEEL_BRAKE_1_PWM]);
					else
						DO_BREAK_WD_DRIVE_1(0);

					if(data[WHEEL_BRAKE_2_OPEN]==1)
						DO_BREAK_WD_DRIVE_2(data[WHEEL_BRAKE_2_PWM]);
					else
						DO_BREAK_WD_DRIVE_2(0);

					if(data[WHEEL_BRAKE_3_OPEN]==1)
						DO_BREAK_WD_DRIVE_3(data[WHEEL_BRAKE_3_PWM]);
					else
						DO_BREAK_WD_DRIVE_3(0);
				#else
					if(data[WHEEL_BRAKE_1_OPEN]==1)
						DO_BREAK_WD_DRIVE_1(1);
					else
						DO_BREAK_WD_DRIVE_1(0);

					if(data[WHEEL_BRAKE_2_OPEN]==1)
						DO_BREAK_WD_DRIVE_2(1);
					else
						DO_BREAK_WD_DRIVE_2(0);

					if(data[WHEEL_BRAKE_3_OPEN]==1)
						DO_BREAK_WD_DRIVE_3(1);
					else
						DO_BREAK_WD_DRIVE_3(0);
				#endif
			}//WD80_754962_CURBRAKE
			SIG_EXIT =
			{
				#ifdef WHEEL_BRAKE_PWM_ON
					// Defined Output
					if(data[WHEEL_BRAKE_1_OPEN]==1)
						DO_BREAK_WD_DRIVE_1(1);
					if(data[WHEEL_BRAKE_2_OPEN]==1)
						DO_BREAK_WD_DRIVE_2(1);
					if(data[WHEEL_BRA KE_3_OPEN]==1)
						DO_BREAK_WD_DRIVE_3(1);
				#endif

			}
		}
		#ifdef WHEEL_BRAKE_PWM_ON
		SIG_WHEEL_BRAKE_DELAY =
		{
			SmPeriod((WHEEL_BRAKE_PERIOD_TIME/WHEEL_BRAKE_CYCLE),id,SIG_WHEEL_BRAKE_PERIOD);
			print("Brake Wheel Drive - Start PWM" );
		}
		#endif
		SIG_WHEEL_BRAKE_REACT_TIME_FALL =
		{
			if(data[WHEEL_BRAKE_1_OPEN])
			{
				print("Brake Wheel Drive 1 - Open" );
				HWAMP_PARAM(WHEEL_DRIVE_1,HWAMP_MAXCUR)	=	WD80_754962_MAXCUR;
				gWheelBrakeOpen[0]=1;
			}
			if(data[WHEEL_BRAKE_2_OPEN])
			{
				print("Brake Wheel Drive 2 - Open" );
				HWAMP_PARAM(WHEEL_DRIVE_2,HWAMP_MAXCUR)	=	WD80_754962_MAXCUR;
				gWheelBrakeOpen[1]=1;
			}
			if(data[WHEEL_BRAKE_3_OPEN])
			{
				print("Brake Wheel Drive 3 - Open" );
				HWAMP_PARAM(WHEEL_DRIVE_3,HWAMP_MAXCUR)	=	WD80_754962_MAXCUR;
				gWheelBrakeOpen[2]=1;
			}
		}
		SIG_WHEEL_BRAKE_REACT_TIME_RISE =
		{
			if(data[WHEEL_BRAKE_1_OPEN]==0)
			{
				print("Brake Wheel Drive 1 - Close"  );
				HWAMP_PARAM(WHEEL_DRIVE_1,HWAMP_MAXCUR)	=	WD80_754962_CURBRAKE;
				gWheelBrakeOpen[0]=0;
			}
			if(data[WHEEL_BRAKE_2_OPEN]==0)
			{
				print("Brake Wheel Drive 2 - Close");
				HWAMP_PARAM(WHEEL_DRIVE_2,HWAMP_MAXCUR)	=	WD80_754962_CURBRAKE;
				gWheelBrakeOpen[1]=0;
			}
			if(data[WHEEL_BRAKE_3_OPEN]==0)
			{
				print("Brake Wheel Drive 3 - Close");
				HWAMP_PARAM(WHEEL_DRIVE_3,HWAMP_MAXCUR)	=	WD80_754962_CURBRAKE;
				gWheelBrakeOpen[2]=0;
			}
		}
		#ifdef WHEEL_BRAKE_PWM_ON
		SIG_WHEEL_BRAKE_PERIOD =
		{
			if(data[WHEEL_BRAKE_PWM_CNT]<=WHEEL_BRAKE_CYCLE_ON)
			{
				data[WHEEL_BRAKE_1_PWM]	=1;
				data[WHEEL_BRAKE_2_PWM]	=1;
				data[WHEEL_BRAKE_3_PWM]	=1;
			}
			else
			{
				data[WHEEL_BRAKE_1_PWM]	=0;
				data[WHEEL_BRAKE_2_PWM]	=0;
				data[WHEEL_BRAKE_3_PWM]	=0;
			}

			if(data[WHEEL_BRAKE_PWM_CNT]<WHEEL_BRAKE_CYCLE)
			{
				data[WHEEL_BRAKE_PWM_CNT]++;
			}
			else
			{
				data[WHEEL_BRAKE_PWM_CNT]=1;
			}
		}
		#endif
	}
} //  WheelBrake

/*********************************************************************
** State Machine Definitions
*********************************************************************/

SmMachine WheelBrakeControl { 		SMID_WDBREAK, 				// State machine ID.
                    					WheelBrakeInit,   		// Initialization function.
                    					WheelBrake, 			// Top-most state.
                    					5,             				// Event queue size.
                    					WHEEL_BRAKE_DATA}    				// Private data array size.

/*********************************************************************
** State Machine Initialization Functions
*********************************************************************/

long WheelBrakeInit(long id, long data[])
{
	SmSubscribe(id,SIG_WHEEL_BRAKE);

	return(0);
}

/*********************************************************************
** State Machine Functions
*********************************************************************/


/*********************************************************************
** Local Functions
*********************************************************************/

