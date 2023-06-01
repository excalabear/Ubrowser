class ssHGInfoLog extends StatLogFile;

function StartLog()
{
	local string FileName;

	FileName="../Logs/HG" $ "." $ GetShortAbsoluteTime();
	StatLogFile = FileName$".tmp";
	StatLogFinal = FileName$".log";
	OpenLog();
}
