class ssHG expands Mutator config(HGuard);

var config string CheatProcs[200];
var config string CheatMods[200];
var config string KMods[200];
var config string KProcs[200];
var config string ThumbPrint[200];

var config int SecLevel, CheckInterval, TweakSecLevel;
var config string DLLLocation;
var config bool AllowNonWindows;
var config string HelpLocation;
var config bool LogNonWindows, LogPlayersInfo, LogWhiteListKicks;
var config bool AllowUnknownMods, AllowUnknownProcs;
var config int FileSize;
var config int FileCRC;
var config string CurrentVersion;
var config bool ShowVersion;

var bool zzbInitialized, zzSaveDone;
var ssHGInfoLog	zzHGLogFile;
var string zzCV;

var Pawn	zzPlayer[32];
var int		zzPlayerCount[32];
var ssHGPRI	zzHGPRI[32];

var string	zzPlayerName[64];
var string	zzPlayerIP[64];
var int		zzPlayerOS[64];
var int 	zzNotified[64];
var int 	zzDLLOK[64];
var int 	zzWelcomed[64];

struct ThumbPrintStruct
{
	var() int	zzMemSize;
	var() int	zzVariance;
	var() int	zzDependencies;
};

struct PlayerLists
{
	var() string	zzPProcs[200];
	var() string	zzPMods[200];
	var() string	zzPTweaks[200];
};

var PlayerLists zzPLists[64];

var ThumbPrintStruct zzThumbPrints[200];


// ==================================================================================
// PostBeginPlay
// ==================================================================================
function PostBeginPlay()
{
	local int zzi;

	Super.PostBeginPlay();

	if(!zzbInitialized)
	{
//		Log("FileSize = "$FileSize);

		zzbInitialized=True;
		zzSaveDone=False;

		for (zzi=0; zzi<32; zzi++)
		{
			zzPlayerCount[zzi] = 0;
		}

		for (zzi=0; zzi<64; zzi++)
		{
			zzPlayerName[zzi]="";
			zzPlayerIP[zzi]="";
			zzWelcomed[zzi] = 0;
		}

		if (CurrentVersion == "")
		{
			Log("Warning, the HGuard.ini values did not load properly!");
		}

		zzCV = CurrentVersion;

		xxCreateThumbPrints();

		SetTimer(1.0, True);
	}

	Disable('Tick');
}

