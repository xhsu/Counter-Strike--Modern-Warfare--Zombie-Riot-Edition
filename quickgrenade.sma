/* AMXX Template by Devzone */

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>

#include <offset>
#include <cstrike_pdatas/pdatas_stocks>

#pragma semicolon 1

#define PLUGIN		"Grenade Quick Throw"
#define VERSION		"1.4.0"
#define AUTHOR		"Luna(plugin) & Matoilet(model)"

/**--------------Configuration: Show a customized progress bar during cooking process?*/
#define SHOW_HINT_TEXT

/**--------------Configuration: Modify the fuse length? (in sec., though.)*/
#define CUSTOM_FUSE_LEN


enum _:GrTypes
{
	NOT_THROWABLE = -1,
	HEGRENADE = 0,
	FLASHBANG = 1,
	SMOKEGRENADE = 2,
};

new const THROWABLES_WORLD_MDL[][] = { "models/w_hegrenade.mdl", "models/w_flashbang.mdl", "models/w_smokegrenade.mdl" };
new const THROWABLES_CLASSNAME[][] = { "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade" };
new const QTG_VMDLS[][] = { "models/v_CODhegrenade.mdl", "models/v_CODflashbang.mdl", "models/v_CODflashbang.mdl" };
new const Float:TIME_PULLPIN[] = { 0.825, 0.825, 0.825 };
new const Float:TIME_THROW[] = { 0.467, 0.833, 0.833 };
new const THROWABLES_BPAMMO[] = { 12, 11, 13 };

#define QUICKTHROW_KEY	541368

#define ANIM_PULLPIN	1
#define ANIM_THROW		2

#define HEG_DEF_EXPLO_TIME	2.0

#define m_flTimePinPulled	currentammo	// It doesn't matter what the data type is. NOTE: current_ammo (offset 8) will cause CTD in ReGameDLL!
#define m_FShouldHolster	maxammo_buckshot	// loan field. For holster after a quick throw.
#define m_FShowUI			ammo_buckshot	// Hide UI if no cooking involved.


#if defined SHOW_HINT_TEXT
new g_hHudSyncObj = 0;
#endif

new g_strQTGVMDLS[3];
new g_rgiLastGrenadeSerial[33], g_rgiLastGrenadeItem[33];	// basically EHANDLE<CBasePlayerItem>

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", true);
	register_forward(FM_SetModel, "fw_SetModel_Post", true);
	
	register_clcmd("+qtg",	"Command_QTGStart");
	register_clcmd("-qtg",	"Command_QTGRelease");
	
	for (new i = 0; i < sizeof THROWABLES_CLASSNAME; ++i)
	{
		RegisterHam(Ham_Item_Deploy, THROWABLES_CLASSNAME[i], "HamF_Item_Deploy_Post", true);
		RegisterHam(Ham_Weapon_PrimaryAttack, THROWABLES_CLASSNAME[i], "HamF_Weapon_PrimaryAttack");
		RegisterHam(Ham_Weapon_SecondaryAttack, THROWABLES_CLASSNAME[i], "HamF_Weapon_SecondaryAttack");
		RegisterHam(Ham_Weapon_WeaponIdle, THROWABLES_CLASSNAME[i], "HamF_Weapon_WeaponIdle");
		RegisterHam(Ham_Item_Holster, THROWABLES_CLASSNAME[i], "HamF_Item_Holster_Post", true);
	}

#if defined SHOW_HINT_TEXT
	g_hHudSyncObj = CreateHudSyncObj();
#endif
}

public plugin_precache()
{
	for (new i = 0; i < sizeof QTG_VMDLS; ++i)
	{
		precache_model(QTG_VMDLS[i]);
		g_strQTGVMDLS[i] = engfunc(EngFunc_AllocString, QTG_VMDLS[i]);
	}
}

