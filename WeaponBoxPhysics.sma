/* AMXX編寫頭版 by Devzone */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#include <offset>
#include <cstrike_pdatas/pdatas_stocks>
#include <metamod_checkfunc>

#define PLUGIN	"CWeaponBox Phys"
#define VERSION	"1.0.4"
#define AUTHOR	"Luna the Reborn"

enum _:HookedEntityTypes
{
	CWeaponBox = 0,
	CArmoury,
	CWShield,
	CItemThighPack,

	CGrenade
}

new const g_rgrgszClassNames[][] = { "weaponbox", "armoury_entity", "weapon_shield", "item_thighpack", "grenade" };
new const g_rgszHitSFX[] = "debris/metal6.wav";
new const g_rgszDropSFX[] = "items/weapondrop1.wav";

#define DMG_BULLET		(1<<1)
#define DMG_HEGRENADE	(1<<24)

#define m_flTimeNextTouchSfx		m_flStartThrow

new cvar_throwingweaponvelocity, cvar_grenadehitvelocity, cvar_grenadehitdamage;
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_forward(FM_SetModel, "fw_SetModel_Post", true);

	for (new i = 0; i < CGrenade; i++)
	{
		RegisterHam(Ham_Touch, g_rgrgszClassNames[i], "HamF_Touch_Post", true);
		RegisterHam(Ham_TraceAttack, g_rgrgszClassNames[i], "HamF_TraceAttack");
		RegisterHam(Ham_TakeDamage, g_rgrgszClassNames[i], "HamF_TakeDamage");
	}

	RegisterHam(Ham_Touch, g_rgrgszClassNames[CGrenade], "HamF_CGrenade_Touch_Post", true);

	cvar_throwingweaponvelocity = register_cvar("weaponphys_throwingweapon_velocity", "350.0");
	cvar_grenadehitvelocity = register_cvar("weaponphys_grenade_hit_velocity", "400.0");
	cvar_grenadehitdamage = register_cvar("weaponphys_grenade_hit_damage", "5.0");
}

public plugin_precache()
{
	precache_sound(g_rgszHitSFX);
	precache_sound(g_rgszDropSFX);
}

public fw_SetModel_Post(iEntity, const szModel[])
{
	new szClassName[32];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));

	new iType = -1;
	if (!strcmp(szClassName, g_rgrgszClassNames[CWeaponBox]))
		iType = CWeaponBox;
	else if (!strcmp(szClassName, g_rgrgszClassNames[CArmoury]))
		iType = CArmoury;
	else if (!strcmp(szClassName, g_rgrgszClassNames[CWShield]))
		iType = CWShield;
	else if (!strcmp(szClassName, g_rgrgszClassNames[CItemThighPack]))
		iType = CItemThighPack;
	else if (!strcmp(szClassName, g_rgrgszClassNames[CGrenade]))
		iType = CGrenade;


	if (iType != -1 && iType != CGrenade)
	{
		Materialization(iEntity);
	}

	if (iType == CWeaponBox || iType == CWShield)
	{
		new iPlayer = pev(iEntity, pev_owner);

		if (is_user_alive(iPlayer))
		{
			new Float:vecOrigin[3], Float:vecVelocity[3];

			UTIL_GetPlayerFront(iPlayer, 64.0, vecOrigin);

			global_get(glb_v_forward, vecVelocity);	// HACKHACK
			xs_vec_mul_scalar(vecVelocity, get_pcvar_float(cvar_throwingweaponvelocity), vecVelocity);

			engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);
			set_pev(iEntity, pev_velocity, vecVelocity);
		}
	}

	if (iType == CWeaponBox || iType == CWShield || (iType == CGrenade && !get_pdata_bool(iEntity, m_bIsC4, XO_CGRENADE)))
	{
		FreeRotationInTheAir(iEntity);
	}
}

