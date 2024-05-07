/*********************************************************************
** StateMachine LED
**
** The statemachine for the control of the LED's is outsourced.
** By means of publish and subscribe the control of a certain
** LED function is requested from the main state machine.
**
*********************************************************************/

/*********************************************************************
** Local Functions
*********************************************************************/


/*********************************************************************
** State Definitions
*********************************************************************/

SmState LedControl
{
	long led[3],ledActive[3],ledPeriod,k;
	SIG_LED_ON 		=
	{
		ledPeriod	= event[LED_PERIOD];
		ledActive[0]= event[LED_1];
		ledActive[1]= event[LED_2];
		ledActive[2]= event[LED_3];
		print("LED Period :",ledPeriod);

		return(SmTrans(->LedOn));
	}

	SIG_LED_OFF 	= SmTrans(->LedOff);

	SIG_LED_FLOW_LEFT	=
	{
		ledPeriod=event[LED_PERIOD];
		return(SmTrans(->LedFlowLeft));
	}

	SIG_LED_FLOW_RIGHT	=
	{
		ledPeriod= event[LED_PERIOD];
		return(SmTrans(->LedFlowRight));
	}

	SmState LedOff
	{
		SIG_ENTRY =
		{
			DO_LED_TRAV_1(0);
			DO_LED_TRAV_2(0);
			DO_LED_TRAV_3(0);

		}
	}


	SmState LedOn
	{
		SIG_ENTRY =
		{
			for(k=0;k<3;k++)
			{
				led[k] = ledActive[k];
			}
			print("LED Period :",ledPeriod);
			SmPeriod(ledPeriod,id,SIG_LED_PERIOD);
		}
		SIG_IDLE =
		{
			if(ledActive[0]) DO_LED_TRAV_1(led[0]);
			if(ledActive[1]) DO_LED_TRAV_2(led[1]);
			if(ledActive[2]) DO_LED_TRAV_3(led[2]);


		}
		SIG_LED_PERIOD =
		{
			for(k=0;k<3;k++)
			{
				led[k] = !led[k];
			}
		}
		SIG_LED_ON 		=
		{
			ledPeriod	= event[LED_PERIOD];
			ledActive[0]= event[LED_1];
			ledActive[1]= event[LED_2];
			ledActive[2]= event[LED_3];
			for(k=0;k<3;k++)
			{
				led[k] = ledActive[k];
			}
			DO_LED_TRAV_1(led[0]);
			DO_LED_TRAV_2(led[1]);
			DO_LED_TRAV_3(led[2]);
			print("LED Period :",ledPeriod);
			SmPeriod(ledPeriod,id,SIG_LED_PERIOD);		
			}



		SIG_EXIT =
		{
			DO_LED_TRAV_1(0);
			DO_LED_TRAV_2(0);
			DO_LED_TRAV_3(0);
			SmPeriod(0,id,SIG_LED_PERIOD);
		}
	}
	SmState LedFlowLeft
	{
		SIG_ENTRY =
		{
			for(k=0;k<3;k++)
			{
				led[k] = 0;
			}
			led[1]=1;
			SmPeriod(ledPeriod,id,SIG_LED_PERIOD);

		}
		SIG_IDLE =
		{
			DO_LED_TRAV_1(led[0]);
			DO_LED_TRAV_2(led[1]);
			DO_LED_TRAV_3(led[2]);
		}
		SIG_LED_PERIOD =
		{
			if(led[1]==1){led[1]=0;led[0]=1;}
			else if(led[0]==1){led[0]=0;led[2]=1;}
			else if(led[2]==1){led[2]=0;led[1]=1;}
		}
		SIG_EXIT =
		{
			DO_LED_TRAV_1(0);
			DO_LED_TRAV_2(0);
			DO_LED_TRAV_3(0);
			SmPeriod(0,id,SIG_LED_PERIOD);
		}
	}
	SmState LedFlowRight
	{
	SIG_ENTRY =
		{
			for(k=0;k<3;k++)
			{
				led[k] = 0;
			}
			led[1]=1;
			SmPeriod(ledPeriod,id,SIG_LED_PERIOD);

		}
		SIG_IDLE =
		{
			DO_LED_TRAV_1(led[0]);
			DO_LED_TRAV_2(led[1]);
			DO_LED_TRAV_3(led[2]);
		}
		SIG_LED_PERIOD =
		{

			if(led[1]==1){led[1]=0;led[2]=1;}
			else if(led[2]==1){led[2]=0;led[0]=1;}
			else if(led[0]==1){led[0]=0;led[1]=1;}
		}
		SIG_EXIT =
		{
			DO_LED_TRAV_1(0);
			DO_LED_TRAV_2(0);
			DO_LED_TRAV_3(0);
			SmPeriod(0,id,SIG_LED_PERIOD);
		}
	}

} //  LedControl

/*********************************************************************
** State Machine Definitions
*********************************************************************/

SmMachine LedControl { 		SMID_LEDCONTROL, 		// State machine ID.
                    		LedControlInit,   		// Initialization function.
                    		LedControl, 			// Top-most state.
                    		5,             			// Event queue size.
                    		LED_DATA}    			// Private data array size.

/*********************************************************************
** State Machine Initialization Functions
*********************************************************************/

long LedControlInit(long id, long data[])
{
	SmSubscribe(id,SIG_LED_ON);
	SmSubscribe(id,SIG_LED_OFF);
	SmSubscribe(id,SIG_LED_FLOW_LEFT);
	SmSubscribe(id,SIG_LED_FLOW_RIGHT);

	return(0);
}

/*********************************************************************
** State Machine Functions
*********************************************************************/


/*********************************************************************
** Local Functions
*********************************************************************/

