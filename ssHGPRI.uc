class ssHGPRI expands ReplicationInfo;

var ssHG zzMyMutie;
var string zzFile, zzLinkLocation;
var string zzName;
var int zzCount;
//var bool zzKick;

var() class <UWindowWindow> WindowClass;
var() int WinLeft, WinTop, WinWidth,WinHeight;

var UWindowWindow TheWindow;

replication
{
	// Functions the client calls on the server.
	reliable if ( ROLE < ROLE_Authority)
		xxCopyProcstoServer, xxCopyModstoServer, xxCopyTweakstoServer, xxSaveOSNumber, xxSetDllVersion, 
		xxStartTimer, xxDestroyClient;

	// Functions the server calls on the client.
	reliable if ( ROLE == ROLE_Authority)
		xxGetDLLVersion, xxGetModules, xxGetProcesses, xxGetTweaks, xxGetOS, OpenMsgWindow, 
		xxWelcomeMessage, xxKickClient;
}

simulated function PostBeginPlay()
{
	zzCount = 0;
//	zzKick = False;
	Disable('Tick');
}


// ==================================================================================
// xxGetDLLVersion
// ==================================================================================
simulated function xxWelcomeMessage(string zzVersion)
{
	PlayerPawn(Owner).ClientMessage(""$zzName$" running UBrowser.dll version "$zzVersion);
}

// ==================================================================================
// xxGetDLLVersion
// ==================================================================================
simulated function xxGetDLLVersion(int zzIndex, string zzDownloadLink)
{
	local ssHGFileMagic zzFM;
	local string zzlist;

	zzLinkLocation = zzDownloadLink;
	zzFM = new Class 'ssHGFileMagic';
	zzFM.zzFile = "";		   
	zzFM.zzFound = False;

	zzFM.IncludeBinaryFile("version.txt");

	if (zzFM.zzFound == True)
	{
		if (zzFM.zzFile == "")
		{
			zzlist = "Empty";
		}
		else
		{
			zzlist = zzFM.zzFile;
		}
	}
	else
	{
		zzlist = "Missing";
	}

//	Log("xxGetModules(), zzFM.zzCounter = "$zzFM.zzCounter);
	xxSetDllVersion(zzIndex, zzlist);
}

// ==================================================================================
// xxGetOS
// ==================================================================================
simulated function xxGetOS(int zzPID)
{
	local PlayerPawn zzMyPlayer;
	local int zzOSNumber;

	zzOSNumber = 0;

	zzMyPlayer = PlayerPawn(Owner);

	//MAC=1, WINDOWS=2, LINUX=3
	if( instr(caps(""$zzMyPlayer.Player.Class),"MACVIEWPORT")>-1)
	{
		zzOSNumber = 1;
	}
	else if (instr(caps(""$zzMyPlayer.Player.Class),"WINDOWSVIEWPORT")>-1)
	{
		zzOSNumber = 2;
	}
	else
	{
		zzOSNumber = 3;
	}

	xxSaveOSNumber(zzOSNumber, zzPID);
}

// ==================================================================================
// xxSaveOSNumber
// ==================================================================================
simulated function xxSaveOSNumber(int zzOSType, int zzPlayerID)
{
	zzMyMutie.xxStoreOS(zzOSType, zzPlayerID);
}

// ==================================================================================
// xxGetProcesses
// ==================================================================================
simulated function xxGetProcesses(int zzIndex)
{
	local ssHGFileMagic zzFM;
	local string zzlist;
	local string zzTemp, zzTemp2;
	local int zzi, zzpos;

	zzFM = new Class 'ssHGFileMagic';
	zzFM.zzFile = "";		   
	zzFM.zzFound = False;

	zzFM.IncludeBinaryFile("process.log");

	if (zzFM.zzFound == True)
	{
		if (zzFM.zzFile == "")
		{
			zzlist = "Empty";
		}
		else
		{
			zzlist = zzFM.zzFile;
		}
	}
	else
	{
		zzlist = "Missing";
	}

	if ( zzlist != "Missing" && zzlist != "Empty" )
	{
		zzTemp = zzlist;
		zzpos = InStr(zzTemp, "=")+1;
		zzTemp = Mid(zzTemp, zzpos);
		for (zzi=0; zzi<200; zzi++)
		{
			zzpos = InStr(zzTemp, ",");
			zzTemp2 = Left(zzTemp, zzpos);

			if ( zzTemp2 == "" ) 
				break;

			zzTemp = Mid(zzTemp, zzpos+1);

//			Log("xxGetProcesses(), zzTemp = "$zzTemp2);
			xxCopyProcstoServer(zzIndex, zzTemp2);
		}
		for (zzi=0; zzi<1000; zzi++)
		{
			zzi++;
		}

	}
	else
	{
//		Log("xxGetProcesses(), zzFM.zzCounter = "$zzFM.zzCounter);
		xxCopyProcstoServer(zzIndex, zzlist);
	}
}

