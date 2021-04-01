/* AMXX编写头版 by Devzone */

#include <amxmodx>
#include <keyvalues>
#include <hamsandwich>
#include <fakemeta>
#include <offset>
#include <orpheu>
#include <xs>

#define PLUGIN		"空袭"
#define VERSION		"1.6.3"
#define AUTHOR		"Luna the Reborn(xhsu)"

#define pev_fighterkey	pev_iuser2
#define pev_fightertype	pev_iuser3

#define pev_startdist	pev_fuser1
#define pev_soundthink	pev_fuser1
#define pev_burnlast	pev_fuser2
#define pev_burnthink	pev_fuser1

#define pev_targetorg	pev_vuser1
#define pev_srcorigin	pev_vuser1

#define RADIO_KEY	16486345
#define RADIO_VMDL	"models/v_radio.mdl"
#define RADIO_PMDL	"models/p_radio.mdl"

#define GROUP_OP_AND	0
#define GROUP_OP_NAND	1

#define ROCKET_GROUPINFO	(1<<10)
#define PETROL_GROUPINFO	(1<<9)
#define ROCKET_OFFSET		0.35
#define MACHINE_GUN_LAST	20.0
#define GAS_BOMB_DELAY		10.0
#define GAS_BOMB_RANGE		1000.0
#define GAS_BOMB_KNOCK		random_float(1000.0, 1400.0)

enum _:ANIM_e
{
	ANIM_IDLE = 0,
	ANIM_DRAW,
	ANIM_HOLSTER,
	ANIM_USE
};

#define ANIM_DRAW_TIME		1.033333333333333
#define ANIM_HOLSTER_TIME	1.3
#define ANIM_USE_TIME		2.755555555555556

enum _:lawsspr_e
{
	lawspr_smoke = 0,
	lawspr_smoke2,
	lawspr_smokespr,
	lawspr_smokespr2,
	lawspr_rocketexp,
	lawspr_rocketexp2,
	lawspr_smoketrail,
	lawspr_fire,
	lawspr_fire2,
	lawspr_fire3
};
new g_iLawsSprIndex[lawsspr_e];

#define g_CvarFriendlyFire	get_cvar_num("mp_friendlyfire")

enum _:ATTACK_TYPE_e
{
	AS_MISSILE = 0,
	AS_PETROL_BOMB,
	AS_CARPET_BOMBING,
	AS_EXPLOSIVES_CLUSTER,
	AS_MACHINE_GUN,
	AS_GAS_BOMB
};
new const g_szAttackTypeName[ATTACK_TYPE_e][] = 
{
	"精准导弹攻击",	// 美军LV1
	"汽油弹",		// 红军LV1
	"地毯式轰炸",	// 美军LV2
	"集束炸药",		// 红军LV2
	"空中机炮支援",	// 美军LV3
	"燃气炸弹"		// 红军LV3
};
new g_szFighterModels[ATTACK_TYPE_e][256];
new g_szBombModels[ATTACK_TYPE_e][256];

#define RADIO_ASK		(ATTACK_TYPE_e + 1)
#define RADIO_REJECT	(ATTACK_TYPE_e + 2)
new g_szRadioVoice[RADIO_REJECT + 1][256];

#define PETROL_EXPLOSION_DMG	120.0
#define PETROL_RANGE			350.0
#define PETROL_BURING_DMG		10.0
#define PETROL_BURING_LAST		30.0

new const g_szBreakModels[][] = { "models/gibs_wallbrown.mdl", "models/gibs_woodplank.mdl", "models/gibs_brickred.mdl" };
new g_iBreakModels[sizeof g_szBreakModels];
new g_iGunShotDecal[5];

new Float:g_flBurningThink[33];
new Float:g_flFlashingThink[33], Float:g_flAsphyxiaThink[33];

new Float:g_vecTargetOrigin[5][3], Float:g_vecCalledOrigin[33][3][3], g_iInAttack[5];
new g_MsgScreenFade, g_MsgScreenShake, g_MsgBarTime;
new OrpheuFunction:g_pfn_RadiusFlash;

new Float:g_vecFighterSpawn[64][3], g_iFighterSpawnPoints;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "HamF_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_knife", "HamF_Item_PostFrame");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "HamF_Weapon_PrimaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "HamF_Weapon_SecondaryAttack");
	RegisterHam(Ham_Item_Holster, "weapon_knife", "HamF_Item_Holster_Post", 1);
	
	register_forward(FM_ClientCommand, "fw_ClientCommand");
	register_forward(FM_CheckVisibility, "fw_CheckVisibility");
	register_forward(FM_Touch, "fw_Touch_Post", 1);
	register_forward(FM_Think, "fw_Think_Post", 1);
	register_forward(FM_SetGroupMask, "fw_SetGroupMask_Post", 1);
	register_forward(FM_TraceLine, "fw_TraceLine_Post", 1);
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink");
	
	g_MsgScreenFade = get_user_msgid("ScreenFade");
	g_MsgScreenShake = get_user_msgid("ScreenShake");
	g_MsgBarTime = get_user_msgid("BarTime");
	
	g_pfn_RadiusFlash = OrpheuGetFunction("RadiusFlash");
}

public plugin_precache()
{
	precache_model(RADIO_PMDL);
	precache_model(RADIO_VMDL);
	precache_model("models/rpgrocket.mdl");
	
	precache_sound("weapons/law_travel.wav");
	precache_sound("ambience/fire_loop_1.wav");
	precache_sound("misc/breathe.wav");
	precache_sound("misc/earring.wav");
	precache_sound("misc/heartbeat.wav");
	
	new szName[64];
	for (new i = 1; i <= 6; i ++)
	{
		formatex(szName, charsmax(szName), "airsupport/explode/explode_near_%d.wav", i);
		precache_sound(szName);
	}
	
	for (new i = 1; i <= 12; i ++)
	{
		formatex(szName, charsmax(szName), "airsupport/jet/jet_short_%d.wav", i);
		precache_sound(szName);
	}
	
	g_iLawsSprIndex[lawspr_smokespr] = precache_model("sprites/exsmoke.spr");
	g_iLawsSprIndex[lawspr_smokespr2] = precache_model("sprites/rockeexfire.spr");
	g_iLawsSprIndex[lawspr_rocketexp] = precache_model("sprites/rockeexplode.spr");
	g_iLawsSprIndex[lawspr_rocketexp2] = precache_model("sprites/zerogxplode-big1.spr");
	g_iLawsSprIndex[lawspr_smoketrail] = precache_model("sprites/tdm_smoke.spr");
	g_iLawsSprIndex[lawspr_fire] = precache_model("sprites/rockefire.spr");
	g_iLawsSprIndex[lawspr_fire2] = precache_model("sprites/hotglow.spr");
	g_iLawsSprIndex[lawspr_fire3] = precache_model("sprites/flame.spr");
	g_iLawsSprIndex[lawspr_smoke] = precache_model("sprites/gas_smoke1.spr");
	g_iLawsSprIndex[lawspr_smoke2] = precache_model("sprites/wall_puff1.spr");
	
	for (new i = 0; i < sizeof g_szBreakModels; i ++)
		g_iBreakModels[i] = precache_model(g_szBreakModels[i]);
	
	g_iGunShotDecal[0] = engfunc(EngFunc_DecalIndex, "{shot1");
	g_iGunShotDecal[1] = engfunc(EngFunc_DecalIndex, "{shot2");
	g_iGunShotDecal[2] = engfunc(EngFunc_DecalIndex, "{shot3");
	g_iGunShotDecal[3] = engfunc(EngFunc_DecalIndex, "{shot4");
	g_iGunShotDecal[4] = engfunc(EngFunc_DecalIndex, "{shot5");
	
	InitializeSettingFile();
	for (new i = 0; i < ATTACK_TYPE_e; i ++)
	{
		if (strlen(g_szBombModels[i]))
			precache_model(g_szBombModels[i]);
		
		if (strlen(g_szFighterModels[i]))
			precache_model(g_szFighterModels[i]);
		
		/*if (strlen(g_szRadioVoice[i]))
			precache_sound(g_szRadioVoice[i]);*/
	}
	
	//precache_sound(g_szRadioVoice[ATTACK_TYPE_e]);
}

public plugin_cfg()
{
	set_cvar_float("sv_maxvelocity", 99999.0);
	set_cvar_float("sv_maxspeed", 9999.0);
}