public fw_UpdateClientData_Post(iPlayer, iSendWeapon, hCD)
{
	if (get_cd(hCD, CD_DeadFlag) != DEAD_NO)
		return;
	
	new iId = get_cd(hCD, CD_ID);
	if (iId != CSW_HEGRENADE && iId != CSW_SMOKEGRENADE && iId != CSW_FLASHBANG)
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
	new iGrenadeType;
	for (iGrenadeType = 0; iGrenadeType < sizeof THROWABLES_WORLD_MDL; ++iGrenadeType)
	{
		if (!strcmp(szModel, THROWABLES_WORLD_MDL[iGrenadeType]))
			break;
	}
	if (iGrenadeType >= sizeof THROWABLES_WORLD_MDL)
		return;
	
	new szClassname[32];
	pev(iEntity, pev_classname, szClassname, charsmax(szClassname));

	if (strcmp(szClassname, "grenade"))
		return;

	new iGrenadePlayerItem = FindPlayerGrenadeEntity(pev(iEntity, pev_owner), iGrenadeType);
	if (pev_valid(iGrenadePlayerItem) != 2)
		return;

	// One can only cook his he grenade
	if (iGrenadeType == HEGRENADE)
	{
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

		if (flDmgTime < 0.01)
			flDmgTime = 0.01;

		set_pev(iEntity, pev_dmgtime, flDmgTime);	// Thus, this grenade could just explo on right on your face.
		set_pev(iEntity, pev_nextthink, get_gametime() + 0.001);	// Originally it was set to 0.1.
	}

	// Flashbang has its auto-holster function included.
	if (iGrenadeType == HEGRENADE || iGrenadeType == SMOKEGRENADE)
	{
		// Only auto-holster if it's a quick throw.
		if (get_pdata_float(iGrenadePlayerItem, m_flTimePinPulled) > 0.0)
		{
			set_pdata_int(iGrenadePlayerItem, m_FShowUI, false, 4);	// Stop the custom progress bar.
			set_task(TIME_THROW[iGrenadeType], "Task_HolsterGrenade", iGrenadePlayerItem + QUICKTHROW_KEY);	// In the case of multiple grenade ammo, it would stuck at the current item after quick throw.
		}
	}
}

public Command_QTGStart(iPlayer)
{
	// never QGT when player had already take it out.
	if (GetGrenadeType(get_pdata_cbase(iPlayer, m_pActiveItem)) != NOT_THROWABLE)
		return PLUGIN_HANDLED;

	/*
	1. Is last item a grenade?
	2. Select the first item in slot 4
	*/

	new iEntity = GetLastGrenade(iPlayer);
	new iGrenadeType = GetGrenadeType(iEntity);

	// This is not a grenade item, select the first item in slot 4.
	if (iGrenadeType == NOT_THROWABLE)
	{
		for (iGrenadeType = 0; get_pdata_int(iPlayer, m_rgAmmo[THROWABLES_BPAMMO[iGrenadeType]]) <= 0; ++iGrenadeType)
		{
			// Player has no grenade.
			if (iGrenadeType >= sizeof THROWABLES_CLASSNAME)
				return PLUGIN_HANDLED;
		}
	}

	iEntity = FindPlayerGrenadeEntity(iPlayer, iGrenadeType);
	client_print(iPlayer, print_chat, "Selected: %s", THROWABLES_CLASSNAME[iGrenadeType]);

	set_pev(iEntity, pev_iuser4, QUICKTHROW_KEY);
	engclient_cmd(iPlayer, THROWABLES_CLASSNAME[iGrenadeType]);
	return PLUGIN_HANDLED;
}

public Command_QTGRelease(iPlayer)
{
	new iEntity = get_pdata_cbase(iPlayer, m_pActiveItem);
	if (pev_valid(iEntity) != 2)
		return PLUGIN_HANDLED;

	if (GetGrenadeType(iEntity) == NOT_THROWABLE)
		return PLUGIN_HANDLED;

	set_pdata_int(iEntity, m_FShowUI, false);
	set_pev(iEntity, pev_iuser3, 0);	// unlock CHEGrenade::WeaponIdle(void)
	return PLUGIN_HANDLED;
}

public HamF_Item_Deploy_Post(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	SetLastGrenade(iPlayer, iEntity);	// record the 'last' in a special way.

	if (pev(iEntity, pev_iuser4) != QUICKTHROW_KEY)
		return;

	new iGrenadeType = GetGrenadeType(iEntity);

	set_pev(iPlayer, pev_viewmodel, g_strQTGVMDLS[iGrenadeType]);

	UTIL_ForceWeaponAnim(iPlayer, iEntity, TIME_PULLPIN[iGrenadeType]);
	UTIL_WeaponAnim(iPlayer, ANIM_PULLPIN);

	set_pev(iEntity, pev_iuser4, 0);	// LUNA: why would I did this before?? - for the prediction, or it will have no animation.
	set_pev(iEntity, pev_iuser3, QUICKTHROW_KEY);	// lock CHEGrenade::WeaponIdle(void)

	// reference: CHEGrenade::PrimaryAttack(void)

	set_pdata_float(iEntity, m_flStartThrow, get_gametime(), 4);
	set_pdata_float(iEntity, m_flReleaseThrow, 0.0, 4);
	set_pdata_float(iEntity, m_flTimeWeaponIdle, TIME_PULLPIN[iGrenadeType], 4);

	// Record the current time for this grenade to "cook up". With a bit of time being offset.
	set_pdata_float(iEntity, m_flTimePinPulled, get_gametime() + TIME_PULLPIN[iGrenadeType], 4);
	set_pdata_int(iEntity, m_FShouldHolster, false);
	set_pdata_int(iEntity, m_FShowUI, true);

	// Stop protection as the VMDL doesn't included a shield.
	SetShieldHitgroup(iPlayer, false);
}

