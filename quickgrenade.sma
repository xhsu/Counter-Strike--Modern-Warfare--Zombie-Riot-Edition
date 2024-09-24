/* AMXX Template by Devzone */

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <offset>
#include <xs>

#define PLUGIN		"Grenade Quick Throw"
#define VERSION		"1.3.2"
#define AUTHOR		"Luna(plugin) & Matoilet(model)"

/**--------------Configuration: Show a customized progress bar during cooking process?*/
#define SHOW_HINT_TEXT	1

/**--------------Configuration: Modify the fuse length? (in sec., though.)*/
#define CUSTOM_FUSE_LEN	1

/**--------------Configuration: Allow grenades detonate on your face. (Requires Orpheu module.)*/
//#tryinclude <orpheu>

#define CLASSNAME_GRENADE	"weapon_hegrenade"
#define QTG_VMDL	"models/v_CODhegrenade.mdl"

#define QUICKTHROW_KEY	541368

#define ANIM_PULLPIN	1
#define ANIM_THROW		2
#define TIME_PULLPIN	0.825
#define TIME_THROW		0.467

#define HEG_AMMOTYPE		m_rgAmmo[12]
#define HEG_DEF_EXPLO_TIME	1.5

#define m_flTimePinPulled	currentammo	// It doesn't matter what the data type is. NOTE: current_ammo (offset 8) will cause CTD in ReGameDLL!
#define m_FShouldHolster	maxammo_buckshot	// loan field. For holster after a quick throw.
#define m_FShowUI			ammo_buckshot	// Hide UI if no cooking involved.

#if defined SHOW_HINT_TEXT
new g_hHudSyncObj = 0;
#endif

#if defined _orpheu_included
new OrpheuFunction:g_pfn_ShootTimed2;
new g_usEvent = 0;
#endif

new g_strQuickHEVMDL;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", true);
	register_forward(FM_SetModel, "fw_SetModel_Post", true)
	
	register_clcmd("+qtg",	"Command_QTGStart");
	register_clcmd("-qtg",	"Command_QTGRelease");
	
	RegisterHam(Ham_Item_Deploy, CLASSNAME_GRENADE, "HamF_Item_Deploy_Post", true);
	RegisterHam(Ham_Weapon_PrimaryAttack, CLASSNAME_GRENADE, "HamF_Weapon_PrimaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, CLASSNAME_GRENADE, "HamF_Weapon_SecondaryAttack");
	RegisterHam(Ham_Weapon_WeaponIdle, CLASSNAME_GRENADE, "HamF_Weapon_WeaponIdle");
	RegisterHam(Ham_Item_Holster, CLASSNAME_GRENADE, "HamF_Item_Holster_Post", true);

#if defined SHOW_HINT_TEXT
	g_hHudSyncObj = CreateHudSyncObj();
#endif

#if defined _orpheu_included
	g_pfn_ShootTimed2 = OrpheuGetFunction("ShootTimed2");
#endif
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, QTG_VMDL);
	
	g_strQuickHEVMDL = engfunc(EngFunc_AllocString, QTG_VMDL);

#if defined _orpheu_included
	g_usEvent = engfunc(EngFunc_PrecacheEvent, 1, "events/createexplo.sc");
#endif
}

public fw_UpdateClientData_Post(iPlayer, iSendWeapon, hCD)
{
	if (get_cd(hCD, CD_DeadFlag) != DEAD_NO)
		return;
	
	if (get_cd(hCD, CD_ID) != CSW_HEGRENADE)
		return;
	
	new iEntity = get_pdata_cbase(iPlayer, m_pActiveItem);
	if (pev(iEntity, pev_iuser4) != QUICKTHROW_KEY && pev(iEntity, pev_iuser3) != QUICKTHROW_KEY)	// don't block normal grenades.
		return;
	
	// reference: client.cpp::void (*UpdateClientData)(const struct edict_s *ent, int sendweapons, struct clientdata_s *cd)
	
	set_cd(hCD, CD_iUser3, 0);	// prevents IUSER3_CANSHOOT
	set_cd(hCD, CD_ID, 0);		// prevents client weapon predicts.
}

