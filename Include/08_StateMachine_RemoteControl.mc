/////////////////////////////////////////////////////////////////////////////////////////////
//
// Test for plain Ethernet Communication
//


/**
*	RC inputs mapping


1.	Joystick Boost Forward AN
2.	Joystick Boost Backward AN
3.	Joystick steer left AN
4.	Joystick steer right AN
5.	Vehicle On
6.	Sleep Mode DI
7.	Curve Drive DI
8.	Rotation Centre point DI
9.	Set Constant Speed
10.	Slow Mode
11.	Invert Mode
12.	Semi Auto On
13.	Semi auto Curve
14.	Ebox1
15.	Ebox2
16. Idle
17. Motor Off
18.Vehicle enable
19. Homing
20. Stop
21. Change velpcity
22. Save velocity
**/
////////////////////////////////////////////////////////////////////////////////////////////


//#include <SysDef.mh>

#define MY_PORT_NUM       8080

void EthernetSendData(void);
void FunctionEthernetHandler(void);


//////////////////////////////////////////////////////////////
/*#pragma SmConfig { SM_RUN_DELAY | SM_RUN_DELDISABLE,    // Runtime flags.
                   10,                                  // Event pool size.
                    2,                                  // Maximum number of timers.
                   10,                                  // Subscribe pool size.
                   50,                                  // Parameter pool size.
                    0,                                  // Position pool size.
                    5 }                                 // System signal pool size.
					*/


//Event
//SmEvent SIG_ETH_RECEIVE {handle}
//SmEvent SIG_PERIOD {}
//SmEvent SIG_TIMER {}


// global variables
long server_handle ;
long array[50];
long length = 45;
long old_time;
long status;



///////////////////////////////////////////////////////////////////
SmState EhternetHandling {

	SIG_ETHERNET_INIT = SmTrans(->DO_EthernetHandling);
	SIG_ETH_RECEIVE = {
	                   print("SIG_ETH_RECEIVE");
	                   FunctionEthernetHandler();

	                 }


	SIG_TIMER = {
					 print("SIG_TIMER :    delete  Ethernet Event ! ");
					 SmSystem(DELETE, ETHERNET, server_handle, id, SIG_ETH_RECEIVE);
	             }


	SIG_PERIOD = {status = EthernetGetConnectionStatus(server_handle);
	              print("SIG_PERIOD :   SOCK_STATUS: ",status);
	              if (status == 3) {
	                //EthernetSendData();
	              }
	              return(SmHandled);
	             }

	SmState DO_EthernetHandling   {

		SIG_ENTRY = {
						print("SIG_ENTRY   EhternetHandling");
					}


		SIG_IDLE = {

				   }


		SIG_EXIT = {
					SmSystem(DELETE, ETHERNET, server_handle, id, SIG_ETH_RECEIVE);
		}
    }  // DO_EthernetHandling

}  // EhternetHandling


//////////////////////////////////////////////////////////////////////////////
SmMachine Sm_Ethernet { SMID_REMOTECONTROL,           // State machine ID.
				   EthernetInit,           // Initialization function.
				   EhternetHandling,        // Top-most state.
				   20,          // Event queue size.
				   1 }          // Private data array size.

//////////////////////////////////////////////////////////////////////////////
/*long main(void)
{

    ErrorClear();

    // First we do a test without Statemachine Syntax
    print("EthernetOpenServer with port: ",MY_PORT_NUM);
    server_handle = EthernetOpenServer(PROT_TCP, MY_PORT_NUM);
    print(" returned handler 'server_handle' : ",server_handle);

    // Now we do the test for receiving Ethernet Telegram within the State Machine Syntax

    //SmRun(Sm_Ethernet);


    return(0);
}*/

/*********************************************************************
** State Machine Initialization Functions
*********************************************************************/

long EthernetInit(long id, long data[])
{

	// First we do a test without Statemachine Syntax
	print("EthernetOpenServer with port: ",MY_PORT_NUM);
	server_handle = EthernetOpenServer(PROT_TCP, MY_PORT_NUM);
	print(" returned handler 'server_handle' : ",server_handle);


	SmSystem (ETHERNET, server_handle, id, SIG_ETH_RECEIVE);
	//SmTimer(90000, id, SIG_TIMER);
	return(SmHandled);
}


////////////////////////////////////////////////////////
void EthernetSendData(void)
{
	long result , i;
	long array[30];

	for (i= 0; i < (30-1); i++) {
       array[i] = 2*i;
    }

	print("we send a Ethernet Telegram at time: ", Time());
    result = EthernetSendTelegram(handle, array, length);
    print("Send Telegramm result : ",result);

    return;
}



