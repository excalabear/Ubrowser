// UBrowser.cpp : Defines the entry point for the DLL application.
//
//#include "afx.h"
//#include <windows.h>
#include <fstream>
#include "stdafx.h"
#include "stdio.h"
//#include <psapi.h>

using namespace std;

//DWORD (WINAPI *lpfGetModuleInformation)(HANDLE, HMODULE, LPMODULEINFO, DWORD);
DWORD (WINAPI *lpfGetModuleInformation)(HANDLE, HMODULE, void *, DWORD);
//DWORD (WINAPI *lpfGetProcessMemoryInfo)(HANDLE, PPROCESS_MEMORY_COUNTERS, DWORD);
BOOL (WINAPI *lpfEnumProcesses)(DWORD *, DWORD, DWORD *);
BOOL (WINAPI *lpfEnumProcessModules)(HANDLE, HMODULE *, DWORD, LPDWORD);
DWORD (WINAPI *lpfGetModuleBaseName)(HANDLE, HMODULE, LPTSTR, DWORD);
DWORD (WINAPI *lpfGetModuleFileNameEx)(HANDLE, HMODULE, LPTSTR, DWORD);

DWORD dwVersion, dwMajorVersion;

UINT TimerID;
FILE *module_fp;
FILE *process_fp;
FILE *version_fp;
FILE *tweak_fp;
FILE *debug_fp;


HINSTANCE hPsapi; 
//HINSTANCE hkernel32;

void debuglog(const char *fmt, ...);
void debuglog_nocr(const char *fmt, ...);

void lpTimerFunc(void);

void getInfo(void);
void SaveVersion(void);

void InitModuleLog(void);
void LogModule(const LPSTR module);
void PrintModules( DWORD processID );
void VerifyModules(const LPSTR module);
bool StoredModule(const char *module);

void InitProcessLog(void);
void LogProcess(const LPSTR process, DWORD PSize, DWORD MCount);

void PrintProcesses( DWORD processID );
void VerifyProcesses(const char *process, DWORD PSize, DWORD ModuleCount);
bool StoredProcess(const char *process);

char ModuleList[MAX_MODS][MAX_PATH];
char ProcessList[MAX_PROCS][MAX_PATH];

void InitTweakLog(void);
void LogTweak(const LPSTR tweak);

void TweakCheck(void);
void CheckLine( char* fline );

bool bFirstTime = TRUE;
bool bDebugLog = FALSE;
bool bEnableModLogging = FALSE;

BOOL APIENTRY DllMain( HANDLE hModule, 
                       DWORD  ul_reason_for_call, 
                       LPVOID lpReserved
					 )
{
	// Get the list of process identifiers.

	if(ul_reason_for_call == DLL_PROCESS_ATTACH)
  	{
		dwVersion = GetVersion();
		dwMajorVersion = (DWORD)(LOBYTE(LOWORD(dwVersion)));

		if ( dwMajorVersion >= 5 )
		{
			remove(PROCESS_LOG);
			remove(MODULE_LOG);
			remove(VERSION_LOG);
			remove(TWEAK_LOG);
			remove(DEBUG_LOG);

			SaveVersion();
			InitProcessLog();
			InitModuleLog();
			InitTweakLog();

			TimerID = SetTimer(NULL, 0, 2000, (TIMERPROC) lpTimerFunc);
		}
		else	// Windows Me/98/95
		{
			LogProcess("Windows9x", 0, 0);
			LogModule("Windows9x");
		}
	}
	else if(ul_reason_for_call == DLL_PROCESS_DETACH)
	{
		if (dwMajorVersion >= 5) // Windows NT
		{
			KillTimer(NULL, TimerID); 
		}
		remove(MODULE_LOG);
		remove(TWEAK_LOG);
		remove(PROCESS_LOG);
		remove(VERSION_LOG);
	}

	return TRUE;
}

void lpTimerFunc(void)
{
	getInfo();
}

