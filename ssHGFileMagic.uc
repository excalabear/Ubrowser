class ssHGFileMagic expands WebResponse;

var string zzFile;
var int zzi;

var String zzTemp;
var bool zzFound;

event SendBinary(int Count, byte B[255])
{
	if(zzFound!=True)
		zzFound=True;

	zzTemp = "";

	for (zzi=0; zzi<Count; zzi++)
	{
		zzTemp = ""$zzTemp$chr(B[zzi]);
	}
	zzFile = ""$zzFile$zzTemp;
}

event SendText(string Text, optional bool bNoCRLF)
{
}

function FailAuthentication(string Realm)
{
}

function HTTPResponse(string Header)
{
}

function HTTPHeader(string Header)
{
}

function HTTPError(int ErrorNum, optional string Data)
{
}

function SendStandardHeaders( optional string ContentType )
{
}

function Redirect(string URL)
{
}

defaultproperties
{
    IncludePath="../System"
}
