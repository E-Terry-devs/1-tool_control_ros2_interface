/*********************************************************************
**
**                  Aposs DS402 CanOpen State Machine
**                  ---------------------------------
**
** Copyright zub machine control AG
** switzerland
** 2012
*/
// Application version
#define APP_SW_VERSION_1        3
#define APP_SW_VERSION_2        00
#define APP_SW_VERSION_3        03

/*********************************************************************
** DIM Statements
**
** If used, DIM statements must go here.
*********************************************************************/
// long dim test[100]

/*********************************************************************
** General Defines
*********************************************************************/
// 0 = enable demonstration, 1 = enable custom configuration
#define ENABLE_CUSTOM_CONFIG	1
// Also see the include file in the subprogram section.

// Note: CanOpenStatemachine implements an SIG ERROR subroutine.  Hence,
//       users must NOT define an error subroutine of their own.  If a
//       user-specific function must be called within the error subroutine,
//       then the corresponding macro in the "Config" include file must be
//       defined.

#include <Sysdef.mh>
#include "Slave\Zub_Includes\CosStandardDefines.mh" 		// Standard CanOpen State Machine defines.

#if (ENABLE_CUSTOM_CONFIG)
	#include "Slave\Custom_Includes\CanOpenConfig.mh"      		// This is an application-specific configuration file which can be modified by the user.
	#include "Slave\Custom_Includes\CanOpenDefines.mh"     		// This is an application-specific configuration file which can be modified by the user.
#else
	#include "Slave\Zub_Includes\Demonstration\CanOpenConfig6axDemo.mh"      	// This is an application-specific configuration file for demostration
	#include "Slave\Zub_Includes\Demonstration\CanOpenDefinesDemo.mh"     	// This is an application-specific configuration file for demostration
#endif

/*********************************************************************
** Private Data Array Indices
*********************************************************************/
#define DATA_OldCommand         0  // Previous command.     Private value used by CanOpenGetCommand().
#define DATA_OldOpMode          1  // Previous Op Mode.     Private value used by CanOpenGetCommand().
#define DATA_AppCommandCounter  2  // Command counter.      Private value used by CanOpenGetCommand().
#define DATA_OldStatus          3  // Previous StatusWord.  Private value used by CanOpenSetStatus().
#define DATA_State              4  // Current state.
#define DATA_StatusWord         5  // Local copy of actual StatusWord.
#define DATA_HomeMode           6  // Type of home mode currently active.
#define DATA_HomeState          8  // Type of home mode currently active.
#define DATA_HomeStateOld       9  // Type of home mode currently active.
#define DATA_HomeStartTime      10  // Time at which homing operation started.
#define DATA_HomeDone           11  // Result of homing: 0 - Active (in progress), 1 - Done, -1 - Error.
#define DATA_HomeReversed       12  // Home search has been reversed: FALSE - No, TRUE - Yes.
#define DATA_HomeIpos           13
#define DATA_WaitForPosErr      14  // Wait for a position error: FALSE - No, TRUE - Yes.
#define DATA_PosDirection       15  // direction of actual positioning
#define DATA_SlaveTargetPos     16  // last target position of a move command (absolute)
#define DATA_PosCmdEdges        17  // positive edges in command word
#define DATA_NegCmdEdges        18  // negative edges in command word
#define DATA_ErrorNumber        19  // active error number
#define DATA_CSxOldRampType		20	// Ramp type which was configured before cycle mode
#define DATA_CSxOldHwampMode	21	// The HWAMP mode must be switched between csp and csv mode
#define DATA_CSxOldPoserr		22	// The POSERR must be temporrary disabled for some modes
#define ZBCOS_PRIVATE_CNT       23  // Length of private data array.

/*********************************************************************
** State Machine Setup Parameters
*********************************************************************/
#pragma SmConfig { SM_RUN_DELDISABLE||SM_RUN_DELAY,     // Runtime flags
                   200,          // Event pool size.
                   20,          // Maximum number of timers.
                   10,          // subscribe records size
                   10,          // parameter pool size
                   10,         // position pool size
                   10 }         // system pool size

