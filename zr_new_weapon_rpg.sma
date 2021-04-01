/* ammx编写头版 by moddev*/

#include <amxmodx>
#include <xs>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <zombieriot>

#define PLUGIN "RPG火箭筒"
#define VERSION "1.0"
#define AUTHOR "DSHGFHDS"

#define ROCKENAME "RPGrocke"
#define ROCKEMODEL "models/rpgrocket.mdl"
#define RPGNONEROCKE 25476
#define MDLCOUNT 20 //爆炸碎片的数量
#define RPGKILLSPR "rpg" //杀敌SPR
#define RPG_IMPULSE 8528

#define IS_ONLINE //是联机使用(不是在最IS_ONLINE前面加上//,是就去掉)

forward zr_gift_primary_ammo(i)
forward zr_buy_primary_ammo(iPlayer)
new const PrimaryEntity[][] = { "weapon_galil", "weapon_famas", "weapon_m4a1", "weapon_ak47", "weapon_sg552", "weapon_aug", "weapon_scout", "weapon_m3", "weapon_xm1014", "weapon_tmp", "weapon_mac10", "weapon_ump45", "weapon_mp5navy", "weapon_p90", "weapon_sg550", "weapon_awp", "weapon_g3sg1", "weapon_m249" }

new szbreakmodels[3]
new bool:rockeshooting[33], bool:rockereloading[33], bool:hudhook[33]
new Float:g_fLastThink[33]
new cvar_rockegravity, cvar_flyoffset, cvar_shoottime, cvar_reloadtime, cvar_flyspeed, cvar_drawtime, cvar_drawtime_none, cvar_shakerange, cvar_lightrange, cvar_rockedamagerange, cvar_rockedamage, cvar_partitiondamage, cvar_punchagele, cvar_rockeknock
new cvar_mdltime, cvar_shootpunchagele, cvar_movespeed
new rockesmoketrail, rockefire, rockefire2, rockesmoke, rockeexplode, rockeexplode2, g_smokeSpr, g_smokeSpr2, rockesmoke2
new const breakmodels[][] = {"models/gibs_wallbrown.mdl", "models/gibs_woodplank.mdl", "models/gibs_brickred.mdl"} //碎片模型
new const RPGrockelaunchermodel[][] = { "models/v_rpg.mdl", "models/pw_rpg_none.mdl", "models/pw_rpg.mdl" }
new const RPGlaunchsound[] = "weapons/rpg7_1.wav"
new const rockeflysound[] = "weapons/rpg_travel.wav"
new const rockeexplodesound[] = "weapons/rocke_explode.wav"
new g_fwBotForwardRegister,g_has_rpg[33]
new RPG7
new const RPGName[] = "RPG-7火箭发射器"
new const RPGCost = 8000
new RPGrocket
new const rocketName[] = "RPG火箭弹"
new const rocketCost = 2000
enum
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
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	static RPGInfo[64]
	formatex(RPGInfo, charsmax(RPGInfo), "%s %d$", RPGName, RPGCost)
	RPG7 = zr_register_item(RPGInfo, HUMAN, 1)
	static rocketInfo[64]
	formatex(rocketInfo, charsmax(rocketInfo), "%s %d$", rocketName, rocketCost)
	RPGrocket = zr_register_item(rocketInfo, HUMAN, 3)
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_forward(FM_Think, "fw_rockethink")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink", 1)
	g_fwBotForwardRegister = register_forward(FM_PlayerPostThink, "fw_BotForwardRegister_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m3", "fwWeapAddToPlayer")
	RegisterHam(Ham_Weapon_Reload, "weapon_m3", "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_m3", "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_m3", "fw_ItemDeploy_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	cvar_movespeed = register_cvar("RPG_rocke_palyerspeed", "210.0") //拿着RPG行走的速度
	cvar_rockegravity = register_cvar("RPG_rocke_gravity", "2.0") //火箭的重量倍数
	cvar_flyspeed = register_cvar("RPG_rocke_flyspeed", "900.0") //火箭飞行速度
	cvar_flyoffset = register_cvar("RPG_rocke_flyoffset", "1.2") //火箭飞行的轨道偏移值
	cvar_shoottime = register_cvar("RPG_rocke_shoottime", "0.5") //射击动作的时间
	cvar_reloadtime = register_cvar("RPG_rocke_reloadtime", "3.3") //上弹时间
	cvar_drawtime = register_cvar("RPG_rocke_drawtime", "0.86") //切换RPG的时间
	cvar_drawtime_none = register_cvar("RPG_rocke_drawtime_none", "0.86") //没有弹药的RPG切换时间
	cvar_shootpunchagele = register_cvar("RPG_rocke_shootpunchagele", "50.0") //射击后坐力
	cvar_rockedamagerange = register_cvar("RPG_rocke_damage_range", "350.0") //爆炸范围
	cvar_rockedamage = register_cvar("RPG_rocke_damage", "7000.0") //爆炸伤害
	cvar_partitiondamage = register_cvar("RPG_rocke_partitiondamage", "0.5") //隔着物体爆炸的伤害倍数
	cvar_rockeknock = register_cvar("RPG_rocke_knock", "10.0") //爆炸击退倍数
	cvar_punchagele = register_cvar("RPG_rocke_punchagele", "30.0") //被炸中的屏幕震动幅度
	cvar_shakerange = register_cvar("RPG_rocke_shake_range", "1000.0") //爆炸地震的影响范围
	cvar_lightrange = register_cvar("RPG_rocke_light_range", "1500.0") //爆炸光刺眼的范围
	cvar_mdltime = register_cvar("RPG_rocke_mdltime", "5.0") //爆炸后碎片的存在时间
}