public fw_SetModel_Post(iEntity, const szModel[])	// This is the last event you can hook in CGrenade::ShootTimed2(), in which everything but pev->dmg had been initialized.
{
	if (pev_valid(iEntity) != 2)
		return;
	
	// The model w_hegrenade.mdl only appear three times in the game.
	// 1. Throwing HE.
	// 2. Dropping HE.
	// 3. Armoury entity contains HE.
	if (strcmp(szModel, "models/w_hegrenade.mdl"))
		return;
	
	new szClassname[32];
	pev(iEntity, pev_classname, szClassname, charsmax(szClassname));

	if (strcmp(szClassname, "grenade"))
		return;

	new iGrenadePlayerItem = FindPlayerGrenadeEntity(pev(iEntity, pev_owner));
	if (pev_valid(iGrenadePlayerItem) != 2)
		return;

	new Float:flTimePinPulled = get_pdata_float(iGrenadePlayerItem, m_flTimePinPulled);
	if (flTimePinPulled == 0.0)
		flTimePinPulled = get_gametime();	// Supporting the fuse modification of vanilla grenade throwing method.

	new Float:flCookingTime = get_gametime() - flTimePinPulled;
	new Float:flDmgTime;
	pev(iEntity, pev_dmgtime, flDmgTime);

#if !defined CUSTOM_FUSE_LEN
	flDmgTime -= flCookingTime;
#else
	flDmgTime = get_gametime() + HEG_DEF_EXPLO_TIME - flCookingTime;
#endif
	set_pev(iEntity, pev_dmgtime, flDmgTime);	// Thus, this grenade could just explo on right on your face.
	set_pev(iEntity, pev_nextthink, get_gametime() + 0.001);	// Originally it was set to 0.1.

	// Only auto-holster if it's a quick throw.
	if (get_pdata_float(iGrenadePlayerItem, m_flTimePinPulled) > 0.0)
	{
		set_pdata_float(iGrenadePlayerItem, m_flTimePinPulled, 0.0, 4);	// Stop the custom progress bar.
		set_task(TIME_THROW, "Task_HolsterGrenade", iGrenadePlayerItem + QUICKTHROW_KEY);	// In the case of multiple grenade ammo, it would stuck at the current item after quick throw.
	}
}

public Command_QTGStart(iPlayer)
{
	if (get_pdata_int(iPlayer, HEG_AMMOTYPE) <= 0)
		return PLUGIN_HANDLED;
	
	new iEntity = FindPlayerGrenadeEntity(iPlayer);
	
	if (get_pdata_cbase(iPlayer, m_pActiveItem) == iEntity)	// never QGT when player had already take it out.
		return PLUGIN_HANDLED;
	
	set_pev(iEntity, pev_iuser4, QUICKTHROW_KEY);
	engclient_cmd(iPlayer, CLASSNAME_GRENADE);
	return PLUGIN_HANDLED;
}

public Command_QTGRelease(iPlayer)
{
	new iEntity = get_pdata_cbase(iPlayer, m_pActiveItem);
	if (pev_valid(iEntity) != 2)
		return PLUGIN_HANDLED;

	if (get_pdata_int(iEntity, m_iId, 4) != CSW_HEGRENADE)
		return PLUGIN_HANDLED;

	set_pdata_int(iEntity, m_FShowUI, false);
	set_pev(iEntity, pev_iuser3, 0);	// unlock CHEGrenade::WeaponIdle(void)
	return PLUGIN_HANDLED;
}