public fw_ClientCommand(id)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	new szCommand[64];
	read_argv(0, szCommand, charsmax(szCommand));
	
	if (!strcmp(szCommand, "takeradio"))
	{
		new iEntity = get_pdata_cbase(id, m_pActiveItem);
		new iId = get_pdata_int(iEntity, m_iId, 4);
		
		if (iId == CSW_KNIFE)
		{
			if (pev(iEntity, pev_weapons) == RADIO_KEY)
				return FMRES_SUPERCEDE;
			
			set_pev(id, pev_viewmodel2, RADIO_VMDL);
			set_pev(id, pev_weaponmodel2, RADIO_PMDL);
			
			set_pdata_float(id, m_flNextAttack, ANIM_DRAW_TIME);
			SendWeaponAnim(id, ANIM_DRAW);
			
			set_pev(iEntity, pev_weapons, RADIO_KEY);
		}
		else
		{
			iEntity = get_pdata_cbase(id, m_rgpPlayerItems[3]);
			
			set_pev(iEntity, pev_weapons, RADIO_KEY);
			
			engclient_cmd(id, "weapon_knife");
		}
		
		return FMRES_SUPERCEDE;
	}
	else if (!strcmp(szCommand, "weapon_knife"))
	{
		new iEntity = get_pdata_cbase(id, m_pActiveItem);
		new iId = get_pdata_int(iEntity, m_iId, 4);
		
		if (iId == CSW_KNIFE)
		{
			if (pev(iEntity, pev_weapons) != RADIO_KEY)
				return FMRES_IGNORED;
			
			set_pev(iEntity, pev_weapons, 0);
			
			ExecuteHamB(Ham_Item_Deploy, iEntity);
			
			remove_task(iEntity);
			return FMRES_SUPERCEDE;
		}
	}
	else if (!strcmp(szCommand, "showmetargetorigin"))
	{
		new Float:vecSrc[3], Float:vecEnd[3];
		pev(id, pev_origin, vecSrc);
		pev(id, pev_view_ofs, vecEnd);
		xs_vec_add(vecSrc, vecEnd, vecSrc);
		
		get_aim_origin_vector(id, 9999.0, 0.0, 0.0, vecEnd);
		
		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, id, 0);
		get_tr2(0, TR_vecEndPos, vecEnd);
		
		client_print(id, print_console, "[ORIGIN]%f, %f, %f", vecEnd[0], vecEnd[1], vecEnd[2]);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public fw_CheckVisibility(iEntity, pSetPVS)
{
	if (pev(iEntity, pev_fighterkey) == RADIO_KEY)
	{
		forward_return(FMV_CELL, true);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public fw_Touch_Post(iEntity, iPtd)
{
	if (pev_valid(iEntity) != 2)
		return;
	
	if (pev(iEntity, pev_fighterkey) == RADIO_KEY && pev_valid(iPtd) != 2)
	{
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
		return;
	}
	
	static szClassName[64];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	
	if (!strcmp(szClassName, "rpgrocket"))
	{
		new Float:vecOrigin[3];
		pev(iEntity, pev_origin, vecOrigin);
		if (engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_SKY)
		{
			engfunc(EngFunc_RemoveEntity, iEntity);
			return;
		}
		
		new id = pev(iEntity, pev_owner);
		RandomExplosionSound(iEntity);
		Explosive(id, vecOrigin, 350.0, 8.0, 275.0, 600.0);
		Effect(vecOrigin);
		
		engfunc(EngFunc_RemoveEntity, iEntity);
	}
	else if (!strcmp(szClassName, "petrol_bomb"))
	{
		set_pev(iEntity, pev_solid, SOLID_NOT);
		set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
		set_pev(iEntity, pev_effects, EF_NODRAW);
		set_pev(iEntity, pev_velocity, Float:{0.0, 0.0, 0.0});
		set_pev(iEntity, pev_nextthink, 0.1);
		
		new Float:vecOrigin[3];
		pev(iEntity, pev_origin, vecOrigin);
		
		RandomExplosionSound(iEntity);
		Explosive(pev(iEntity, pev_owner), vecOrigin, PETROL_RANGE, 8.0, PETROL_EXPLOSION_DMG, 100.0);
		Effect(vecOrigin);
		
		set_pev(iEntity, pev_burnlast, get_gametime() + PETROL_BURING_LAST);
	}
}

public fw_Think_Post(iEntity)
{
	if (pev_valid(iEntity) != 2)
		return;
	
	new iType = pev(iEntity, pev_fightertype);
	if (pev(iEntity, pev_fighterkey) == RADIO_KEY && (iType == AS_PETROL_BOMB || iType == AS_EXPLOSIVES_CLUSTER || iType == AS_GAS_BOMB))
	{
		static Float:vecOrigin[3];
		pev(iEntity, pev_origin, vecOrigin);
		
		new id = pev(iEntity, pev_owner);
		if (get_distance_f(vecOrigin, g_vecCalledOrigin[id][1]) <= 20.0)
		{
			xs_vec_copy(g_vecCalledOrigin[id][1], vecOrigin);
			vecOrigin[2] -= 1.0;
			
			if (iType == AS_PETROL_BOMB)
				Throw(id, vecOrigin, "petrol_bomb", g_szBombModels[AS_PETROL_BOMB]);
			else if (iType == AS_EXPLOSIVES_CLUSTER)
			{
				new iBomb = Throw(id, vecOrigin, "explosives_cluster", g_szBombModels[AS_EXPLOSIVES_CLUSTER]);
				set_pev(iBomb, pev_startdist, get_distance_f(vecOrigin, g_vecTargetOrigin[get_pdata_int(id, m_iTeam)]));
				set_pev(iBomb, pev_targetorg, g_vecTargetOrigin[get_pdata_int(id, m_iTeam)]);
				set_pev(iBomb, pev_nextthink, 0.1);
			}
			else if (iType == AS_GAS_BOMB)
			{
				new iBomb = Throw(id, vecOrigin, "gas_bomb", g_szBombModels[AS_GAS_BOMB]);
				set_pev(iBomb, pev_startdist, get_distance_f(vecOrigin, g_vecTargetOrigin[get_pdata_int(id, m_iTeam)]));
				set_pev(iBomb, pev_targetorg, g_vecTargetOrigin[get_pdata_int(id, m_iTeam)]);
				set_pev(iBomb, pev_nextthink, 0.1);
			}
			
			set_pev(iEntity, pev_fightertype, 0);	// 注销其可投掷的能力，防止多发
		}
		
		set_pev(iEntity, pev_nextthink, 0.1);
		return;
	}
	else if (pev(iEntity, pev_fighterkey) == RADIO_KEY && iType == AS_CARPET_BOMBING)
	{
		new Float:vecOrigin3[2][3];
		pev(iEntity, pev_origin, vecOrigin3[0]);
		pev(iEntity, pev_origin, vecOrigin3[1]);
		
		vecOrigin3[0][0] += random_float(-75.0, 75.0);
		vecOrigin3[0][1] += random_float(-75.0, 75.0);
		vecOrigin3[0][2] -= 2.0;
		
		vecOrigin3[1][0] += random_float(-75.0, 75.0);
		vecOrigin3[1][1] += random_float(-75.0, 75.0);
		vecOrigin3[1][2] -= 2.0;
		
		Throw(pev(iEntity, pev_owner), vecOrigin3[0], "rpgrocket", g_szBombModels[AS_CARPET_BOMBING]);
		Throw(pev(iEntity, pev_owner), vecOrigin3[1], "rpgrocket", g_szBombModels[AS_CARPET_BOMBING]);
		
		set_pev(iEntity, pev_nextthink, get_gametime() + 0.2);
		return;
	}
	
	static szClassName[32];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	
	if (!strcmp(szClassName, "petrol_bomb") && pev(iEntity, pev_solid) == SOLID_NOT)
	{
		new id = -1, Float:vecOrigin[3], Float:vecOrigin2[3], Float:flTakeDamage;
		pev(iEntity, pev_origin, vecOrigin);
		while ((id = engfunc(EngFunc_FindEntityInSphere, id, vecOrigin, PETROL_RANGE)) > 0)
		{
			pev(id, pev_takedamage, flTakeDamage);
			if (flTakeDamage == DAMAGE_NO)
				continue;
			
			if (is_user_alive(id) && !g_CvarFriendlyFire && fm_is_user_same_team(pev(iEntity, pev_owner), id))
				continue;
			
			pev(id, pev_origin, vecOrigin2);
			if (!UTIL_PointVisible(vecOrigin, vecOrigin2, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, id))
				continue;
			
			ExecuteHamB(Ham_TakeDamage, id, iEntity, pev(iEntity, pev_owner), PETROL_BURING_DMG, DMG_BURN|DMG_SLOWBURN);
			
			if (is_user_alive(id) && !pev(iEntity, pev_weapons))
				g_flBurningThink[id] = get_gametime() + PETROL_BURING_LAST / random_float(2.0, 4.0);
		}
		
		pev(iEntity, pev_burnlast, flTakeDamage);
		if (flTakeDamage <= get_gametime())
		{
			engfunc(EngFunc_RemoveEntity, iEntity);
			return;
		}
		
		pev(iEntity, pev_soundthink, flTakeDamage);
		if (flTakeDamage <= get_gametime())
		{
			emit_sound(iEntity, CHAN_AUTO, "ambience/fire_loop_1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			set_pev(iEntity, pev_soundthink, get_gametime() + 4.0);
		}
		
		set_pev(iEntity, pev_nextthink, get_gametime() + random_float(0.5, 1.0));
		
		if (pev(iEntity, pev_weapons))
			return;
		
		for (new i = 0; i < 25; i ++)
		{
			vecOrigin2[0] = vecOrigin[0] + random_float(-PETROL_RANGE/2.0, PETROL_RANGE/2.0);
			vecOrigin2[1] = vecOrigin[1] + random_float(-PETROL_RANGE/2.0, PETROL_RANGE/2.0);
			vecOrigin2[2] = vecOrigin[2];
			
			if (engfunc(EngFunc_PointContents, vecOrigin2) != CONTENTS_EMPTY)
				vecOrigin2[2] += get_distance_f(vecOrigin, vecOrigin2);
			
			set_pev(iEntity, pev_origin, vecOrigin2);
			engfunc(EngFunc_DropToFloor, iEntity);
			pev(iEntity, pev_origin, vecOrigin2);
			
			if (engfunc(EngFunc_PointContents, vecOrigin2) != CONTENTS_EMPTY)
				continue;
			
			if (!UTIL_PointVisible(vecOrigin, vecOrigin2))
				continue;
			
			vecOrigin2[2] += random_float(75.0, 95.0);
			
			new iFireEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "cycler_sprite"));
			engfunc(EngFunc_SetOrigin, iFireEntity, vecOrigin2);
			engfunc(EngFunc_SetModel, iFireEntity, "sprites/flame.spr");
			set_pev(iFireEntity, pev_classname, "petrol_fire");
			set_pev(iFireEntity, pev_scale, random_float(0.9, 1.1));
			set_pev(iFireEntity, pev_solid, SOLID_NOT);
			set_pev(iFireEntity, pev_frame, random_float(0.0, float(engfunc(EngFunc_ModelFrames, g_iLawsSprIndex[lawspr_fire3]))));
			set_pev(iFireEntity, pev_framerate, 0.1);
			set_pev(iFireEntity, pev_animtime, get_gametime());
			set_pev(iFireEntity, pev_rendermode, kRenderTransAdd);
			set_pev(iFireEntity, pev_renderamt, 200.0);
			set_pev(iFireEntity, pev_nextthink, get_gametime() + 0.01);
			set_pev(iFireEntity, pev_burnlast, get_gametime() + PETROL_BURING_LAST);
		}
		
		set_pev(iEntity, pev_origin, vecOrigin);
		set_pev(iEntity, pev_weapons, true);
	}
	else if (!strcmp(szClassName, "petrol_fire"))
	{
		new Float:flFrame;
		pev(iEntity, pev_frame, flFrame);
		flFrame += 1.0;
		
		if (flFrame > float(engfunc(EngFunc_ModelFrames, g_iLawsSprIndex[lawspr_fire3])))
		{
			new Float:fUser2;
			pev(iEntity, pev_burnlast, fUser2);
			
			if (fUser2 <= get_gametime())
			{
				engfunc(EngFunc_RemoveEntity, iEntity);
				return;
			}
			
			flFrame = 1.0;
		}
		
		set_pev(iEntity, pev_frame, flFrame);
		set_pev(iEntity, pev_nextthink, get_gametime() + 0.08);
	}
	else if (!strcmp(szClassName, "explosives_cluster"))
	{
		new Float:vecOrigin[3], Float:vecUser1[3];
		pev(iEntity, pev_origin, vecOrigin);
		pev(iEntity, pev_targetorg, vecUser1);
		
		new Float:flStartDistance;
		pev(iEntity, pev_startdist, flStartDistance);
		
		if (get_distance_f(vecOrigin, vecUser1) / flStartDistance <= 0.5)
		{
			Effect(vecOrigin);
			RandomExplosionSound(iEntity);
			
			new Float:flRange = get_distance_f(vecOrigin, vecUser1) * 0.5;
			new Float:vecOrigin2[3];
			for (new i = 0; i < 8; i ++)
			{
				xs_vec_set(vecOrigin2, vecOrigin[0] + random_float(-flRange, flRange), vecOrigin[1] + random_float(-flRange, flRange), vecOrigin[2] + random_float(-flRange, flRange));
				
				Throw(pev(iEntity, pev_owner), vecOrigin2, "rpgrocket", g_szBombModels[AS_EXPLOSIVES_CLUSTER]);
			}
			
			engfunc(EngFunc_SetGroupMask, ROCKET_GROUPINFO, GROUP_OP_NAND);
			engfunc(EngFunc_RemoveEntity, iEntity);
			return;
		}
		
		set_pev(iEntity, pev_nextthink, 0.1);
	}
	else if (!strcmp(szClassName, "rpgrocket"))
	{
		set_pev(iEntity, pev_nextthink, get_gametime() + random_float(0.015, 0.05));
		
		static Float:fCurTime, Float:fUser1;
		global_get(glb_time, fCurTime);
		pev(iEntity, pev_soundthink, fUser1);
		if (fUser1 <= fCurTime)
		{
			set_pev(iEntity, pev_soundthink, fCurTime + 1.0);
			emit_sound(iEntity, CHAN_WEAPON, "weapons/law_travel.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		
		static Float:vecAngles[3];
		pev(iEntity, pev_v_angle, vecAngles);
		vecAngles[0] += random_float(-ROCKET_OFFSET, ROCKET_OFFSET);
		vecAngles[1] += random_float(-ROCKET_OFFSET, ROCKET_OFFSET);
		vecAngles[2] += random_float(-ROCKET_OFFSET, ROCKET_OFFSET);
		set_pev(iEntity, pev_v_angle, vecAngles);
		
		static Float:vecVelocity[3];
		velocity_by_aim(iEntity, 1000, vecVelocity);
		set_pev(iEntity, pev_velocity, vecVelocity);
		vector_to_angle(vecVelocity, vecAngles);
		set_pev(iEntity, pev_angles, vecAngles);
		
		static Float:vecOrigin[3];
		pev(iEntity, pev_origin, vecOrigin);
		get_aim_origin_vector(iEntity, -100.0, 1.0, 5.0, vecOrigin);
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		write_short(g_iLawsSprIndex[lawspr_fire2]);
		write_byte(3);
		write_byte(255);
		message_end();
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecOrigin[0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[2]);
		write_short(g_iLawsSprIndex[random_num(lawspr_smoke, lawspr_smokespr)]);
		write_byte(random_num(1, 10));
		write_byte(random_num(50, 255));
		message_end();
	}
	else if (!strcmp(szClassName, "gas_bomb"))
	{
		new Float:vecOrigin[3];
		pev(iEntity, pev_origin, vecOrigin);
		
		if (pev(iEntity, pev_effects) & EF_NODRAW)
		{
			new id = pev(iEntity, pev_owner);
			Explosive(id, vecOrigin, GAS_BOMB_RANGE, 12.0, 300.0, 0.0);
			
			new Float:vecOrigin2[3];
			for (new i = 0; i < 33; i ++)
			{
				if (!is_user_alive(i))
					continue;
				
				static Float:vecVelocity[3];
				pev(i, pev_origin, vecOrigin2);
				xs_vec_sub(vecOrigin, vecOrigin2, vecVelocity);
				xs_vec_normalize(vecVelocity, vecVelocity);
				xs_vec_mul_scalar(vecVelocity, GAS_BOMB_KNOCK, vecVelocity);
				set_pev(i, pev_velocity, vecVelocity);
				
				get_aim_origin_vector(i, 10.0, 0.0, 0.0, vecVelocity);
				RadiusFlash(vecVelocity, iEntity, id, 1.0);
				
				client_cmd(i, "spk %s", "misc/breathe.wav");
				client_cmd(i, "spk %s", "misc/earring.wav");
				client_cmd(i, "spk %s", "misc/heartbeat.wav");
				client_cmd(i, "room_type 15");
				
				g_flFlashingThink[i] = get_gametime() + 15.0;
				g_flAsphyxiaThink[i] = get_gametime() + 5.0;
			}
			
			for (new i = 0; i < 25; i ++)
			{
				vecOrigin2[0] = vecOrigin[0] + random_float(-GAS_BOMB_RANGE/2.0, GAS_BOMB_RANGE/2.0);
				vecOrigin2[1] = vecOrigin[1] + random_float(-GAS_BOMB_RANGE/2.0, GAS_BOMB_RANGE/2.0);
				vecOrigin2[2] = vecOrigin[2] + random_float(-GAS_BOMB_RANGE/2.0, GAS_BOMB_RANGE/2.0);
				
				if (engfunc(EngFunc_PointContents, vecOrigin2) != CONTENTS_EMPTY)
					continue;
				
				set_pev(iEntity, pev_origin, vecOrigin2);
				engfunc(EngFunc_DropToFloor, iEntity);
				pev(iEntity, pev_origin, vecOrigin2);
				
				if (engfunc(EngFunc_PointContents, vecOrigin2) != CONTENTS_EMPTY)
					continue;
				
				vecOrigin2[2] += random_float(75.0, 95.0);
				
				new iFireEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "cycler_sprite"));
				engfunc(EngFunc_SetOrigin, iFireEntity, vecOrigin2);
				engfunc(EngFunc_SetModel, iFireEntity, "sprites/flame.spr");
				set_pev(iFireEntity, pev_classname, "petrol_fire");
				set_pev(iFireEntity, pev_scale, random_float(0.9, 1.1));
				set_pev(iFireEntity, pev_solid, SOLID_NOT);
				set_pev(iFireEntity, pev_frame, random_float(0.0, float(engfunc(EngFunc_ModelFrames, g_iLawsSprIndex[lawspr_fire3]))));
				set_pev(iFireEntity, pev_framerate, 0.1);
				set_pev(iFireEntity, pev_animtime, get_gametime());
				set_pev(iFireEntity, pev_rendermode, kRenderTransAdd);
				set_pev(iFireEntity, pev_renderamt, 200.0);
				set_pev(iFireEntity, pev_nextthink, get_gametime() + 0.01);
				set_pev(iFireEntity, pev_burnlast, get_gametime() + PETROL_BURING_LAST);
			}
			
			engfunc(EngFunc_RemoveEntity, iEntity);
			return;
		}
		
		new Float:flStartDistance, Float:vecUser1[3];
		pev(iEntity, pev_startdist, flStartDistance);
		pev(iEntity, pev_targetorg, vecUser1);
		
		if (get_distance_f(vecOrigin, vecUser1) / flStartDistance <= 0.25)
		{
			engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
			write_byte(TE_DLIGHT);
			engfunc(EngFunc_WriteCoord, vecOrigin[0]);
			engfunc(EngFunc_WriteCoord, vecOrigin[1]);
			engfunc(EngFunc_WriteCoord, vecOrigin[2]);
			write_byte(255);	// radius
			write_byte(7);		// r
			write_byte(223);	// g
			write_byte(160);	// b
			write_byte(floatround(GAS_BOMB_DELAY * 10.0));		// life
			write_byte(15);		// decay rate
			message_end();
			
			emit_sound(iEntity, CHAN_WEAPON, "weapons/sg_explode.wav", 1.0, 0.3, 0, PITCH_NORM);
			
			set_pev(iEntity, pev_solid, SOLID_NOT);
			set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
			set_pev(iEntity, pev_effects, EF_NODRAW);
			set_pev(iEntity, pev_velocity, Float:{0.0, 0.0, 0.0});
			set_pev(iEntity, pev_nextthink, get_gametime() + GAS_BOMB_DELAY);
			return;
		}
		
		set_pev(iEntity, pev_nextthink, 0.1);
	}
}

public fw_SetGroupMask_Post(iMask, iOperation)
{
	engfunc(EngFunc_SetGroupMask, ROCKET_GROUPINFO, GROUP_OP_NAND);
}

public fw_TraceLine_Post(Float:vecSrc[3], Float:vecEnd[3], iIgnoreType, iSkipEntity, ptr)
{
	if (!is_user_alive(iSkipEntity))
		return;
	
	if (g_iInAttack[get_pdata_int(iSkipEntity, m_iTeam)] != iSkipEntity)
		return;
	
	new Float:vecTargetOrigin[3], Float:vecTemp[3];
	get_tr2(ptr, TR_vecEndPos, vecTargetOrigin);
	xs_vec_set(vecTemp, vecTargetOrigin[0], vecTargetOrigin[1], 9999.0);
	engfunc(EngFunc_TraceLine, vecTargetOrigin, vecTemp, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, get_tr2(ptr, TR_pHit), 0);
	get_tr2(0, TR_vecEndPos, vecTemp);
	
	if (engfunc(EngFunc_PointContents, vecTemp) != CONTENTS_SKY)
	{
		client_print(iSkipEntity, print_center, "请阁下指定室外地点!")
		return;
	}
	
	new Float:vecOrigin[3];
	pev(iSkipEntity, pev_origin, vecOrigin);
	xs_vec_set(vecTemp, vecOrigin[0], vecOrigin[1], 9999.0);
	engfunc(EngFunc_TraceLine, vecOrigin, vecTemp, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, iSkipEntity, 0);
	get_tr2(0, TR_vecEndPos, vecTemp);
	
	if (engfunc(EngFunc_PointContents, vecTemp) != CONTENTS_SKY)
	{
		client_print(iSkipEntity, print_center, "请阁下移驾室外!")
		return;
	}
	
	Explosive(iSkipEntity, vecTargetOrigin, 40.0, 5.0, 70.0, 30.0);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecTargetOrigin, 0);
	write_byte(TE_TRACER);
	engfunc(EngFunc_WriteCoord, vecTemp[0]);
	engfunc(EngFunc_WriteCoord, vecTemp[1]);
	engfunc(EngFunc_WriteCoord, vecTemp[2]);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[2]);
	message_end();
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[2]);
	write_byte(g_iGunShotDecal[random_num(0, 4)]);
	message_end();
	
	new Float:vecVelocity[3];
	get_tr2(ptr, TR_vecPlaneNormal, vecVelocity);
	xs_vec_mul_scalar(vecVelocity, random_float(100.0, 200.0), vecVelocity);
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecTargetOrigin, 0);
	write_byte(TE_BREAKMODEL);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[2]);
	engfunc(EngFunc_WriteCoord, 1.0);
	engfunc(EngFunc_WriteCoord, 1.0);
	engfunc(EngFunc_WriteCoord, 1.0);
	engfunc(EngFunc_WriteCoord, vecVelocity[0]);
	engfunc(EngFunc_WriteCoord, vecVelocity[1]);
	engfunc(EngFunc_WriteCoord, vecVelocity[2]);
	write_byte(10);
	write_short(g_iBreakModels[random_num(0, sizeof g_szBreakModels - 1)]);
	write_byte(random_num(5, 10));
	write_byte(random_num(10, 20));
	write_byte(0x40);
	message_end();
	
	new Float:vecOffset[3];
	xs_vec_sub(vecTargetOrigin, vecTemp, vecOffset);
	xs_vec_normalize(vecOffset, vecOffset);
	xs_vec_mul_scalar(vecOffset, get_distance_f(vecTargetOrigin, vecTemp) - 2.5, vecOffset);
	xs_vec_add(vecTemp, vecOffset, vecTargetOrigin);
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecTargetOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecTargetOrigin[2]);
	write_short(engfunc(EngFunc_ModelIndex, "sprites/wall_puff1.spr"));
	write_byte(random_num(10, 20));
	write_byte(50);
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES);
	message_end();
}