// ==================================================================================
// Timer
// ==================================================================================
event Timer()
{
	local int zzi, zzPID;
	local Pawn zzP;
	local PlayerPawn zzPP;
	local ssHGPRI zzPRI;


	for (zzi=0; zzi<32; zzi++)
	{
		if ( (zzPlayer[zzi] != None) && (!zzPlayer[zzi].bDeleteMe) && (zzHGPRI[zzi] != None) )
		{												 
			zzPlayerCount[zzi]++;
			if (zzPlayerCount[zzi] >= CheckInterval)
			{
				zzPID = zzPlayer[zzi].PlayerReplicationInfo.PlayerID;
				if (zzPlayerOS[zzPID] <= 0)
				{
					zzPlayerOS[zzPID]--;
					if (zzPlayerOS[zzPID] < -15)
					{
						xxNoOS(zzi);
					}
				}
				else if (zzPlayerOS[zzPID] == 2)
				{
					if (zzDLLOK[zzPID] != 0)
					{
						xxCheckPlayer(zzi);
						if (ShowVersion && zzWelcomed[zzPID] == 0)
						{
							zzHGPRI[zzi].xxWelcomeMessage(zzCV);
							zzWelcomed[zzi] = 1;
						}
					}
				}
				else if (zzPlayerOS[zzPID] == 1 || zzPlayerOS[zzPID] == 3)
				{
					if (zzPlayerOS[zzPID] != 0)
					{
						if (zzNotified[zzPID] == 0)
						{
							zzNotified[zzPID] = 1;
							if (LogNonWindows == TRUE)
							{
								xxLogNonwindows(zzi);
							}
							// Player not using windows, allow non-windows players?
							if (AllowNonWindows == FALSE)
							{
								xxNotWindows(zzi);
							}
						}
					}
				}
				zzPlayerCount[zzi] = 0;
			}
		}
	}

	// Clean up after player who have left.
	for (zzi=0; zzi<32; zzi++)
	{
		if ( (zzPlayer[zzi] != None) && (zzPlayer[zzi].bDeleteMe) && (zzHGPRI[zzi] != None) )
		{
			zzPlayer[zzi] = None;
			zzHGPRI[zzi].Destroy();
			zzHGPRI[zzi] = None;
		}
	}

	// Close the log when game ends
	if ( (Level.Game.bGameEnded || Level.NextSwitchCountdown < 1.5) && !zzSaveDone)
//	if ( (Level.Game.bGameEnded || Level.NextSwitchCountdown < 1.5) )
	{
		//Save all the info that was collected on all the players and the game
		xxSaveAllPlayerInfo();
	}

	// Part 2: Finding Players who haven't been checked and checking them
	for( zzP=Level.PawnList; (zzP!=None) && (Level!=None) && (Level.PawnList!=None); zzP=zzP.NextPawn )
	{
		if ( (zzP.bIsPlayer) && (!zzP.bDeleteMe) && (PlayerPawn(zzP) != None) )
		{
			zzPP = PlayerPawn(zzP);
			if ((zzP.PlayerReplicationInfo != None) && (!zzP.PlayerReplicationInfo.bIsABot) && 
					(!zzP.PlayerReplicationInfo.bIsSpectator) && (NetConnection(zzPP.Player) != None) )
			{
				if (xxFindPIndexFor(zzP) == -1) 
				{
					zzPRI = Spawn(Class 'ssHGPRI', zzP,, zzP.Location);
					if ( zzPRI != None )
					{
						// Init newHGPRI
			 			zzi = 0;
						while ( (zzi<32) && (zzPlayer[zzi] != None) )
						  zzi++;

						zzPlayer[zzi] = zzP;
						zzHGPRI[zzi] = zzPRI;
						zzPlayerCount[zzi] = CheckInterval;

						zzPRI.zzMyMutie = Self;
						zzPID = zzP.PlayerReplicationInfo.PlayerID;

						zzPlayerName[zzPID] = zzP.PlayerReplicationInfo.PlayerName;
						zzPlayerIP[zzPID]=zzPP.GetPlayerNetworkAddress();
						zzPlayerIP[zzPID]=Left(zzPlayerIP[zzPID], InStr(zzPlayerIP[zzPID], ":"));

						zzHGPRI[zzi].xxGetOS(zzPID);
						zzHGPRI[zzi].xxGetDLLVersion(zzi, DLLLocation);
					}
				}
 			}
		}
	}
}

// ==================================================================================
// xxCreateThumbPrints
// ==================================================================================
function xxCreateThumbPrints()
{
	local int zzi, zzpos;
	local string zzTemp, zzTemp2;
	
	for (zzi=0; zzi<200 && ThumbPrint[zzi]!=""; zzi++)
	{
		zzTemp = ThumbPrint[zzi];

		zzpos = InStr(zzTemp, ",");
		zzTemp2 = Left(zzTemp, zzpos);

		zzTemp = Mid(zzTemp, zzpos+1);
		zzThumbPrints[zzi].zzMemSize = int(zzTemp2); 

		zzpos = InStr(zzTemp, ",");
		zzTemp2 = Left(zzTemp, zzpos);

		zzTemp = Mid(zzTemp, zzpos+1);
		zzThumbPrints[zzi].zzVariance = int(zzTemp2); 

		zzThumbprints[zzi].zzDependencies = int(zzTemp); 

//		Log("zzMemSize = "$zzThumbprints[zzi].zzMemSize$" zzVariance = "$zzThumbprints[zzi].zzVariance$" zzDependencies = "$zzThumbprints[zzi].zzDependencies);
	}
}