public HamF_Item_Deploy_Post(iEntity)
{
	if (pev(iEntity, pev_iuser4) != QUICKTHROW_KEY)
		return;
	
	new iPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	set_pev(iPlayer, pev_viewmodel, g_strQuickHEVMDL);
	
	UTIL_ForceWeaponAnim(iPlayer, iEntity, TIME_PULLPIN);
	UTIL_WeaponAnim(iPlayer, ANIM_PULLPIN);
	
	set_pev(iEntity, pev_iuser4, 0);	// LUNA: why would I did this before?? - for the prediction, or it will have no animation.
	set_pev(iEntity, pev_iuser3, QUICKTHROW_KEY);	// lock CHEGrenade::WeaponIdle(void)
	
	// reference: CHEGrenade::PrimaryAttack(void)
	
	set_pdata_float(iEntity, m_flStartThrow, get_gametime(), 4);
	set_pdata_float(iEntity, m_flReleaseThrow, 0.0, 4);
	set_pdata_float(iEntity, m_flTimeWeaponIdle, TIME_PULLPIN, 4);

	// Record the current time for this grenade to "cook up". With a bit of time being offset.
	set_pdata_float(iEntity, m_flTimePinPulled, get_gametime() + TIME_PULLPIN, 4);
	set_pdata_int(iEntity, m_FShouldHolster, false);
	set_pdata_int(iEntity, m_FShowUI, true);
}