public fw_PlayerPostThink(id)
{
	
	if (g_flFlashingThink[id] <= get_gametime() && g_flFlashingThink[id] > 0.0)
	{
		client_cmd(id, "room_type 0");
		g_flFlashingThink[id] = 0.0;
	}
	else if (g_flAsphyxiaThink[id] <= get_gametime() && g_flFlashingThink[id] > get_gametime())
	{
		ExecuteHamB(Ham_TakeDamage, id, 0, 0, PETROL_BURING_DMG * random_float(0.5, 0.8), DMG_DROWN|DMG_DROWNRECOVER);
		g_flAsphyxiaThink[id] = get_gametime() + 1.0;
	}
	
	if (g_flBurningThink[id] <= get_gametime())
		g_flBurningThink[id] = 0.0;
	
	if (pev(id, pev_flags) & FL_INWATER)
		g_flBurningThink[id] = 0.0;
	
	if (g_flBurningThink[id] == 0.0)
		return;
	
	new Float:fUser1;
	pev(id, pev_burnthink, fUser1);
	if (fUser1 >= get_gametime())
		return;
	
	new Float:vecOrigin[3];
	pev(id, pev_origin, vecOrigin);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + random_float(75.0, 95.0));
	write_short(g_iLawsSprIndex[lawspr_fire3]);
	write_byte(random_num(8, 10));
	write_byte(90);
	message_end();
	
	ExecuteHamB(Ham_TakeDamage, id, 0, 0, PETROL_BURING_DMG * random_float(0.8, 1.0), DMG_BURN|DMG_SLOWBURN);
	set_pev(id, pev_burnthink, get_gametime() + 0.8);
}

