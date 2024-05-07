/*********************************************************************
** StateMachine Actuatin Break
**
** The statemachine for the control of the Break's is outsourced.
** By means of publish and subscribe the control of a certain
** Break function is requested from the main state machine.
**
*********************************************************************/

/*********************************************************************
** Local Functions
*********************************************************************/


/*********************************************************************
** State Definitions
*********************************************************************/

//#define ACT_BREAK_PWM_ON

SmState ActuatingBreak
{
	SIG_ACT_BREAK 		=
	{
		data[ACT_BREAK_PWM_CNT]=0;
		data[ACT_BREAK_1_OPEN]	= event[ACT_BREAK_1];
		data[ACT_BREAK_2_OPEN]	= event[ACT_BREAK_2];
		data[ACT_BREAK_3_OPEN]	= event[ACT_BREAK_3];
		return(SmTrans(->ResetBreak));
	}
	SmState ResetBreak
	{
		SIG_IDLE =
		{
			return(SmTrans(ChangeBreak));
		}
	}
	SmState ChangeBreak
	{

		SIG_ENTRY =
		{
			data[ACT_BREAK_PWM_CNT]=0;
			data[ACT_BREAK_1_PWM] = data[ACT_BREAK_1_OPEN];
			data[ACT_BREAK_2_PWM] = data[ACT_BREAK_2_OPEN];
			data[ACT_BREAK_3_PWM] = data[ACT_BREAK_3_OPEN];




		}
		SIG_IDLE =
		{
			return(SmTrans(->WaitForStandStill));
		}
		SIG_EXIT =
		{
			// Delte Timers

			#ifdef ACT_BREAK_PWM_ON
				SmPeriod(0,id,SIG_ACT_BREAK_PERIOD);
				SmTimer(0, id, SIG_ACT_BREAK_DELAY);
			#endif
			SmTimer(0, id, SIG_ACT_BREAK_REACT_TIME_RISE);
			SmTimer(0, id, SIG_ACT_BREAK_REACT_TIME_FALL);
		}
		SmState WaitForStandStill
		{
			SIG_IDLE =
			{
				if( (data[ACT_BREAK_1_OPEN] || (abs(Avel(ACTUATING_DRIVE_1))<ACT_BREAK_STANDSTILL_VEL)) && (data[ACT_BREAK_2_OPEN] || (abs(Avel(ACTUATING_DRIVE_2))<ACT_BREAK_STANDSTILL_VEL))&&(data[ACT_BREAK_3_OPEN] || (abs(Avel(ACTUATING_DRIVE_3))<ACT_BREAK_STANDSTILL_VEL)))
				{
					return(SmTrans(SetBreakOutput));
				}
			}
			SIG_EXIT =
			{
				#ifdef ACT_BREAK_PWM_ON
					SmTimer((ACT_BREAK_PWM_DELAY-ACT_BREAK_PERIOD_TIME), id, SIG_ACT_BREAK_DELAY);
				#endif
				SmTimer(ACT_BREAK_REACT_TIME_RISE, id, SIG_ACT_BREAK_REACT_TIME_RISE);
				SmTimer(ACT_BREAK_REACT_TIME_FALL, id, SIG_ACT_BREAK_REACT_TIME_FALL);
			}
		}
		SmState SetBreakOutput
		{
			SIG_ENTRY =
			{
				if(data[ACT_BREAK_1_OPEN])
				{
					HWAMP_PARAM(ACTUATING_DRIVE_1,HWAMP_MAXCUR)	=	IDX56M_B7CFC7F7E927_MAXCUR;
				}
				if(data[ACT_BREAK_2_OPEN])
				{
					HWAMP_PARAM(ACTUATING_DRIVE_2,HWAMP_MAXCUR)	=	IDX56M_B7CFC7F7E927_MAXCUR;
				}
				if(data[ACT_BREAK_3_OPEN])
				{
					HWAMP_PARAM(ACTUATING_DRIVE_3,HWAMP_MAXCUR)	=	IDX56M_B7CFC7F7E927_MAXCUR;
				}
			}

			SIG_IDLE =
			{
				#ifdef ACT_BREAK_PWM_ON
					if(data[ACT_BREAK_1_OPEN]==1)
						DO_BREAK_ACT_DRIVE_1(data[ACT_BREAK_1_PWM]);
					else
						DO_BREAK_ACT_DRIVE_1(0);

					if(data[ACT_BREAK_2_OPEN]==1)
						DO_BREAK_ACT_DRIVE_2(data[ACT_BREAK_2_PWM]);
					else
						DO_BREAK_ACT_DRIVE_2(0);

					if(data[ACT_BREAK_3_OPEN]==1)
						DO_BREAK_ACT_DRIVE_3(data[ACT_BREAK_3_PWM]);
					else
						DO_BREAK_ACT_DRIVE_3(0);
				#else
					if(data[ACT_BREAK_1_OPEN]==1)
						DO_BREAK_ACT_DRIVE_1(1);
					else
						DO_BREAK_ACT_DRIVE_1(0);

					if(data[ACT_BREAK_2_OPEN]==1)
						DO_BREAK_ACT_DRIVE_2(1);
					else
						DO_BREAK_ACT_DRIVE_2(0);

					if(data[ACT_BREAK_3_OPEN]==1)
						DO_BREAK_ACT_DRIVE_3(1);
					else
						DO_BREAK_ACT_DRIVE_3(0);
				#endif
			}//IDX56M_B7CFC7F7E927_CURBREAK
			SIG_EXIT =
			{
				#ifdef ACT_BREAK_PWM_ON
					// Defined Output
					if(data[ACT_BREAK_1_OPEN]==1)
						DO_BREAK_ACT_DRIVE_1(1);
					if(data[ACT_BREAK_2_OPEN]==1)
						DO_BREAK_ACT_DRIVE_2(1);
					if(data[ACT_BREAK_3_OPEN]==1)
						DO_BREAK_ACT_DRIVE_3(1);
				#endif

			}
		}
		#ifdef ACT_BREAK_PWM_ON
		SIG_ACT_BREAK_DELAY =
		{
			SmPeriod((ACT_BREAK_PERIOD_TIME/ACT_BREAK_CYCLE),id,SIG_ACT_BREAK_PERIOD);
			print("Break Actuating Drive - Start PWM" );
		}
		#endif
		SIG_ACT_BREAK_REACT_TIME_FALL =
		{
			if(data[ACT_BREAK_1_OPEN])
			{
				print("Break Actuating Drive 1 - Open" );
				HWAMP_PARAM(ACTUATING_DRIVE_1,HWAMP_MAXCUR)	=	IDX56M_B7CFC7F7E927_MAXCUR;
				gActBreakOpen[0]=1;
			}
			if(data[ACT_BREAK_2_OPEN])
			{
				print("Break Actuating Drive 2 - Open" );
				HWAMP_PARAM(ACTUATING_DRIVE_2,HWAMP_MAXCUR)	=	IDX56M_B7CFC7F7E927_MAXCUR;
				gActBreakOpen[1]=1;
			}
			if(data[ACT_BREAK_3_OPEN])
			{
				print("Break Actuating Drive 3 - Open" );
				HWAMP_PARAM(ACTUATING_DRIVE_3,HWAMP_MAXCUR)	=	IDX56M_B7CFC7F7E927_MAXCUR;
				gActBreakOpen[2]=1;
			}
		}
		SIG_ACT_BREAK_REACT_TIME_RISE =
		{
			if(data[ACT_BREAK_1_OPEN]==0)
			{
				print("Break Actuating Drive 1 - Close"  );
				HWAMP_PARAM(ACTUATING_DRIVE_1,HWAMP_MAXCUR)	=	IDX56M_B7CFC7F7E927_CURBREAK;
				gActBreakOpen[0]=0;
			}
			if(data[ACT_BREAK_2_OPEN]==0)
			{
				print("Break Actuating Drive 2 - Close");
				HWAMP_PARAM(ACTUATING_DRIVE_2,HWAMP_MAXCUR)	=	IDX56M_B7CFC7F7E927_CURBREAK;
				gActBreakOpen[1]=0;
			}
			if(data[ACT_BREAK_3_OPEN]==0)
			{
				print("Break Actuating Drive 3 - Close");
				HWAMP_PARAM(ACTUATING_DRIVE_3,HWAMP_MAXCUR)	=	IDX56M_B7CFC7F7E927_CURBREAK;
				gActBreakOpen[2]=0;
			}
		}
		#ifdef ACT_BREAK_PWM_ON
		SIG_ACT_BREAK_PERIOD =
		{
			if(data[ACT_BREAK_PWM_CNT]<=ACT_BREAK_CYCLE_ON)
			{
				data[ACT_BREAK_1_PWM]	=1;
				data[ACT_BREAK_2_PWM]	=1;
				data[ACT_BREAK_3_PWM]	=1;
			}
			else
			{
				data[ACT_BREAK_1_PWM]	=0;
				data[ACT_BREAK_2_PWM]	=0;
				data[ACT_BREAK_3_PWM]	=0;
			}

			if(data[ACT_BREAK_PWM_CNT]<ACT_BREAK_CYCLE)
			{
				data[ACT_BREAK_PWM_CNT]++;
			}
			else
			{
				data[ACT_BREAK_PWM_CNT]=1;
			}
		}
		#endif
	}
} //  ActuatingBreak

/*********************************************************************
** State Machine Definitions
*********************************************************************/

SmMachine ActuatingBreakControl { 		SMID_ACTBREAK, 				// State machine ID.
                    					ActuatingBreakInit,   		// Initialization function.
                    					ActuatingBreak, 			// Top-most state.
                    					5,             				// Event queue size.
                    					ACT_BREAK_DATA}    				// Private data array size.

/*********************************************************************
** State Machine Initialization Functions
*********************************************************************/

long ActuatingBreakInit(long id, long data[])
{
	SmSubscribe(id,SIG_ACT_BREAK);

	return(0);
}

/*********************************************************************
** State Machine Functions
*********************************************************************/


/*********************************************************************
** Local Functions
*********************************************************************/