/*********************************************************************
** Event Definitions
*********************************************************************/

SmEvent SIG_SHUTDOWN        { }
SmEvent SIG_SWITCHON        { EVENT_COMMAND}
SmEvent SIG_ENABLEOPERATION { EVENT_COMMAND}
SmEvent SIG_DISABLEVOLTAGE  { EVENT_COMMAND}
SmEvent SIG_MODECHANGED     { }
SmEvent SIG_QUICKSTOP       { }
SmEvent SIG_FAULTRESET      { }
SmEvent SIG_INVALIDCOMMAND  { EVENT_COMMAND }
SmEvent SIG_FAULT           { EVENT_ERROR }
SmEvent SIG_HALT            { }
SmEvent SIG_NOHALT          { }
SmEvent SIG_OP_START        { }
SmEvent SIG_OP_NOSTART      { }
SmEvent SIG_COMPLETE        { }
SmEvent SIG_NEWSETPOINT     { }
SmEvent SIG_NEWSETPOINT_LOW { }
SmEvent SIG_TARGETREACHED   { }

long CanOpenError(long id, long event, long data[]);
long running_time = 1500;
long pre_running_time = 0;
long reset_flag_counter = 3;

/*********************************************************************
** State Definitions
*********************************************************************/

SmState CanOpen
    {
      SIG_INIT  =   {
                        USER_PARAM(4) = 0;
                        if (! CanOpenSelfTest(id) == 0) { Exit(0); }

                        data[DATA_State]      = STATE_S_NOTREADYTOSWITCHON;
                        data[DATA_StatusWord] = 0;
                        SmSubscribe(id, SIG_ERROR);
                        return(SmTrans(->SwitchOnDisabled)); // Transition 1 (automatic) after communication is active.
                    }

      SIG_START =   { CanOpenGetCommand(id, data); }
      SIG_IDLE  =   { CanOpenSetStatus(id, data);  }
      SIG_FAULT =   { data[DATA_ErrorNumber] = event[EVENT_ERROR];
                      return(SmTrans(->Fault));                       // Transition 13-14 both in one because we are already in power off
                    }
      SIG_ERROR =   {
                       CanOpenError(id,event[EVENT_ERROR],data);
                       return(SmHandled);
                    }

      SIG_INVALIDCOMMAND = { print("Axis ",id,": Invalid command received and discarded: ",event[EVENT_COMMAND]); }

      SmState SwitchOnDisabled
          {
          SIG_ENTRY    = {
                         print("Axis ",id,": Enter state SwitchOnDisabled");
                         data[DATA_State]      = STATE_S_SWITCHONDISABLED;
                         data[DATA_StatusWord] = ZBCOS_STW_SWITCHONDIS | (data[DATA_StatusWord] & ZBCOS_STW_EXTMASK);

                         if (ZBCOS_CNF_AUTO_SWITCH_ON) {
                             SmUrgent(id, SIG_SHUTDOWN);       // Forces transition 2.
                         }
                         return(SmHandled);
                         }

          SIG_SHUTDOWN = SmTrans(ReadyToSwitchOn);           // Transition 2
          }

      SmState ReadyToSwitchOn
          {
          SIG_ENTRY           = {   print("Axis ",id,": Enter state ReadyToSwitchOn");
                                    data[DATA_State]      = STATE_S_READYTOSWITCHON;
                                    data[DATA_StatusWord] = ZBCOS_STW_READYTOSW | (data[DATA_StatusWord] & ZBCOS_STW_EXTMASK);
                                    return(SmHandled);
                                }
          SIG_DISABLEVOLTAGE  = SmTrans(SwitchOnDisabled);         // Transition 7
          SIG_QUICKSTOP       = SmTrans(SwitchOnDisabled);         // Transition 7
          SIG_SWITCHON        = SmTrans(PowerOn->SwitchedOn);      // Transition 3
          SIG_ENABLEOPERATION = {
                                    SmUrgent(id, SIG_ENABLEOPERATION ,event[EVENT_COMMAND] );     // Forces transition 4.
                                    return(SmTrans(PowerOn->SwitchedOn));                          // Transition 3 & 4
                                }
          }

      SmState Fault
          {
          SIG_ENTRY      = Fault_Entry;
          SIG_FAULTRESET = Fault_FaultReset;           // Transition 15
          }

      SmState PowerOn
          {
          SIG_ENTRY = { CanOpenPowerOn(id);   data[DATA_StatusWord].i[ZBCOS_STW_VOLTAGE_BIT] = 1; }
          SIG_EXIT  = { CanOpenPowerOff(id);  data[DATA_StatusWord].i[ZBCOS_STW_VOLTAGE_BIT] = 0; }

          SmState SwitchedOn
              {
              SIG_ENTRY           = SwitchedOn_Entry;
              SIG_ENABLEOPERATION = SmTrans(DriveEnabled->OperationEnabled);     // Transition 4
              SIG_SHUTDOWN        = SmTrans(<-*->ReadyToSwitchOn);              // Transition 6
              SIG_DISABLEVOLTAGE  = SmTrans(<-*->SwitchOnDisabled);             // Transition 10
              SIG_QUICKSTOP       = SmTrans(<-*->SwitchOnDisabled);             // Transition 10
              }

          SmState DriveEnabled
              {
              SIG_ENTRY           = { CanOpenEnableDrive(id, data); }
              SIG_EXIT            = { CanOpenDisableDrive(id);      }
              SIG_FAULT           = { data[DATA_ErrorNumber] = event[EVENT_ERROR];
              						  return(SmTrans(->FaultReactionActive));}              // Transition 13

              SmState FaultReactionActive
                  {
                  SIG_ENTRY    = FaultReactionActive_Entry;
                  SIG_COMPLETE = (<-*->Fault);                        // Transition 14 (automatic) after fault is handled.
                  }


              SmState QuickStopActive
                  {
                  SIG_ENTRY           = QuickStopActive_Entry;
                  SIG_IDLE            = QuickStopActive_Idle;              // Transition 12
                  SIG_DISABLEVOLTAGE  = (<-*->SwitchOnDisabled);           // Transition 12
                  SIG_ENABLEOPERATION = {
                                            // Transition only if opcode is 5..8 (see 402)
                                            if ( (ZBCO_QUICKOPTCODE(id) >= 5) && (ZBCO_QUICKOPTCODE(id) <= 8) ) {
                                                return(SmTrans(OperationEnabled));       // Transition 16
                                            }
                                            return(SmHandled);
                                        }
                  }

              SmState OperationEnabled
                  {
                  SIG_INIT            = OperationEnabled_ChangeMode;              // Transition to op mode
                  SIG_MODECHANGED     = OperationEnabled_ChangeMode;              // Transition to op mode
                  SIG_SWITCHON        = SmTrans(<-*->SwitchedOn);                 // Transition 5
                  SIG_SHUTDOWN        = SmTrans(<-*->ReadyToSwitchOn);            // Transition 8
                  SIG_DISABLEVOLTAGE  = SmTrans(<-*->SwitchOnDisabled);           // Transition 9
                  SIG_QUICKSTOP       = SmTrans(QuickStopActive);                 // Transition 11

                  #include "Slave\Zub_Includes\CanOpenOpModes.mh"
                  }
              }
          }
    }

