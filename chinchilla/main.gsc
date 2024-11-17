#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;
#include scripts\mp\chinchilla\functions;
#include scripts\mp\chinchilla\joey;
#include scripts\mp\chinchilla\binds;

init()
{
	setDvar("scr_sd_timelimit", 0);
	setDvar("scr_sd_roundswitch", 3);
	setDvar("jump_slowdownenable",0);
	setDvar("timescale", 1);
    SetDvarIfNotInizialized("botdefault", "none");
    level thread onConnect();
    level thread randomround();

	level.onOneLeftEvent = undefined;

	level.botcount = 0;
	level.botnames[0] = "bot0";
	level.botnames[1] = "bot1";
	level.botnames[2] = "bot2";
	level.botnames[3] = "bot3";

	replaceFunc(maps\mp\h2_killstreaks\_airdrop::tryUseAirdrop, ::tryUseAirdrop_stub);

	wait 1;

	level.numkills = 1;
	level.rankedmatch = 1;
    level.allowlatecomers = 1;
    level.graceperiod = 0;
    level.ingraceperiod = 0;
    level.prematchperiod = 0;
    level.waitingforplayers = 0;
    level.prematchperiodend = 0;
}

onConnect()
{
	level endon("disconnect");
    for(;;)
	{
		level waittill("connected", player);
		if(!isSubStr(player.guid, "bot"))
		{
			player thread playerLoop();
			player thread playerSpawn();
			player thread menuInit();
			player thread coreInit();
			player thread bindInit();
			player notifyOnPlayerCommand("dpad1", "+actionslot 1");
			player notifyOnPlayerCommand("dpad2", "+actionslot 2");
			player notifyOnPlayerCommand("dpad3", "+actionslot 3");
			player notifyOnPlayerCommand("dpad4", "+actionslot 4");
			player notifyOnPlayerCommand("knife", "+melee");
			player notifyOnPlayerCommand("knife", "+melee_zoom");
			player notifyOnPlayerCommand("usereload", "+usereload");
			player notifyOnPlayerCommand("usereload", "+reload");
			if(player == level.player)
				player thread hostStuff();
		}
		else
		{
			player thread botSpawn();
			player thread botLoop();
		}
    }
}

playerSpawn()
{
	self endon("disconnect");	
	for(;;)
	{
		self waittill("spawned_player");
		self freezeControls(false);
		self thread loadPos();
		if(!isDefined(self.pers["first"]))
		{
			self.pers["first"] = true;
			self iPrintLn("Press [{+speed_throw}] and [{+actionslot 2}] to open");
			self iPrintLn("Chinchilla Menu - H2M by ^1joey");
		}
	}
}

playerLoop()
{
	self endon("disconnect");	
	for(;;)
	{
		self SetMoveSpeedScale( 1 );
        self setPerk("specialty_unlimitedsprint");
		wait 0.1;
	}
}

botSpawn()
{
	self endon( "disconnect" );	
	for(;;)
	{
		self waittill("spawned_player");
		self thread botLoad();
	}
}

botloop()
{
	self endon("disconnect");	
	for(;;)
	{
		self freezeControls(true);
		wait 0.1;
	}
}

hostStuff()
{
	if(!isDefined(self.pers["tscale"]))
		self.pers["tscale"] = 1;
	
	if(self.pers["tscale"] == 0.5)
	{
		wait 2;
		setDvar("timescale", 0.5);
	}
	setDvar("bg_gravity",self.pers["gravity"]);
	self waittill("begin_killcam");
	setDvar("timescale", 1);
}

randomRound()
{
	if(getDvar("g_gametype") != "sd")
		return;

	scoreaxis = RandomIntrange(0, 3);
    scoreallies = RandomIntrange(0, 3);
    total = scoreaxis + scoreallies;
	wait 2;
	game["roundsWon"]["axis"] = scoreaxis;
	game["roundsWon"]["allies"] = scoreallies;
	game["teamScores"]["allies"] = scoreaxis;
	game["teamScores"]["axis"] = scoreallies;
	wait 0.1;	
}

tryUseAirdrop_stub( lifeId, kID, dropType )
{
	result = undefined;

	if ( !isDefined( dropType ) )
		dropType = "airdrop_marker_mp";

	if(self.pers["airspace"])
	{
		self iprintlnbold( &"LUA_KS_UNAVAILABLE_AIRSPACE" );
		return false;
	}

	if ( !isDefined( self.pers["kIDs_valid"][kID] ) )
		return true;

	if ( level.littleBirds >= 3 && dropType != "airdrop_mega_marker_mp")
	{
		self iprintlnbold( &"LUA_KS_UNAVAILABLE_AIRSPACE" );
		return false;
	} 

	if ( isDefined( level.civilianJetFlyBy ) )
	{
		self iprintlnbold( &"MP_CIVILIAN_AIR_TRAFFIC" );
		return false;
	}

	if ( self isUsingRemote() )
	{
		return false;
	}

	if ( dropType != "airdrop_mega_marker_mp" )
	{
		level.littleBirds++;
		self thread maps\mp\h2_killstreaks\_airdrop::watchDisconnect();
	}

	result = self maps\mp\h2_killstreaks\_airdrop::beginAirdropViaMarker( lifeId, kID, dropType );

	if ( (!isDefined( result ) || !result) && isDefined( self.pers["kIDs_valid"][kID] ) )
	{
		self notify( "markerDetermined" );

		if ( dropType != "airdrop_mega_marker_mp" )
			maps\mp\h2_killstreaks\_airdrop::decrementLittleBirdCount();

		return false;
	}

	if ( dropType == "airdrop_mega_marker_mp" )
		thread teamPlayerCardSplash( "callout_used_airdrop_mega", self );

	self notify( "markerDetermined" );
	return true;
}