////////////////////////////////////////////////////////
void FunctionEthernetHandler(void)
{
	long result;
	long receiveArray[50];
	wchar sendResponse[]="sendResponse";
	long a[50]; // Set max size according to your needs
	long i, x, k;

    arrayset(receiveArray,0,result);

    result = EthernetReceiveTelegram(handle, receiveArray);
    print("\nwe received a Ethernet Telegram at time: ", Time());
    print("num of received data: ",result);
	print("receiveArray: ", receiveArray);

	 k = 0;
	 for (i = 0; i < result; i++)
	 {
	  x = 0;
	   while (receiveArray[i] != ',' && i < result)
	   {

	   	 if (receiveArray[i] == '[' || receiveArray[i] == ']' || receiveArray[i] == ' ')
	   	 {
	   	 	i++;
	   	 }else
	   	 {
		 	x = x * 10 + (receiveArray[i] - '0'); // s[i]-'0' to get digit
		 	i++;
		 }                	// Eg:- s[i]='2' so ASCII value of 2 is 50
	   }                     // ASCII value of '0' is 48
	   a[k] = x;             // s[i]-'0' => 50 - 48 = 2
	   k++;
	 }
	 switch(a[0])
	 {
	    case 1:
	 		gAngleMonitor = (double)a[1]/10* -1;
	 		//print("right ", gAngleMonitor);
	 		break;
	 	case 2:
	 		gAngleMonitor = (double)a[1]/10;
	 		//print("left ", gAngleMonitor);
	 		break;
	 	case 3:
	    	gVelocityMonitor = (double)a[1]/10 * -1;
	 		//print("backward", gVelocityMonitor);
	 		break;
	 	case 4:
			gVelocityMonitor = (double)a[1]/10;
			//print("forward", gVelocityMonitor);
	 		break;
	 	case 5://vehicleOn
			USER_PARAM(USER_MONITOR_REMOTE).i[5] = a[1];
			//print(" vehicle on ", vehicleOn);
	 		break;
	 	case 6://sleepMode
	 		//print("sleepMode ", sleepMode);
	 		break;
	 	case 7://curveDrive
			USER_PARAM(USER_MONITOR_REMOTE).i[6] = a[1];
	 		//print("CurveDrive ", curveDrive);
	 		break;
	 	case 8://rotCentralPoint
			USER_PARAM(USER_MONITOR_REMOTE).i[1] = a[1];
	 		//print("received value ", rotCentralPoint);
	 		break;
	 	case 9://setConstSpeed
			USER_PARAM(USER_MONITOR_REMOTE).i[3] = a[1];
	 		//print("received value ", setConstSpeed);
	 		break;
	 	case 10://slowMode
			USER_PARAM(USER_MONITOR_REMOTE).i[2] = a[1];
	 		//print("slowMode ", a[1]);
	 		break;
	 	case 11: //invertMode
			USER_PARAM(USER_MONITOR_REMOTE).i[0] = a[1];
	 		print("invertMode ", a[1]);
	 		break;
	 	case 12: //semiAutoOn
			USER_PARAM(USER_MONITOR_REMOTE).i[7] = a[1];
	 		//print("semiAutoOn ", a[1]);
	 		break;
	 	case 13://semiAutoCurve
			USER_PARAM(USER_MONITOR_REMOTE).i[8] = a[1];
	 		//print("semiAutoCurve ", semiAutoCurve);
	 		break;
		case 14://eBox1
	 		//print("ebox1 ", eBox1);
	 		break;
	 	case 15://eBox2
	 		//print("ebox ", eBox2);
	 		break;
	 	case 16://idle
			if(a[1] == 1)
			{
				USER_PARAM(USER_MONITOR_COMMAND) = CMD_IDLE;
			}
	 		//print("received value ", idle);
	 		break;
	 	case 17://motOff
			if(a[1] == 1)
			{
				USER_PARAM(USER_MONITOR_COMMAND) = CMD_MOTOFF;
			}
	 		//print("received value ", motOff);
	 		break;
	 	case 18://vehicleEnable
			if(a[1] == 1)
			{
				USER_PARAM(USER_MONITOR_COMMAND) = CMD_VEHICLE_ENB;
			}
	 		//print("slowMode ", vehicleEnable);
	 		break;
	 	case 19://homing
			if(a[1] == 1)
			{
				USER_PARAM(USER_MONITOR_COMMAND) = CMD_HOMING;
			}
	 		//print("invertMode ", homing);
	 		break;
	 	case 20://stop
			if(a[1] == 1)
			{
				USER_PARAM(USER_MONITOR_COMMAND) = CMD_STOP;
			}
	 		//print("semiAutoOn ", stop);
	 		break;
	 	case 21://chanegVel
			if(a[1] == 1)
			{
				USER_PARAM(USER_MONITOR_COMMAND) = CMD_CHANGEVEL;
			}
	 		//print("semiAutoCurve ", chanegVel);
	 		break;
		case 22://saveVel
			if(a[1] == 1)
			{
				USER_PARAM(USER_MONITOR_COMMAND) = CMD_SAVEVEL;
			}
	 		//print("semiAutoCurve ", saveVel);
	 		break;
	 	}


    return;
}