bool CheckForDebugging(void)
{ 
	FILE *enable_fp;
	char FLine[1024];

	fopen_s(&enable_fp, DEBUG_ENABLE, "r");
	if(enable_fp == NULL)
	{
		return FALSE;
	}

	fseek(enable_fp, SEEK_SET, 0);

	fgets(FLine, 1024, enable_fp);

	if (strncmp(FLine, "EnableModLogging=1", 18) == 0 )
	{
		bEnableModLogging = TRUE;
	}
	
	fclose (tweak_fp );

	return TRUE;
}


void getInfo(void)
{ 
	// Get the list of process identifiers.
	DWORD aProcesses[4096], cbNeeded, cProcesses;
	unsigned int i;

	if ( bFirstTime	)
	{
		bFirstTime = FALSE;

		bDebugLog = CheckForDebugging();

		debuglog("Version = 0x%x\n", dwVersion);

		hPsapi = LoadLibraryA("PSAPI.DLL");
		if (NULL == hPsapi)
		{
			debuglog("LoadLibrary of psapi failed");
			return;
		}

//		lpfGetProcessMemoryInfo = (DWORD(WINAPI *)(HANDLE, PPROCESS_MEMORY_COUNTERS, DWORD))
//		GetProcAddress(hPsapi, "GetProcessMemoryInfo");
//		if (lpfGetProcessMemoryInfo == NULL) 
//		{
//			debuglog("lpfGetProcessMemoryInfo == NULL");
//			return;
//		}

//		lpfGetModuleInformation = (DWORD(WINAPI *)(HANDLE, HMODULE, LPMODULEINFO, DWORD))

		lpfGetModuleInformation = (DWORD(WINAPI *)(HANDLE, HMODULE, void *, DWORD))
		GetProcAddress(hPsapi, "GetModuleInformation");
		if (lpfGetModuleInformation == NULL) 
		{
			debuglog("lpfGetModuleInformation == NULL");
			return;
		}

		lpfEnumProcesses = (BOOL (WINAPI *)(DWORD *, DWORD, DWORD*))
		GetProcAddress(hPsapi, "EnumProcesses");
		if (lpfEnumProcesses == NULL) 
		{
			debuglog("lpfEnumProcesses== NULL");
			return;
		}

		lpfEnumProcessModules = (BOOL (WINAPI *)(HANDLE, HMODULE *,
			DWORD, LPDWORD)) GetProcAddress(hPsapi, "EnumProcessModules");
		if (lpfEnumProcessModules == NULL)
		{
			debuglog("lpfEnumProcessModules == NULL, error = %d", GetLastError());
			return;
		}
		lpfGetModuleBaseName = (DWORD (WINAPI *)(HANDLE, HMODULE,
			LPTSTR, DWORD)) GetProcAddress(hPsapi, "GetModuleBaseNameA");
		if (lpfGetModuleBaseName == NULL)
		{
			debuglog("lpfGetModuleBaseName== NULL, error = %d", GetLastError());
			return;
		}
		
		lpfGetModuleFileNameEx = (DWORD (WINAPI *)(HANDLE, HMODULE, LPTSTR, DWORD)) 
			GetProcAddress(hPsapi, "GetModuleFileNameExA");
//			GetProcAddress(hPsapi, "GetModuleFileNameExW");
		if (lpfGetModuleFileNameEx == NULL)
		{
			debuglog("lpfGetModuleFileNameEx == NULL, error = %d", GetLastError());
			return;
		}

		TweakCheck();
		
		KillTimer(NULL, TimerID); 
		TimerID = SetTimer(NULL, 0, TIMER, (TIMERPROC) lpTimerFunc);
	}


	// If the function address is valid, call the function.
	if ( !lpfEnumProcesses( aProcesses, sizeof(aProcesses), &cbNeeded ) )
	{
		debuglog("lpfEnumProcesses == FALSE");
		return;
	}

	// Calculate how many process identifiers were returned.
	cProcesses = cbNeeded / sizeof(DWORD);

	debuglog("\r\nGetInfo(), Number of processes = %d, bytes needed = %d", cProcesses, cbNeeded);

	// Print the name of the modules for each process.
	for ( i = 0; i < cProcesses; i++ )
	{
		debuglog("\r\nGetInfo(), Process %d is %d", i, aProcesses[i]);
		PrintModules( aProcesses[i] );
	}
}