public HamF_Weapon_PrimaryAttack(iEntity)
{
	if (pev(iEntity, pev_iuser4) == QUICKTHROW_KEY)
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public HamF_Weapon_SecondaryAttack(iEntity)
{
	if (pev(iEntity, pev_iuser4) == QUICKTHROW_KEY)
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public HamF_Weapon_WeaponIdle(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	new Float:flTimePinPulled = get_pdata_float(iEntity, m_flTimePinPulled);

	if (flTimePinPulled != 0.0)
	{
		new Float:flCookingTime = get_gametime() - flTimePinPulled;

		if (flCookingTime >= HEG_DEF_EXPLO_TIME)
		{
#if defined _orpheu_included
			new Float:vecOrigin[3], Float:vecVelocity[3];
			pev(iPlayer, pev_origin, vecOrigin);
			pev(iPlayer, pev_view_ofs, vecVelocity);
			xs_vec_add(vecOrigin, vecVelocity, vecOrigin);
			pev(iPlayer, pev_velocity, vecVelocity);

			// Spawn a grenade exploded on player's face.
			ShootTimed2(iPlayer, vecOrigin, vecVelocity, 0.01, get_pdata_int(iPlayer, m_iTeam), g_usEvent);

			set_pdata_int(iPlayer, HEG_AMMOTYPE, max(0, get_pdata_int(iPlayer, HEG_AMMOTYPE) - 1));
			UTIL_RemovePlayerWeapon(iPlayer, iEntity);
#else
			// I can't make a grenade explode on my face without orpheu module support.
			engclient_cmd(iPlayer, "lastinv");
#endif

			return HAM_SUPERCEDE;
		}

#if defined SHOW_HINT_TEXT
		if (get_pdata_int(iEntity, m_FShowUI))
		{
			new szText[64];
			new Float:flPercentageToOverCook = flCookingTime / HEG_DEF_EXPLO_TIME;
			new iDotNum = floatround(flPercentageToOverCook * 20.0);
			new iLineNum = max(20 - iDotNum, 0);
			new Float:flFrameTime; global_get(glb_frametime, flFrameTime);

			for (new i = 0; i < iLineNum; i++)
				strcat(szText, "|", charsmax(szText));

			for (new i = 0; i < iDotNum; i++)
				strcat(szText, "•", charsmax(szText));	// HACKHACK: This is an unicode character. Potential compiling failure.

			// According to UTIL_HudMessage(), this float will be converted to an unsigned short. Make sure the number actually have "1" to send.
			// In FixedUnsigned16() the first param will multiply by the second param.
			// Therefore, we cannot make the float we passed in less than 1/256 (256 == 1<<8).
			// Due to the precision loss of float, I decide to raise the numerator to 1.5 instead of 1.
			// Reference: 
			// WRITE_SHORT(FixedUnsigned16(textparms.holdTime, (1<<8)));
			flFrameTime = floatmax(flFrameTime, 1.0 / 60.0);

			set_hudmessage(
				floatround(200.0 * flPercentageToOverCook), floatround(200.0 * (1.0 - flPercentageToOverCook)), 0,	// RGB
				-1.0, 0.4, 0, 6.0, flFrameTime, 0.0, 0.0, -1
			);

			ShowSyncHudMsg(iPlayer, g_hHudSyncObj, szText);
		}
#endif
	}

	if (get_pdata_int(iEntity, m_FShouldHolster))
	{
		ExecuteHamB(Ham_Weapon_RetireWeapon, iEntity);
		return HAM_SUPERCEDE;
	}

	if (pev(iEntity, pev_iuser3) == QUICKTHROW_KEY)
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public HamF_Item_Holster_Post(iEntity)
{
	set_pev(iEntity, pev_iuser3, 0);
	set_pev(iEntity, pev_iuser4, 0);
	set_pdata_float(iEntity, m_flTimePinPulled, 0.0, 4);
	set_pdata_int(iEntity, m_FShouldHolster, false, 4);
	set_pdata_int(iEntity, m_FShowUI, false);
}

public Task_HolsterGrenade(iEntity)
{
	iEntity -= QUICKTHROW_KEY;

	if (pev_valid(iEntity) == 2)
	{
		new iPlayer = get_pdata_cbase(iEntity, m_pPlayer);

		if (get_pdata_cbase(iPlayer, m_pActiveItem) == iEntity)
			set_pdata_int(iEntity, m_FShouldHolster, true);
	}
}

FindPlayerGrenadeEntity(iPlayer)
{
	new iEntity = -1;
	while ((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", CLASSNAME_GRENADE)))
	{
		if (pev_valid(iEntity) != 2)
			continue;
		
		if (get_pdata_cbase(iEntity, m_pPlayer, 4) != iPlayer)
			continue;
		
		// FOUND!
		break;
	}

	return iEntity;
}

#if defined _orpheu_included
ShootTimed2(iPlayer, const Float:vecOrigin[3], const Float:vecVelocity[3], Float:flFuseTime, iTeam, usEvent)
{
	return OrpheuCallSuper(g_pfn_ShootTimed2,
		iPlayer,
		vecOrigin[0], vecOrigin[1], vecOrigin[2],
		vecVelocity[0], vecVelocity[1], vecVelocity[2],
		flFuseTime,
		iTeam,
		usEvent);
}
#endif

stock UTIL_WeaponAnim(id, iAnim)
{
	set_pev(id, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, id);
	write_byte(iAnim);
	write_byte(pev(id, pev_body));
	message_end();
}

stock UTIL_ForceWeaponAnim(iPlayer, iEntity, Float:flTime = 0.0)
{
	set_pdata_float(iPlayer, m_flNextAttack,			flTime);
	set_pdata_float(iEntity, m_flNextPrimaryAttack,		flTime, 4);
	set_pdata_float(iEntity, m_flNextSecondaryAttack,	flTime, 4);
	set_pdata_float(iEntity, m_flTimeWeaponIdle,		flTime, 4);
}

stock UTIL_RemovePlayerWeapon(iPlayer, iEntity)
{
	ExecuteHamB(Ham_Weapon_RetireWeapon, iEntity);
	ExecuteHamB(Ham_RemovePlayerItem, iPlayer, iEntity);
	ExecuteHamB(Ham_Item_Kill, iEntity);
	set_pev(iPlayer, pev_weapons, pev(iPlayer, pev_weapons) & ~(1<<get_pdata_int(iEntity, m_iId, 4)));
}








