/* ammx编写头版 by Devzone*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define PLUGIN "C4"
#define VERSION "1.0"
#define AUTHOR "DSHGFHDS"

#define C4CLASSNAME "C4BOMB"
#define C4OFF 997521

new const C4Sounds[2][] = { "c4/plant.wav", "c4/explode_close.wav" }
new const C4Models[3][] = { "models/c4/v_morec4.mdl", "models/c4/x_detonator.mdl", "models/c4/x_morec4.mdl" }

new cvar_amount, cvar_damage, cvar_range

new Mode[33], Float:NextThink[33]
new C4Index, DetonatorIndex, g_smodelindexfireball2, g_smodelindexfireball3

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("HLTV", "EVENT_RoundStart", "a", "1=0", "2=0")
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink", 1)
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_c4", "HAM_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_c4", "HAM_Weapon_WeaponIdle")
	RegisterHam(Ham_Item_Deploy, "weapon_c4", "HAM_ItemDeploy_Post", 1)
	RegisterHam(Ham_Item_Holster, "weapon_c4", "HAM_ItemHolster_Post", 1)
	RegisterHam(Ham_Spawn, "weapon_c4", "HAM_Spawn_Post", 1)
	RegisterHam(Ham_Touch, "info_target", "HAM_Touch_Post", 1)
	cvar_amount = register_cvar("c4_amount", "3")			//C4数量
	cvar_damage = register_cvar("c4_damage", "400.0")		//C4伤害
	cvar_range = register_cvar("c4_range", "250.0")			//C4伤害范围
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheSound, C4Sounds[0])
	engfunc(EngFunc_PrecacheSound, C4Sounds[1])
	engfunc(EngFunc_PrecacheModel, C4Models[0])
	DetonatorIndex = engfunc(EngFunc_PrecacheModel, C4Models[1])
	C4Index = engfunc(EngFunc_PrecacheModel, C4Models[2])
	g_smodelindexfireball2 = engfunc(EngFunc_PrecacheModel, "sprites/eexplo.spr")
	g_smodelindexfireball3 = engfunc(EngFunc_PrecacheModel, "sprites/fexplo.spr")
}

public EVENT_RoundStart()
{
	new iEntity = -1
	while((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", C4CLASSNAME))) engfunc(EngFunc_RemoveEntity, iEntity)
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
	
	BombExplose(bEntity)
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
	
	set_pev(iEntity, pev_modelindex, DetonatorIndex)
	
	return FMRES_SUPERCEDE
}

public HAM_Weapon_PrimaryAttack(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, 41, 4)
	
	set_pdata_float(iEntity, 46, 0.9, 4)
	SendWeaponAnim(iPlayer, 1)
	
	new Float:fCurTime
	global_get(glb_time, fCurTime)
	
	NextThink[iPlayer] = fCurTime + 0.3
	Mode[iPlayer] = 1
	
	return HAM_SUPERCEDE
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
	SendWeaponAnim(iPlayer, 2)
	
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
	set_pev(iPlayer, pev_weaponmodel2, C4Models[2])
	SendWeaponAnim(iPlayer, 3)
	
	message_begin(MSG_ONE, get_user_msgid("AmmoX"), {0, 0, 0 }, iPlayer)
	write_byte(14)
	write_byte(pev(iEntity, pev_iuser4))
	message_end()
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
	
	engfunc(EngFunc_EmitSound, iEntity, CHAN_ITEM, C4Sounds[0], 0.2, ATTN_NORM, 0, PITCH_NORM)
}

public BombExplose(iEntity)
{
	new iC4Weapon = pev(iEntity, pev_owner)
	new iPlayer = get_pdata_cbase(iC4Weapon, 41, 4)
	
	if(!is_user_alive(iPlayer))
	{
	engfunc(EngFunc_RemoveEntity, iEntity)
	return
	}
	
	new Float:origin[3]
	pev(iEntity, pev_origin, origin)
	
	new i = -1
	while((i = engfunc(EngFunc_FindEntityInSphere, i, origin, get_pcvar_float(cvar_range))) > 0)
	{
	if(!pev_valid(i) || iEntity == i)
	continue
	
	if(pev(i, pev_takedamage) == DAMAGE_NO)
	continue
	
	static classname[33]
	pev(i, pev_classname, classname, charsmax(classname))
	if(!strcmp(classname, "func_breakable"))
	{
	ExecuteHamB(Ham_TakeDamage, i, pev(iEntity, pev_iuser2), iPlayer, get_pcvar_float(cvar_damage), DMG_GENERIC)
	continue
	}
	
	new Float:origin2[3]
	pev(i, pev_origin, origin2)
	
	new Float:damage = floatclamp(get_pcvar_float(cvar_damage)*(1.0-(get_distance_f(origin2, origin)-21.0)/get_pcvar_float(cvar_range)), 0.0, get_pcvar_float(cvar_damage))
	if(damage == 0.0)
	continue
	
	ExecuteHamB(Ham_TakeDamage, i, iC4Weapon, iPlayer, damage, DMG_GENERIC)
	}
	
	new Float:Vec[3]
	pev(iEntity, pev_v_angle, Vec)
	xs_vec_mul_scalar(Vec, 55.0, Vec)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, origin[0]+Vec[0])
	engfunc(EngFunc_WriteCoord, origin[1]+Vec[1])
	engfunc(EngFunc_WriteCoord, origin[2]+Vec[2])
	write_short(g_smodelindexfireball3)
	write_byte(clamp(floatround(get_pcvar_float(cvar_range)/6.0), 10, 30))
	write_byte(50)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()
	
	pev(iEntity, pev_v_angle, Vec)
	xs_vec_mul_scalar(Vec, random_float(70.0, 95.0), Vec)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, origin[0]+Vec[0])
	engfunc(EngFunc_WriteCoord, origin[1]+Vec[1])
	engfunc(EngFunc_WriteCoord, origin[2]+Vec[2])
	write_short(g_smodelindexfireball2)
	write_byte(clamp(floatround(get_pcvar_float(cvar_range)/6.0), 10, 30))
	write_byte(30)
	write_byte(TE_EXPLFLAG_NOSOUND)
	message_end()
	
	engfunc(EngFunc_EmitSound, iEntity, CHAN_WEAPON, C4Sounds[1], VOL_NORM, 0.4, 0, PITCH_NORM)
	
	engfunc(EngFunc_RemoveEntity, iEntity)
}

public CreateC4Bomb(iPlayer)
{
	new bEntity = get_pdata_cbase(iPlayer, 373)
	if(bEntity <= 0)
	return
	
	new Amount = pev(bEntity, pev_iuser4)-1
	set_pev(bEntity, pev_iuser4, Amount)
	message_begin(MSG_ONE, get_user_msgid("AmmoX"), {0, 0, 0 }, iPlayer)
	write_byte(14)
	write_byte(Amount)
	message_end()
	
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
	engfunc(EngFunc_SetSize, iEntity, {-1.0, -1.0, -1.0}, {1.0, 1.0, 1.0})
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

stock SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, iPlayer)
	write_byte(iAnim)
	write_byte(pev(iPlayer, pev_body))
	message_end()
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

stock get_speed_vector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}