void PrintModules( DWORD processID )
{
    HMODULE hMods[128];
    HANDLE hProcess;
    DWORD cbNeeded, RetVal;
	int i, BuffSize, ModCount;
    TCHAR szProcessName[1024] = TEXT("<unknown>");
	TCHAR szModName[MAX_PATH];
	char *szModName_nopath;
	char delimiter = {'\\'};
//	PPROCESS_MEMORY_COUNTERS MemInfo;
	int Result;
	DWORD DataSize;
//	LPMODULEINFO ModInfo;
	LPMYMODULEINFO ModInfo;

	// Get a list of all the modules in this process.
    hProcess = OpenProcess(PROCESS_QUERY_INFORMATION|PROCESS_VM_READ, FALSE, processID);
    if (hProcess == NULL)
	{
		debuglog("hProcess == NULL");
        return;
	}
/*
	MemInfo = new PROCESS_MEMORY_COUNTERS;
	DataSize = sizeof(PROCESS_MEMORY_COUNTERS);
	Result = lpfGetProcessMemoryInfo (hProcess, MemInfo, DataSize);
	if ( Result <= 0 )
	{
		debuglog("lpfGetProcessMemoryInfo retutrned 0, error = %d", GetLastError());
	    CloseHandle( hProcess );
		return;
	}
	debuglog("PageFaultCount = %d, PeakWorkingSetSize = %d, WorkingSetSize = %d, ", MemInfo->PageFaultCount, MemInfo->PeakWorkingSetSize, MemInfo->WorkingSetSize); 
*/

	RetVal = lpfEnumProcessModules (hProcess, hMods, sizeof(hMods), &cbNeeded);
    if(RetVal <= 0)
    {
		debuglog("lpfEnumProcessModules returned FALSE, error = %d, RetVal = %d", GetLastError(), RetVal);
	    CloseHandle( hProcess );
		return;
	}
	else
	{
//		debuglog("lpfEnumProcessModules sizeof(hMods) = %d", sizeof(hMods));
//		debuglog("lpfEnumProcessModules cbNeeded = %d ", cbNeeded);


//		DataSize = sizeof(MODULEINFO);
//		ModInfo = new MODULEINFO;
		DataSize = sizeof(MYMODULEINFO);
		ModInfo = new MYMODULEINFO;

		Result = lpfGetModuleInformation (hProcess, hMods[0], ModInfo, DataSize);
		if ( Result <= 0 )
		{
			debuglog("lpfGetModuleInformation retutrned 0, error = %d", GetLastError());
			CloseHandle( hProcess );
			return;
		}
  
		debuglog("PrintModules(), lpBaseOfDll = 0x%x, SizeOfImage = %d, EntryPoint = 0x%x", ModInfo->lpBaseOfDll, ModInfo->SizeOfImage, ModInfo->EntryPoint);

		RetVal = lpfGetModuleBaseName(hProcess, hMods[0], szProcessName, 1024);
		if (RetVal <= 0)
		{
			debuglog("lpfGetModuleBaseName retutrned 0, error = %d", GetLastError());
		    CloseHandle( hProcess );
			return;
		}


		ModCount = cbNeeded/sizeof(HMODULE);
		debuglog("PrintModules(), Process %s has %d modules", szProcessName, ModCount);

		VerifyProcesses(szProcessName, ModInfo->SizeOfImage, ModCount);

		debuglog("Process Name: %s", szProcessName);
		debuglog_nocr("Mod name: ");

		// Just check UT, checking all processes causes lag
		if ( strstr(szProcessName, "UnrealTournament") != NULL || bEnableModLogging )
		{
			for ( i=0; i<ModCount; i++ )
			{
				// Get the full path to the module's file.
				BuffSize = lpfGetModuleFileNameEx( hProcess, hMods[i], szModName, sizeof(szModName)/sizeof(TCHAR));
				if ( BuffSize <= 0 )
				{
					debuglog("lpfGetModuleFileNameEx retutrned 0, error = %d", GetLastError());
					CloseHandle( hProcess );
					return;
				}

				// Get rid of path and print the mod name.
				szModName_nopath = strrchr(szModName, delimiter);
				szModName_nopath = szModName_nopath + sizeof(char);

				debuglog("%s", szModName_nopath);
				VerifyModules(szModName_nopath);
			}
		}
	}

    CloseHandle( hProcess );
}

