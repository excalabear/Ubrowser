class ssMessageWindow expands UWindowMessageBox;

var string zzLink;

function Created()
{
    bSizable = false;
	bSetupSize = True;
	Result=MR_None;

    Super.Created();

    WinLeft = Root.WinWidth/2 - WinWidth/2;
    WinTop = Root.WinHeight/2 - WinHeight/2;
}


function Close(optional bool bByParent)
{
	Super.Close(bByParent);

	if (Result == MR_OK)
	{
		getplayerowner().ConsoleCommand("start"@zzLink);
	}
	else
	{
		getplayerowner().ConsoleCommand("Disconnect");
	}

	WindowConsole(GetPlayerOwner().Player.Console).CloseUWindow(); // remove the mouse pointer
}