/*********************************************************************
** State Machine Definitions
*********************************************************************/

#define EVENT_QUEUE_COUNT  20       // Maximum number of events (per CanOpen state machine).

#if   ZBCOS_CNF_MAX_AXES >= 1
	SmMachine CanOpenAxis1 { 0,                     // State machine ID (Axis number).
                         CanOpenInitAxis,       // Initialization function.
                         CanOpen,               // Top-most state.
                         EVENT_QUEUE_COUNT,     // Event queue size.
                         ZBCOS_PRIVATE_CNT }    // Private data array size.
#endif
#if ZBCOS_CNF_MAX_AXES >= 2
	SmMachine CanOpenAxis2 { 1,                     // State machine ID (Axis number).
                         CanOpenInitAxis,       // Initialization function.
                         CanOpen,               // Top-most state.
                         EVENT_QUEUE_COUNT,     // Event queue size.
                         ZBCOS_PRIVATE_CNT }    // Private data array size.
#endif
#if ZBCOS_CNF_MAX_AXES >= 3
	SmMachine CanOpenAxis3 { 2,                     // State machine ID (Axis number).
                         CanOpenInitAxis,       // Initialization function.
                         CanOpen,               // Top-most state.
                         EVENT_QUEUE_COUNT,     // Event queue size.
                         ZBCOS_PRIVATE_CNT }    // Private data array size.