public HamF_Weapon_PrimaryAttack(iEntity)
{
	if (get_pdata_float(iEntity, m_flTimePinPulled) != 0.0)
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public HamF_Weapon_SecondaryAttack(iEntity)
{
	if (get_pdata_float(iEntity, m_flTimePinPulled) != 0.0)
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public HamF_Weapon_WeaponIdle(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);
	new Float:flTimePinPulled = get_pdata_float(iEntity, m_flTimePinPulled);
	new iGrenadeType = GetGrenadeType(iEntity);

	// One can only cook he grenade
	if (iGrenadeType == HEGRENADE && flTimePinPulled != 0.0)
	{
		new Float:flCookingTime = get_gametime() - flTimePinPulled;

		if (flCookingTime >= HEG_DEF_EXPLO_TIME)
		{
			// I can't make a grenade explode on my face without orpheu module support.
			engclient_cmd(iPlayer, "lastinv");

			return HAM_SUPERCEDE;
		}

#if defined SHOW_HINT_TEXT
		if (get_pdata_int(iEntity, m_FShowUI))
		{
			new szText[64];
			new Float:flPercentageToOverCook = flCookingTime / HEG_DEF_EXPLO_TIME;
			new iDotNum = floatround(flPercentageToOverCook * 21.0);
			new iLineNum = max(21 - iDotNum, 0);
			new Float:flFrameTime; global_get(glb_frametime, flFrameTime);

			formatex(szText, charsmax(szText), "         %.1f         ^n", HEG_DEF_EXPLO_TIME - flCookingTime);

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
	new iPlayer = get_pdata_cbase(iEntity, m_pPlayer, XO_CBASEPLAYERITEM);

	// Is using quick throw?
	if (get_pdata_float(iEntity, m_flTimePinPulled) > 0.0 && get_pdata_bool(iPlayer, m_bOwnsShield))
		SetShieldHitgroup(iPlayer, true);

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

FindPlayerGrenadeEntity(iPlayer, iGrenadeType = HEGRENADE)
{
	new iEntity = -1;
	while ((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", THROWABLES_CLASSNAME[iGrenadeType])))
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

GetGrenadeType(iWeapon)
{
	if (pev_valid(iWeapon) != 2)
		return NOT_THROWABLE;

	switch (get_pdata_int(iWeapon, m_iId, XO_CBASEPLAYERITEM))
	{
		case CSW_HEGRENADE:
			return HEGRENADE;
		case CSW_FLASHBANG:
			return FLASHBANG;
		case CSW_SMOKEGRENADE:
			return SMOKEGRENADE;

		default:
			return NOT_THROWABLE;
	}

	return NOT_THROWABLE;	// unreachable.
}

SetLastGrenade(iPlayer, iWeapon)
{
	g_rgiLastGrenadeItem[iPlayer] = iWeapon;
	g_rgiLastGrenadeSerial[iPlayer] = pev_serial(iWeapon);
}

GetLastGrenade(iPlayer)
{
	if (pev_valid(g_rgiLastGrenadeItem[iPlayer]) != 2)
		return -1;

	if (pev_serial(g_rgiLastGrenadeItem[iPlayer]) != g_rgiLastGrenadeSerial[iPlayer])
		return -1;

	new iGrenadeType = GetGrenadeType(g_rgiLastGrenadeItem[iPlayer]);
	if (iGrenadeType == NOT_THROWABLE)
		return -1;

	// In case the last one was thrown and only a 'shell' item left.
	new iBpAmmoOfs = m_rgAmmo[THROWABLES_BPAMMO[iGrenadeType]];
	if (get_pdata_int(iPlayer, iBpAmmoOfs) <= 0)
		return -1;

	return g_rgiLastGrenadeItem[iPlayer];
}

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

stock SetShieldHitgroup(iPlayer, bool:bEnabled)
{
	// 0 - has shield, 1 - no shield
	set_pev(iPlayer, pev_gamestate, !bEnabled);
}