public HamF_Item_Deploy_Post(iEntity)
{
	if (pev(iEntity, pev_weapons) != RADIO_KEY)
		return;
	
	new id = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	set_pev(id, pev_viewmodel2, RADIO_VMDL);
	set_pev(id, pev_weaponmodel2, RADIO_PMDL);
		
	set_pdata_float(id, m_flNextAttack, ANIM_DRAW_TIME);
	SendWeaponAnim(id, ANIM_DRAW);
	
	if (pev(iEntity, pev_fightertype) == AS_CARPET_BOMBING)
		set_pev(id, pev_srcorigin, Float:{0.0, 0.0, 0.0});
}

public HamF_Item_PostFrame(iEntity)
{
	if (pev(iEntity, pev_weapons) != RADIO_KEY || pev(iEntity, pev_fightertype) != AS_CARPET_BOMBING)
		return;
	
	new id = get_pdata_cbase(iEntity, m_pPlayer, 4);
	new iTeam = get_pdata_int(id, m_iTeam);
	new bitsButton = get_pdata_int(id, m_afButtonPressed);
	
	if (bitsButton & IN_USE)
	{
		new Float:vecSrc[3], Float:vecEnd[3];
		pev(id, pev_origin, vecSrc);
		pev(id, pev_view_ofs, vecEnd);
		xs_vec_add(vecSrc, vecEnd, vecSrc);
		
		get_aim_origin_vector(id, 9999.0, 0.0, 0.0, vecEnd);
		
		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, id, 0);
		get_tr2(0, TR_vecEndPos, g_vecTargetOrigin[iTeam]);
		
		xs_vec_copy(g_vecTargetOrigin[iTeam], vecEnd);
		vecEnd[2] += 9999.0;
		engfunc(EngFunc_TraceLine, g_vecTargetOrigin[iTeam], vecEnd, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, get_tr2(0, TR_pHit), 0);
		get_tr2(0, TR_vecEndPos, vecEnd);
		
		if (engfunc(EngFunc_PointContents, vecEnd) != CONTENTS_SKY)
		{
			client_print(id, print_center, "你呼叫的起始地点处于室内!");
			return;
		}
		
		client_print(id, print_center, "%s起始点已重置!", g_szAttackTypeName[AS_CARPET_BOMBING]);
		set_pev(id, pev_srcorigin, vecEnd);
	}
}