public plugin_precache()
{
	for(new i = 0; i < sizeof breakmodels; i++) szbreakmodels[i] = engfunc(EngFunc_PrecacheModel, breakmodels[i])
	for(new i = 0; i < sizeof RPGrockelaunchermodel; i++) engfunc(EngFunc_PrecacheModel, RPGrockelaunchermodel[i])
	engfunc(EngFunc_PrecacheModel, ROCKEMODEL)
	g_smokeSpr = engfunc(EngFunc_PrecacheModel, "sprites/exsmoke.spr")
	g_smokeSpr2 = engfunc(EngFunc_PrecacheModel, "sprites/rockeexfire.spr")
	rockeexplode = engfunc(EngFunc_PrecacheModel, "sprites/rockeexplode.spr")
	rockeexplode2 = engfunc(EngFunc_PrecacheModel, "sprites/m79grenadeex.spr")
	rockesmoketrail = engfunc(EngFunc_PrecacheModel, "sprites/tdm_smoke.spr")
	rockefire = engfunc(EngFunc_PrecacheModel, "sprites/rockefire.spr")
	rockefire2 = engfunc(EngFunc_PrecacheModel, "sprites/hotglow.spr")
	rockesmoke2 = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	rockesmoke = engfunc(EngFunc_PrecacheModel, "sprites/gas_smoke1.spr")
	engfunc(EngFunc_PrecacheSound, RPGlaunchsound)
	engfunc(EngFunc_PrecacheSound, rockeflysound)
	engfunc(EngFunc_PrecacheSound, rockeexplodesound)
	#if defined IS_ONLINE
	engfunc(EngFunc_PrecacheSound, "battery/weapon_rpg7_reload.wav")
	engfunc(EngFunc_PrecacheSound, "battery/weapon_rpg7_select_n.wav")
	#endif
	register_clcmd("weapon_rpg", "Hook_SelectWeapon")
}

public plugin_natives()
{
	register_native("is_user_has_rpg", "native_bool_has_rpg",1)
	register_native("zr_give_rpg", "give_RPG",1)
}

public bool:native_bool_has_rpg(id)
{
	if(!is_user_alive(id) || !is_user_connected(id)) return false
	
	if(g_has_rpg[id]) return true
	
	return false
}

public fw_BotForwardRegister_Post(iPlayer)
{
	if (is_user_bot(iPlayer))
	{
	unregister_forward(FM_PlayerPostThink, g_fwBotForwardRegister, 1)
	RegisterHamFromEntity(Ham_TakeDamage, iPlayer, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TakeDamage, iPlayer, "fw_TakeDamage_Post", 1)
	}
}

public Hook_SelectWeapon(id)  
{ 
	engclient_cmd(id, "weapon_m3") 
	return PLUGIN_HANDLED
}