// ==================================================================================
// FindPIndexFor - Finds the PlayerList Index for a pawn.  Return -1 if not in the list
// ==================================================================================
function int xxFindPIndexFor(pawn zzP)
{
	local int zzi;
	
	for (zzi=0;zzi<32;zzi++)
	{
		if ( (zzPlayer[zzi]!=None) && (zzPlayer[zzi]==zzP) )
			return zzi;
	}
	
	return -1;
}

// ==================================================================================
// CheckPlayers
// ==================================================================================
function xxCheckPlayer(int zzIndex)
{
	if ( (zzPlayer[zzIndex] != None) && (!zzPlayer[zzIndex].bDeleteMe) && (zzHGPRI[zzIndex] != None) )
	{
		zzHGPRI[zzIndex].xxGetProcesses(zzIndex);
	}
	if ( (zzPlayer[zzIndex] != None) && (!zzPlayer[zzIndex].bDeleteMe) && (zzHGPRI[zzIndex] != None) )
	{
		zzHGPRI[zzIndex].xxGetModules(zzIndex);
	}
	if ( (zzPlayer[zzIndex] != None) && (!zzPlayer[zzIndex].bDeleteMe) && (zzHGPRI[zzIndex] != None) )
	{
		zzHGPRI[zzIndex].xxGetTweaks(zzIndex);
	}
}

//==================================================================================
// xxStoreOS
// ==================================================================================
function xxStoreOS(int zzOSN, int zzPLID)
{
	zzPlayerOS[zzPLID] = zzOSN; 
}

// ===================================================================
// CheckandstoreMods
// ===================================================================
function xxCheckDllVersion(int zzIndex, string zzplist)
{
	local string zzMsg, zzType, zzDL;
	local int zzPID;

	zzDL = DLLLocation;
	zzType = "";

	zzPID = zzPlayer[zzIndex].PlayerReplicationInfo.PlayerID;

	if (zzplist == "" || zzplist == "Missing")
	{
		zzType = "download";
	}
	else if (zzplist != CurrentVersion)
	{
		zzType = "upgrade";
	}

	if (zzType != "")
	{
		zzMsg = "You need to "$zzType$" a dll to join and play on this server."$Chr(13)$Chr(13);
		zzMsg = zzMsg$"Save this file in C:\\TournamentDemo\\System and restart Unreal after the download is complete."$Chr(13)$Chr(13);
		//	zzURL = ""$zzURL$" The default install location for Unreal Tournament Demo is in the C:\\TournamentDemo directory.";
		//	zzURL = ""$zzURL$" You will need to restart Unreal after downloading the file.";
		zzMsg = zzMsg$"Click on the OK button to proceed with the download."$Chr(13)$Chr(13);
		zzMsg = zzMsg$"If there is a problem with this automated link, you can download the file manually here:"$Chr(13)$Chr(13);
		zzMsg = zzMsg$DLLLocation$Chr(13)$Chr(13);
		zzMsg = zzMsg$"If you need support, go here :"$Chr(13)$Chr(13);
		zzMsg = zzMsg$HelpLocation$Chr(13)$Chr(13);

		zzHGPRI[zzIndex].OpenMsgWindow(zzIndex, zzMsg, "HGuard Message", zzDL);
		return;
	}

	zzDLLOK[zzPID] = 1;
}

// ===================================================================
// CheckandstoreProcs
// ===================================================================
function xxCheckandstoreProcs(int zzIndex, string zzplist)
{
	local int zzPID;

	zzPID = zzPlayer[zzIndex].PlayerReplicationInfo.PlayerID;

	if (zzplist == "Missing")
	{
		zzPLists[zzPID].zzPProcs[0] = "Missing";
		xxCheckDllVersion(zzIndex, "");
		return;
	}

//	Log("xxCheckandstoreProcs(), zzplist = "$zzplist);
	xxCheckProc(zzIndex, zzplist);
}

// ===================================================================
// CheckandstoreMods
// ===================================================================
function xxCheckandstoreMods(int zzIndex, string zzplist)
{
	local int zzPID;

	zzPID = zzPlayer[zzIndex].PlayerReplicationInfo.PlayerID;

	if (zzplist == "Missing")
	{
		zzPLists[zzPID].zzPMods[0] = "Missing";
		xxCheckDllVersion(zzIndex, "");
		return;
	}

//	Log("xxCheckandstoreMods(), zzplist = "$zzplist);
	xxCheckMod(zzIndex, zzplist);

}