public HamF_Weapon_PrimaryAttack(iEntity)
{
	if (pev(iEntity, pev_weapons) != RADIO_KEY)
		return HAM_IGNORED;
	
	new id = get_pdata_cbase(iEntity, m_pPlayer, 4);
	new iTeam = get_pdata_int(id, m_iTeam);
	
	if (g_iInAttack[iTeam])
	{
		client_print(id, print_center, "空袭进行中!");
		return HAM_SUPERCEDE;
	}
	else if (pev(iEntity, pev_fightertype) == AS_CARPET_BOMBING)
	{
		new Float:vecUser1[3];
		pev(id, pev_srcorigin, vecUser1);
		
		if (xs_vec_equal(vecUser1, Float:{0.0, 0.0, 0.0}))
		{
			client_print(id, print_center, "请先按下使用键指定起始轰炸点!");
			return HAM_SUPERCEDE;
		}
	}
	
	set_pdata_float(id, m_flNextAttack, ANIM_USE_TIME);
	SendWeaponAnim(id, ANIM_USE);
	client_cmd(id, "spk %s", g_szRadioVoice[RADIO_ASK]);
	
	new Float:vecSrc[3], Float:vecEnd[3];
	pev(id, pev_origin, vecSrc);
	pev(id, pev_view_ofs, vecEnd);
	xs_vec_add(vecSrc, vecEnd, vecSrc);
	
	get_aim_origin_vector(id, 9999.0, 0.0, 0.0, vecEnd);
	
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, id, 0);
	get_tr2(0, TR_vecEndPos, g_vecTargetOrigin[iTeam]);
	
	xs_vec_copy(g_vecTargetOrigin[iTeam], vecEnd);
	vecEnd[2] += 9999.0;
	engfunc(EngFunc_TraceLine, g_vecTargetOrigin[iTeam], vecEnd, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, get_tr2(0, TR_pHit), 0);
	get_tr2(0, TR_vecEndPos, vecEnd);
	
	if (engfunc(EngFunc_PointContents, vecEnd) != CONTENTS_SKY)
	{
		client_print(id, print_center, "你呼叫的目标地点处于室内!");
		set_task(ANIM_USE_TIME, "Task_RejectRadio", id + RADIO_KEY * 2);
		return HAM_SUPERCEDE;
	}
	
	xs_vec_copy(g_vecTargetOrigin[iTeam], vecSrc);
	vecSrc[2] -= 9999.0;
	engfunc(EngFunc_TraceLine, vecEnd, vecSrc, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, get_tr2(0, TR_pHit), 0);		// 变量名与实际情况无关, 我这边这样是因为vecEnd在天上, 肯定是空对地导弹啊= =
	get_tr2(0, TR_vecEndPos, g_vecTargetOrigin[iTeam]);
	
	xs_vec_copy(vecSrc, g_vecCalledOrigin[id][0]);
	xs_vec_copy(vecEnd, g_vecCalledOrigin[id][1]);
	pev(id, pev_origin, g_vecCalledOrigin[id][2]);
	
	set_task(ANIM_USE_TIME, "Task_HolsterAnim", iEntity);
	
	return HAM_SUPERCEDE;
}

public HamF_Weapon_SecondaryAttack(iEntity)
{
	if (pev(iEntity, pev_weapons) != RADIO_KEY)
		return HAM_IGNORED;
	
	new iType = pev(iEntity, pev_fightertype) + 1;
	if (iType >= ATTACK_TYPE_e)
		iType = 0;
	
	new id = get_pdata_cbase(iEntity, m_pPlayer, 4);
	
	set_pev(iEntity, pev_fightertype, iType);
	client_print(id, print_center, "切换为%s", g_szAttackTypeName[iType]);
	set_pdata_float(id, m_flNextAttack, 0.5, 4);
	
	return HAM_SUPERCEDE;
}

public HamF_Item_Holster_Post(iEntity)
{
	set_pev(iEntity, pev_weapons, 0);
	
	remove_task(iEntity);
}

public Task_HolsterAnim(iEntity)
{
	new id = get_pdata_cbase(iEntity, m_pPlayer, 4);
	new iTeam = get_pdata_int(id, m_iTeam);
	new iType = pev(iEntity, pev_fightertype);
	
	set_pdata_float(id, m_flNextAttack, ANIM_HOLSTER_TIME);
	SendWeaponAnim(id, ANIM_HOLSTER);
	client_cmd(id, "spk %s", g_szRadioVoice[iType]);
	
	if (iType == AS_MISSILE)
	{
		new Float:vecOrigin[3];
		Call(id, iTeam, g_vecCalledOrigin[id][0], g_vecCalledOrigin[id][1], vecOrigin, g_szFighterModels[AS_MISSILE]);
		
		engfunc(EngFunc_SetGroupMask, ROCKET_GROUPINFO, GROUP_OP_NAND);
		Launch(id, vecOrigin, g_vecTargetOrigin[iTeam]);
	}
	else if (iType == AS_MACHINE_GUN)
	{
		client_print(id, print_center, "飞机已经到位");
		
		emessage_begin(MSG_ONE, g_MsgBarTime, _, id);
		ewrite_short(floatround(MACHINE_GUN_LAST));
		emessage_end();
		
		g_iInAttack[iTeam] = id;
		set_task(MACHINE_GUN_LAST, "Task_StopAttack", iTeam + RADIO_KEY);
	}
	else if (iType == AS_PETROL_BOMB || iType == AS_EXPLOSIVES_CLUSTER || iType == AS_GAS_BOMB)
	{
		new Float:vecTemp[3];
		new iFighter = Call(id, iTeam, g_vecCalledOrigin[id][0], g_vecCalledOrigin[id][1], vecTemp, g_szFighterModels[iType]);
		set_pev(iFighter, pev_fightertype, iType);
		set_pev(iFighter, pev_nextthink, 0.1);
	}
	else if (iType == AS_CARPET_BOMBING)
	{
		new Float:vecAngles[3], Float:vecSrc[3], Float:vecVelocity[3];
		pev(id, pev_srcorigin, vecSrc);
		vecSrc[2] -= 1.0;
		g_vecCalledOrigin[id][1][2] -= 1.0;
		xs_vec_sub(g_vecCalledOrigin[id][1], vecSrc, vecVelocity);
		vector_to_angle(vecVelocity, vecAngles);
		xs_vec_normalize(vecVelocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, 1000.0, vecVelocity);
		
		new iFighter = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		engfunc(EngFunc_SetOrigin, iFighter, vecSrc);
		engfunc(EngFunc_SetModel, iFighter, g_szFighterModels[AS_CARPET_BOMBING]);
		engfunc(EngFunc_SetSize, iFighter, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});
		set_pev(iFighter, pev_classname, "fighter");
		set_pev(iFighter, pev_solid, SOLID_TRIGGER);
		set_pev(iFighter, pev_movetype, MOVETYPE_FLY);
		set_pev(iFighter, pev_angles, vecAngles);
		set_pev(iFighter, pev_v_angle, vecAngles);
		set_pev(iFighter, pev_velocity, vecVelocity);
		set_pev(iFighter, pev_fighterkey, RADIO_KEY);
		set_pev(iFighter, pev_fightertype, AS_CARPET_BOMBING);
		set_pev(iFighter, pev_groupinfo, ROCKET_GROUPINFO);
		set_pev(iFighter, pev_owner, id);
		set_pev(iFighter, pev_nextthink, 0.1);
	}
	
	set_task(ANIM_HOLSTER_TIME, "Task_Holster", iEntity + RADIO_KEY);
}

public Task_Holster(iEntity)
{
	iEntity -= RADIO_KEY;
	
	new id = get_pdata_cbase(iEntity, m_pPlayer, 4);
	if (!is_user_alive(id))
		return;
	
	if (pev(iEntity, pev_weapons) != RADIO_KEY || get_pdata_cbase(id, m_pActiveItem) != iEntity)
		return;
	
	engclient_cmd(id, "lastinv");
}

public Task_StopAttack(iTeam)
{
	iTeam -= RADIO_KEY;
	g_iInAttack[iTeam] = 0;
}

public Task_RejectRadio(id)
{
	id -= RADIO_KEY * 2;
	
	client_cmd(id, "spk %s", g_szRadioVoice[RADIO_REJECT]);
}