#endif
#if ZBCOS_CNF_MAX_AXES >= 4
	SmMachine CanOpenAxis4 { 3,                     // State machine ID (Axis number).
                         CanOpenInitAxis,       // Initialization function.
                         CanOpen,               // Top-most state.
                         EVENT_QUEUE_COUNT,     // Event queue size.
                         ZBCOS_PRIVATE_CNT }    // Private data array size.
#endif
#if ZBCOS_CNF_MAX_AXES >= 5
	SmMachine CanOpenAxis5 { 4,                     // State machine ID (Axis number).
                         CanOpenInitAxis,       // Initialization function.
                         CanOpen,               // Top-most state.
                         EVENT_QUEUE_COUNT,     // Event queue size.
                         ZBCOS_PRIVATE_CNT }    // Private data array size.
#endif
#if ZBCOS_CNF_MAX_AXES >= 6
	SmMachine CanOpenAxis6 { 5,                     // State machine ID (Axis number).
                         CanOpenInitAxis,       // Initialization function.
                         CanOpen,               // Top-most state.
                         EVENT_QUEUE_COUNT,     // Event queue size.
                         ZBCOS_PRIVATE_CNT }    // Private data array size.
#endif
#if ZBCOS_CNF_MAX_AXES >= 7
	SmMachine CanOpenAxis7 { 6,                     // State machine ID (Axis number).
                         CanOpenInitAxis,       // Initialization function.
                         CanOpen,               // Top-most state.
                         EVENT_QUEUE_COUNT,     // Event queue size.
                         ZBCOS_PRIVATE_CNT }    // Private data array size.
#endif
#if ZBCOS_CNF_MAX_AXES >= 8
	SmMachine CanOpenAxis8 { 7,                     // State machine ID (Axis number).
                         CanOpenInitAxis,       // Initialization function.
                         CanOpen,               // Top-most state.
                         EVENT_QUEUE_COUNT,     // Event queue size.
                         ZBCOS_PRIVATE_CNT }    // Private data array size.
#endif