public HamF_Touch_Post(iEntity, iPtd)
{
	static Float:vecVelocity[3];
	pev(iPtd, pev_velocity, vecVelocity);

	if (iPtd >= 1 && iPtd <= global_get(glb_maxClients))
	{
		if (xs_vec_len(vecVelocity) > 140.0)	// Walking won't kick anything.
			PlayerKick(iEntity, iPtd);
		/*else
		{
			pev(iEntity, pev_velocity, vecVelocity);
			
			new Float:flSpeed = xs_vec_len(vecVelocity);
			if (flSpeed < 10.0)
				return;

			new Float:vecSrc[3], Float:vecDest[3];
			pev(iEntity, pev_origin, vecSrc);
			xs_vec_add(vecSrc, vecVelocity, vecDest);

			new Float:vecNormal[3];
			engfunc(EngFunc_TraceLine, vecSrc, vecDest, DONT_IGNORE_MONSTERS, iEntity, 0);
			get_tr2(0, TR_vecPlaneNormal, vecNormal);

			xs_vec_reflect(vecVelocity, vecNormal, vecVelocity);
			xs_vec_normalize(vecVelocity, vecVelocity);
			xs_vec_mul_scalar(vecVelocity, flSpeed, vecVelocity);
			set_pev(iEntity, pev_velocity, vecVelocity);
		}*/

		return;
	}
	
	new iOwner = pev(iEntity, pev_owner);
	if (CHECK_ENTITY(iOwner) && iPtd != iOwner)
	{
		set_pev(iEntity, pev_owner, 0);	// Feel free to touch anything.
	}

	pev(iEntity, pev_velocity, vecVelocity);	// Refer to wmodel speed now.

	if (pev(iPtd, pev_solid) == SOLID_BSP)
	{
		lie_flat(iEntity);

		if (floatabs(vecVelocity[2]) > 1.0 && get_pdata_float(iEntity, m_flTimeNextTouchSfx, XO_CWEAPONBOX) < get_gametime())
		{
			engfunc(EngFunc_EmitSound, iEntity, CHAN_WEAPON, g_rgszDropSFX, 0.25, ATTN_STATIC, 0, random_num(94, 110));
			set_pdata_float(iEntity, m_flTimeNextTouchSfx, get_gametime() + 0.2, XO_CWEAPONBOX);
		}

		// Door, glass, etc.
		if (CHECK_NONPLAYER(iPtd) && pev(iPtd, pev_takedamage) != DAMAGE_NO && xs_vec_len(vecVelocity) >= 350.0)
		{
			dllfunc(DLLFunc_Use, iPtd, iEntity);
		}
		
		// Weaponbox drop down from high place.
		if (xs_vec_len(vecVelocity) >= 1000.0)
		{
			MetalHit(iEntity);
		}
		
		// disown, such that we can pickup our own gun.
		set_pev(iEntity, pev_owner, -1);	// according to fakemeta, this means nullptr.
	}

	FreeRotationInTheAir(iEntity);

	if (pev(iEntity, pev_flags) & FL_ONGROUND)
	{
		xs_vec_mul_scalar(vecVelocity, 0.95, vecVelocity);	// Additional friction. Don't hrash.
		set_pev(iEntity, pev_velocity, vecVelocity);
	}
}

public HamF_CGrenade_Touch_Post(iEntity, iPtd)
{
	if (pev(iPtd, pev_solid) == SOLID_BSP)
		lie_flat(iEntity);

	if (get_pcvar_float(cvar_grenadehitdamage) <= 0.0)
		return;

	new Float:vecVelocity[3], Float:flSpeed;
	pev(iEntity, pev_velocity, vecVelocity);
	flSpeed = xs_vec_len(vecVelocity);

	new iAttacker = pev(iEntity, pev_owner);
	if (flSpeed < get_pcvar_float(cvar_grenadehitvelocity) || iAttacker == iPtd)
		return;

	new szClassName[32];
	pev(iPtd, pev_classname, szClassName, charsmax(szClassName));
	if (strcmp(szClassName, "player") && strcmp(szClassName, "hostage_entity") && strcmp(szClassName, "monster_scientist"))
		return;

	new Float:flDamage = flSpeed / get_pcvar_float(cvar_grenadehitvelocity) * get_pcvar_float(cvar_grenadehitdamage)
	ExecuteHamB(Ham_TakeDamage, iPtd, iEntity, iAttacker, flDamage, DMG_CRUSH);
}

public HamF_TraceAttack(iVictim, iAttacker, Float:flDamage, Float:vecDir[3], tr, bitsDamageTypes)
{
	if (bitsDamageTypes & (DMG_CLUB | DMG_BULLET))
	{
		new Float:vecVelocity[3];
		pev(iVictim, pev_velocity, vecVelocity);
		
		new Float:vecVel2[3];
		xs_vec_mul_scalar(vecDir, flDamage * 20.0, vecVel2);
		xs_vec_add(vecVel2, vecVelocity, vecVel2);	// Original speed must be included.
		set_pev(iVictim, pev_velocity, vecVel2);
		
		pev(iVictim, pev_origin, vecVel2);
		MakeMetalSFX(iVictim);
		UTIL_Spark(vecVel2);
		
		FreeRotationInTheAir(iVictim);
	}
	
	return HAM_SUPERCEDE;
}

public HamF_TakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageTypes)
{
	if (bitsDamageTypes & DMG_HEGRENADE)
	{
		new Float:vecOrigin[3];
		pev(iInflictor, pev_origin, vecOrigin);
		
		new Float:vecVelocity[3];
		pev(iVictim, pev_origin, vecVelocity);
		xs_vec_sub(vecVelocity, vecOrigin, vecVelocity);
		xs_vec_normalize(vecVelocity, vecVelocity);
		xs_vec_mul_scalar(vecVelocity, flDamage * 20.0, vecVelocity);
		set_pev(iVictim, pev_velocity, vecVelocity)
		
		FreeRotationInTheAir(iVictim);
		MetalHit(iVictim);
	}

	return HAM_SUPERCEDE;
}