public Call(id, iTeam, Float:vecSrc[3], Float:vecEnd[3], Float:vecReturn[3], const szModel[])
{
	new Float:vecOrigin[3];
	if (g_iFighterSpawnPoints)
	{
		new Float:flFraction, bool:bSucceeded = false;
		for (new i = 0; i < g_iFighterSpawnPoints; i ++)
		{
			engfunc(EngFunc_TraceLine, g_vecFighterSpawn[i], g_vecTargetOrigin[iTeam], DONT_IGNORE_MONSTERS, 0, 0);
			get_tr2(0, TR_flFraction, flFraction);
			
			if (flFraction >= 1.0)
			{
				engfunc(EngFunc_TraceLine, g_vecFighterSpawn[i], vecEnd, DONT_IGNORE_MONSTERS, 0, 0);
				get_tr2(0, TR_flFraction, flFraction);
				
				if (flFraction >= 1.0)
				{
					xs_vec_copy(g_vecFighterSpawn[i], vecOrigin);
					bSucceeded = true;
					break;
				}
			}
		}
		
		if (!bSucceeded)
			goto LAB_GET_FROM_PLAYER;
	}
	else
	{
		LAB_GET_FROM_PLAYER:
		xs_vec_copy(g_vecCalledOrigin[id][2], vecOrigin);
		vecOrigin[2] = vecEnd[2] - 1.0;
	}
	
	new Float:vecAngles[3];
	vecEnd[2] -= 1.0;	// 确保不会一开始就直接打到天空上- -
	xs_vec_sub(vecEnd, vecOrigin, vecSrc);
	vector_to_angle(vecSrc, vecAngles);
	xs_vec_normalize(vecSrc, vecSrc);
	xs_vec_mul_scalar(vecSrc, 3000.0, vecSrc);
	
	new iFighter = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	engfunc(EngFunc_SetOrigin, iFighter, vecOrigin);
	engfunc(EngFunc_SetModel, iFighter, szModel);
	engfunc(EngFunc_SetSize, iFighter, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});
	set_pev(iFighter, pev_classname, "fighter");
	set_pev(iFighter, pev_solid, SOLID_TRIGGER);
	set_pev(iFighter, pev_movetype, MOVETYPE_FLY);
	set_pev(iFighter, pev_angles, vecAngles);
	set_pev(iFighter, pev_v_angle, vecAngles);
	set_pev(iFighter, pev_velocity, vecSrc);
	set_pev(iFighter, pev_fighterkey, RADIO_KEY);
	set_pev(iFighter, pev_groupinfo, ROCKET_GROUPINFO);
	set_pev(iFighter, pev_owner, id);
	
	vecOrigin[2] -= 1.0;
	xs_vec_copy(vecOrigin, vecReturn);
	
	new szName[64];
	formatex(szName, charsmax(szName), "airsupport/jet/jet_short_%d.wav", random_num(1, 12));
	for (new i = 1; i <= global_get(glb_maxClients); i ++)
		client_cmd(i, "spk %s", szName);
	
	return iFighter;
}

public Explosive(iAttacker, const Float:vecOrigin[3], Float:flRange, Float:flPunchMax, Float:flDamage, Float:flKnockForce)
{
	new id = -1, Float:flTakeDamage, szClassName[32], Float:vecOrigin2[3], Float:flDistance, Float:flRealDamage;
	
	while ((id = engfunc(EngFunc_FindEntityInSphere, id, vecOrigin, flRange)) > 0)
	{
		pev(id, pev_takedamage, flTakeDamage);
		if (flTakeDamage == DAMAGE_NO)
			continue;
		
		if (is_user_alive(id) && !g_CvarFriendlyFire && fm_is_user_same_team(iAttacker, id))
			continue;
		
		pev(id, pev_classname, szClassName, charsmax(szClassName));
		if (!strcmp(szClassName, "func_breakable") || !strcmp(szClassName, "func_pushable"))
		{
			dllfunc(DLLFunc_Use, iAttacker, id);
			continue;
		}
		
		pev(id, pev_origin, vecOrigin2);
		flDistance = get_distance_f(vecOrigin, vecOrigin2);
		flRealDamage = flDamage * ((flRange - flDistance) / flRange);
		
		if (flRealDamage <= 0.0)
			continue;
		
		if (UTIL_PointVisible(vecOrigin, vecOrigin2, _, id))
			flRealDamage *= random_float(0.4, 0.5);
		
		ExecuteHamB(Ham_TakeDamage, id, 0, iAttacker, flRealDamage, DMG_BLAST);
		
		if (!is_user_alive(id))
			continue;
		
		emessage_begin(MSG_ONE_UNRELIABLE, g_MsgScreenShake, _, id);
		ewrite_short(1<<13);
		ewrite_short(1<<13);
		ewrite_short(1<<13);
		emessage_end();
		
		emessage_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id);
		ewrite_short(1<<10);
		ewrite_short(0);
		ewrite_short(0x0000);
		ewrite_byte(255);
		ewrite_byte(255);
		ewrite_byte(255);
		ewrite_byte(255);
		emessage_end();
		
		new Float:vecPunchAngle[3];
		vecPunchAngle[0] = random_float(-flPunchMax, flPunchMax)
		vecPunchAngle[1] = random_float(-flPunchMax, flPunchMax)
		vecPunchAngle[2] = random_float(-flPunchMax, flPunchMax)
		set_pev(id, pev_punchangle, vecPunchAngle)
		
		new Float:vecVelocity[3], Float:flSpeed;
		xs_vec_sub(vecOrigin2, vecOrigin, vecVelocity);								// 创造一个向量, 方向指向受害者的点。(计算时需要将受害者的坐标减去爆炸中心)
		xs_vec_normalize(vecVelocity, vecVelocity);									// 修正此向量为单位向量
		flSpeed = floatpower(flKnockForce, (flRange - flDistance) / flRange);		// 以指数衰减定义冲击波
		xs_vec_mul_scalar(vecVelocity, flSpeed, vecVelocity);						// 向量数乘, 将速率转为速度
		vecVelocity[2] += flKnockForce * random_float(0.35, 0.45);					// 强化竖直方向上的速度
		set_pev(id, pev_velocity, vecVelocity);										// 给受害者设置计算完毕的速度(即击退)
	}
}

public Effect(Float:vecOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 200.0);
	write_short(g_iLawsSprIndex[lawspr_rocketexp]);
	write_byte(20);
	write_byte(100);
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 70.0);
	write_short(g_iLawsSprIndex[lawspr_rocketexp2]);
	write_byte(30);
	write_byte(255);
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_WORLDDECAL);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_byte(engfunc(EngFunc_DecalIndex, "{scorch1"));
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_DLIGHT);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_byte(50);
	write_byte(255);
	write_byte(0);
	write_byte(0);
	write_byte(2);
	write_byte(0);
	message_end();
	
	new Float:vecSrc[3], Float:vecEnd[3], Float:vecPlaneNormal[3];
	xs_vec_set(vecSrc, vecOrigin[0], vecOrigin[1], vecOrigin[2] + 9999.0);
	xs_vec_set(vecEnd, vecOrigin[0], vecOrigin[1], vecOrigin[2] - 9999.0);
	engfunc(EngFunc_TraceLine, vecOrigin, vecSrc, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, 0, 0);
	get_tr2(0, TR_vecEndPos, vecSrc);
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS|IGNORE_MISSILE|IGNORE_GLASS, 0, 0);
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNormal);
	
	new iEntity;
	for (new i = 0; i < 3; i ++)
	{
		iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "spark_shower"));
		engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);
		set_pev(iEntity, pev_angles, vecPlaneNormal);
		xs_vec_set(vecSrc, vecOrigin[0] + 1.0, vecOrigin[1] + 1.0, vecOrigin[2] + 1.0);
		xs_vec_set(vecEnd, vecOrigin[0] - 1.0, vecOrigin[1] - 1.0, vecOrigin[2] - 1.0);
		set_pev(iEntity, pev_absmin, vecEnd);
		set_pev(iEntity, pev_absmax, vecSrc);
		dllfunc(DLLFunc_Spawn, iEntity);
	}
	
	if (engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_WATER)
		return;
	
	vecOrigin[2] += 40.0;
	
	new Float:vecOrigin2[8][3], Float:vecOrigin3[21][3], Float:vecPosition[3];
	xs_vec_copy(vecOrigin, vecPosition);
	get_spherical_coord(vecPosition, 100.0, 20.0, 0.0, vecOrigin3[0]);
	get_spherical_coord(vecPosition, 0.0, 100.0, 0.0, vecOrigin3[1]);
	get_spherical_coord(vecPosition, 100.0, 100.0, 0.0, vecOrigin3[2]);
	get_spherical_coord(vecPosition, 70.0, 120.0, 0.0, vecOrigin3[3]);
	get_spherical_coord(vecPosition, 120.0, 20.0, 0.0, vecOrigin3[4]);
	get_spherical_coord(vecPosition, 120.0, 65.0, 0.0, vecOrigin3[5]);
	get_spherical_coord(vecPosition, 120.0, 110.0, 0.0, vecOrigin3[6]);
	get_spherical_coord(vecPosition, 120.0, 155.0, 0.0, vecOrigin3[7]);
	get_spherical_coord(vecPosition, 120.0, 200.0, 0.0, vecOrigin3[8]);
	get_spherical_coord(vecPosition, 120.0, 245.0, 0.0, vecOrigin3[9]);
	get_spherical_coord(vecPosition, 120.0, 290.0, 20.0, vecOrigin3[10]);
	get_spherical_coord(vecPosition, 120.0, 335.0, 20.0, vecOrigin3[11]);
	get_spherical_coord(vecPosition, 120.0, 40.0, 20.0, vecOrigin3[12]);
	get_spherical_coord(vecPosition, 40.0, 120.0, 20.0, vecOrigin3[13]);
	get_spherical_coord(vecPosition, 40.0, 110.0, 20.0, vecOrigin3[14]);
	get_spherical_coord(vecPosition, 60.0, 110.0, 20.0, vecOrigin3[15]);
	get_spherical_coord(vecPosition, 110.0, 40.0, 20.0, vecOrigin3[16]);
	get_spherical_coord(vecPosition, 120.0, 30.0, 20.0, vecOrigin3[17]);
	get_spherical_coord(vecPosition, 30.0, 130.0, 20.0, vecOrigin3[18]);
	get_spherical_coord(vecPosition, 30.0, 125.0, 20.0, vecOrigin3[19]);
	get_spherical_coord(vecPosition, 30.0, 120.0, 20.0, vecOrigin3[20]);
	
	for (new i = 0; i < 21; i++)
	{
		if (i < 8)
		{
			engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, vecOrigin, 0);
			write_byte(TE_BREAKMODEL);
			engfunc(EngFunc_WriteCoord, vecOrigin[0]);
			engfunc(EngFunc_WriteCoord, vecOrigin[1]);
			engfunc(EngFunc_WriteCoord, vecOrigin[2]);
			engfunc(EngFunc_WriteCoord, 1.0);
			engfunc(EngFunc_WriteCoord, 1.0);
			engfunc(EngFunc_WriteCoord, 1.0);
			engfunc(EngFunc_WriteCoord, random_float(-500.0, 500.0));
			engfunc(EngFunc_WriteCoord, random_float(-500.0, 500.0));
			engfunc(EngFunc_WriteCoord, random_float(-300.0, 300.0));
			write_byte(10);
			write_short(g_iBreakModels[random_num(0, sizeof g_szBreakModels - 1)]);
			write_byte(random_num(1, 4));
			write_byte(random_num(4, 8) * 10);
			write_byte(0x40);
			message_end();
		}
		
		MakeSmoke(vecOrigin3[i], g_iLawsSprIndex[lawspr_smokespr2], 10, 255);
	}
	
	vecOrigin[2] += 120.0;

	get_spherical_coord(vecOrigin, 0.0, 0.0, 185.0, vecOrigin2[0]);
	get_spherical_coord(vecOrigin, 0.0, 80.0, 130.0, vecOrigin2[1]);
	get_spherical_coord(vecOrigin, 41.0, 43.0, 110.0, vecOrigin2[2]);
	get_spherical_coord(vecOrigin, 90.0, 90.0, 90.0, vecOrigin2[3]);
	get_spherical_coord(vecOrigin, 80.0, 25.0, 185.0, vecOrigin2[4]);
	get_spherical_coord(vecOrigin, 101.0, 100.0, 162.0, vecOrigin2[5]);
	get_spherical_coord(vecOrigin, 68.0, 35.0, 189.0, vecOrigin2[6]);
	get_spherical_coord(vecOrigin, 0.0, 95.0, 155.0, vecOrigin2[7]);
	
	for (new i = 0; i < 8; i++)
		MakeSmoke(vecOrigin2[i], g_iLawsSprIndex[lawspr_smoke], 50, 50);
}