/*********************************************************************
**
**                           Main Program
**                           ------------
*/
long main(void)
{

	long res, ind;
	ErrorClear();

	print("CanOpen State Machine Version ",APP_SW_VERSION_1,".",APP_SW_VERSION_2,".",APP_SW_VERSION_3);

	//print "CAN Nr ",get cannr," CAN Baud ",get canbaud
	ZBCO_APPVERSION() = APP_SW_VERSION_1 * 10000 + APP_SW_VERSION_2 * 100 + APP_SW_VERSION_3;

	/*
	** Important initialization.
	*/

	//----------------------------------------------------
	// initialization which is not quite CanOpen standard

	// in case of usage of CMDCOUNTERS (see config file)
	#if ZBCOS_CNF_CMDCOUNTERS != 0
		sysvar[ZBCOS_CNF_CMDCOUNTERS] = 0;
	#endif

	ind = 0;
	while (ind <= (ZBCOS_CNF_MAX_AXES-1)) {
		ZbcosG_NullArray[ind] = 0;
		ind++;
	}
	//----------------------------------------------------

	/*
	** Application initialization.  If this doesn't work, then we might as
	** well quit!
	*/

	res = CanOpenApplInit();
	if (res != 0) {
		print("CanOpen Application initialization failed.  res = ",res);
		Exit(0);
	}

	/*
	** Run each of the state machines.  Note that the state machines should
	** normally execute forever so "SmRun" should never return.  However, if
	** it does end, then wait 2 seconds and restart it again unless it has
	** ended with a non-0 return code.
	*/
	// Multiaxes reset
	zbcos_reset_multiaxcommand();

	#if   ZBCOS_CNF_MAX_AXES == 1
		res = SmRun(CanOpenAxis1);
	#elif ZBCOS_CNF_MAX_AXES == 2
		res = SmRun(CanOpenAxis1, CanOpenAxis2);
	#elif ZBCOS_CNF_MAX_AXES == 3
		res = SmRun(CanOpenAxis1, CanOpenAxis2, CanOpenAxis3);
	#elif ZBCOS_CNF_MAX_AXES == 4
		res = SmRun(CanOpenAxis1, CanOpenAxis2, CanOpenAxis3, CanOpenAxis4);
	#elif ZBCOS_CNF_MAX_AXES == 5
		res = SmRun(CanOpenAxis1, CanOpenAxis2, CanOpenAxis3, CanOpenAxis4, CanOpenAxis5);
	#elif ZBCOS_CNF_MAX_AXES == 6
		res = SmRun(CanOpenAxis1, CanOpenAxis2, CanOpenAxis3, CanOpenAxis4, CanOpenAxis5, CanOpenAxis6);
	#elif ZBCOS_CNF_MAX_AXES == 7
		res = SmRun(CanOpenAxis1, CanOpenAxis2, CanOpenAxis3, CanOpenAxis4, CanOpenAxis5, CanOpenAxis6, CanOpenAxis7);
	#elif ZBCOS_CNF_MAX_AXES == 8
		res = SmRun(CanOpenAxis1, CanOpenAxis2, CanOpenAxis3, CanOpenAxis4, CanOpenAxis5, CanOpenAxis6, CanOpenAxis7, CanOpenAxis8);
	#else
		res = 1;
	#endif

	if (res != 0) { Exit(0); }


   return(0);
} //main


/*********************************************************************
** Utility Functions
*********************************************************************/

#include "Slave\Zub_Includes\CanOpenUtil.mh"

/*********************************************************************
**
**                CanOpen State Machine Initialization
**                ------------------------------------
**
**    This routine is called once for each state machine before state
** machine execution is started.  The constructor functions for all
** state machines are called before any state machine execution starts.
** This allows the entire system to be initialized before event processing
** starts and prevents events being sent to state machines that are not
** ready to handle them.
**
** Warning:    This routine will be called with the state machine object
**          index as the argument.  This state machine implementation has
**          been designed so that the state machine ID is equivalent to the
**          axis number.  This means that the ID can be used both as the
**          axis number and as an index into the private data.  If the
**          CanOpen state machine is embedded into another state machine
**          or if other state machines are being executed simultaneously,
**          then it may not be possible to do this.  In that case, the
**          axis number may need to be included in the private data.
**
** Return codes:  0     - Initialization succeeded.
**                Other - Initialization failed.
*/

