class ssHGCheatLog extends StatLogFile;

function StartLog()
{
	local string FileName;

	FileName="../Logs/HGCheat"$"."$GetShortAbsoluteTime();
	StatLogFile = FileName$".tmp";
	StatLogFinal = FileName$".log";
	OpenLog();
}