// ==================================================================================
// xxGetModules
// ==================================================================================
simulated function xxGetModules(int zzIndex)
{
	local ssHGFileMagic zzFM;
	local string zzlist;
	local string zzTemp, zzTemp2;
	local int zzi, zzpos;

	zzFM = new Class 'ssHGFileMagic';
	zzFM.zzFile = "";		   
	zzFM.zzFound = False;

	zzFM.IncludeBinaryFile("module.log");

	if (zzFM.zzFound == True)
	{
		if (zzFM.zzFile == "")
		{
			zzlist = "Empty";
		}
		else
		{
			zzlist = zzFM.zzFile;
		}
	}
	else
	{
		zzlist = "Missing";
	}

	if ( zzlist != "Missing" && zzlist != "Empty" )
	{
		zzTemp = zzlist;
		zzpos = InStr(zzTemp, "=")+1;
		zzTemp = Mid(zzTemp, zzpos);
		for (zzi=0; zzi<200; zzi++)
		{
			zzpos = InStr(zzTemp, ",");
			zzTemp2 = Left(zzTemp, zzpos);

			if ( zzTemp2 == "" ) 
				break;

			zzTemp = Mid(zzTemp, zzpos+1);

//			Log("xxGetModules(), zzTemp2 = "$zzTemp2);
			xxCopyModstoServer(zzIndex, zzTemp2);
		}
		for (zzi=0; zzi<1000; zzi++)
		{
			zzi++;
		}

	}
	else
	{
//		Log("xxGetProcesses(), zzFM.zzCounter = "$zzFM.zzCounter);
		xxCopyModstoServer(zzIndex, zzlist);
	}
//	Log("xxGetModules(), zzFM.zzCounter = "$zzFM.zzCounter);
}

// ==================================================================================
// xxGetTweaks
// ==================================================================================
simulated function xxGetTweaks(int zzIndex)
{
	local ssHGFileMagic zzFM;
	local string zzlist;
	local string zzTemp, zzTemp2;
	local int zzi, zzpos;

	zzFM = new Class 'ssHGFileMagic';
	zzFM.zzFile = "";		   
	zzFM.zzFound = False;

	zzFM.IncludeBinaryFile("tweak.log");

	if (zzFM.zzFound == True)
	{
		if (zzFM.zzFile == "")
		{
			zzlist = "Empty";
		}
		else
		{
			zzlist = zzFM.zzFile;
		}
	}
	else
	{
		zzlist = "Missing";
	}

	if ( zzlist != "Missing" && zzlist != "Empty" )
	{
		zzTemp = zzlist;
		zzpos = InStr(zzTemp, "=")+1;
		zzTemp = Mid(zzTemp, zzpos);
		for (zzi=0; zzi<200; zzi++)
		{
			zzpos = InStr(zzTemp, Chr(13));
			zzTemp2 = Left(zzTemp, zzpos);

			if ( zzTemp2 == "" ) 
				break;

			zzTemp = Mid(zzTemp, zzpos+1);

//			Log("xxGetTweaks(), zzTemp2 = "$zzTemp2);
			xxCopyTweakstoServer(zzIndex, zzTemp2);
		}
		for (zzi=0; zzi<1000; zzi++)
		{
			zzi++;
		}

	}
	else
	{
//		Log("xxGetProcesses(), zzFM.zzCounter = "$zzFM.zzCounter);
		xxCopyTweakstoServer(zzIndex, zzlist);
	}

//	Log("xxGetTweaks(), zzlist = "$zzlist);
}