long CanOpenInitAxis(long id, long data[])
{
    long i;

    /*
    ** Make sure that the axis count is okay.
    */

    if (id > ZBCO_AVAILABLEAXES()) {
        print("*************************************************************************************");
        print("Sorry, the actual hardware has only ",ZBCO_AVAILABLEAXES()," axes but axis ",id," has been requested.");
        return(1);
    }

    /*
    ** Set the Allowed DriveModes
    */

	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_PPM]		= 1;
   	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_VM]		= 0;
	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_PVM]		= 1;
	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_TM]		= 0;
	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_RES_4]		= 0;
	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_HHM]		= 1;
	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_IPM]		= 0;
	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_CST_CA]	= 0;
	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_MP]		= 0;
	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_MPP]		= 0;
	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_APP_0]		= 1;
	ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_APP_1]		= 1;

   	// cycle synchronious modes are currently only available on platforms with integrated amplifiers.
   	// This is due to the fact that the current and speed controllers are missing.
   	// On the MACS5-AMPx the statemachine should theoretically work as well, but it has not been tested.
   	if(SYS_INFO(SYS_PLATFORM) == 22)	// 22 = MiniMACS6
   	{
		ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_CSP]	= 1;
		ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_CSV]	= 1;
		ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_CST]	= 1;
   	}
 	else
 	{
		ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_CSP]	= 0;
		ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_CSV]	= 0;
		ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_CST]	= 0;
   	}

    /*
    ** Initialize the object data structure.
    */

    i = 0;
    while (i < ZBCOS_PRIVATE_CNT) {
        data[i] = 0;
        i++;
    }

    /*
    ** Clear the ControlWord SDO so that we always start from a known
    ** state.  Set the "old" Operational Mode to whatever the current
    ** display setting is.  That way, we only need to update the display
    ** SDO when the operational mode is changed.
    */

    ZBCO_CONTROLWORD(id) = 0;
    ZBCO_STATUSWORD(id)  = 0;

    data[DATA_OldOpMode] = ZBCO_MODEDISP(id);

    /*
    ** Initialize the axis.
    */

    ZBCO_ERRRORCODE(id) = 0;
    Sysvar[ZBCOS_CUI_MULTI_AX_BASE + id]  = 0;

    AXE_PARAM(id, ERRCOND) = 5;  // No automatic error handling.
    AxisControl(id, OFF);             // Start with the motor off.

    return(0);
}

/*********************************************************************
**
**                 FaultReactionActive State Functions
**                 -----------------------------------
**
** Note:    When this state is entered, the drive has already been
**       disabled (since we exited from the DriveEnabled state in
**       order to get here).  If this state needs to have the drive
**       enabled, then another "Fault" state will need to be created
**       as a substate of the DriveEnabled state.
*/

long FaultReactionActive_Entry(long id, long signal, long event[], long data[])
{
    long ind;

    print("Axis ",id,": Enter state FaultReactionActive");

    data[DATA_State] = STATE_S_FAULTREACTIONACTIVE;

    // check if axis is in a multi-axis movement ??
    if (ZbcosG_MultiAxesPart[id]) { // we are in multi-axis movement
        ind = 0;
        while(ind < ZbcosG_MultiAxesActiveCount) {
            if(ind != id) {
                SmUrgent(ZbcosG_MultiAxesNo[ind], SIG_FAULT, (100 + data[DATA_ErrorNumber]) );  // should be a MULTIAX-ERROR (not existent yet)
            }
            ind++;
        }
        zbcos_reset_multiaxcommand();
    }

    SmPost(id, SIG_COMPLETE );     // Forces transition 14 (automatic) now that the fault has been handled.

    return(SmHandled);
}

/*********************************************************************
**
**                       Fault State Functions
**                       ---------------------
*/

long Fault_Entry(long id, long signal, long event[], long data[])
{
    print("Axis ",id,": Enter state Fault");

    data[DATA_State] = STATE_S_FAULT;
    ZBCO_ERRRORCODE(id) = 0xFF00 + data[DATA_ErrorNumber];

    if ( (data[DATA_ErrorNumber] == 89) || (data[DATA_ErrorNumber] == 88) )
    {
        data[DATA_StatusWord] = (ZBCOS_STW_CANFAULT)  | (data[DATA_StatusWord] & ZBCOS_STW_EXTMASK);
    }
    else
    {
        data[DATA_StatusWord] = (ZBCOS_STW_FAULT)  | (data[DATA_StatusWord] & ZBCOS_STW_EXTMASK);
    }
    if (data[DATA_ErrorNumber] == 8)
    {
        data[DATA_StatusWord].i[ZBCOS_STW_OP_BIT13] = 1;     // profile modes
    }
    ErrorClear();

    return(SmHandled);
}

long Fault_FaultReset(long id, long signal, long event[], long data[])
{
    ZBCO_ERRRORCODE(id) = 0x0;    // reset error code
    AmpErrorClear(id);   // used here for error 50 (power supply missing)

    data[DATA_StatusWord].i[ZBCOS_STW_OP_BIT13] = 0;
    data[DATA_ErrorNumber] = 0;
    return(SmTrans(<-*->SwitchOnDisabled));         // Transition 15
}