public zr_item_event(iPlayer, item, Slot)
{
	if(item == RPG7)
	{
	
	new imoney = zr_get_user_money(iPlayer)
	
	if(imoney < RPGCost)
	{
		zr_print_chat(iPlayer, GREYCHAT, "不够金钱无法购买!")
		return
	}
	
	give_RPG(iPlayer)
	zr_set_user_money(iPlayer, imoney-RPGCost, 1)
	new netname[64]
	pev(iPlayer,pev_netname,netname,charsmax(netname))
	zr_print_chat(0, GREENCHAT, "本应该拿出祖先的伏特加和长剑战斗的%s，在猛喝了一口伏特加以后，嚷着俄语用RPG7炸烂了旁边一只僵尸。",netname)
	}
	else if(item == RPGrocket)
	{
		new imoney = zr_get_user_money(iPlayer)
	
		if(imoney < rocketCost)
		{
			zr_print_chat(iPlayer, BLUECHAT, "不够金钱无法购买!")
			return
		}
		else if(!g_has_rpg[iPlayer])
		{
			zr_print_chat(iPlayer, BLUECHAT, "你没有RPG!")
			return
		}
		
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 1, PITCH_NORM)
		zr_set_user_money(iPlayer, imoney-rocketCost, 1)
		for(new e = 0; e < sizeof PrimaryEntity; e++)
		{
			new iEntity
			while((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", PrimaryEntity[e])) != 0)
			{
				if(pev(iEntity, pev_owner) != iPlayer)
				continue
			
				set_pdata_int(iPlayer, 376 + get_pdata_int(iEntity, 49, 4), 15, 4)
				zr_print_chat(iPlayer, BLUECHAT, "你将RPG火箭弹补充至15发!")
				break
			}
		}
	}
}

public give_RPG(iPlayer)
{
	drop_weapons(iPlayer,1)
	
	g_has_rpg[iPlayer] = true
	new iEntity = give_item(iPlayer, "weapon_m3")
	if(iEntity > 0) set_pdata_int(iPlayer, 376+get_pdata_int(iEntity, 49, 4), 15, 4)
	write_hud(iPlayer,"weapon_rpg")
	set_pdata_int(iEntity, 51, 1, 4) // set clip
}

public zr_hook_changeteam(id) g_has_rpg[id] = false

public zr_gift_primary_ammo(i)
{
	if(!is_user_alive(i))
	return ZR_IGNORED
	
	if(zr_is_user_zombie(i))
	return ZR_IGNORED
		
	if(!g_has_rpg[i])
	return ZR_IGNORED
	
	new iEntity = get_pdata_cbase(i, 378)
	//if(iEntity <= 0)
	//return ZR_IGNORED
	
	set_pdata_int(iEntity, 51, 15, 4)
	zr_print_chat(i,BLUECHAT,"获得完成奖励:RPG火箭弹")
	return ZR_SUPERCEDE
}

public zr_buy_primary_ammo(iPlayer)
{
	if(!is_user_alive(iPlayer))
	return ZR_IGNORED
	
	if(zr_is_user_zombie(iPlayer))
	return ZR_IGNORED
		
	if(!g_has_rpg[iPlayer])
	return ZR_IGNORED
		
	zr_print_chat(iPlayer,BLUECHAT,"RPG火箭弹与一般子弹不通用!")
	return ZR_SUPERCEDE
}

public message_DeathMsg()
{
	new iPlayer = get_msg_arg_int(1)
	if(hudhook[iPlayer])
	{
	set_msg_arg_string(4, RPGKILLSPR)
	hudhook[iPlayer] = false
	}
}

public Event_CurWeapon(iPlayer) 
{
	new iEntity = get_pdata_cbase(iPlayer, 373)
	if(iEntity <= 0)
	return
	
	new iClip,iAmmo
	if(get_user_weapon(iPlayer) == CSW_M3 && g_has_rpg[iPlayer])
	{
		iClip = get_pdata_int(iEntity, 51, 4) 
		iAmmo = get_pdata_int(iPlayer, 376+get_pdata_int(iEntity, 49, 4), 4)
		if(iClip > 1) set_pdata_int(iEntity, 51, 1, 4)
		if(iAmmo > 15) set_pdata_int(iPlayer, 376+get_pdata_int(iEntity, 49, 4), 15, 4)
	}
	
	if(!user_has_weapon(iPlayer,CSW_M3)) g_has_rpg[iPlayer] = false
}

public fwWeapAddToPlayer(rpg,id)
{
	if(entity_get_int(rpg,EV_INT_impulse) == RPG_IMPULSE)
	{
		g_has_rpg[id] = true
		entity_set_int(rpg,EV_INT_impulse,0)
		write_hud(id,"weapon_rpg")
	}
	else if(!g_has_rpg[id]) write_hud(id,"weapon_m3")
}

public fw_SetModel(entity,model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED
	
	static szClassName[33]
	entity_get_string(entity,EV_SZ_classname,szClassName,charsmax(szClassName))
	
	if(!equal(szClassName,"weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner=entity_get_edict(entity,EV_ENT_owner)
	
	new iWeapon = get_pdata_cbase(entity, 35, 4)
	if(iWeapon <= 0)
	return FMRES_IGNORED
	
	if(equal(model,"models/w_m3.mdl"))
	{
		static iStoredAugID
		iStoredAugID=find_ent_by_owner(-1,"weapon_m3",entity)
		if(!is_valid_ent(iStoredAugID))
		return FMRES_IGNORED
		if(g_has_rpg[iOwner])
		{
			entity_set_int(iStoredAugID,EV_INT_impulse,RPG_IMPULSE)
			if(pev(entity, pev_iuser1) == RPGNONEROCKE) entity_set_model(entity,RPGrockelaunchermodel[1])
			else entity_set_model(entity,RPGrockelaunchermodel[2])
			return FMRES_SUPERCEDE
		}
		else return FMRES_IGNORED
	}
	return FMRES_IGNORED
}

public fw_UpdateClientData_Post(iPlayer, sendweapons, cd_handle) 
{ 
	if(!is_user_alive(iPlayer)) 
	return
	
	new iEntity = get_pdata_cbase(iPlayer, 373)
	if(iEntity <= 0)
	return
	
	if(get_pdata_int(iEntity, 43, 4) != CSW_M3||!g_has_rpg[iPlayer])
	return
	
	if(get_pdata_float(iPlayer, 83, 5) <= 0) set_cd(cd_handle, CD_ID, 0)
}

public fw_CmdStart(iPlayer, uc_handle, seed)
{
	if(!is_user_alive(iPlayer))
	return FMRES_IGNORED
	
	new iEntity = get_pdata_cbase(iPlayer, 373)
	if(iEntity <= 0)
	return FMRES_IGNORED
	
	if(get_pdata_int(iEntity, 43, 4) != CSW_M3||!g_has_rpg[iPlayer])
	return FMRES_IGNORED
	
	new button = get_uc(uc_handle, UC_Buttons)
	new oldbutton = pev(iPlayer, pev_oldbuttons)
	
	if(!(button & IN_ATTACK))
	return FMRES_IGNORED
	
	button &= ~IN_ATTACK
	set_uc(uc_handle, UC_Buttons, button)
	
	if(oldbutton & IN_ATTACK)
	return FMRES_IGNORED
	
	if(pev(iEntity, pev_iuser1) == RPGNONEROCKE || get_pdata_float(iPlayer, 83, 5) > 0)
	return FMRES_IGNORED
	
	new Float:fCurTime
	global_get(glb_time, fCurTime)
	g_fLastThink[iPlayer] = fCurTime + get_pcvar_float(cvar_shoottime)
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_WEAPON, RPGlaunchsound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	native_playanim(iPlayer, idle)
	native_playanim(iPlayer, shoot1)
	makerocke(iPlayer)
	set_pdata_float(iEntity, 46, get_pcvar_float(cvar_shoottime), 4)
	set_pdata_int(iEntity, 51, 0, 4)
	rockeshooting[iPlayer] = true
	new Float:punchangle[3]
	pev(iPlayer, pev_punchangle, punchangle)
	punchangle[0] -= get_pcvar_float(cvar_shootpunchagele)
	set_pev(iPlayer, pev_punchangle, punchangle)
	
	new Float:fVelocity[3]
	pev(iPlayer, pev_velocity, fVelocity)
	fVelocity[0] = 0.0
	fVelocity[1] = 0.0
	set_pev(iPlayer, pev_velocity, fVelocity)
	set_pev(iEntity, pev_iuser1, RPGNONEROCKE)
	
	return FMRES_IGNORED
}

public fw_PlayerPreThink(iPlayer)
{
	if(!is_user_alive(iPlayer))
	return FMRES_IGNORED
	
	new iEntity = get_pdata_cbase(iPlayer, 373)
	if(iEntity <= 0)
	return FMRES_IGNORED
	
	if(get_pdata_int(iEntity, 43, 4) != CSW_M3||!g_has_rpg[iPlayer])
	return FMRES_IGNORED
	
	set_pev(iPlayer, pev_maxspeed, get_pcvar_float(cvar_movespeed))
	
	return FMRES_IGNORED
}

public fw_PlayerPostThink(iPlayer)
{
	if(!is_user_alive(iPlayer))
	return
	
	new iEntity = get_pdata_cbase(iPlayer, 373)
	if(iEntity <= 0)
	return
	
	if(get_pdata_int(iEntity, 43, 4) != CSW_M3||!g_has_rpg[iPlayer])
	{
	rockereloading[iPlayer] = false
	rockeshooting[iPlayer] = false
	return
	}
	
	new Float:fCurTime
	global_get(glb_time, fCurTime)
	
	if(rockeshooting[iPlayer] && get_pdata_float(iPlayer, 83, 5) <= 0 && fCurTime >= g_fLastThink[iPlayer]) rockeshooting[iPlayer] = false
	
	new rocke = get_pdata_int(iPlayer, 376+get_pdata_int(iEntity, 49, 4), 4)
	if(!rockereloading[iPlayer] && !rockeshooting[iPlayer] && get_pdata_float(iPlayer, 83, 5) <= 0 && rocke && pev(iEntity, pev_iuser1) == RPGNONEROCKE)
	{
	rockereloading[iPlayer] = true
	g_fLastThink[iPlayer] = fCurTime + get_pcvar_float(cvar_reloadtime)
	native_playanim(iPlayer, idle_none)
	native_playanim(iPlayer, reload)
	set_pdata_float(iPlayer, 83, get_pcvar_float(cvar_reloadtime), 5)
	}
	
	if(rockereloading[iPlayer] && get_pdata_float(iPlayer, 83, 5) <= 0 && fCurTime >= g_fLastThink[iPlayer])
	{
	native_playanim(iPlayer, idle)
	set_pdata_int(iEntity, 51, 1, 4)
	set_pdata_int(iPlayer, 376+get_pdata_int(iEntity, 49, 4), rocke-1, 4)
	set_pev(iEntity, pev_iuser1, 0)
	rockereloading[iPlayer] = false
	}
}

public makerocke(iPlayer)
{
	new Float:fOrigin[3], Float:fAngle[3], Float:vfAngle[3]

	get_aim_origin_vector(iPlayer, 32.0, 4.0, 1.0, fOrigin)
	pev(iPlayer, pev_angles, fAngle)
	pev(iPlayer, pev_v_angle, vfAngle)
	fAngle[0] *=3
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(iEntity))
	return
	
	engfunc(EngFunc_SetOrigin, iEntity, fOrigin)
	engfunc(EngFunc_SetModel, iEntity, ROCKEMODEL)
	set_pev(iEntity, pev_classname, ROCKENAME)
	set_pev(iEntity, pev_owner, iPlayer)
	set_pev(iEntity, pev_mins, {-2.0, -2.0, -2.0})
	set_pev(iEntity, pev_maxs, {2.0, 2.0, 2.0})
	set_pev(iEntity, pev_solid, SOLID_BBOX)
	set_pev(iEntity, pev_movetype, MOVETYPE_TOSS)
	set_pev(iEntity, pev_gravity, get_pcvar_float(cvar_rockegravity))
	set_pev(iEntity, pev_angles, fAngle)
	set_pev(iEntity, pev_v_angle, vfAngle)
	fw_rockethink(iEntity)
	
	engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, rockeflysound, 1.0, 0.5, 0, PITCH_NORM)
	
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(rockefire)
	write_byte(5)
	write_byte(255)
	message_end()
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(iEntity)
	write_short(rockesmoketrail)
	write_byte(floatround(get_pcvar_float(cvar_flyspeed)/100.0))
	write_byte(3)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	message_end()
	
	new Float:newOrigin[5][3], Float:newOrigin2[5][3]
	get_spherical_coord(fOrigin, 20.0, 30.0, 5.0, newOrigin[0])
	get_spherical_coord(fOrigin, 20.0, -20.0, -5.0, newOrigin[1])
	get_spherical_coord(fOrigin, -14.0, 30.0, 7.0, newOrigin[2])
	get_spherical_coord(fOrigin, 25.0, 10.0, -8.0, newOrigin[3])
	get_spherical_coord(fOrigin, -17.0, 17.0, 0.0, newOrigin[4])
	get_aim_origin_vector(iPlayer, -80.0, 4.0, 1.0, fOrigin)
	get_spherical_coord(fOrigin, 30.0, 40.0, 2.0, newOrigin2[0])
	get_spherical_coord(fOrigin, 30.0, -30.0, -3.0, newOrigin2[1])
	get_spherical_coord(fOrigin, -24.0, 40.0, 4.0, newOrigin2[2])
	get_spherical_coord(fOrigin, 35.0, 20.0, -4.0, newOrigin2[3])
	get_spherical_coord(fOrigin, -27.0, 27.0, 0.0, newOrigin2[4])
	for(new i = 0; i < 5; i++)
	{
	producesmoke(newOrigin[i], 10, 50)
	producesmoke(newOrigin2[i], random_num(10, 15), random_num(50, 100))
	}
}

public producesmoke(Float:fOrigin[3], size, deep)
{
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(g_smokeSpr)
	write_byte(size)
	write_byte(deep)
	message_end()
}

public fw_rockethink(iEntity)
{
	if(!pev_valid(iEntity))
	return FMRES_IGNORED
	
	new classname[32]
	pev(iEntity, pev_classname, classname, charsmax(classname))
	if(equali(classname, ROCKENAME))
	{
	set_pev(iEntity, pev_nextthink, get_gametime()+0.01)
	new Float:fOrigin[3], Float:vfAngle[3], Float:aimOrigin[3], Float:fVelocity[3]
	pev(iEntity, pev_origin, fOrigin)
	pev(iEntity, pev_v_angle, vfAngle)
	vfAngle[0] += random_float(-get_pcvar_float(cvar_flyoffset), get_pcvar_float(cvar_flyoffset))
	vfAngle[1] += random_float(-get_pcvar_float(cvar_flyoffset), get_pcvar_float(cvar_flyoffset))
	vfAngle[2] += random_float(-get_pcvar_float(cvar_flyoffset), get_pcvar_float(cvar_flyoffset))
	set_pev(iEntity, pev_v_angle, vfAngle)
	fm_get_aim_origin(iEntity, aimOrigin)
	get_speed_vector(fOrigin, aimOrigin, get_pcvar_float(cvar_flyspeed), fVelocity)
	set_pev(iEntity, pev_velocity, fVelocity)
	new Float:fAngle[3]
	pev(iEntity, pev_velocity, fVelocity)
	vector_to_angle(fVelocity, fAngle)
	set_pev(iEntity, pev_angles, fAngle)
	
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_DLIGHT) 
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_byte(15)
	write_byte(255)
	write_byte(127)
	write_byte(100)
	write_byte(1)
	write_byte(0)
	message_end()
	
	get_aim_origin_vector(iEntity, -100.0, 1.0, 5.0, fOrigin)
	
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(rockefire2)
	write_byte(3)
	write_byte(255)
	message_end()
	
	new num = random_num(0,2)
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	if(num == 0) write_short(rockesmoke)
	else if(num == 1) write_short(rockesmoke2)
	else if(num == 2) write_short(g_smokeSpr)
	write_byte(random_num(1, 10))
	write_byte(random_num(50, 255))
	message_end()
	}
	return FMRES_IGNORED
}

