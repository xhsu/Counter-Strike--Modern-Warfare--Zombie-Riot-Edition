/* AMXX Template by Devzone */
/*

Created Date: Apr 03 2021

Modern Warfare Dev Team
 - Luna the Reborn

*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <offset>
#include <xs>
#include <orpheu>
#include <zombieriot>

#include <cstrike_pdatas/pdatas_stocks>
#include "Library/LibMath.inc"
#include "Library/LibWeapons.sma"
#include "Library/LibExplosion.sma"
#include "Library/LibProjectile.sma"

#define PLUGIN		"RPG-7 for ZombieRiot"
#define VERSION		"2.0.3 CSMW:ZR"
#define AUTHOR		"Luna the Reborn"

#define VMDL 			"models/v_rpg.mdl"			// view model
#define XMDL 			"models/pw_rpg.mdl"			// world model
#define XMDL_EMPTY		"models/pw_rpg_none.mdl"	// emptied world model
#define ROCKET_MDL		"models/rpgrocket.mdl"
#define LAUNCH_SFX		"weapons/rpg7_1.wav"
#define TRAVEL_SFX		"weapons/rpg_travel.wav"
#define EXPLO_SFX		"weapons/rocke_explode.wav"
#define HUD				"weapon_rpg"				// hud txt
#define KILLICON		"rpg"

#define BUY_COMMAND		"getrpg7"
#define ROCKET_NAME		"rpg7_rocket"
#define WEAPON_CSW		CSW_M3					// original weapon number: CSW_XXXX
#define WEAPON_ENT		"weapon_m3"				// original weapon entity: weapon_xxx
#define WEAPON_SLOT		1
#define OLD_WMDL		"models/w_m3.mdl"
#define OLD_KILLICON	"m3"

stock const g_szTanks[][] =
{
	"func_tank",
	"func_tankmortar",
	"func_tankrocket",
	"func_tanklaser"
};

enum _:ERPG7Anims
{
	idle,
	shoot1,
	shoot2,
	reload,
	reload2,
	reload3,
	draw,
	idle_none,
	draw_none,
};
stock const Float:g_rgflRPG7AnimLength[ERPG7Anims] = { 20.0, 0.4667, 0.4667, 3.3, 3.3, 3.3, 0.8667, 20.0, 0.8667 };

new g_strViewModel = 0, g_strWorldModel = 0, g_strWorldEmptyModel = 0;
new g_hHamBotRegisterFunction = 0;
new bool:g_bKillIconHook[33];
new cvar_maxammo, cvar_recoil, cvar_flyspeed, cvar_flyoffset, cvar_gravity, cvar_directdmg, cvar_rangedmg, cvar_radius, cvar_playerfxrad, cvar_shakedur, cvar_shakeamp, cvar_shakefreq, cvar_punchmax, cvar_knockvel;
new g_indexRPG7Item;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMsg");
	
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", true);
	
	RegisterHam(Ham_Item_AddToPlayer, WEAPON_ENT, "HamF_Item_AddToPlayer_Post", true);
	RegisterHam(Ham_Item_Deploy, WEAPON_ENT, "HamF_Item_Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame, WEAPON_ENT, "HamF_Item_PostFrame");
	//RegisterHam(Ham_CS_Item_GetMaxSpeed, WEAPON_ENT, "HamF_CS_Item_GetMaxSpeed");	// LUNA: Somehow Ham_CS_Item_GetMaxSpeed does not work in ZR. Thus use orpheu instead.
	//OrpheuRegisterHook(OrpheuGetFunctionFromClass(WEAPON_ENT, "GetMaxSpeed", "CBasePlayerItem"), "OrpheuF_Item_GetMaxSpeed");	// LUNA: Orpheu will break entire player speed system.
	RegisterHam(Ham_Touch, "info_target", "HamF_Touch");
	RegisterHam(Ham_Think, "info_target", "HamF_Think");

	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage_Post", true);

	g_hHamBotRegisterFunction = register_forward(FM_PlayerPostThink, "fw_HamBotRegisterFunc", true);

	cvar_maxammo = register_cvar("RPG_MaxAmmo", "15");
	cvar_recoil = register_cvar("RPG_Recoil", "30.0");
	cvar_flyspeed = register_cvar("RPG_FlySpeed", "900.0");
	cvar_flyoffset = register_cvar("RPG_FlyOffset", "1.2");
	cvar_gravity = register_cvar("RPG_ProjectileGravity", "2.0");
	cvar_directdmg = register_cvar("RPG_ProjectileHitDamage", "120.0");
	cvar_rangedmg = register_cvar("RPG_ExplosionDamage", "7000.0");
	cvar_radius = register_cvar("RPG_ExplosionRadius", "350.0");
	cvar_playerfxrad = register_cvar("RPG_ExplosionPlayerFXRadius", "700.0");
	cvar_shakedur = register_cvar("RPG_ExplosionShakeDuration", "5.0");
	cvar_shakeamp = register_cvar("RPG_ExplosionShakeAmplitude", "20.0");
	cvar_shakefreq = register_cvar("RPG_ExplosionShakeFrequency", "10.0");
	cvar_punchmax = register_cvar("RPG_ExplosionMaxiumPunchAngle", "25.0");
	cvar_knockvel = register_cvar("RPG_ExplosionKnockbackMomentum", "400.0");

	g_indexRPG7Item = zr_register_item("RPG-7 \y8000", HUMAN, 4);
	
	for (new e = 0; e < sizeof g_szTanks; e ++)
		RegisterHam(Ham_Use, g_szTanks[e], "HamF_Use_Post", 1);
	
	LibWeapons_Init();
	LibExplosion_Init();
	LibProjectile_Init();
}

public plugin_precache()
{
	precache_model(VMDL);
	precache_model(XMDL);
	precache_model(XMDL_EMPTY);
	precache_model(ROCKET_MDL);
	
	g_strWorldModel = engfunc(EngFunc_AllocString, XMDL);
	g_strViewModel = engfunc(EngFunc_AllocString, VMDL);
	g_strWorldEmptyModel = engfunc(EngFunc_AllocString, XMDL_EMPTY);

	precache_sound(LAUNCH_SFX);
	precache_sound(TRAVEL_SFX);
	precache_sound(EXPLO_SFX);
	
	register_clcmd(BUY_COMMAND, "Command_GiveWeapon");
	register_clcmd(HUD, "Command_HookSelectWeapon");
	register_clcmd("updateammo", "Command_UpdateRPGAmmo");

	LibExplosion_Precache();
	LibExplosion_SetExploSprite(_, precache_model("sprites/m79grenadeex.spr"));
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////Command Callback Functions///////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public Command_HookSelectWeapon(iPlayer)  
{ 
	engclient_cmd(iPlayer, WEAPON_ENT);
	return PLUGIN_HANDLED;
}

public Command_GiveWeapon(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return;
	
	DropFirearmIfNecessary(iPlayer);
	
	new iEntity = GiveItem(iPlayer, WEAPON_ENT, RPG7_SPECIAL_CODE);
	if (pev_valid(iEntity) != 2)
		return;

	set_pdata_int(iEntity, m_iClip, 1);
	ReplenishRPG7Rockets(iPlayer, iEntity, get_pcvar_num(cvar_maxammo));
}

public Command_UpdateRPGAmmo(iPlayer)
{
	new iEntity = get_pdata_cbase(iPlayer, m_pActiveItem);

	UTIL_UpdateBpAmmoCount(iPlayer, AMMO_RPG_ROCKET, get_pdata_int(iEntity, m_iRocketBpammo, XO_CBASEPLAYERWEAPON));
}

public zr_item_event(iPlayer, iItemIndex, iSlot)
{
	if (iItemIndex == g_indexRPG7Item)
	{
		new iMoney = zr_get_user_money(iPlayer);
		
		if (iMoney < 8000)
		{
			client_print(iPlayer, print_center, "没有足够的金钱!")
			return;
		}
		
		Command_GiveWeapon(iPlayer)
		zr_set_user_money(iPlayer, iMoney - 8000, true);

		new szNetName[64];
		pev(iPlayer, pev_netname, szNetName,charsmax(szNetName));
		zr_print_chat(0, GREENCHAT, "%s购买了一把RPG-7反坦克火箭炮", szNetName);
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////Weapon Class Hook Callbacks//////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public HamF_Item_AddToPlayer_Post(iEntity, iPlayer)
{
	if (pev(iEntity, pev_weapons) == RPG7_SPECIAL_CODE)
		UTIL_WeaponList(iPlayer, WEAPON_CSW, HUD, get_pcvar_num(cvar_maxammo), WEAPON_SLOT, AMMO_RPG_ROCKET);
}

public HamF_Item_Deploy_Post(iEntity)
{
	if (pev(iEntity, pev_weapons) == RPG7_SPECIAL_CODE)
	{
		new iPlayer = get_pdata_cbase(iEntity, m_pPlayer, XO_CBASEPLAYERITEM);
		new iClip = get_pdata_int(iEntity, m_iClip, XO_CBASEPLAYERWEAPON);
		
		set_pev(iPlayer, pev_viewmodel, g_strViewModel);
		set_pev(iPlayer, pev_weaponmodel, iClip > 0 ? g_strWorldModel : g_strWorldEmptyModel);

		if (iClip > 1)
			set_pdata_int(iEntity, m_iClip, 1);
		
		UTIL_WeaponAnim(iPlayer, iClip > 0 ? draw : draw_none);
		UTIL_ForceWeaponAnim(iPlayer, iEntity, g_rgflRPG7AnimLength[iClip > 0 ? draw : draw_none]);
		UTIL_UpdateBpAmmoCount(iPlayer, AMMO_RPG_ROCKET, get_pdata_int(iEntity, m_iRocketBpammo, XO_CBASEPLAYERWEAPON));
	}
}

public HamF_Item_PostFrame(iEntity)
{
	if (pev(iEntity, pev_weapons) != RPG7_SPECIAL_CODE)
		return HAM_IGNORED;
	
	new iPlayer = get_pdata_cbase(iEntity, m_pPlayer, XO_CBASEPLAYERITEM);
	new iClip = get_pdata_int(iEntity, m_iClip, XO_CBASEPLAYERWEAPON);
	new iAmmo = get_pdata_int(iEntity, m_iRocketBpammo, XO_CBASEPLAYERWEAPON);
	new bitsButtonPressed = get_pdata_int(iPlayer, m_afButtonPressed);

	if (get_pdata_int(iEntity, m_fInReload, XO_CBASEPLAYERWEAPON))
	{
		set_pdata_int(iEntity, m_fInReload, false, XO_CBASEPLAYERWEAPON);

		if (iAmmo > 0 && iClip < 1)
		{
			iClip = 1;
			iAmmo--;

			set_pdata_int(iEntity, m_iClip, iClip, XO_CBASEPLAYERWEAPON);
			set_pdata_int(iEntity, m_iRocketBpammo, iAmmo, XO_CBASEPLAYERWEAPON);

			UTIL_UpdateBpAmmoCount(iPlayer, AMMO_RPG_ROCKET, iAmmo);
		}
	}
	else if (get_pdata_float(iEntity, m_flNextPrimaryAttack, XO_CBASEPLAYERWEAPON) <= 0.0 && bitsButtonPressed & IN_ATTACK)
	{
		if (iClip > 0)
		{
			iClip = 0;
			set_pdata_int(iEntity, m_iClip, iClip, XO_CBASEPLAYERWEAPON);

			UTIL_WeaponAnim(iPlayer, shoot1);
			UTIL_ForceWeaponAnim(iPlayer, iEntity, g_rgflRPG7AnimLength[shoot1]);
			emit_sound(iPlayer, CHAN_WEAPON, LAUNCH_SFX, 1.0, ATTN_NORM, 0, PITCH_NORM);

			new Float:vecRocketOrigin[3];
			get_aim_origin_vector(iPlayer, 32.0, 4.0, 1.0, vecRocketOrigin);

			new Float:vecPlayerOrigin[3], Float:vecPlayerVAngle[3];
			pev(iPlayer, pev_origin, vecPlayerOrigin);
			pev(iPlayer, pev_view_ofs, vecPlayerVAngle);
			xs_vec_add(vecPlayerVAngle, vecPlayerOrigin, vecPlayerOrigin);
			pev(iPlayer, pev_v_angle, vecPlayerVAngle);

			new Float:vecVel[3];
			angle_vector(vecPlayerVAngle, ANGLEVECTOR_FORWARD, vecVel);
			xs_vec_mul_scalar(vecVel, get_pcvar_float(cvar_flyspeed), vecVel);

			new iRocket = LibProjectile_CreateProjectile(iPlayer, vecRocketOrigin, vecVel, ROCKET_MDL, ROCKET_NAME);
			set_pev(iRocket, pev_movetype, MOVETYPE_TOSS);
			set_pev(iRocket, pev_gravity, get_pcvar_float(cvar_gravity));
			set_pev(iRocket, pev_nextthink, get_gametime() + 0.01);

			LibProjectile_AddContrail(iRocket, g_iLawsSprIndex[lawspr_smoketrail], get_pcvar_float(cvar_flyspeed));
			LibProjectile_AddFlare(iRocket);
			LibProjectile_RocketLaunchVFX(vecRocketOrigin, vecPlayerOrigin, vecPlayerVAngle, g_iLawsSprIndex[lawspr_fire], g_iLawsSprIndex[lawspr_smokespr]);
			emit_sound(iRocket, CHAN_STATIC, TRAVEL_SFX, 1.0, 0.5, 0, random_num(94, 102));
			KickBack(iEntity, get_pcvar_float(cvar_recoil), 0.0, get_pcvar_float(cvar_recoil), get_pcvar_float(cvar_recoil) * 0.3, get_pcvar_float(cvar_recoil), get_pcvar_float(cvar_recoil) * 0.3, 2);

			pev(iPlayer, pev_velocity, vecVel);
			vecVel[0] = 0.0;
			vecVel[1] = 0.0;
			set_pev(iPlayer, pev_velocity, vecVel);	// An sudden stop for player.
		}
		else
		{
			ExecuteHamB(Ham_Weapon_ResetEmptySound, iEntity);	// Have to reset before you can play another.
			ExecuteHamB(Ham_Weapon_PlayEmptySound, iEntity);
		}
	}
	else if (iAmmo > 0 && iClip <= 0 && bitsButtonPressed & IN_RELOAD)
	{
		set_pdata_int(iEntity, m_fInReload, true, XO_CBASEPLAYERWEAPON);

		UTIL_WeaponAnim(iPlayer, reload);
		UTIL_ForceWeaponAnim(iPlayer, iEntity, g_rgflRPG7AnimLength[reload]);

		SetAnimation(iPlayer, PLAYER_RELOAD);
		MakeReloadSound(iEntity);
	}

	if (get_pdata_float(iEntity, m_flTimeWeaponIdle, XO_CBASEPLAYERWEAPON) <= 0.0)
	{
		new iAnimSupposeToPlay = idle;
		if (iClip < 1)
			iAnimSupposeToPlay = idle_none;
		
		if (pev(iPlayer, pev_weaponanim) != iAnimSupposeToPlay)
			UTIL_WeaponAnim(iPlayer, iAnimSupposeToPlay);
	}

	set_pev(iPlayer, pev_weaponmodel, iClip > 0 ? g_strWorldModel : g_strWorldEmptyModel);

	return HAM_SUPERCEDE;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////Other Callback Functions/////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

public fw_SetModel(iEntity, szModel[])
{
	if (strcmp(szModel, OLD_WMDL))
		return FMRES_IGNORED;
	
	static szClassName[32];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	if (strcmp(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	
	new iWeapon = get_pdata_cbase(iEntity, m_rgpPlayerItems2[WEAPON_SLOT], XO_CWEAPONBOX);
	if (pev_valid(iWeapon) != 2)
		return FMRES_IGNORED;
	
	if (pev(iWeapon, pev_weapons) != RPG7_SPECIAL_CODE)
		return FMRES_IGNORED;

	engfunc(EngFunc_SetModel, iEntity, get_pdata_int(iWeapon, m_iClip, XO_CBASEPLAYERWEAPON) ? XMDL : XMDL_EMPTY);
	UTIL_WeaponList(pev(iEntity, pev_owner), WEAPON_CSW, WEAPON_ENT);	// Restore original status.
	
	return FMRES_SUPERCEDE;
}

public fw_UpdateClientData_Post(iPlayer, iSendWeapon, hClientData) 
{ 
	if (!is_user_alive(iPlayer)) 
		return;
	
	new iEntity = get_pdata_cbase(iPlayer, m_pActiveItem);
	if (pev_valid(iEntity) != 2)
		return;
	
	if (pev(iEntity, pev_weapons) != RPG7_SPECIAL_CODE)
		return;
	
	if (get_pdata_float(iPlayer, m_flNextAttack) <= 0.0)
		set_cd(hClientData, CD_ID, 0);
}

public Message_DeathMsg(iMsgIndex, iMsgDestType, iReceiver)
{
	new iKiller = get_msg_arg_int(1);
	if (!g_bKillIconHook[iKiller])
		return;

	set_msg_arg_string(4, KILLICON);
}

public HamF_Use_Post(iEntity, id, iActivator, iUseType)
{
	if (iUseType != 0 || !is_user_alive(id))
		return;
	
	new iWeapon = get_pdata_cbase(id, m_pActiveItem);
	if (pev_valid(iWeapon) != 2 ||  pev(iWeapon, pev_weapons) != RPG7_SPECIAL_CODE)
		return;
	
	set_pev(id, pev_viewmodel, g_strViewModel);
	set_pev(id, pev_weaponmodel, get_pdata_int(iWeapon, m_iClip, XO_CBASEPLAYERWEAPON) ? g_strWorldModel : g_strWorldEmptyModel);
}

public HamF_TakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageTypes)
{
	if (pev_valid(iInflictor) != 2)
		return HAM_IGNORED;

	static szClassName[32];
	pev(iInflictor, pev_classname, szClassName, charsmax(szClassName));
	if (strcmp(szClassName, ROCKET_NAME))
		return HAM_IGNORED;
	
	g_bKillIconHook[iAttacker] = true;
	return HAM_IGNORED;
}

public HamF_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageTypes)
{
	g_bKillIconHook[iAttacker] = false;
}

public HamF_Touch(iEntity, iPtd)
{
	if (pev_valid(iEntity) != 2)
		return HAM_IGNORED;
	
	static szClassName[32];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	if (strcmp(szClassName, ROCKET_NAME))
		return HAM_IGNORED;
	
	LibProjectile_DirectHit(iEntity, get_pcvar_float(cvar_directdmg));

	new Float:vecOrigin[3], iPlayer = pev(iEntity, pev_owner);
	pev(iEntity, pev_origin, vecOrigin);
	LibExplosion_RadiusDamage(iPlayer, iEntity, vecOrigin, get_pcvar_float(cvar_radius), get_pcvar_float(cvar_rangedmg));
	LibExplosion_FullVFX(LibProjectile_GetTR());
	LibExplosion_PlayerFX(iEntity, vecOrigin, get_pcvar_float(cvar_playerfxrad),
		get_pcvar_float(cvar_shakedur), get_pcvar_float(cvar_shakefreq), get_pcvar_float(cvar_shakeamp),	// Shake [Dur, Freq, Amp]
		0.25, 0.25,	// Fade
		get_pcvar_float(cvar_punchmax),	// Punch
		get_pcvar_float(cvar_knockvel)	// Knock
	);

	emit_sound(iEntity, CHAN_WEAPON, EXPLO_SFX, 1.2, 0.3, 0, random_num(90, 111));

	UTIL_SoftRemoval(iEntity);
	return HAM_SUPERCEDE;
}

public HamF_Think(iEntity)
{
	if (pev_valid(iEntity) != 2)
		return HAM_IGNORED;
	
	static szClassName[32];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	if (strcmp(szClassName, ROCKET_NAME))
		return HAM_IGNORED;
	
	new Float:vecOrigin[3];
	get_aim_origin_vector(iEntity, -100.0, 1.0, 5.0, vecOrigin);

	LibProjectile_RndFlyingDir(iEntity, get_pcvar_float(cvar_flyoffset), get_pcvar_float(cvar_flyspeed));
	LibProjectile_RocketFlyingVFX(vecOrigin, g_iLawsSprIndex[lawspr_fire2], UTIL_RandomizeSmokeSprite());

	set_pev(iEntity, pev_nextthink, get_gametime() + 0.02);
	return HAM_SUPERCEDE;
}

public fw_HamBotRegisterFunc(iPlayer)
{
	if (!is_user_bot(iPlayer))
		return;
	
	unregister_forward(FM_PlayerPostThink, g_hHamBotRegisterFunction, true);

	RegisterHamFromEntity(Ham_TakeDamage, iPlayer, "HamF_TakeDamage");
	RegisterHamFromEntity(Ham_TakeDamage, iPlayer, "HamF_TakeDamage_Post", true);
}