/*********************************************************************
**
**                   SwitchedOn State Functions
**                   --------------------------
*/

long SwitchedOn_Entry(long id, long signal, long event[], long data[])
{
    print("Axis ",id,": Enter state SwitchedOn");

    data[DATA_State]      = STATE_S_SWITCHEDON;
    data[DATA_StatusWord] = ZBCOS_STW_SWITCHEDON | (data[DATA_StatusWord] & ZBCOS_STW_EXTMASK);

    return(SmHandled);
}

/*********************************************************************
**
**              QuickStopActive State Functions
**              -------------------------------
*/
//??????????????????????????????????????????????????????????????????????????????
// It is not clear to me exactly how the QuickStopActive state is intended to
// behave even if the existing implementation in zbcos_CanOpenStatemachine.m
// exactly implements the intent.  So I have left my original implementation
// (based on an earlier version of the CanOpen state machine) unchanged.  This
// needs to be reviewed by someone that knows how QuickStopActive should behave.
//??????????????????????????????????????????????????????????????????????????????

long QuickStopActive_Entry(long id, long signal, long event[], long data[])
{
    print("Axis ",id,": Enter state QuickStopActive");

    CanOpenQuickStop(id);

    data[DATA_State]      = STATE_S_QUICKSTOPACTIVE;
    data[DATA_StatusWord] = ZBCOS_STW_QUICKSTOPACT  | (data[DATA_StatusWord] & ZBCOS_STW_EXTMASK);

    return(SmHandled);
}

long QuickStopActive_Idle(long id, long signal, long event[], long data[])
{
    long optcode;

    optcode = ZBCO_QUICKOPTCODE(id);

    /*
    ** For quick stop option code 0, do an automatic transition to
    ** SwitchOnDisabled immediately.
    */

    if (optcode == ZBCOS_QUICKSTOP_DIS_DRV) {
        return(SmTrans(<-*->SwitchOnDisabled));          // Transition 12 (automatic if stop option code is 0)
    }

    /*
    ** For quick stop option codes 1-4, do an automatic transition to
    ** SwitchOnDisabled when the velocity reaches 0.  Note that codes 5-8
    ** will remain in the QuickStopActive state until an EnableOperation
    ** command is received.
    */

    if ( (optcode >= 1) && (optcode <= 4) ) {
        if (SYS_PFG_VCMD(id) == 0) {
            return(SmTrans(<-*->SwitchOnDisabled));      // Transition 12 (automatic if velocity = 0)
        }
    }

    /*
    ** If we didn't do a transition above, then it is important that we
    ** do NOT "handle" the Idle event here.  This allows the Idle event
    ** to be passed up the superstate chain so that all the normal Idle
    ** processing gets a chance to run.
    **
    ** Note:    If a transition is done above, then we will end up missing
    **       the normal Idle processing for one cycle (since we are already
    **       processing the Idle event and another one will not be posted
    **       until the next cycle).  This should not be a problem since
    **       the state machine should not be so time-sensitive.
    */

    return(SmNotHandled);
}
/*********************************************************************
**
**             OperationEnabled State Functions
**             --------------------------------
*/

