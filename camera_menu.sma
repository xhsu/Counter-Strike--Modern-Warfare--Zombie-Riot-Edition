/* 本插件由 AMXX-Studio 中文版自动生成*/
/* UTF-8 func by www.DT-Club.net */

#include <amxmodx>
#include <fakemeta_util>
#include <xs>

//#define PLAYER_ALPHA		// 是否开启透明玩家

#define CAMERA_NONE		0
#define CAMERA_3RDPERSON	1
#define CAMERA_UPLEFT		2
#define CAMERA_TOPDOWN		3

#define PLUGIN_NAME		"Player Camera"
#define PLUGIN_VERSION		"1.0"
#define PLUGIN_AUTHOR		"Martin"

new g_view_ent[33],g_view_type[33]

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_concmd("camera_menu","show_menu_camera")
	#if defined PLAYER_ALPHA
	register_forward(FM_AddToFullPack,"fw_AddToFullPackPost",1)
	#endif
	register_forward(FM_PlayerPostThink,"fw_PlayerPostThink_Post",1)
}

public client_connect(id)
{
	if(pev_valid(g_view_ent[id])) fm_remove_entity(g_view_ent[id])
	
	g_view_ent[id] = 0
	g_view_type[id] = 0
}

#if defined PLAYER_ALPHA
public fw_AddToFullPackPost(es_handle, e, ent, host, hostflags, id, pSet)
{
	if(ent != host) return
	
	new classname[32]
	pev(ent,pev_classname,classname,charsmax(classname))
	if(!equal(classname,"player")) return
	
	set_es(es_handle, ES_RenderMode, kRenderTransTexture)
	set_es(es_handle, ES_RenderAmt, 100)
}
#endif

public fw_PlayerPostThink_Post(id)
{
	if(!is_user_alive(id)) return
	if(!g_view_type[id]) return
	if(!pev_valid(g_view_ent[id])) return
	
	static Float:v_angle[3],Float:punchangle[3],Float:makevectors[3]
	pev(id,pev_v_angle,v_angle)
	pev(id,pev_punchangle,punchangle)
	xs_vec_add(v_angle,punchangle,makevectors)
	engfunc(EngFunc_MakeVectors,makevectors)
	
	static Float:origin[3],Float:viewofs[3],Float:vecSrc[3]
	pev(id,pev_origin,origin)
	pev(id,pev_view_ofs,viewofs)
	xs_vec_add(origin,viewofs,vecSrc)
	
	static Float:vecAiming[3]
	global_get(glb_v_forward,vecAiming)
	
	static tr
	switch(g_view_type[id])
	{
		case CAMERA_3RDPERSON:
		{
			static Float:vecResult[3]
			xs_vec_mul_scalar(vecAiming,128.0,vecAiming)
			xs_vec_sub(vecSrc,vecAiming,vecResult)
			
			engfunc(EngFunc_TraceLine,vecSrc,vecResult,IGNORE_MONSTERS,id,tr)
                
			new Float:ret[3]
			get_tr2(tr, TR_vecEndPos,ret)
			set_pev(g_view_ent[id],pev_origin,ret)
                
			static Float:angles[3]
			pev(id,pev_v_angle,angles)
			set_pev(g_view_ent[id],pev_angles,angles)
			
			engfunc(EngFunc_SetView,id,g_view_ent[id])
		}
		case CAMERA_UPLEFT:
		{
			static Float:vecResult[3],Float:vecRight[3],Float:vecUp[3]
			global_get(glb_v_up,vecUp)
			global_get(glb_v_right,vecRight)
			xs_vec_mul_scalar(vecUp,15.0,vecUp)
			xs_vec_mul_scalar(vecRight,15.0,vecRight)
			xs_vec_add(vecUp,vecRight,vecUp)
			xs_vec_mul_scalar(vecAiming,32.0,vecAiming)
			xs_vec_sub(vecAiming,vecUp,vecAiming)
			xs_vec_sub(vecSrc,vecAiming,vecResult)
			
			engfunc(EngFunc_TraceLine,vecSrc,vecResult,IGNORE_MONSTERS,id,tr)
                
			new Float:ret[3]
			get_tr2(tr, TR_vecEndPos,ret)
			set_pev(g_view_ent[id],pev_origin,ret)
                
			static Float:angles[3]
			pev(id,pev_v_angle,angles)
			set_pev(g_view_ent[id],pev_angles,angles)
			
			engfunc(EngFunc_SetView,id,g_view_ent[id])
		}
		case CAMERA_TOPDOWN:
		{
			new Float:vecAdd[3] = {0.0,0.0,2048.0}
			xs_vec_add(vecSrc,vecAdd,vecAdd)
			engfunc(EngFunc_TraceLine,vecSrc,vecAdd,IGNORE_MONSTERS,id,tr)
                
			new Float:ret[3]
			get_tr2(tr, TR_vecEndPos,ret)
			ret[2] -= 40.0
			set_pev(g_view_ent[id],pev_origin,ret)
                
			static Float:angles[3]
			pev(id,pev_v_angle,angles)
			angles[0] = 90.0,angles[2] = 0.0
			set_pev(g_view_ent[id],pev_angles,angles)
			
			engfunc(EngFunc_SetView,id,g_view_ent[id])
		}
	}
}