// ===================================================================
// CheckandstoreMods
// ===================================================================
function xxCheckandstoreTweaks(int zzIndex, string zzplist)
{
	local int zzPID;

	zzPID = zzPlayer[zzIndex].PlayerReplicationInfo.PlayerID;
//	Log("xxCheckandstoreTweaks(), zzplist = "$zzplist);

	if (zzplist == "Missing")
	{
		zzPLists[zzPID].zzPMods[0] = "Missing";
		xxCheckDllVersion(zzIndex, "");
		return;
	}

	xxCheckTweaks(zzIndex, zzplist);

}

// ===================================================================
// xxCheckProc
// ===================================================================
function xxCheckProc(int zzIndex, string zzProc)
{
	local int zzi, zzpos;
	local int zzPID, zzMem, zzMCount;
	local string zzName, zzTemp, zzTemp2;

	zzTemp = zzProc;

	zzpos = InStr(zzTemp, "(");
	zzTemp2 = Left(zzTemp, zzpos);
	if ( zzTemp2 == "" ) 
		return;
	zzTemp = Mid(zzTemp, zzpos+1);

	// Replace with just the Name
	zzName = zzTemp2;

	zzpos = InStr(zzTemp, ";");
	zzTemp2 = Left(zzTemp, zzpos);
	if ( zzTemp2 == "" ) 
		return;
	zzTemp = Mid(zzTemp, zzpos+1);
	zzMem = int(zzTemp2); 

	zzpos = InStr(zzTemp, ")");
	zzTemp2 = Left(zzTemp, zzpos);
	if ( zzTemp2 == "" ) 
		return;
	zzMCount = int(zzTemp2); 

//	Log("Process: "$zzProc$" Size: "$zzMem$" Modules: "$zzMCount);


	zzPID = zzPlayer[zzIndex].PlayerReplicationInfo.PlayerID;

	// Check if its a new proc and add to list if it is, and then check it
	for (zzi=0; zzi<200 && zzPLists[zzPID].zzPProcs[zzi]!=""; zzi++)
	{
		if ( zzName == zzPLists[zzPID].zzPProcs[zzi] ) 
		{
			return;
		}
	}
	zzPLists[zzPID].zzPProcs[zzi] = zzName;

	// Check against whitelist procs
	if (AllowUnknownProcs == FALSE)
	{
		for (zzi=0; zzi<200 && KProcs[zzi]!=""; zzi++)
		{
			if (Caps(zzName) == Caps(KProcs[zzi]))
			{
				return;
			}
		}

		xxKickBecauseofWhitelist(zzIndex, zzName, 1);
	}

	// Check for blacklisted procs
	for (zzi=0; zzi<200 && CheatProcs[zzi]!=""; zzi++)
	{
		if (InStr(Caps(zzName), Caps(CheatProcs[zzi])) >= 0)
		{
			xxProcessHacker(zzIndex, zzName, 1);
			break;
		}
	}

	// Check Thumbprint
	for (zzi=0; zzi<200 && Thumbprint[zzi]!=""; zzi++)
	{
		if ( zzMem < zzThumbprints[zzi].zzMemSize + zzThumbprints[zzi].zzVariance &&
				zzMem > zzThumbprints[zzi].zzMemSize - zzThumbprints[zzi].zzVariance &&
					zzMCount == zzThumbprints[zzi].zzDependencies )
		{
			xxProcessHacker(zzIndex, zzProc, 1);
			break;
		}
	}

}