public fw_Touch(iEntity, iPtd)
{
	if(!pev_valid(iEntity))
	return FMRES_IGNORED
	
	new classname[32]
	pev(iEntity, pev_classname, classname, charsmax(classname))
	if(equali(classname, ROCKENAME))
	{
	new Float:fOrigin[3]
	pev(iEntity, pev_origin, fOrigin)
	if(engfunc(EngFunc_PointContents, fOrigin) == CONTENTS_SKY)
	{
	engfunc(EngFunc_RemoveEntity, iEntity)
	return FMRES_IGNORED
	}
	
	for(new e = 1 ; e < 33 ; e++)
	{
	if(is_user_alive(e))
	{
	new Float:iOrigin[3]
	pev(e, pev_origin, iOrigin)
	new Float:range = get_distance_f(fOrigin, iOrigin)
	if(range <= get_pcvar_float(cvar_shakerange))
	{
	message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0,0,0}, e)
	write_short((1<<12))
	write_short((1<<12))
	write_short((1<<12))
	message_end()
	}
	if(fm_is_ent_visible(e, iEntity) && get_pcvar_float(cvar_lightrange) > range)
	{
	new lightrange = floatround(get_pcvar_float(cvar_lightrange) - range)
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, e)
	write_short(lightrange)
	write_short(0)
	write_short(0x0000)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	message_end()
	}
	}
	}
	
	new i = 0
	while((i = engfunc(EngFunc_FindEntityInSphere, i, fOrigin, get_pcvar_float(cvar_rockedamagerange))) > 0)
	{
	if(pev_valid(i))
	{
	new iPlayer = pev(iEntity, pev_owner)
	new Ptdclassname[32]
	pev(i, pev_classname, Ptdclassname, charsmax(Ptdclassname))
	new Float:iOrigin[3]
	pev(i, pev_origin, iOrigin)
	new Float:range = get_distance_f(fOrigin, iOrigin)
	new Float:fMaxDistant = get_pcvar_float(cvar_rockedamagerange)
	new Float:fDamage = get_pcvar_float(cvar_rockedamage)
	new Float:fMaxDamage = fDamage*((fMaxDistant-range)/fMaxDistant)
	if(!fMaxDamage) fMaxDamage = fDamage
	if(!fm_is_ent_visible(i, iEntity)) fMaxDamage *= get_pcvar_float(cvar_partitiondamage)
	if(pev(i, pev_takedamage) != DAMAGE_NO)
	{
	if(equali(Ptdclassname, "player")&&is_user_alive(i)&&get_pdata_int(iPlayer, 114, 5) != get_pdata_int(i, 114, 5))
	{
	new Float:punchangle[3]
	pev(i, pev_punchangle, punchangle)
	punchangle[0] +=random_float(-get_pcvar_float(cvar_punchagele), get_pcvar_float(cvar_punchagele))
	punchangle[1] +=random_float(-get_pcvar_float(cvar_punchagele), get_pcvar_float(cvar_punchagele))
	punchangle[2] +=random_float(-get_pcvar_float(cvar_punchagele), get_pcvar_float(cvar_punchagele))
	set_pev(i, pev_punchangle, punchangle)
	set_velocity_from_origin(i, fOrigin, get_pcvar_float(cvar_rockeknock)*fMaxDamage)
	}
	ExecuteHamB(Ham_TakeDamage, i, iEntity, iPlayer, fMaxDamage, DMG_GENERIC)
	if(equali(Ptdclassname, "func_breakable") || equali(Ptdclassname, "func_pushable")) dllfunc(DLLFunc_Use, i, iEntity)
	}
	}
	}
	engfunc(EngFunc_EmitSound, iEntity, CHAN_WEAPON, rockeexplodesound, 1.0, 0.3, 0, PITCH_NORM)
	
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord,fOrigin[0])
	engfunc(EngFunc_WriteCoord,fOrigin[1])
	engfunc(EngFunc_WriteCoord,fOrigin[2]+200.0)
	write_short(rockeexplode)
	write_byte(20)
	write_byte(100)
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord,fOrigin[0])
	engfunc(EngFunc_WriteCoord,fOrigin[1])
	engfunc(EngFunc_WriteCoord,fOrigin[2]+70.0)
	write_short(rockeexplode2)
	write_byte(30)
	write_byte(255)
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_WORLDDECAL)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_byte(engfunc(EngFunc_DecalIndex, "{scorch1"))
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_DLIGHT) 
	engfunc(EngFunc_WriteCoord,fOrigin[0])
	engfunc(EngFunc_WriteCoord,fOrigin[1])
	engfunc(EngFunc_WriteCoord,fOrigin[2])
	write_byte(50)
	write_byte(255)
	write_byte(0)
	write_byte(0)
	write_byte(2)
	write_byte(0)
	message_end()
	
	fOrigin[2] += 40.0
	makesmoke(iEntity, fOrigin)
	
	engfunc(EngFunc_RemoveEntity, iEntity)
	}
	return FMRES_IGNORED
}