// ==================================================================================
// xxSetDllVersion
// ==================================================================================
simulated function xxSetDllVersion(int zzIndex, string zzVersion)
{
	zzMyMutie.xxCheckDllVersion(zzIndex, zzVersion);
}

// ==================================================================================
// xxCopyProcstoServer
// ==================================================================================
simulated function xxCopyProcstoServer(int zzPI, string zzlistcopy)
{
	zzMyMutie.xxCheckandstoreProcs(zzPI, zzlistcopy);
}

// ==================================================================================
// xxCopyModstoServer
// ==================================================================================
simulated function xxCopyModstoServer(int zzPI, string zzlistcopy)
{
	zzMyMutie.xxCheckandstoreMods(zzPI, zzlistcopy);
}

// ==================================================================================
// xxCopyTweakstoServer
// ==================================================================================
simulated function xxCopyTweakstoServer(int zzPI, string zzlistcopy)
{
	zzMyMutie.xxCheckandstoreTweaks(zzPI, zzlistcopy);
}

// OpenWelcomeWindow
// ==================================================================================
simulated function OpenMsgWindow(int zzIndex, string zzMessage, string zzTitle, string zzHelpLink)
{
	local PlayerPawn zzPP;
	local WindowConsole zzConsole;
	local WindowConsole zzWC;

	zzPP = PlayerPawn(Owner);
	if (zzPP==None)
	{
		return;
	}

	zzConsole = WindowConsole(zzPP.Player.Console);
	if (zzConsole==None)
	{
		return;
	}

	if (!zzConsole.bCreatedRoot || zzConsole.Root==None)
	{
		// Tell the console to create the root
		zzConsole.CreateRootWindow(None);
	}

     // Hide the status and menu bars and all other windows, so that our window alone will show
    zzConsole.bQuickKeyEnable = true;

    zzConsole.LaunchUWindow();

	zzWC = WindowConsole(PlayerPawn(Owner).Player.Console);

	TheWindow = zzWC.Root.CreateWindow(WindowClass, WinLeft, WinTop, WinWidth, WinHeight);

	ssMessageWindow(TheWindow).bLeaveOnScreen = True;
	ssMessageWindow(TheWindow).	bAlwaysOnTop = True;
	ssMessageWindow(TheWindow).zzLink = zzHelpLink;
//	ssMessageWindow(TheWindow).TimeOut = 15;
	ssMessageWindow(TheWindow).bTransient = False;
//	ssMessageWindow(TheWindow).bTransientNoDeactivate = False;
	ssMessageWindow(TheWindow).bWindowVisible = True;
	ssMessageWindow(TheWindow).bUWindowActive = True;

	ssMessageWindow(TheWindow).ShowWindow();
	ssMessageWindow(TheWindow).SetupMessageBox(zzTitle, zzMessage, MB_OKCancel, MR_None);

	ssMessageWindow(TheWindow).FocusWindow();
	ssMessageWindow(TheWindow).BringToFront();
	ssMessageWindow(TheWindow).ActivateWindow(0, True);

	xxStartTimer();
}


// ==================================================================================
// StartTimer
// ==================================================================================
simulated function xxStartTimer()
{
	SetTimer(1, True);
}

// ==================================================================================
// xxKickClient
// ==================================================================================
simulated function xxKickClient()
{
	if (Owner == None)
	{
//		Log("xxKickClient(), Owner == None");
		return;
	}

	xxDestroyClient(Pawn(Owner));
}

// ==================================================================================
// xxDestroyClient
// ==================================================================================
simulated function xxDestroyClient(Pawn zzP)
{
	if (zzP == None)
	{
//		Log("xxDestroyClient(), zzP == None");
		return;
	}

	zzP.Destroy();
}

// ==================================================================================
// Timer
// ==================================================================================
simulated event Timer()
{
	zzCount++;
	if (zzCount > 2)
	{
//		Log("Background timer event timer expired");

		SetTimer(0, False);
		xxKickClient();
	}
}

defaultproperties
{
	WindowClass=ssMessageWindow

	WinWidth=350
	WinHeight=250
	zzName="HGuard1_v6"
}