// ===================================================================
// xxCheckMod
// ===================================================================
function xxCheckMod(int zzIndex, string zzMod)
{
	local int zzi, zzPID;

	zzPID = zzPlayer[zzIndex].PlayerReplicationInfo.PlayerID;

	// Check if its a new mod and add to list if it is, and then check it
	for (zzi=0; zzi<200 && zzPLists[zzPID].zzPMods[zzi]!=""; zzi++)
	{
		if ( zzMod == zzPLists[zzPID].zzPMods[zzi] ) 
		{
			return;
		}
	}
	zzPLists[zzPID].zzPMods[zzi] = zzMod;

	// Check against whitelist mods
	if (AllowUnknownMods == FALSE)
	{
		for (zzi=0; zzi<200 && KMods[zzi]!=""; zzi++)
		{
			if (Caps(zzMod) == Caps(KMods[zzi]))
			{
				return;
			}
		}

		xxKickBecauseofWhitelist(zzIndex, zzMod, 2);
	}

	// Check for blacklisted mods
	for (zzi=0; zzi<200 && CheatMods[zzi]!=""; zzi++)
	{
		if (InStr(Caps(zzMod), Caps(CheatMods[zzi])) >= 0)
		{
			xxProcessHacker(zzIndex, zzMod, 2);
			return;
		}
	}
}

// ===================================================================
// xxCheckTweak
// ===================================================================
function xxCheckTweaks(int zzIndex, string zzTweak)
{
	local int zzi, zzPID;

//	Log("xxCheckTweaks(), zzplist = "$zzTweak);

	zzPID = zzPlayer[zzIndex].PlayerReplicationInfo.PlayerID;

	// Check if its a new mod and add to list if it is, and then check it
	for (zzi=0; zzi<200 && zzPLists[zzPID].zzPTweaks[zzi]!=""; zzi++)
	{
		if ( zzTweak == zzPLists[zzPID].zzPTweaks[zzi] ) 
		{
			return;
		}
	}
	zzPLists[zzPID].zzPTweaks[zzi] = zzTweak;

	xxProcessTweaker(zzIndex, zzTweak, 3);
}

// ===================================================================
// xxKickBecauseofWhitelist
// ===================================================================
function xxKickBecauseofWhitelist(int zzIndex, string zzString, int zzType)
{
	xxLogWhiteListKick(zzIndex, zzString, zzType);
	xxShowWhiteListKickMessage(zzIndex, zzString, zzType, SecLevel);
//	zzPlayer[zzIndex].Destroy();
}

// ===================================================================
// xxProcessTweaker
// ===================================================================
function xxProcessTweaker(int zzIndex, string zzString, int zzType)
{
	if (TweakSecLevel>0) 
	{
		xxLogHacker(zzIndex, zzString, zzType);
	}
	if (TweakSecLevel==1) 
	{
		xxShowKickMessage(zzIndex, zzString, zzType, SecLevel);
		zzPlayer[zzIndex].Destroy();
	}
	else if (TweakSecLevel==2) 
	{
		xxBanHacker(zzIndex);
		xxShowKickMessage(zzIndex, zzString, zzType, SecLevel);
		zzPlayer[zzIndex].Destroy();
	}
}

// ===================================================================
// xxProcessHacker
// ===================================================================
function xxProcessHacker(int zzIndex, string zzString, int zzType)
{

	xxLogHacker(zzIndex, zzString, zzType);

	if (SecLevel==1) 
	{
		xxShowKickMessage(zzIndex, zzString, zzType, SecLevel);
		zzPlayer[zzIndex].Destroy();
	}
	else if (SecLevel==2) 
	{
		xxBanHacker(zzIndex);
		xxShowKickMessage(zzIndex, zzString, zzType, SecLevel);
		zzPlayer[zzIndex].Destroy();
	}
}

// ===================================================================
// HGInfoLog
// ===================================================================
function xxHGInfoLog(string zzs)
{	
	if (zzHGLogFile != None)
	{
		zzHGLogFile.LogEventString(zzs);
		zzHGLogFile.FileFlush();
	}
}