public Launch(id, const Float:vecSrc[3], const Float:vecEnd[3])
{
	new Float:vecTemp[3], Float:vecAngles[3];
	xs_vec_sub(vecEnd, vecSrc, vecTemp);
	xs_vec_normalize(vecTemp, vecTemp);
	xs_vec_mul_scalar(vecTemp, 1000.0, vecTemp);
	vector_to_angle(vecTemp, vecAngles);
	
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	engfunc(EngFunc_SetOrigin, iEntity, vecSrc);
	engfunc(EngFunc_SetModel, iEntity, g_szBombModels[AS_MISSILE]);
	engfunc(EngFunc_SetSize, iEntity, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});
	set_pev(iEntity, pev_classname, "rpgrocket");
	set_pev(iEntity, pev_owner, id);
	set_pev(iEntity, pev_solid, SOLID_BBOX);
	set_pev(iEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(iEntity, pev_gravity, 1.0);
	set_pev(iEntity, pev_angles, vecAngles);
	vecAngles[0] *= -1.0;	// 这就是vangle和angles的换算 -3.0
	set_pev(iEntity, pev_v_angle, vecAngles);
	set_pev(iEntity, pev_velocity, vecTemp);
	set_pev(iEntity, pev_groupinfo, ROCKET_GROUPINFO);
	fw_Think_Post(iEntity);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecSrc, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, vecSrc[0]);
	engfunc(EngFunc_WriteCoord, vecSrc[1]);
	engfunc(EngFunc_WriteCoord, vecSrc[2]);
	write_short(g_iLawsSprIndex[lawspr_fire]);
	write_byte(5);
	write_byte(255);
	message_end();
	
	set_pev(iEntity, pev_effects, EF_LIGHT | EF_BRIGHTLIGHT);
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(g_iLawsSprIndex[lawspr_smoketrail]);
	write_byte(floatround(1000.0/100.0));
	write_byte(3);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	write_byte(255);
	message_end();
	
	new Float:vecOrigin[5][3];
	get_spherical_coord(vecSrc, 20.0, 30.0, 5.0, vecOrigin[0]);
	get_spherical_coord(vecSrc, 20.0, -20.0, -5.0, vecOrigin[1]);
	get_spherical_coord(vecSrc, -14.0, 30.0, 7.0, vecOrigin[2]);
	get_spherical_coord(vecSrc, 25.0, 10.0, -8.0, vecOrigin[3]);
	get_spherical_coord(vecSrc, -17.0, 17.0, 0.0, vecOrigin[4]);
	
	for (new i = 0; i < 5; i++)
	{
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin[i], 0);
		write_byte(TE_SPRITE);
		engfunc(EngFunc_WriteCoord, vecOrigin[i][0]);
		engfunc(EngFunc_WriteCoord, vecOrigin[i][1]);
		engfunc(EngFunc_WriteCoord, vecOrigin[i][2]);
		write_short(g_iLawsSprIndex[lawspr_smokespr]);
		write_byte(10);
		write_byte(50);
		message_end();
	}
}

public Throw(id, const Float:vecOrigin[3], const szClassName[], const szModel[])
{
	new iBomb = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	engfunc(EngFunc_SetOrigin, iBomb, vecOrigin);
	engfunc(EngFunc_SetModel, iBomb, szModel);
	engfunc(EngFunc_SetSize, iBomb, Float:{-2.0, -2.0, -2.0}, Float:{2.0, 2.0, 2.0});
	set_pev(iBomb, pev_classname, szClassName);
	set_pev(iBomb, pev_owner, id);
	set_pev(iBomb, pev_solid, SOLID_BBOX);
	set_pev(iBomb, pev_movetype, MOVETYPE_FLY);
	set_pev(iBomb, pev_velocity, Float:{0.0, 0.0, -500.0});
	set_pev(iBomb, pev_groupinfo, ROCKET_GROUPINFO);
	
	static Float:vecAngles[3];
	vector_to_angle(Float:{0.0, 0.0, -1.0}, vecAngles);
	set_pev(iBomb, pev_angles, vecAngles);
	vecAngles[0] *= -1.0;
	set_pev(iBomb, pev_v_angle, vecAngles);
	
	return iBomb;
}