PlayerKick(iEntity, iPlayer)
{
	static Float:vecOriginEnt[3], Float:vecOriginPlayer[3];
	pev(iEntity, pev_origin, vecOriginEnt);
	pev(iPlayer, pev_origin, vecOriginPlayer);

	static Float:vecVelocity[3], Float:vecPlayerVel[3];
	pev(iPlayer, pev_velocity, vecPlayerVel);
	xs_vec_sub(vecOriginEnt, vecOriginPlayer, vecVelocity);
	xs_vec_normalize(vecVelocity, vecVelocity);
	xs_vec_mul_scalar(vecVelocity, xs_vec_len(vecPlayerVel) * 1.65, vecVelocity);
	
	// Add player velocity as if it were taken by the player.
	xs_vec_mul_scalar(vecPlayerVel, 1.65, vecPlayerVel);
	xs_vec_add(vecVelocity, vecPlayerVel, vecVelocity);

	set_pev(iEntity, pev_velocity, vecVelocity);
}

Materialization(iEntity)
{
	set_pev(iEntity, pev_friction, 0.7);	// Make it slide-able.
	set_pev(iEntity, pev_gravity, 1.4);
	set_pev(iEntity, pev_solid, SOLID_BBOX);
	set_pev(iEntity, pev_movetype, MOVETYPE_BOUNCE);
	set_pev(iEntity, pev_takedamage, DAMAGE_YES);
	engfunc(EngFunc_SetSize, iEntity, Float:{-4.0, -4.0, -0.5}, Float:{4.0, 4.0, 0.5});
}

FreeRotationInTheAir(iEntity)
{
	static Float:vecVelocity[3], Float:vecAngularVelocity[3];
	//pev(iEntity, pev_avelocity, vecAngularVelocity);

	//if (xs_vec_len(vecAngularVelocity) > 0.0)
	//	return;

	pev(iEntity, pev_velocity, vecVelocity);
	vecAngularVelocity[0] = xs_vec_len(vecVelocity)
	vecAngularVelocity[1] = random_float(-vecAngularVelocity[0], vecAngularVelocity[0]);
	set_pev(iEntity, pev_avelocity, vecAngularVelocity);
}

stock UTIL_Spark(Float:vecOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin, 0);
	write_byte(TE_SPARKS);
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	message_end();
}

MakeMetalSFX(iEntity)
{
	emit_sound(iEntity, CHAN_ITEM, g_rgszHitSFX, 0.5, ATTN_STATIC, 0, random_num(94, 110));
}

MetalHit(iEntity)
{
	new Float:vecOrigin[3];
	pev(iEntity, pev_origin, vecOrigin);
	vecOrigin[0] += random_float(-10.0, 10.0);
	vecOrigin[1] += random_float(-10.0, 10.0);

	UTIL_Spark(vecOrigin);
	MakeMetalSFX(iEntity);
}

stock lie_flat(iEntity)
{
	if(pev(iEntity, pev_flags) &~ FL_ONGROUND)
	return
	
	new Float:origin[3], Float:traceto[3], trace = 0, Float:fraction, Float:angles[3], Float:angles2[3]
	pev(iEntity, pev_origin, origin)
	pev(iEntity, pev_angles, angles)
	xs_vec_sub(origin, Float:{0.0, 0.0, 10.0}, traceto)
	engfunc(EngFunc_TraceLine, origin, traceto, IGNORE_MONSTERS, iEntity, trace)
	get_tr2(trace, TR_flFraction, fraction)
	
	if(fraction == 1.0)
	return
	
	new Float:original_forward[3]
	angle_vector(angles, ANGLEVECTOR_FORWARD, original_forward)
	new Float:right[3], Float:up[3], Float:fwd[3]
	get_tr2(trace, TR_vecPlaneNormal, up)
	xs_vec_cross(original_forward, up, right)
	xs_vec_cross(up, right, fwd)
	vector_to_angle(fwd, angles)
	vector_to_angle(right, angles2)
	angles[2] = -1.0 * angles2[0]
	set_pev(iEntity, pev_angles, angles)
}

stock Float:UTIL_GetPlayerFront(iPlayer, Float:flMaxDist, Float:vecOrigin[3])
{
	new Float:start[3], Float:dest[3];
	pev(iPlayer, pev_origin, start);
	pev(iPlayer, pev_view_ofs, dest);
	xs_vec_add(start, dest, start);

	pev(iPlayer, pev_v_angle, dest);
	dest[0] = floatclamp(dest[0], -70.0, 65.0);	// This is specialized, remove this line for other usages.

	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, flMaxDist, dest);
	xs_vec_add(start, dest, dest);

	engfunc(EngFunc_TraceLine, start, dest, DONT_IGNORE_MONSTERS, iPlayer, 0);
	get_tr2(0, TR_vecEndPos, vecOrigin);

	new Float:flFraction;
	get_tr2(0, TR_flFraction, flFraction);
	return flMaxDist * flFraction;
}