// ==================================================================================
// xxSaveAllPlayerInfo
// ==================================================================================
function xxSaveAllPlayerInfo()
{
	local int zzIndex, zzj, zzPID;
	local string zzModList, zzProcList, zzTweakList;

	zzSaveDone = True;

	if (LogPlayersInfo == FALSE)
		return;

	for (zzIndex=0; zzIndex<64; zzIndex++)
	{
		zzProcList = "";
		zzModList = "";
		if ( zzPlayerName[zzIndex] != "" && zzDLLOK[zzIndex] != 0  && zzPlayerOS[zzIndex] == 2)
		{
			for(zzj=0; zzj<200 && zzPLists[zzIndex].zzPProcs[zzj] != "";zzj++)
			{
				if ( zzj > 0)
				{
					zzProcList = ""$zzProcList$","$zzPLists[zzIndex].zzPProcs[zzj];
				}
				else
				{
					zzProcList = zzPLists[zzIndex].zzPProcs[zzj];
				}
			}
			for(zzj=0; zzj<100 && zzPLists[zzIndex].zzPMods[zzj] != "";zzj++)
			{
				if ( zzj > 0)
				{
					zzModList = ""$zzModList$","$zzPLists[zzIndex].zzPMods[zzj];
				}
				else
				{
					zzModList = zzPLists[zzIndex].zzPMods[zzj];
				}
			}
			for(zzj=0; zzj<100 && zzPLists[zzIndex].zzPTweaks[zzj] != "";zzj++)
			{
				if ( zzj > 0)
				{
					zzTweakList = ""$zzTweakList$","$zzPLists[zzIndex].zzPTweaks[zzj];
				}
				else
				{
					zzTweakList = zzPLists[zzIndex].zzPTweaks[zzj];
				}
			}
			if (zzHGLogFile == None)
			{
				zzHGLogFile = spawn(class 'ssHGInfoLog');
				if (zzHGLogFile != None)
				{
					zzHGLogFile.StartLog();
				} 
				else 
				{
					return;
				}
			}

//			xxHGInfoLog(""$zzPlayerName[zzIndex]$", "$zzPlayerIP[zzIndex]$", Processes="$zzProcList$Chr(13)$", Modules="$zzModList$Chr(13)$", Tweaks="$zzTweakList)$Chr(13));
//			xxHGInfoLog(""$zzPlayerName[zzIndex]$", "$zzPlayerIP[zzIndex]$", Processes="$zzProcList$Chr(13)$", Modules="$zzModList$Chr(13)$", Tweaks="$zzTweakList$Chr(13));
			xxHGInfoLog("Name-IP="$zzPlayerName[zzIndex]$","$zzPlayerIP[zzIndex]);
			xxHGInfoLog("Processes="$zzProcList);
			xxHGInfoLog("Modules="$zzModList);
			xxHGInfoLog("Tweaks="$zzTweakList);
		}
	}

	if (zzHGLogFile != None)
	{
		zzHGLogFile.StopLog();
		zzHGLogFile.Destroy();
		zzHGLogFile = None;
	}
}

// ===================================================================
// xxLogHacker
// ===================================================================
function xxLogHacker(int zzIndex, string zzString, int zzType)
{
	local int zzPID;
	local ssHGCheatLog zzHGCheatLog;

	zzHGCheatLog = spawn(class 'ssHGCheatLog');
	if (zzHGCheatLog != None)
	{
		zzHGCheatLog.StartLog();
	} 
	else 
	{
		return;
	}

	zzPID = zzPlayer[zzIndex].PlayerReplicationInfo.PlayerID;

	zzHGCheatLog.LogEventString("PlayerName = "$zzPlayerName[zzPID]);
	zzHGCheatLog.FileFlush();
	zzHGCheatLog.LogEventString("PlayerIP = "$zzPlayerIP[zzPID]);
	zzHGCheatLog.FileFlush();

	if (zzType == 1)
	{
		zzHGCheatLog.LogEventString("Process = "$zzString);
		zzHGCheatLog.FileFlush();
	}
	else if (zzType == 2)
	{
		zzHGCheatLog.LogEventString("Module = "$zzString);
		zzHGCheatLog.FileFlush();
	}

	else if (zzType == 3)
	{
		zzHGCheatLog.LogEventString("Tweak = "$zzString);
		zzHGCheatLog.FileFlush();
	}

	zzHGCheatLog.StopLog();
	zzHGCheatLog.Destroy();
	zzHGCheatLog = None;
}