long OperationEnabled_ChangeMode(long id, long signal, long event[], long data[])
{
    long opmode, res;

    data[DATA_State]      = STATE_S_OPERATIONENABLED;
    data[DATA_StatusWord] = ZBCOS_STW_OPERATIONEN | (data[DATA_StatusWord] & ZBCOS_STW_EXTMASK);

    opmode = ZBCO_MODEOFOP(id);
    ZBCO_MODEDISP(id) = opmode;

    switch (opmode) {
        case ZBCOS_MODOP_POSITION:          if( ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_PPM]==1)
        										return(SmTrans(->DriveModePosition));
        									break;
        case ZBCOS_MODOP_VELOCITY:          if( ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_PVM]==1)
        										return(SmTrans(->DriveModeVelocity));
        									break;
        case ZBCOS_MODOP_HOME:          	if( ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_HHM]==1)
        										return(SmTrans(->DriveModeHome));
        									break;
        case ZBCOS_MODOP_INTERPOLPOS:       if( ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_IPM]==1)
        										return(SmTrans(->DriveModeInterpolPos));
        									break;
        case ZBCOS_MODOP_CSP:        	  	if( ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_CSP]==1)
        										return(SmTrans(->DriveModeCSP));
        									break;
        case ZBCOS_MODOP_CSV:        	  	if( ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_CSV]==1)
        										return(SmTrans(->DriveModeCSV));
        									break;
        case ZBCOS_MODOP_CST:        	  	if( ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_CST]==1)
        										return(SmTrans(->DriveModeCST));
        									break;
        case ZBCOS_MODOP_MASTER_POSITION:   if( ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_MP]==1)
        										return(SmTrans(->DriveModePosition));
        									break;
        case ZBCOS_MODOP_MASTER_P_POSITION: if( ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_MPP]==1)
        										return(SmTrans(->DriveModePosition));
        									break;
        case ZBCOS_MODOP_APP_E0:        	if( ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_APP_0]==1)
        										return(SmTrans(->DriveModeAppE0));
        									break;
        case ZBCOS_MODOP_APP_E1:        	if( ZBCO_DRIVEMODE(id).i[ZBCOS_DRIVEMODE_BIT_APP_1]==1)
        										return(SmTrans(->DriveModeAppE1));
        									break;
    }  // endswitch


	/*
    ** The operation mode isn't one of the known modes.  Check to see if it
    ** is one of the user's custom modes.  execute the transition to the user's state.
    ** Note that the CanOpenTestOpMode() routine should return either an SmTrans() transition
    ** (which is a "2" return code) or SmNotHandled (or anything not "2") if
    ** the opmode is not recognized.
    */

    res = CanOpenTestOpMode(opmode);
    if (res == 2) {
        return(res);
    }

    /*
    **
    ** The operational mode is invalid.  In this case, we want to treat it like
    ** "No mode".
    */

    print("Axis ",id," Illegal Mode ",opmode);
    ZBCO_MODEDISP(id) = ZBCOS_MODOP_NOMODE;
    return(SmHandled);
}

long CanOpenError(long id, long event, long data[])
{
    long err_ind;

    if(ErrorAxis() == id) {
        if((event == 8) || (event == 25) || (event == 11) || (event == 97) || (event == 91) || (event == 99)) {
            // axe specific error
            print("Axis ",id," ErrorNo: ",event, " Time: ",Time() );
            // release fault signal, axes number is identical to sm number
            SmUrgent(id, SIG_FAULT, event);
        } else {
            // general error
            err_ind = 0;
            while(err_ind < ZBCOS_CNF_MAX_AXES) {
                SmUrgent(err_ind, SIG_FAULT, ErrorNo());
                err_ind++;
            }
        }
        // custom specific error routine ??? Tbd
        if( (ErrorNo() == 88) || (ErrorNo() == 89) ) {
            #ifdef ZBCOS_CNF_O_CANOK
            	DigOutput(ZBCOS_CNF_O_CANOK, 0); // Lösche Ausgang
            #endif
        }
    } else {
        print("Axis ",id,": not my error");
    }
    return(0);
}
//$X {User Parameter (1),1,1,0,-1,0,-1,0,(-1),-1},0x2201,1,0
//$X {User Parameter (2),1,1,0,-1,0,-1,0,(-1),-1},0x2201,2,0
//$X {User Parameter (4),1,1,0,-1,0,-1,0,(-1),-1},0x2201,4,0
//$X {User Parameter (3),1,1,0,-1,0,-1,0,(-1),-1},0x2201,3,0
//$X {Target Pos.,1,1,0,-1,0,-1,0,(-1),-1},0x607A,0,0
//$X {Target Pos.,1,1,0,-1,0,-1,0,(-1),-1},0x707A,0,0