public fw_ItemDeploy_Post(weapon)
{
	static id;
	id = get_pdata_cbase(weapon, 41, 4);
	
	if(g_has_rpg[id])
	{
		if(pev(weapon, pev_iuser1) == RPGNONEROCKE)
		{
			native_playanim(id, draw_none)
			set_pdata_float(id, 83, get_pcvar_float(cvar_drawtime_none), 5)
		}
		else set_pdata_float(id, 83, get_pcvar_float(cvar_drawtime), 5)
		set_pev(id, pev_viewmodel2, RPGrockelaunchermodel[0])
		if(pev(weapon, pev_iuser1) == RPGNONEROCKE) set_pev(id, pev_weaponmodel2, RPGrockelaunchermodel[1])
		else set_pev(id, pev_weaponmodel2, RPGrockelaunchermodel[2])
	}
}

public fw_Weapon_WeaponIdle_Post(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, 41, 4)
	
	if(rockereloading[iPlayer] || rockeshooting[iPlayer])
	return
	
	if(pev(iEntity, pev_iuser1) == RPGNONEROCKE) native_playanim(iPlayer, idle_none)
}

public fw_Weapon_Reload(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, 41, 4)
	if(g_has_rpg[iPlayer]) return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_connected(attacker) || !is_user_connected(victim))
	return HAM_HANDLED
	
	if(pev(inflictor, pev_owner) != attacker)
	return HAM_HANDLED
	
	new classname[32]
	pev(inflictor, pev_classname, classname, charsmax(classname))
	if(equali(classname, ROCKENAME)) hudhook[attacker] = true
	
	return HAM_HANDLED
}

