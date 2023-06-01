class ssHGServerActor expands Info;

function PostBeginPlay()
{
	local  ssHG zzHGMute;

	Super.PostBeginPlay();

	// Make sure it wasn't added as a mutator
	foreach AllActors(Class 'ssHG', zzHGMute)
	{
		return;
	}

	zzHGMute = Level.Spawn(Class 'ssHG');
	zzHGMute.NextMutator = Level.Game.BaseMutator;
	Level.Game.BaseMutator = zzHGMute;
}