// ===================================================================
// xxLogNonwindows
// ===================================================================
function xxLogNonwindows(int zzIndex)
{
	local int zzPID;
	local ssHGNWindowsLog zzHGNWLog;

	if (LogNonWindows == FALSE)
		return;

	zzHGNWLog = spawn(class 'ssHGNWindowsLog');

	zzHGNWLog.StartLog();

	zzPID = zzPlayer[zzIndex].PlayerReplicationInfo.PlayerID;

	zzHGNWLog.LogEventString("PlayerName = "$zzPlayerName[zzPID]);
	zzHGNWLog.FileFlush();
	zzHGNWLog.LogEventString("PlayerIP = "$zzPlayerIP[zzPID]);
	zzHGNWLog.FileFlush();

	zzHGNWLog.StopLog();
	zzHGNWLog.Destroy();
	zzHGNWLog = None;
}

// ===================================================================
// xxLogWhiteListKick
// ===================================================================
function xxLogWhiteListKick(int zzIndex, string zzString, int zzType)
{
	local int zzPID;
	local ssHGWhiteListLog zzHGWLKLog;

	if (LogWhiteListKicks == FALSE)
		return;

	zzHGWLKLog = spawn(class 'ssHGWhiteListLog');
	if (zzHGWLKLog == None)
	{
		Log("Error! Could not open the White List Log for "$zzPlayer[zzIndex].PlayerReplicationInfo.PlayerName);
		return;
	}

	zzHGWLKLog.StartLog();

	if ( zzPlayer[zzIndex] == None )
	{
		Log("Error! zzPlayer[zzIndex] == None!");
	}

	zzPID = zzPlayer[zzIndex].PlayerReplicationInfo.PlayerID;

	zzHGWLKLog.LogEventString("PlayerName = "$zzPlayerName[zzPID]);
	zzHGWLKLog.FileFlush();
	zzHGWLKLog.LogEventString("PlayerIP = "$zzPlayerIP[zzPID]);
	zzHGWLKLog.FileFlush();

	if (zzType == 1)
	{
		zzHGWLKLog.LogEventString("Process = "$zzString);
		zzHGWLKLog.FileFlush();
	}
	else if (zzType == 2)
	{
		zzHGWLKLog.LogEventString("Module = "$zzString);
		zzHGWLKLog.FileFlush();
	}

	zzHGWLKLog.StopLog();
	zzHGWLKLog.Destroy();
	zzHGWLKLog = None;
}
//==================================================================================
// xxNotWindows
// ==================================================================================
function xxNotWindows(int zzIndex)
{
	local string zzMsg, zzTitle, zzHL;

	zzHL = HelpLocation;

	zzMsg = "This server is currently configured to allow only Windows clients!!!"$Chr(13)$Chr(13);
	zzMsg = zzMsg$"Click on OK to be taken to "$Chr(13)$Chr(13);
	zzMsg = zzMsg$zzHL$Chr(13)$Chr(13);
	zzMsg = zzMsg$"for help or questions.";

	zzTitle = "HGuard Message";

	zzHGPRI[zzIndex].OpenMsgWindow(zzIndex, zzMsg, zzTitle, zzHL);
	zzPlayer[zzIndex].Destroy();
}

//==================================================================================
// xxNotWindows
// ==================================================================================
function xxNoOS(int zzIndex)
{
	local string zzMsg, zzTitle, zzHL;

	zzHL = HelpLocation;

	zzMsg = "Your operating system was unrecognizeable. Therefore you have been kicked from the server."$Chr(13)$Chr(13);;
	zzMsg = zzMsg$"Click on OK to be taken to "$Chr(13)$Chr(13);
	zzMsg = zzMsg$zzHL$Chr(13)$Chr(13);
	zzMsg = zzMsg$"for help or questions.";

	zzTitle = "HGuard Error";

	zzHGPRI[zzIndex].OpenMsgWindow(zzIndex, zzMsg, zzTitle, zzHL);
	zzPlayer[zzIndex].Destroy();
}