void VerifyProcesses(const char *process, DWORD PSize, DWORD ModuleCount)
{
	char l_buff[MAX_PATH];
	INT i;
	bool Found;

	debuglog("VerifyProcesses(), Process: %s", process);

	memset(l_buff, 0, MAX_PATH);
	memcpy(l_buff, process, MAX_PATH);

	i = strlen(l_buff);

	Found=FALSE;
	i=0;
	while((Processes[i] != NULL) && (i<MAX_PROCS))
	{
		if(strcmp(l_buff,Processes[i++]) == 0)
		{
			Found = TRUE;
		}
	}

	if (!Found)
	{
//		debuglog("Process %s was not found in list!", l_buff);
		if(!StoredProcess(l_buff))
		{
			LogProcess(l_buff, PSize, ModuleCount);
		}
	}
}

bool StoredProcess(const char *process)
{
	INT i, Count;

	Count = 0;
	for (i=0; i<MAX_PROCS; i++)
	{
		if(strlen(&ProcessList[i][0]) > 0)
		{
			Count++;
			if(strcmp(process, &ProcessList[i][0]) == 0)
			{
				return TRUE;
			}
		}
		else
		{
			break;
		}
	}
	memcpy(&ProcessList[Count][0], process, MAX_PATH);
	return FALSE;
}

void VerifyModules(const LPSTR module)
{
	char l_buff[MAX_PATH];
	int bs = 92;
	INT i;
	bool Found;

	memset(l_buff, 0, MAX_PATH);
	memcpy(l_buff, module, MAX_PATH);

	Found=FALSE;
	i=0;
	while((Modules[i] != NULL) && (i<MAX_MODS))
	{
		if(strcmp(l_buff,Modules[i++]) == 0)
		{
			Found = TRUE;
		}
	}

	if (!Found)
	{
//		debuglog("UT Module %s was not found in List!", l_buff);
		if(!StoredModule(l_buff))
		{
			LogModule(l_buff);
		}
	}
}

bool StoredModule(const char *module)
{
	INT i, Count;

	Count = 0;
	for (i=0; i<MAX_MODS; i++)
	{
		if(strlen(&ModuleList[i][0]) > 0)
		{
			Count++;
			if(strcmp(module, &ModuleList[i][0]) == 0)
			{
				return TRUE;
			}
		}
		else
		{	break;
		}
	}
	memcpy(&ModuleList[Count][0], module, MAX_PATH);
	return FALSE;
}



void InitModuleLog(void)
{
	fopen_s(&module_fp, MODULE_LOG, "a");
	if(module_fp == NULL)
	{
		debuglog("Unable to open session log");
		return;
	}

	fprintf(module_fp ,"Modules=");
	fflush(module_fp );
	fclose (module_fp );
}

void LogModule(const LPSTR module)
{
	fopen_s(&module_fp, MODULE_LOG, "a");
	if(module_fp == NULL)
	{
		debuglog("Unable to open session log");
		return;
	}

	fseek(module_fp, SEEK_END, 0);

	fprintf(module_fp,"%s,", module);

	fflush(module_fp);
	fclose (module_fp);
}

void LogProcess(const LPSTR process, DWORD PSize, DWORD MCount)
{
	fopen_s(&process_fp, PROCESS_LOG, "a");
	if(process_fp == NULL)
	{
		debuglog("Unable to open session log");
		return;
	}

	fseek(process_fp , SEEK_END, 0);

	fprintf(process_fp ,"%s(%d;%d),", process, PSize, MCount);

	fflush(process_fp );

	fclose (process_fp );
}

