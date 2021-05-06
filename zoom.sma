/* ammx编写头版 by moddev*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "DSHGFHDS"
#define VERSION "1.0"
#define AUTHOR "ZOOM"

new Float:g_fLastThink[33]
new const gunname[][] = { "weapon_awp", "weapon_scout", "weapon_g3sg1", "weapon_sg550" }

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_forward(FM_CmdStart, "fw_CmdStart")
	for(new i = 0; i < 4; i++) RegisterHam(Ham_Spawn, gunname[i], "fw_WeaponSpawn_Post", 1)
	register_clcmd("zoomin", "gunzoomin")
	register_clcmd("zoomout", "gunzoomout")
}

public Event_CurWeapon(iPlayer)
{
	new iEntity = get_pdata_cbase(iPlayer, 373)
	if(iEntity <= 0)
	return PLUGIN_CONTINUE
	
	new iWeapon = get_pdata_int(iEntity, 43, 4)
	if(iWeapon != CSW_AWP && iWeapon != CSW_SCOUT && iWeapon != CSW_G3SG1 && iWeapon != CSW_SG550)
	{
	client_cmd(iPlayer, "bind MWHEELDOWN invnext")
	client_cmd(iPlayer, "bind MWHEELUP invprev")
	return PLUGIN_CONTINUE
	}
	
	if(get_pdata_int(iPlayer, 363, 5) >= 90)
	{
	client_cmd(iPlayer, "bind MWHEELDOWN invnext")
	client_cmd(iPlayer, "bind MWHEELUP invprev")
	}
	else
	{
	client_cmd(iPlayer,"bind MWHEELUP zoomin")
	client_cmd(iPlayer,"bind MWHEELDOWN zoomout")
	}
	
	return PLUGIN_CONTINUE
}

public fw_WeaponSpawn_Post(iEntity)
{
	set_pev(iEntity, pev_weapons, 40);
}

public fw_CmdStart(iPlayer, uc_handle, seed)
{
	if(!is_user_alive(iPlayer))
	return FMRES_IGNORED
	
	new iEntity = get_pdata_cbase(iPlayer, 373)
	if(iEntity <= 0)
	return FMRES_IGNORED
	
	new iWeapon = get_pdata_int(iEntity, 43, 4)
	if(iWeapon != CSW_AWP && iWeapon != CSW_SCOUT && iWeapon != CSW_G3SG1 && iWeapon != CSW_SG550)
	return FMRES_IGNORED

	new button = get_uc(uc_handle, UC_Buttons)
	new oldbutton = pev(iPlayer, pev_oldbuttons)
	
	if(!(button & IN_ATTACK2))
	return FMRES_IGNORED
	
	button &= ~IN_ATTACK2
	set_uc(uc_handle, UC_Buttons, button)
	
	if(oldbutton & IN_ATTACK2)
	return FMRES_IGNORED
	
	if(get_pdata_float(iPlayer, 83, 5) > 0 || get_pdata_float(iEntity, 46, 4) > 0)
	return FMRES_IGNORED

	new Float:fCurTime
	global_get(glb_time, fCurTime)
	
	if(fCurTime < g_fLastThink[iPlayer])
	return FMRES_IGNORED
	
	g_fLastThink[iPlayer] = fCurTime + 0.25
	if(get_pdata_int(iPlayer, 363, 5) >= 90) set_pdata_int(iPlayer, 363, pev(iEntity, pev_weapons), 5)
	else set_pdata_int(iPlayer, 363, 90, 5)
	
	return FMRES_IGNORED
}

public gunzoomin(iPlayer)
{
	new iEntity = get_pdata_cbase(iPlayer, 373)
	if(iEntity <= 0)
	return
	
	new iWeapon = get_pdata_int(iEntity, 43, 4)
	if(iWeapon != CSW_AWP && iWeapon != CSW_SCOUT && iWeapon != CSW_G3SG1 && iWeapon != CSW_SG550)
	return
	
	if(pev(iEntity, pev_weapons) > 10 && pev(iEntity, pev_weapons) <= 40)
	{
	set_pev(iEntity, pev_weapons, pev(iEntity, pev_weapons)-3)
	set_pdata_int(iPlayer, 363, pev(iEntity, pev_weapons), 5)
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100)
	}
}

public gunzoomout(iPlayer)
{
	new iEntity = get_pdata_cbase(iPlayer, 373)
	if (iEntity <= 0)
	return
	
	new iWeapon = get_pdata_int(iEntity, 43, 4)
	if(iWeapon != CSW_AWP && iWeapon != CSW_SCOUT && iWeapon != CSW_G3SG1 && iWeapon != CSW_SG550)
	return
	
	if(pev(iEntity, pev_weapons) < 40)
	{
	set_pev(iEntity, pev_weapons, pev(iEntity, pev_weapons)+3)
	set_pdata_int(iPlayer, 363, pev(iEntity, pev_weapons), 5)
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100)
	}
}