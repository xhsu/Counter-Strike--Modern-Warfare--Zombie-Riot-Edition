/* ammx编写头版 by Devzone*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombieriot>
#include <xs>

#include <offset>
#include "Library/LibMath.inc"
#include "Library/LibExplosion.sma"
#include "Library/LibWeapons.sma"

#define PLUGIN	"Zr Bomber"
#define VERSION	"1.0.3 CSMW:ZR"
#define AUTHOR	"DSHGFHDS & Luna"

#define C4CLASSNAME "C4BOMB"
#define C4OFF 997521

new const C4Sound[] = "zombieriot/plant.wav"
new const C4Models[2][] = { "models/zombieriot/v_morec4.mdl", "models/zombieriot/x_morec4.mdl" }
new const ExplosionSound[] = { "weapons/c4_explode1.wav" }

new cvar_amount, cvar_damage, cvar_range, cvar_bulletrange, cvar_bulletdamage, cvar_grenadecapacity;

new Mode[33], Float:NextThink[33], Firing[33], bool:FixHoldTime[33]
new C4Index, SmokeIndex[4]

new C4Id
new const C4Name[] = "C4炸药"	//名称
new const C4Cost = 50			//价格

new const BomberID = 4			//爆破者的ID

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	set_msg_block(get_user_msgid("BombDrop"), BLOCK_SET)
	set_msg_block(get_user_msgid("BombPickup"), BLOCK_SET)
	register_message(get_user_msgid("StatusIcon"), "Message_StatusIcon")
	register_message(get_user_msgid("TextMsg"), "Message_TextMsg")
	register_message(get_user_msgid("AmmoX"), "Message_AmmoX")
	register_forward(FM_ClientCommand, "fw_ClientCommand")
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink", 1)
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_TraceLine, "fw_TraceLine_Post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_c4", "HAM_C4_PrimaryAttack")
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_c4", "HAM_Weapon_WeaponIdle")
	RegisterHam(Ham_Item_Deploy, "weapon_c4", "HAM_ItemDeploy_Post", 1)
	RegisterHam(Ham_Item_Holster, "weapon_c4", "HAM_ItemHolster_Post", 1)
	RegisterHam(Ham_Spawn, "weapon_c4", "HAM_Spawn_Post", 1)
	RegisterHam(Ham_Touch, "info_target", "HAM_Touch_Post", 1)
	for (new i = 1; i < sizeof WEAPON_CLASSNAME; i++)
	{
		if (WEAPON_SLOT[i] != PRIMARY_WEAPON_SLOT && WEAPON_SLOT[i] != PISTOL_SLOT)	// Filter non-ballistic weapon.
			continue;

		RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_CLASSNAME[i], "HamF_Weapon_PrimaryAttack");
		RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_CLASSNAME[i], "HamF_Weapon_PrimaryAttack_Post", true);
	}
	static C4Info[64]
	formatex(C4Info, charsmax(C4Info), "%s %d$", C4Name, C4Cost)
	C4Id = zr_register_item(C4Info, HUMAN, 4)
	cvar_amount = register_cvar("zr_bomber_c4_amount", "3")				//C4数量
	cvar_damage = register_cvar("zr_bomber_c4_damage", "500.0")			//C4伤害
	cvar_range = register_cvar("zr_bomber_c4_range", "300.0")			//C4伤害范围
	cvar_bulletrange = register_cvar("zr_bomber_bulletrange", "40.0")	//高爆子弹的伤害范围
	cvar_bulletdamage = register_cvar("zr_bomber_bulletdamage", "8.0")	//高爆子弹的伤害

	LibExplosion_Init();
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheSound, C4Sound)
	engfunc(EngFunc_PrecacheModel, C4Models[0])
	engfunc(EngFunc_PrecacheSound, ExplosionSound);
	C4Index = engfunc(EngFunc_PrecacheModel, C4Models[1])
	SmokeIndex[0] = engfunc(EngFunc_PrecacheModel, "sprites/black_smoke1.spr")
	SmokeIndex[1] = engfunc(EngFunc_PrecacheModel, "sprites/black_smoke2.spr")
	SmokeIndex[2] = engfunc(EngFunc_PrecacheModel, "sprites/black_smoke3.spr")
	SmokeIndex[3] = engfunc(EngFunc_PrecacheModel, "sprites/black_smoke4.spr")

	LibExplosion_Precache();
}

public Message_TextMsg(msg_id, msg_dest, msg_entity)
{
	static textmsg[22]
	get_msg_arg_string(2, textmsg, charsmax(textmsg))
	
	if(!strcmp(textmsg, "#Got_bomb") || !strcmp(textmsg, "#Game_bomb_drop"))
	return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public Message_StatusIcon(msg_id, msg_dest, msg_entity)
{
	static szBuffer[8]
	get_msg_arg_string(2, szBuffer, charsmax(szBuffer))
	return strcmp(szBuffer, "c4") ? PLUGIN_CONTINUE : PLUGIN_HANDLED
}

public Message_AmmoX(msg_id, msg_dest, iPlayer)
{
	if(get_msg_arg_int(1) != 14)
	return PLUGIN_CONTINUE
	
	return PLUGIN_HANDLED
}

public fw_ClientCommand(iPlayer)
{
	static szCommand[24]
	read_argv(0, szCommand, charsmax(szCommand))
	
	if(strcmp(szCommand, "drop"))
	return FMRES_IGNORED
	
	new iEntity = get_pdata_cbase(iPlayer, 373)
	if(pev_valid(iEntity) && get_pdata_int(iEntity, 43, 4) == CSW_C4)
	{
	client_print(iPlayer, print_center, "技能武器无法被扔掉")
	return FMRES_SUPERCEDE
	}
	
	read_argv(1, szCommand, charsmax(szCommand))
	
	if(strcmp(szCommand, "weapon_c4"))
	return FMRES_IGNORED
	
	client_print(iPlayer, print_center, "技能武器无法被扔掉")
	
	return FMRES_SUPERCEDE
}

public fw_PlayerPostThink(iPlayer)
{
	if(pev(iPlayer, pev_deadflag) != DEAD_NO)
	return
	
	if(!Mode[iPlayer])
	return
	
	new Float:fCurTime
	global_get(glb_time, fCurTime)
	
	if(NextThink[iPlayer] > fCurTime)
	return
	
	if(Mode[iPlayer] == 1)
	{
	Mode[iPlayer] = 0
	
	new iEntity = get_pdata_cbase(iPlayer, 373)
	if(iEntity <= 0)
	return
	
	new bEntity = -1
	while((bEntity = engfunc(EngFunc_FindEntityByString, bEntity, "classname", C4CLASSNAME)))
	{
	if(pev(bEntity, pev_owner) != iEntity)
	continue
	
	new Float:vecOrigin[3];
	pev(bEntity, pev_origin, vecOrigin);
	LibExplosion_RadiusDamage(iEntity, bEntity, vecOrigin, get_pcvar_float(cvar_range), get_pcvar_float(cvar_damage));

	new Float:vecDir[3];
	pev(bEntity, pev_v_angle, vecDir);
	if (vector_length(vecDir) < 0.5)
		xs_vec_set(vecDir, 0.0, 0.0, 1.0);
	
	LibExplosion_SetGlobalTrace(vecOrigin, vecDir);
	LibExplosion_FullVFX();
	LibExplosion_PlayerFX(iEntity, vecOrigin, get_pcvar_float(cvar_range) * 2.0,
		5.0, 10.0, 20.0,	// Shake
		0.25, 0.25,	// Fade
		25.0,	// Punch
		400.0);	// Knock

	engfunc(EngFunc_EmitSound, bEntity, CHAN_STATIC, ExplosionSound, VOL_NORM, 0.4, 0, random_num(92, 104));

	set_pev(bEntity, pev_flags, FL_KILLME);
	}
	return
	}
	
	Mode[iPlayer] = 0
	CreateC4Bomb(iPlayer)
}

public fw_UpdateClientData_Post(iPlayer, iSendWeapon, CD_Handle)
{
	if(get_cd(CD_Handle, CD_DeadFlag) != DEAD_NO)
	return
	
	if(get_cd(CD_Handle, CD_ID) != CSW_C4)
	return
	
	if(get_pdata_float(iPlayer, 83, 5) > 0.0)
	return
	
	set_cd(CD_Handle, CD_ID, 0)
}

public fw_SetModel(iEntity, Model[])
{
	if(strcmp(Model, "models/w_backpack.mdl"))
	return FMRES_IGNORED
	
	static classname[33]
	pev(iEntity, pev_classname, classname, charsmax(classname))
	
	if(strcmp(classname, "weaponbox"))
	return FMRES_SUPERCEDE
	
	set_pev(iEntity, pev_flags, FL_KILLME)
	
	return FMRES_SUPERCEDE
}

public fw_TraceLine_Post(Float:vecStart[3], Float:vecEnd[3], iConditions, iSkipEntity, iTrace)
{
	if(!is_user_connected(iSkipEntity))
	return
	
	if(!Firing[iSkipEntity])
	return
	
	new iEntity = get_pdata_cbase(iSkipEntity, 373)
	if(iEntity <= 0)
	return
	
	if(FixHoldTime[iSkipEntity] && get_pdata_int(iEntity, 74, 4) == 16)
	{
	FixHoldTime[iSkipEntity] = false
	return
	}
	
	BulletExplosion(iSkipEntity, iTrace)
	
	Firing[iSkipEntity] --
	FixHoldTime[iSkipEntity] = true
}

public HAM_C4_PrimaryAttack(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, 41, 4)
	
	set_pdata_float(iEntity, 46, 0.9, 4)
	UTIL_WeaponAnim(iPlayer, 1)
	
	new Float:fCurTime
	global_get(glb_time, fCurTime)
	
	NextThink[iPlayer] = fCurTime + 0.3
	Mode[iPlayer] = 1
	
	return HAM_SUPERCEDE
}

public HamF_Weapon_PrimaryAttack(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, 41, 4)
	
	if(zr_is_user_zombie(iPlayer))
	return FMRES_IGNORED
	
	if(zr_get_human_id(iPlayer) != BomberID)
	return FMRES_IGNORED
	
	if(!get_pdata_int(iEntity, 51, 4))
	return FMRES_IGNORED
	
	new burstmode = get_pdata_int(iEntity, 74, 5)
	if(burstmode == 16 || burstmode == 2)
	{
	Firing[iPlayer] = min(3, get_pdata_int(iEntity, 51, 4))
	FixHoldTime[iPlayer] = false
	return FMRES_IGNORED
	}
	
	Firing[iPlayer] = 1
	
	return FMRES_IGNORED
}

public HamF_Weapon_PrimaryAttack_Post(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, 41, 4)
	if(Firing[iPlayer] != 1)
	return
	
	new burstmode = get_pdata_int(iEntity, 74, 4)
	if(burstmode == 16)
	return
	
	Firing[iPlayer] = 0
}

public HAM_Weapon_WeaponIdle(iEntity)
{
	if(!pev(iEntity, pev_iuser4))
	return HAM_IGNORED
	
	if(get_pdata_float(iEntity, 46, 4) > 0.0)
	return HAM_IGNORED
	
	new iPlayer = get_pdata_cbase(iEntity, 41, 4)
	
	if(!(get_pdata_int(iPlayer, 246, 5) & IN_ATTACK2))
	return HAM_IGNORED
	
	if(!pev(iEntity, pev_iuser4))
	return HAM_IGNORED
	
	set_pdata_float(iEntity, 46, 0.9, 4)
	UTIL_WeaponAnim(iPlayer, 2)
	
	new Float:fCurTime
	global_get(glb_time, fCurTime)
	
	NextThink[iPlayer] = fCurTime + 0.05
	Mode[iPlayer] = 2
	
	return HAM_SUPERCEDE
}

public HAM_ItemDeploy_Post(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, 41, 4)
	
	set_pev(iPlayer, pev_viewmodel2, C4Models[0])
	set_pev(iPlayer, pev_weaponmodel2, C4Models[1])
	
	UTIL_WeaponAnim(iPlayer, 3)
	UTIL_UpdateBpAmmoCount(iPlayer, AMMO_C4, pev(iEntity, pev_iuser4));
}

public HAM_ItemHolster_Post(iEntity) Mode[get_pdata_cbase(iEntity, 41, 4)] = 0

public HAM_Spawn_Post(iEntity) set_pev(iEntity, pev_iuser4, get_pcvar_num(cvar_amount))

public HAM_Touch_Post(iEntity, iPtd)
{
	if(!pev_valid(iEntity))
	return
	
	if(is_user_alive(iPtd))
	return
	
	if(pev_valid(iPtd))
	{
	static classname[33]
	pev(iPtd, pev_classname, classname, charsmax(classname))
	if(strcmp(classname, "func_breakable") && strcmp(classname, "func_ladder") && strcmp(classname, "func_wall"))
	return
	}
	
	if(pev(iEntity, pev_iuser2) != C4OFF)
	return
	
	new Float:origin[3]
	pev(iEntity, pev_origin, origin)
	if(engfunc(EngFunc_PointContents, origin) == CONTENTS_SKY)
	return
	
	new Float:velocity[3], Float:End[3]
	pev(iEntity, pev_velocity, velocity)
	
	xs_vec_add(origin, velocity, End)
	engfunc(EngFunc_TraceLine, origin, End, IGNORE_MONSTERS, iEntity, 0)
	
	new Float:PlaneNormal[3], Float:angles[3]
	get_tr2(0, TR_vecPlaneNormal, PlaneNormal)
	
	engfunc(EngFunc_VecToAngles, PlaneNormal, angles)
	set_pev(iEntity, pev_angles, angles)
	set_pev(iEntity, pev_sequence, 1)
	
	set_pev(iEntity, pev_v_angle, PlaneNormal)
	set_pev(iEntity, pev_movetype, MOVETYPE_NONE)
	set_pev(iEntity, pev_iuser2, 0)
	
	engfunc(EngFunc_EmitSound, iEntity, CHAN_ITEM, C4Sound, 0.2, ATTN_STATIC, 0, PITCH_NORM)
}

public CreateC4Bomb(iPlayer)
{
	new bEntity = get_pdata_cbase(iPlayer, 373)
	if(bEntity <= 0)
	return
	
	new Amount = pev(bEntity, pev_iuser4)-1
	set_pev(bEntity, pev_iuser4, Amount)
	UTIL_UpdateBpAmmoCount(iPlayer, AMMO_C4, Amount);
	
	new Float:origin[2][3], Float:angles[3]
	get_aim_origin_vector(iPlayer, 16.0, 0.0, -4.0, origin[0])
	get_aim_origin_vector(iPlayer, 16.0, 0.0, 0.0, origin[1])
	xs_vec_sub(origin[1], origin[0], origin[1])
	engfunc(EngFunc_VecToAngles, origin[1], angles)
	
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(iEntity, pev_classname, C4CLASSNAME)
	set_pev(iEntity, pev_solid, SOLID_TRIGGER)
	set_pev(iEntity, pev_movetype, MOVETYPE_TOSS)
	set_pev(iEntity, pev_owner, bEntity)
	set_pev(iEntity, pev_iuser2, C4OFF)
	set_pev(iEntity, pev_angles, angles)
	set_pev(iEntity, pev_modelindex, C4Index)
	engfunc(EngFunc_SetOrigin, iEntity, origin[0])
	
	new Float:start[3], Float:view_ofs[3], Float:end[3]
	pev(iPlayer, pev_origin, start)
	pev(iPlayer, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)
	
	pev(iPlayer, pev_v_angle, end)
	engfunc(EngFunc_MakeVectors, end)
	global_get(glb_v_forward, end)
	xs_vec_mul_scalar(end, 8120.0, end)
	xs_vec_add(start, end, end)
	engfunc(EngFunc_TraceLine, start, end, DONT_IGNORE_MONSTERS, iPlayer, 0)
	get_tr2(0, TR_vecEndPos, end)
	
	new Float:velocity[2][3], Float:avelocity[3]
	get_speed_vector(origin[0], end, 290.0, velocity[0])
	pev(iPlayer, pev_velocity, velocity[1])
	xs_vec_add(velocity[0], velocity[1], velocity[0])
	set_pev(iEntity, pev_velocity, velocity[0])
	avelocity[0] = 290.0
	avelocity[1] = random_float(-290.0, 290.0)
	set_pev(iEntity, pev_avelocity, avelocity)
}

public BulletExplosion(iPlayer, iTrace)
{
	new Float:origin[3]
	get_tr2(iTrace, TR_vecEndPos, origin)
	
	if(engfunc(EngFunc_PointContents, origin) == CONTENTS_SKY)
	return
	
	new Float:PlaneNormal[3]
	get_tr2(iTrace, TR_vecPlaneNormal, PlaneNormal)
	
	xs_vec_mul_scalar(PlaneNormal, 27.0, PlaneNormal)
	xs_vec_add(origin, PlaneNormal, origin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_SMOKE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2]-23.0)
	write_short(SmokeIndex[random_num(0, 3)])
	write_byte(random_num(10, 15))
	write_byte(random_num(100, 110))
	message_end()
	
	get_tr2(iTrace, TR_vecEndPos, origin)
	
	new i = -1
	while((i = engfunc(EngFunc_FindEntityInSphere, i, origin, get_pcvar_float(cvar_bulletrange))) > 0)
	{
	if(!pev_valid(i))
	continue
	
	if(pev(i, pev_takedamage) == DAMAGE_NO)
	continue
	
	new Float:iOrigin[3]
	pev(i, pev_origin, iOrigin)
	
	new Float:damage = floatclamp(get_pcvar_float(cvar_bulletdamage)*(1.0-(get_distance_f(iOrigin, origin)-21.0)/get_pcvar_float(cvar_bulletrange)), 0.0, get_pcvar_float(cvar_bulletdamage))
	if(damage == 0.0)
	continue
	
	ExecuteHamB(Ham_TakeDamage, i, iPlayer, iPlayer, damage, DMG_GENERIC)
	if(!is_user_alive(i))
	continue
	
	UTIL_ScreenShake(i, 0.2, 5.0, -3.0);
	}
}

public zr_roundbegin_event(Weather)
{
	new iEntity = -1
	while((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", C4CLASSNAME))) set_pev(iEntity, pev_flags, FL_KILLME)
}

public zr_item_event(iPlayer, item, Slot)
{
	if(item != C4Id)
	return
	
	if(zr_get_human_id(iPlayer) != BomberID)
	{
	zr_print_chat(iPlayer, GREYCHAT, "只有爆破者能够购买!")
	return
	}
	
	new Money = zr_get_user_money(iPlayer)
	if(Money < C4Cost)
	{
	zr_print_chat(iPlayer, GREYCHAT, "没有足够的金币!")
	return
	}
	
	new iEntity = get_pdata_cbase(iPlayer, 372)
	if(iEntity <= 0)
	return
	
	new Amount = pev(iEntity, pev_iuser4)
	
	if(Amount >= get_pcvar_float(cvar_amount))
	{
	zr_print_chat(iPlayer, GREYCHAT, "C4数量已达到上限!")
	return
	}
	
	Amount += 1
	set_pev(iEntity, pev_iuser4, Amount)
	UTIL_UpdateBpAmmoCount(iPlayer, AMMO_C4, Amount);
	
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 1, PITCH_NORM)
	
	zr_set_user_money(iPlayer, Money-C4Cost, true)
	zr_print_chat(iPlayer, BLUECHAT, "你购买了一份C4炸药!")
}

public zr_being_human(iPlayer)
{
	if (!cvar_grenadecapacity)
		cvar_grenadecapacity = get_cvar_pointer("zr_bomber_grenade_capacity");
	
	new iBomberCapacity = get_pcvar_num(cvar_grenadecapacity);

	if (zr_get_human_id(iPlayer) != BomberID)	// Restore capacity info.
	{
		UTIL_WeaponList(iPlayer, CSW_HEGRENADE, WEAPON_CLASSNAME[CSW_HEGRENADE]);
		UTIL_WeaponList(iPlayer, CSW_SMOKEGRENADE, WEAPON_CLASSNAME[CSW_SMOKEGRENADE]);
		UTIL_WeaponList(iPlayer, CSW_FLASHBANG, WEAPON_CLASSNAME[CSW_FLASHBANG]);

		return;
	}
	else
	{
		UTIL_WeaponList(iPlayer, CSW_HEGRENADE, WEAPON_CLASSNAME[CSW_HEGRENADE], iBomberCapacity);
		UTIL_WeaponList(iPlayer, CSW_SMOKEGRENADE, WEAPON_CLASSNAME[CSW_SMOKEGRENADE], iBomberCapacity);
		UTIL_WeaponList(iPlayer, CSW_FLASHBANG, WEAPON_CLASSNAME[CSW_FLASHBANG], iBomberCapacity);
	}
	
	for (new i = 0; i < iBomberCapacity; i++)
		GiveGrenade(iPlayer, CSW_HEGRENADE, iBomberCapacity);
	
	UTIL_AmmoPickup(iPlayer, AMMO_HEGrenade, iBomberCapacity);
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/gunpickup1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	new iEntity = GiveItem(iPlayer, "weapon_c4");
	if (pev_valid(iEntity) != 2 || !(iEntity = get_pdata_cbase(iPlayer, m_rgpPlayerItems[C4_SLOT])))
		return;
	
	set_pev(iEntity, pev_iuser4, get_pcvar_num(cvar_amount));

	UTIL_UpdateBpAmmoCount(iPlayer, AMMO_C4, get_pcvar_num(cvar_amount));
	UTIL_WeaponList(iPlayer, CSW_C4, "weapon_c4", get_pcvar_num(cvar_amount));
}

stock get_speed_vector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}
