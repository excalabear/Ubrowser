class ssHGNWindowsLog extends StatLogFile;

function StartLog()
{
	local string FileName;

	FileName="../Logs/Nonwindows"$"."$GetShortAbsoluteTime();
	StatLogFile = FileName$".tmp";
	StatLogFinal = FileName$".log";
	OpenLog();
}