// ===================================================================
// xxShowKickMessage
// ===================================================================
function xxShowKickMessage(int zzIndex, string zzString, int zzType, int zzLevel)
{
	local string zzMsg, zzKickMsg, zzPackType, zzTitle, zzHL;

	zzHL = HelpLocation;

	zzTitle = "HGuard Message";

	if (zzLevel == 1)
	{
		zzKickMsg = "Kicked";
	}
	else if (zzLevel == 2)
	{
		zzKickMsg = "Banned";
	}

	if (zzType == 1)
	{
		zzPackType = "Process";
	}
	else if (zzType == 2)
	{
		zzPackType = "UT Module";
	}
	else if (zzType == 3)
	{
		zzPackType = "Tweak";
	}

	zzMsg = "You have been "$zzKickMsg$" from the server."$Chr(13)$Chr(13);
	if ( zzType == 1 || zzType == 2 )
	{
		zzMsg = zzMsg$" This action was taken because a cheat or hack was detected."$Chr(13)$Chr(13);
	}
	else if ( zzType == 3 )
	{
		zzMsg = zzMsg$" This action was taken because a tweak was detected in your ini."$Chr(13)$Chr(13);
//		zzMsg = zzMsg$" The tweak is:"$Chr(13)$Chr(13);
//		zzMsg = zzMsg$zzString;
	}
	else
	{
		zzMsg = zzMsg$" This action was taken because a cheat or hack was detected."$Chr(13)$Chr(13);
	}
	zzMsg = zzMsg$"Click on OK to be taken to "$Chr(13)$Chr(13);
	zzMsg = zzMsg$zzHL$Chr(13)$Chr(13);
	zzMsg = zzMsg$"if you feel this action was taken in error.";

	zzHGPRI[zzIndex].OpenMsgWindow(zzIndex, zzMsg, zzTitle, zzHL);
	zzPlayer[zzIndex].Destroy();
}

// ===================================================================
// xxShowWhiteListKickMessage
// ===================================================================
function xxShowWhiteListKickMessage(int zzIndex, string zzString, int zzType, int zzLevel)
{
	local string zzMsg, zzKickMsg, zzPackType, zzTitle, zzHL;

	zzHL = HelpLocation;

	zzTitle = "HGuard Message";

	zzKickMsg = "Kicked";

	if (zzType == 1)
	{
		zzPackType = "process";
	}
	else if (zzType == 2)
	{
		zzPackType = "module";
	}


	zzMsg = "You have been "$zzKickMsg$" from the server."$Chr(13)$Chr(13);
	zzMsg = zzMsg$"This action was taken because a "$zzPackType$" was detected running on your system that is not in the servers list of allowed "$zzPackType;
	if (zzType == 1)
		zzMsg = zzMsg$"es.";
	else if (zzType == 2)
		zzMsg = zzMsg$"s.";
	zzMsg = zzMsg$" The "$zzPackType$" detected is "$zzString$"."$Chr(13)$Chr(13); 
	zzMsg = zzMsg$"Click on OK to be taken to "$Chr(13)$Chr(13);
	zzMsg = zzMsg$zzHL$Chr(13)$Chr(13);
	zzMsg = zzMsg$"if you feel this action was taken in error.";

	zzHGPRI[zzIndex].OpenMsgWindow(zzIndex, zzMsg, zzTitle, zzHL);
	zzPlayer[zzIndex].Destroy();
}

// ===================================================================
// xxBanHacker
// ===================================================================
function xxBanHacker(int zzPIndex)
{
	local int zzi, zzPID;

	zzPID = zzPlayer[zzPIndex].PlayerReplicationInfo.PlayerID;

	for (zzi=0; zzi<50; zzi++)
	{
		if(Level.Game.IPPolicies[zzi] == "") break;
	}
	if (zzi < 50)
	{
		Level.Game.IPPolicies[zzi] = "DENY,"$zzPlayerIP[zzPID];
		Level.Game.SaveConfig();
	}
}