public InitializeSettingFile()
{
	g_iFighterSpawnPoints = 0;
	for (new i = 0; i < ATTACK_TYPE_e; i ++)
	{
		formatex(g_szBombModels[i], charsmax(g_szBombModels[]), "");
		formatex(g_szFighterModels[i], charsmax(g_szFighterModels[]), "");
	}
	
	new szLineData[512];
	get_localinfo("amxx_configsdir", szLineData, charsmax(szLineData));
	format(szLineData, charsmax(szLineData), "%s/airsupport.txt", szLineData);
	
	new szMapName[64];
	global_get(glb_mapname, szMapName, charsmax(szMapName));
	
	new hMapSpawnOrigin = kv_create(), hGlobalSetting;
	kv_load_from_file(hMapSpawnOrigin, szLineData);
	hGlobalSetting = kv_find_key(hMapSpawnOrigin, "global_setting");
	hMapSpawnOrigin = kv_find_key(hMapSpawnOrigin, szMapName);
	
	if (!hMapSpawnOrigin)
		hMapSpawnOrigin = hGlobalSetting;
	
	new hValue, szName[128];
	hValue = kv_get_first_value(hMapSpawnOrigin);
	
	while (hValue)
	{
		kv_get_name(hValue, szName, charsmax(szName));
		
		if (containi(szName, "origin") != -1)
		{
			kv_get_string(hValue, "", szLineData, charsmax(szLineData));
			
			UTIL_StrToVector(szLineData, g_vecFighterSpawn[g_iFighterSpawnPoints]);
			g_iFighterSpawnPoints ++;
		}
		else if (!strcmp(szName, "missile_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_MISSILE], charsmax(g_szFighterModels[]));
		else if (!strcmp(szName, "petrol_bomb_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_PETROL_BOMB], charsmax(g_szFighterModels[]));
		else if (!strcmp(szName, "carpet_bomb_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_CARPET_BOMBING], charsmax(g_szFighterModels[]));
		else if (!strcmp(szName, "explosives_cluster_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_EXPLOSIVES_CLUSTER], charsmax(g_szFighterModels[]));
		else if (!strcmp(szName, "machine_gun_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_MACHINE_GUN], charsmax(g_szFighterModels[]));
		else if (!strcmp(szName, "gas_bomb_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_GAS_BOMB], charsmax(g_szFighterModels[]));
		else if (!strcmp(szName, "missile_bomb_model"))
			kv_get_string(hValue, "", g_szBombModels[AS_MISSILE], charsmax(g_szBombModels[]));
		else if (!strcmp(szName, "petrol_bomb_model"))
			kv_get_string(hValue, "", g_szBombModels[AS_PETROL_BOMB], charsmax(g_szBombModels[]));
		else if (!strcmp(szName, "carpet_bomb_model"))
			kv_get_string(hValue, "", g_szBombModels[AS_CARPET_BOMBING], charsmax(g_szBombModels[]));
		else if (!strcmp(szName, "explosives_cluster_bomb_model"))
			kv_get_string(hValue, "", g_szBombModels[AS_EXPLOSIVES_CLUSTER], charsmax(g_szBombModels[]));
		else if (!strcmp(szName, "gas_bomb_model"))
			kv_get_string(hValue, "", g_szBombModels[AS_GAS_BOMB], charsmax(g_szBombModels[]));
		else if (!strcmp(szName, "missile_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_MISSILE], charsmax(g_szRadioVoice[]));
		else if (!strcmp(szName, "petrol_bomb_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_PETROL_BOMB], charsmax(g_szRadioVoice[]));
		else if (!strcmp(szName, "carpet_bomb_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_CARPET_BOMBING], charsmax(g_szRadioVoice[]));
		else if (!strcmp(szName, "explosives_cluster_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_EXPLOSIVES_CLUSTER], charsmax(g_szRadioVoice[]));
		else if (!strcmp(szName, "machine_gun_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_MACHINE_GUN], charsmax(g_szRadioVoice[]));
		else if (!strcmp(szName, "gas_bomb_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_GAS_BOMB], charsmax(g_szRadioVoice[]));
		else if (!strcmp(szName, "request_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[RADIO_ASK], charsmax(g_szRadioVoice[]));
		else if (!strcmp(szName, "reject_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[RADIO_REJECT], charsmax(g_szRadioVoice[]));
		
		hValue = kv_get_next_value(hValue);
	}
	
	hValue = kv_get_first_value(hGlobalSetting);
	while (hValue)
	{
		kv_get_name(hValue, szName, charsmax(szName));
		
		if (!strlen(g_szFighterModels[AS_MISSILE]) && !strcmp(szName, "missile_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_MISSILE], charsmax(g_szFighterModels[]));
		else if (!strlen(g_szFighterModels[AS_PETROL_BOMB]) && !strcmp(szName, "petrol_bomb_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_PETROL_BOMB], charsmax(g_szFighterModels[]));
		else if (!strlen(g_szFighterModels[AS_CARPET_BOMBING]) && !strcmp(szName, "carpet_bomb_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_CARPET_BOMBING], charsmax(g_szFighterModels[]));
		else if (!strlen(g_szFighterModels[AS_EXPLOSIVES_CLUSTER]) && !strcmp(szName, "explosives_cluster_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_EXPLOSIVES_CLUSTER], charsmax(g_szFighterModels[]));
		else if (!strlen(g_szFighterModels[AS_MACHINE_GUN]) && !strcmp(szName, "machine_gun_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_MACHINE_GUN], charsmax(g_szFighterModels[]));
		else if (!strlen(g_szFighterModels[AS_GAS_BOMB]) && !strcmp(szName, "gas_bomb_fighter"))
			kv_get_string(hValue, "", g_szFighterModels[AS_GAS_BOMB], charsmax(g_szFighterModels[]));
		else if (!strlen(g_szBombModels[AS_MISSILE]) && !strcmp(szName, "missile_bomb_model"))
			kv_get_string(hValue, "", g_szBombModels[AS_MISSILE], charsmax(g_szBombModels[]));
		else if (!strlen(g_szBombModels[AS_PETROL_BOMB]) && !strcmp(szName, "petrol_bomb_model"))
			kv_get_string(hValue, "", g_szBombModels[AS_PETROL_BOMB], charsmax(g_szBombModels[]));
		else if (!strlen(g_szBombModels[AS_CARPET_BOMBING]) && !strcmp(szName, "carpet_bomb_model"))
			kv_get_string(hValue, "", g_szBombModels[AS_CARPET_BOMBING], charsmax(g_szBombModels[]));
		else if (!strlen(g_szBombModels[AS_EXPLOSIVES_CLUSTER]) && !strcmp(szName, "explosives_cluster_bomb_model"))
			kv_get_string(hValue, "", g_szBombModels[AS_EXPLOSIVES_CLUSTER], charsmax(g_szBombModels[]));
		else if (!strlen(g_szBombModels[AS_GAS_BOMB]) && !strcmp(szName, "gas_bomb_model"))
			kv_get_string(hValue, "", g_szBombModels[AS_GAS_BOMB], charsmax(g_szBombModels[]));
		else if (!strlen(g_szRadioVoice[AS_MISSILE]) && !strcmp(szName, "missile_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_MISSILE], charsmax(g_szRadioVoice[]));
		else if (!strlen(g_szRadioVoice[AS_PETROL_BOMB]) && !strcmp(szName, "petrol_bomb_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_PETROL_BOMB], charsmax(g_szRadioVoice[]));
		else if (!strlen(g_szRadioVoice[AS_CARPET_BOMBING]) && !strcmp(szName, "carpet_bomb_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_CARPET_BOMBING], charsmax(g_szRadioVoice[]));
		else if (!strlen(g_szRadioVoice[AS_EXPLOSIVES_CLUSTER]) && !strcmp(szName, "explosives_cluster_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_EXPLOSIVES_CLUSTER], charsmax(g_szRadioVoice[]));
		else if (!strlen(g_szRadioVoice[AS_MACHINE_GUN]) && !strcmp(szName, "machine_gun_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_MACHINE_GUN], charsmax(g_szRadioVoice[]));
		else if (!strlen(g_szRadioVoice[AS_GAS_BOMB]) && !strcmp(szName, "gas_bomb_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[AS_GAS_BOMB], charsmax(g_szRadioVoice[]));
		else if (!strlen(g_szRadioVoice[RADIO_ASK]) && !strcmp(szName, "request_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[RADIO_ASK], charsmax(g_szRadioVoice[]));
		else if (!strlen(g_szRadioVoice[RADIO_REJECT]) && !strcmp(szName, "reject_radio"))
			kv_get_string(hValue, "", g_szRadioVoice[RADIO_REJECT], charsmax(g_szRadioVoice[]));
		
		hValue = kv_get_next_value(hValue);
	}
}

public RandomExplosionSound(iEntity)
{
	new szName[64];
	formatex(szName, charsmax(szName), "airsupport/explode/explode_near_%d.wav", random_num(1, 6));
	emit_sound(iEntity, CHAN_WEAPON, szName, 1.0, 0.3, 0, PITCH_NORM);
}

stock SendWeaponAnim(iPlayer, iAnim, iBody = 0)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, iPlayer);
	write_byte(iAnim);
	write_byte(iBody);
	message_end();
}

stock get_aim_origin_vector(iPlayer, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(iPlayer, pev_origin, vOrigin)
	pev(iPlayer, pev_view_ofs, vUp)
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(iPlayer, pev_v_angle, vAngle)
	
	angle_vector(vAngle, ANGLEVECTOR_FORWARD, vForward)
	angle_vector(vAngle, ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle, ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock bool:fm_is_user_same_team(index1, index2)
	return !!(get_pdata_int(index1, m_iTeam) == get_pdata_int(index2, m_iTeam));

stock RadiusFlash(const Float:vecSrc[3], pevInflictor, pevAttacker, Float:flDamage)
	OrpheuCallSuper(g_pfn_RadiusFlash, vecSrc[0], vecSrc[1], vecSrc[2], pevInflictor, pevAttacker, flDamage);

stock get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	static Float:length
	length = redius * floatcos(vertical_angle, degrees)
	
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}

stock MakeSmoke(const Float:position[3], sprite_index, size, light)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, position, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, position[0])
	engfunc(EngFunc_WriteCoord, position[1])
	engfunc(EngFunc_WriteCoord, position[2])
	write_short(sprite_index)
	write_byte(size)
	write_byte(light)
	message_end()
}

stock UTIL_StrToVector(const szString[], Float:vecReturn[3])
{
	new iAmount, szVector[3][256], szValue[512];
	copy(szValue, charsmax(szValue), szString);
	
	while (szValue[0] && strtok(szValue, szVector[iAmount], charsmax(szVector[]), szValue, charsmax(szValue), ','))
	{
		trim(szVector[iAmount]);
		trim(szValue);
		iAmount ++;
	}
	
	//据说用直接的比循环快
	vecReturn[0] = str_to_float(szVector[0]);
	vecReturn[1] = str_to_float(szVector[1]);
	vecReturn[2] = str_to_float(szVector[2]);
}

stock bool:UTIL_PointVisible(const Float:vecSrc[3], const Float:vecEnd[3], iIgnoreType = DONT_IGNORE_MONSTERS, iSkipEntity = 0)
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, iIgnoreType, iSkipEntity, 0);
	get_tr2(0, TR_flFraction, flFraction);
	
	return (flFraction >= 1.0);
}

/**
pev_iuser1	用于标记对讲机召唤来的飞机iEntity
pev_iuser2	用于标记战斗机实体(RADIO_KEY)
pev_iuser3	用于标记召唤模式
*/