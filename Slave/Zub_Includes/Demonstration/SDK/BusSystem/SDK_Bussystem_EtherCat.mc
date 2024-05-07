/**
*	@file		SDK_Bussystem_EtherCat.mc
*	@brief		Functions to work with an EtherCat Master/ slave
*	$Revision: 22 $
*
*/

#pragma once

#include <SysDef.mh>
#include "SDK_Bussystem_EtherCat.mh"

/**
*	@brief 		Initialization of an EtherCAT master
*	@details	Initializes an EtherCAT master and scans the EtherCat bus for slaves.
*				The slaves are now in PREOP state.
* 	@param 		-
*	@return 	value:	Number of slaves found on bus \n
*				value 	> 0 Process successful 	\n
*				value 	= 0 Process is active 	\n
*				value 	< 0 Error
*/
long sdkEtherCATMasterInitialize(void)
{
    long slaveCount;

    ECatMasterCommand(0x1000, 0);				// disable Master
    ECatMasterCommand(0x1000, 1);				// start Master
    slaveCount = ECatMasterInfo(0x1000, 0);		// slave count

    print(" ECAT salve count: ",slaveCount);
    return(slaveCount);
}


/**
*	@brief 		Start an EtherCAT Master
*	@details	Map Input/ Output buffers and go to safeop.
*				After that the system waits until all slaves are in the OP state.
* 	@param -
*	@return 	value:	Always 1 in this function \n
*				value 	> 0 Process successful 	\n
*				value 	= 0 Process is active 	\n
*				value 	< 0 Error
*/
long sdkEtherCATMasterStart(void)
{
    print("map input/output");
    ECatMasterCommand(0x1000, 2);	//  Map Input and Output buffers (go to safeop)

    print("wait for op");
    ECatMasterCommand(0x1000, 3);	//  request & wait OP state for all slaves

    return(1);
}


/**
*	@brief 		Sets the duty cycle of the individual slave
*	@details	Map Input and Output buffers => go to safeop.
*				After that the system waits until all slaves are in the OP state.
* 	@param 		slaveNo			ID of the EhterCAT slave
* 	@param 		cycleTime_ms	cycletime in milliseconds
* 	@param 		offset_us		shift offset
*	@return 	value:	Always 1 in this function \n
*				value 	> 0 Process successful 	\n
*				value 	= 0 Process is active 	\n
*				value 	< 0 Error
*/
long sdkEtherCATSetupDC(long slaveNo, long cycleTime_ms, long offset_us)
{
    ECatMasterCommand(slaveNo, ( (cycleTime_ms<<8) + (offset_us<<16)));

    return(1);
}