public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_connected(attacker))
	return
	
	hudhook[attacker] = false
}

public makesmoke(iEntity, Float:position[3])
{
	if(engfunc(EngFunc_PointContents, position) != CONTENTS_WATER)
	{
	new Float:origin[8][3], Float:iorigin[21][3], Float:iposition[3]
	iposition[0]=position[0]
	iposition[1]=position[1]
	iposition[2]=position[2]
	get_spherical_coord(iposition, 100.0, 20.0, 0.0, iorigin[0])
	get_spherical_coord(iposition, 0.0, 100.0, 0.0, iorigin[1])
	get_spherical_coord(iposition, 100.0, 100.0, 0.0, iorigin[2])
	get_spherical_coord(iposition, 70.0, 120.0, 0.0, iorigin[3])
	get_spherical_coord(iposition, 120.0, 20.0, 0.0, iorigin[4])
	get_spherical_coord(iposition, 120.0, 65.0, 0.0, iorigin[5])
	get_spherical_coord(iposition, 120.0, 110.0, 0.0, iorigin[6])
	get_spherical_coord(iposition, 120.0, 155.0, 0.0, iorigin[7])
	get_spherical_coord(iposition, 120.0, 200.0, 0.0, iorigin[8])
	get_spherical_coord(iposition, 120.0, 245.0, 0.0, iorigin[9])
	get_spherical_coord(iposition, 120.0, 290.0, 20.0, iorigin[10])
	get_spherical_coord(iposition, 120.0, 335.0, 20.0, iorigin[11])
	get_spherical_coord(iposition, 120.0, 40.0, 20.0, iorigin[12])
	get_spherical_coord(iposition, 40.0, 120.0, 20.0, iorigin[13])
	get_spherical_coord(iposition, 40.0, 110.0, 20.0, iorigin[14])
	get_spherical_coord(iposition, 60.0, 110.0, 20.0, iorigin[15])
	get_spherical_coord(iposition, 110.0, 40.0, 20.0, iorigin[16])
	get_spherical_coord(iposition, 120.0, 30.0, 20.0, iorigin[17])
	get_spherical_coord(iposition, 30.0, 130.0, 20.0, iorigin[18])
	get_spherical_coord(iposition, 30.0, 125.0, 20.0, iorigin[19])
	get_spherical_coord(iposition, 30.0, 120.0, 20.0, iorigin[20])
	for(new i = 0; i < MDLCOUNT; i++)
	{
	new Float:velocity[MDLCOUNT][3]
	velocity[i][0] = random_float(-500.0,500.0)
	velocity[i][1] = random_float(-500.0,500.0)
	velocity[i][2] = random_float(-300.0,300.0)
	makebreakmodels(position, 1.0, 1.0, 1.0, velocity[i][0], velocity[i][1], velocity[i][2], szbreakmodels[random_num(0, sizeof szbreakmodels-1)], 1, get_pcvar_num(cvar_mdltime))
	}
	for(new e = 0; e < 21; e++) make_smoke(iorigin[e], g_smokeSpr2, 10, 255)
	position[2]+=120.0
	get_spherical_coord(position, 0.0, 0.0, 185.0, origin[0])
	get_spherical_coord(position, 0.0, 80.0, 130.0, origin[1])
	get_spherical_coord(position, 41.0, 43.0, 110.0, origin[2])
	get_spherical_coord(position, 90.0, 90.0, 90.0, origin[3])
	get_spherical_coord(position, 80.0, 25.0, 185.0, origin[4])
	get_spherical_coord(position, 101.0, 100.0, 162.0, origin[5])
	get_spherical_coord(position, 68.0, 35.0, 189.0, origin[6])
	get_spherical_coord(position, 0.0, 95.0, 155.0, origin[7])
	
	for(new c = 0; c < 8; c++) make_smoke(origin[c], rockesmoke, 50, 50)
	}
}