void InitProcessLog(void)
{
	fopen_s(&process_fp, PROCESS_LOG, "a");
	if(process_fp == NULL)
	{
		debuglog("Unable to open session log");
		return;
	}

	fprintf(process_fp ,"Processes=");
	
	fflush(process_fp );

	fclose (process_fp );
}

void InitTweakLog(void)
{
	fopen_s(&tweak_fp, TWEAK_LOG, "a");
	if(tweak_fp == NULL)
	{
		debuglog("Unable to open tweak log");
		return;
	}

	fprintf(tweak_fp ,"Tweaks=");
	
	fflush(tweak_fp );

	fclose (tweak_fp );
}

void LogTweak(const LPSTR tweak)
{
	fopen_s(&tweak_fp, TWEAK_LOG, "a");
	if(tweak_fp == NULL)
	{
		debuglog("Unable to open tweak log");
		return;
	}

	fseek(tweak_fp , SEEK_END, 0);

	fprintf(tweak_fp ,"%s\r", tweak);

	fflush(tweak_fp );

	fclose (tweak_fp );
}

void SaveVersion(void)
{
	FILE *version_fp;

	fopen_s(&version_fp, VERSION_LOG, "a");
	if(version_fp == NULL)
	{
		debuglog("Unable to open version log");
		return;
	}

	fseek(version_fp, SEEK_END, 0);
	fprintf(version_fp, "%s", VERSION);
	fflush(version_fp);
	fclose (version_fp);
}

void debuglog(const char *fmt, ...)
{
	if ( bDebugLog )
	{
		va_list va_alist;
		char logbuf[1024];
		if (fmt==NULL)
		{
			return;
		}
		memset(logbuf,0,1024);

		va_start (va_alist, fmt);
		_vsnprintf_s (logbuf+strlen(logbuf), 8192, sizeof(logbuf) - strlen(logbuf), fmt, va_alist);
		va_end (va_alist);
		
		fopen_s(&debug_fp, DEBUG_LOG, "a");
		if (debug_fp != NULL)
		{
			fprintf(debug_fp, "%s\n", (char *)logbuf);
		}
		fclose (debug_fp);
	}
}

void debuglog_nocr(const char *fmt, ...)
{
	if ( bDebugLog )
	{
		va_list va_alist;
		char logbuf[1024];

		if (fmt==NULL)
		{
			return;
		}
		memset(logbuf,0,1024);

		va_start (va_alist, fmt);
		_vsnprintf_s (logbuf+strlen(logbuf), 8192, sizeof(logbuf) - strlen(logbuf), fmt, va_alist);
		va_end (va_alist);
		
		fopen_s(&debug_fp, DEBUG_LOG, "a");
		if (debug_fp != NULL)
		{
			fprintf(debug_fp, "%s", (char *)logbuf);
		}
		fclose (debug_fp);

	}
}

void TweakCheck( void )
{
	char line[1024];

	ifstream IniFile("User.ini", ios_base::in );


	if(!IniFile)
	{
		debuglog("Unable to open ini");
		return;
	}

	while ( IniFile.getline(line, 1024, '\n') != NULL )
	{
		CheckLine(line);
		//debuglog("%s", line);
	}
	
	IniFile.close();
}


void CheckLine( char *fline )
{
	char tmp_line[1024];
	char *new_line;

	// Copy to tmp_line to keep string manipulatiopn local to function
	strcpy_s(tmp_line, fline);

	new_line = strstr(tmp_line, "set");
	if ( new_line != NULL )
	{
		LogTweak(fline);
		debuglog("%s", tmp_line);
		return;
	}

	new_line = strstr(tmp_line, "SET");
	if ( new_line != NULL )
	{
		LogTweak(fline);
		debuglog("%s", tmp_line);
		return;
	}
}