public show_menu_camera(id)
{
	static menuid, menu[128]
	
	formatex(menu, charsmax(menu), "视角菜单")
	menuid = menu_create(menu, "menu_camera")
	
	menu_additem(menuid,"第三人称视角 (远)")
	menu_additem(menuid,"第三人称视角 (近)")
	menu_additem(menuid,"俯视")
	menu_additem(menuid,"第一人称视角")
	
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	menu_display(id, menuid)
}

public menu_camera(id, menuid, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED;
	}
	
	if (!is_user_alive(id))
	{
		menu_destroy(menuid)
		return PLUGIN_HANDLED
	}
	
	switch(item)
	{
		case 0:fm_set_view(id,CAMERA_3RDPERSON)
		case 1:fm_set_view(id,CAMERA_UPLEFT)
		case 2:fm_set_view(id,CAMERA_TOPDOWN)
		case 3:fm_set_view(id,CAMERA_NONE)
	}
	
	menu_destroy(menuid)
	return PLUGIN_HANDLED;
}

stock fm_set_view(id,type) 
{ 
	if(!type)
	{
		engfunc(EngFunc_SetView, id, id)
			
		if(pev_valid(g_view_ent[id])) fm_remove_entity(g_view_ent[id])
			
		g_view_type[id] = CAMERA_NONE
		g_view_ent[id] = 0

		set_pev(id,pev_rendermode,kRenderNormal)
		set_pev(id,pev_renderamt,0.0)

		return 1
	}
	
	if(type == g_view_type[id]) return 0
	
	g_view_type[id] = type
	
	if(pev_valid(g_view_ent[id])) fm_remove_entity(g_view_ent[id])
	
	new camera = fm_create_entity("info_target")
	set_pev(camera,pev_classname,"VexdCam")

	engfunc(EngFunc_SetModel,camera,"models/w_usp.mdl")
	engfunc(EngFunc_SetSize,camera,{0.0,0.0,0.0},{0.0,0.0,0.0})
		
	set_pev(camera,pev_movetype,MOVETYPE_NOCLIP)
	set_pev(camera,pev_solid,SOLID_NOT)
	set_pev(camera,pev_takedamage,DAMAGE_NO)
	set_pev(camera,pev_gravity,0.0)
	set_pev(camera,pev_owner,id)
	set_pev(camera,pev_rendermode,kRenderTransColor)
	set_pev(camera,pev_renderamt,0.0)
	set_pev(camera,pev_renderfx,kRenderFxNone)

	engfunc(EngFunc_SetView, id, camera)

	g_view_ent[id] = camera
			
	return 1
}