stock make_smoke(Float:position[3], sprite_index, size, light)
{
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, position, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, position[0])
	engfunc(EngFunc_WriteCoord, position[1])
	engfunc(EngFunc_WriteCoord, position[2])
	write_short(sprite_index)
	write_byte(size)
	write_byte(light)
	message_end()
}

stock makebreakmodels(Float:vecOrigin[3], Float:sizex, Float:sizey, Float:sizez, Float:velocityx, Float:velocityy, Float:velocityz, const models_index, count, livetime)
{
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, vecOrigin, 0)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	engfunc(EngFunc_WriteCoord, sizex)
	engfunc(EngFunc_WriteCoord, sizey)
	engfunc(EngFunc_WriteCoord, sizez)
	engfunc(EngFunc_WriteCoord, velocityx)
	engfunc(EngFunc_WriteCoord, velocityy)
	engfunc(EngFunc_WriteCoord, velocityz)
	write_byte(10)
	write_short(models_index)
	write_byte(count)
	write_byte(livetime*10)
	write_byte(0x40)
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

stock native_playanim(player, anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1
}

stock fm_get_aim_origin(index, Float:origin[3])
{
	new Float:start[3], Float:view_ofs[3]
	pev(index, pev_origin, start)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)
	
	new Float:dest[3]
	pev(index, pev_v_angle, dest)
	engfunc(EngFunc_MakeVectors, dest)
	global_get(glb_v_forward, dest)
	xs_vec_mul_scalar(dest, 9999.0, dest)
	xs_vec_add(start, dest, dest)
	
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0)
	get_tr2(0, TR_vecEndPos, origin)
	
	return 1
}

