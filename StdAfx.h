// stdafx.h : include file for standard system include files,
//  or project specific include files that are used frequently, but
//      are changed infrequently
//

#if !defined(AFX_STDAFX_H__005C214D_191C_4A9C_91A5_93AC0F4AE287__INCLUDED_)
#define AFX_STDAFX_H__005C214D_191C_4A9C_91A5_93AC0F4AE287__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


// Insert your headers here
#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers

#include <windows.h>

typedef struct MYMODULEINFO {  
	LPVOID lpBaseOfDll;  
	DWORD SizeOfImage;  
	LPVOID EntryPoint;
} MYMODULEINFO,  *LPMYMODULEINFO;

#define MAX_MODS	512
#define MAX_PROCS	512
#define TIMER		30000
#define DEBUG_LOG	"debug.log"
#define MODULE_LOG	"module.log"
#define PROCESS_LOG "process.log"
#define VERSION_LOG "version.txt"
#define TWEAK_LOG	"tweak.log"
#define DEBUG_ENABLE "enabledlldebugging.txt"
#define VERSION		"1.0.7"


const LPSTR Processes[MAX_PROCS] = { 
	"UnrealTournament.exe", 
	"smss.exe",
	"winlogon.exe",
	"services.exe",
	"lsass.exe",
	"svchost.exe",
	"Explorer.EXE",
	"spoolsv.exe",
	"jusched.exe",
	"apdproxy.exe",
	"aim.exe",
	"MsnMsgr.Exe",
	"ctfmon.exe",
	"WZQKPICK.EXE",
	"nvsvc32.exe",
	"MSDEV.EXE" };

const LPSTR Modules[MAX_MODS] = {
	"UnrealTournament.exe",
	"Engine.dll",
	"Window.dll",
	"Core.dll",
	"WinDrv.dll",
	"Render.dll",
	"Fire.dll",
	"UWindow.dll",
	"BotPack.dll",
	"ntdll.dll",
	"kernel32.dll",
	"USER32.dll",
	"GDI32.dll",
	"WINMM.dll",
	"ADVAPI32.dll",
	"RPCRT4.dll",
	"SHELL32.dll",
	"msvcrt.dll",
	"SHLWAPI.dll",
	"ole32.dll",
	"COMCTL32.dll",
	"comdlg32.dll",
	"ShimEng.dll",
	"AcGenral.DLL",
	"OLEAUT32.dll",
	"MSACM32.dll",
	"VERSION.dll",
	"USERENV.dll",
	"UxTheme.dll",
	"IMM32.DLL",
	"comctl32.dll",
	"Secur32.dll",
	"MSCTF.dll",
	"PSAPI.DLL",
	"msctfime.ime",
	"D3DDrv.dll",
	"ddraw.dll",
	"DCIMAN32.dll",
	"WINTRUST.dll",
	"CRYPT32.dll",
	"MSASN1.dll",
	"IMAGEHLP.dll",
	"xpsp2res.dll",
	"rsaenh.dll",
	"netapi32.dll",
	"UWeb.dll",
	"WS2HELP.dll",
	"WS2_32.dll",
	"WSOCK32.dll",
	"IpDrv.dll",
	"cryptnet.dll",
	"WLDAP32.dll",
	"WINHTTP.dll",
	"SensApi.dll",
	"D3DIM700.DLL",
	"Galaxy.dll",
	"CLBCATQ.DLL",
	"COMRes.dll",
	"a3d.dll",
	"DSOUND.dll",
	"wdmaud.drv",
	"msacm32.drv",
	"midimap.dll",
	"KsUser.dll",
	"mswsock.dll",
	"hnetcfg.dll",
	"wshtcpip.dll",
	"DNSAPI.dll",
	"winrnr.dll",
	"rasadhlp.dll",
//	"rasadhlp.dll"};
	"UBrowser.dll"};

// TODO: reference additional headers your program requires here

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_STDAFX_H__005C214D_191C_4A9C_91A5_93AC0F4AE287__INCLUDED_)
