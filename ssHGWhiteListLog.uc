class ssHGWhiteListLog extends StatLogFile;

function StartLog()
{
	local string FileName;

	FileName="../Logs/WhiteListKick"$"."$GetShortAbsoluteTime();
	StatLogFile = FileName$".tmp";
	StatLogFinal = FileName$".log";
	OpenLog();
}