stock get_velocity_from_origin( ent, Float:fOrigin[3], Float:fSpeed, Float:fVelocity[3] )
{
	new Float:fEntOrigin[3]
	pev( ent, pev_origin, fEntOrigin )
	
	new Float:fDistance[3]
	fDistance[0] = fEntOrigin[0] - fOrigin[0]
	fDistance[1] = fEntOrigin[1] - fOrigin[1]
	fDistance[2] = fEntOrigin[2] - fOrigin[2]
	
	new Float:fTime = ( vector_distance( fEntOrigin,fOrigin ) / fSpeed )
	
	fVelocity[0] = fDistance[0] / fTime
	fVelocity[1] = fDistance[1] / fTime
	fVelocity[2] = fDistance[2] / fTime
	
	return ( fVelocity[0] && fVelocity[1] && fVelocity[2] )
}

stock set_velocity_from_origin(ent, Float:fOrigin[3], Float:fSpeed)
{
	new Float:fVelocity[3]
	get_velocity_from_origin(ent,fOrigin,fSpeed,fVelocity)
	fVelocity[2] /= 2.0
	set_pev(ent,pev_velocity,fVelocity)
	return 1
} 

stock get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length=redius*floatcos(vertical_angle, degrees)
	origin[0]=ent_origin[0]+length*floatcos(level_angle,degrees)
	origin[1]=ent_origin[1]+length*floatsin(level_angle,degrees)
	origin[2]=ent_origin[2]+redius*floatsin(vertical_angle,degrees)
}

stock bool:fm_is_ent_visible(index, entity, ignoremonsters = 0) 
{
	new Float:start[3], Float:dest[3]
	pev(index, pev_origin, start)
	pev(index, pev_view_ofs, dest)
	xs_vec_add(start, dest, start)
	pev(entity, pev_origin, dest)
	engfunc(EngFunc_TraceLine, start, dest, ignoremonsters, index, 0)
	new Float:fraction
	get_tr2(0, TR_flFraction, fraction)
	if(fraction == 1.0 || get_tr2(0, TR_pHit) == entity) return true
	return false
}

public write_hud(id,const hud[])
{
	message_begin(MSG_ONE,get_user_msgid("WeaponList"),{0,0,0},id)
	write_string(hud)
	write_byte(5)
	write_byte(32)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(5)
	write_byte(CSW_M3)
	message_end()
}

stock give_item(iPlayer, const wEntity[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, wEntity))
	new Float:origin[3]
	pev(iPlayer, pev_origin, origin)
	set_pev(iEntity, pev_origin, origin)
	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, iEntity)
	new save = pev(iEntity, pev_solid)
	dllfunc(DLLFunc_Touch, iEntity, iPlayer)
	if(pev(iEntity, pev_solid) != save)
	return iEntity
	engfunc(EngFunc_RemoveEntity, iEntity)
	return -1
}

stock drop_weapons(iPlayer, Slot)
{
	new item = get_pdata_cbase(iPlayer, 367+Slot, 4)
	while(item > 0)
	{
	static classname[24]
	pev(item, pev_classname, classname, charsmax(classname))
	engclient_cmd(iPlayer, "drop", classname)
	item = get_pdata_cbase(item, 42, 5)
	}
	set_pdata_cbase(iPlayer, 367, -1, 4)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg936\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset134 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang2052\\ f0\\ fs16 \n\\ par }
*/
