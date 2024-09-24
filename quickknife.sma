/* Header Template by Devzone */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <offset>
#include <cstrike_pdatas/pdatas_stocks>

#define PLUGIN_NAME		"快速出刀"
#define PLUGIN_VERSION	"1.0.5"
#define PLUGIN_AUTHOR	"Luna the Reborn"

#define KMDL		"models/v_Quickknife.mdl"
#define TIME_ANIM	0.4286
#define ATTACK_DIST	64.0
#define pev_melee	pev_button
#define KNIFE_SLOT	3

#define STATE_REGULAR	0
#define STATE_MELEEING	1

new g_fwBotForwardRegister = 0;
new g_qstringKMDL = 0;
new bool:g_bWantMelee[33], bool:g_bMeleeing[33];

stock const g_rgszSupportWeapons[][] = 
{
	"weapon_p228", 
	"weapon_scout", 
	"weapon_hegrenade", 
	"weapon_xm1014", 
	"weapon_c4", 
	"weapon_mac10",
	"weapon_aug", 
	"weapon_smokegrenade", 
	"weapon_elite", 
	"weapon_fiveseven", 
	"weapon_ump45", 
	"weapon_sg550",
	"weapon_galil", 
	"weapon_famas", 
	"weapon_usp", 
	"weapon_glock18", 
	"weapon_awp", 
	"weapon_mp5navy", 
	"weapon_m249",
	"weapon_m3", 
	"weapon_m4a1", 
	"weapon_tmp", 
	"weapon_g3sg1", 
	"weapon_flashbang", 
	"weapon_deagle", 
	"weapon_sg552",
	"weapon_ak47", 
	"weapon_p90" 
};

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	register_clcmd("melee", "Command_Melee", _, _, 0);
	
	register_message(get_user_msgid("DeathMsg"), "Message_DeathMSG");
	
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink");
	register_forward(FM_TraceLine, "fw_TraceLine");
	register_forward(FM_TraceHull, "fw_TraceHull");
	
	for (new i = 0; i < sizeof g_rgszSupportWeapons; i++)
	{
		RegisterHam(Ham_Item_Holster, g_rgszSupportWeapons[i], "HamF_Item_Holster_Post", true);
		RegisterHam(Ham_Item_PostFrame, g_rgszSupportWeapons[i], "HamF_Item_PostFrame");
	}
	
	g_fwBotForwardRegister = register_forward(FM_PlayerPostThink, "fw_BotForwardRegister_Post", true);

	RegisterHam(Ham_TraceAttack, "player", "HamF_TraceAttack");
}

public plugin_precache()
{
	precache_model(KMDL);

	g_qstringKMDL = engfunc(EngFunc_AllocString, KMDL);
}

public Command_Melee(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return;
	
	g_bWantMelee[iPlayer] = true;
}

public HamF_TraceAttack(iVictim, iAttacker, Float:flDamage, Float:vecDirection[3], tr, bitsDamageTypes)
{
	if (!is_user_alive(iAttacker) || !is_user_connected(iVictim))
		return HAM_IGNORED;
	
	new szViewModel[128];
	pev(iAttacker, pev_viewmodel2, szViewModel, charsmax(szViewModel));
	
	if (!strcmp(szViewModel, KMDL))
		SetHamParamFloat(3, flDamage * 2.0);
	
	return HAM_IGNORED;
}

public HamF_Item_Holster_Post(iEntity) set_pev(iEntity, pev_melee, STATE_REGULAR);

public HamF_Item_PostFrame(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, m_pPlayer, 4);

	if (g_bWantMelee[iPlayer] && pev(iEntity, pev_melee) == STATE_REGULAR)
	{
		g_bWantMelee[iPlayer] = false;

		set_pdata_int(iPlayer, m_iFOV, 90);
		set_pev(iPlayer, pev_viewmodel, g_qstringKMDL);
		set_pev(iEntity, pev_melee, STATE_MELEEING);

		// The secondary attack will become shield close if you own a shield.
		new bool:bOwnsShield = get_pdata_bool(iPlayer, m_bOwnsShield);
		set_pdata_bool(iPlayer, m_bOwnsShield, false);

		// Warning: DO NOT use ExecuteHamB here.
		g_bMeleeing[iPlayer] = true;
		ExecuteHam(Ham_Weapon_SecondaryAttack, get_pdata_cbase(iPlayer, m_rgpPlayerItems[KNIFE_SLOT], 4))	// CKnife::Stab(TRUE);
		g_bMeleeing[iPlayer] = false;

		set_pdata_bool(iPlayer, m_bOwnsShield, bOwnsShield);
		
		new Float:vecPunch[3];
		vecPunch[1] += random_float(4.5, 6.5)	//屏幕左歪
		vecPunch[2] -= random_float(4.5, 6.5)	//屏幕斜上歪
		set_pev(iPlayer, pev_punchangle, vecPunch);

		// Put both anim and idle time after CKnife::Stab.
		// In which these vars will be reset and override.
		
		UTIL_SendWeaponAnim(iPlayer, 0);

		set_pdata_float(iPlayer, m_flNextAttack, TIME_ANIM);
		set_pdata_float(iEntity, m_flNextPrimaryAttack, TIME_ANIM + 0.1, 4);
		set_pdata_float(iEntity, m_flNextSecondaryAttack, TIME_ANIM + 0.1, 4);
		set_pdata_float(iEntity, m_flTimeWeaponIdle, TIME_ANIM + 0.1, 4);
		
		return HAM_SUPERCEDE;
	}
	
	// Post-melee behaviour.
	if (pev(iEntity, pev_melee) == STATE_MELEEING)
	{
		set_pev(iEntity, pev_melee, STATE_REGULAR);
		ExecuteHamB(Ham_Item_Deploy, iEntity);

		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public Message_DeathMSG(msg_id, msg_dest, msg_ent)
{
	new szViewModel[128];
	pev(get_msg_arg_int(1), pev_viewmodel2, szViewModel, charsmax(szViewModel));
	
	if (!strcmp(szViewModel, KMDL))
		set_msg_arg_string(4, "knife");
	
	return PLUGIN_CONTINUE;
}

public fw_PlayerPostThink(iPlayer)
{
	if (is_user_bot(iPlayer))
		return;

	new iWeapon = get_pdata_cbase(iPlayer, m_pActiveItem);
	if (pev_valid(iWeapon) != 2)
		return;
	
	if (pev(iWeapon, pev_melee) == STATE_REGULAR && g_bWantMelee[iPlayer])
	{
		// Allow CBasePlayer::ItemPostFrame works again.
		// In which the g_bWantMelee[] flag will be removed.

		set_pdata_float(iPlayer, m_flNextAttack, 0.0);
		set_pdata_int(iWeapon, m_fInReload, 0);
		set_pdata_int(iWeapon, m_fInSpecialReload, 0);	// Fixed for shotguns.
	}
}

public fw_TraceLine(Float:vecSrc[3], Float:vecEnd[3], iConditions, iSkippedEntity, tr)
{
	if (!is_user_alive(iSkippedEntity))
		return FMRES_IGNORED;
	
	if (!g_bMeleeing[iSkippedEntity])
		return FMRES_IGNORED;
	
	new szViewModel[128];
	pev(iSkippedEntity, pev_viewmodel2, szViewModel, charsmax(szViewModel));
	
	if (strcmp(szViewModel, KMDL))
		return FMRES_IGNORED;
	
	pev(iSkippedEntity, pev_v_angle, vecEnd);
	angle_vector(vecEnd, ANGLEVECTOR_FORWARD, vecEnd);
	xs_vec_mul_scalar(vecEnd, ATTACK_DIST, vecEnd);
	xs_vec_add(vecSrc, vecEnd, vecEnd);
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, iConditions, iSkippedEntity, tr);
	
	return FMRES_SUPERCEDE;
}

public fw_TraceHull(Float:vecSrc[3], Float:vecEnd[3], iConditions, iHull, iSkippedEntity, tr)
{
	if (!is_user_alive(iSkippedEntity))
		return FMRES_IGNORED;
	
	if (!g_bMeleeing[iSkippedEntity])
		return FMRES_IGNORED;
	
	new szViewModel[128];
	pev(iSkippedEntity, pev_viewmodel2, szViewModel, charsmax(szViewModel));
	
	if (strcmp(szViewModel, KMDL))
		return FMRES_IGNORED;
	
	pev(iSkippedEntity, pev_v_angle, vecEnd);
	angle_vector(vecEnd, ANGLEVECTOR_FORWARD, vecEnd);
	xs_vec_mul_scalar(vecEnd, ATTACK_DIST, vecEnd);
	xs_vec_add(vecSrc, vecEnd, vecEnd);
	engfunc(EngFunc_TraceHull, vecSrc, vecEnd, iConditions, iHull, iSkippedEntity, tr);
	
	return FMRES_SUPERCEDE;
}

stock UTIL_SendWeaponAnim(index, anim)
{
	set_pev(index, pev_weaponanim, anim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, index);
	write_byte(anim);
	write_byte(pev(index, pev_body));
	message_end();
}

stock bool:fm_is_user_same_team(index1, index2)
	return !!(get_pdata_int(index1, m_iTeam) == get_pdata_int(index2, m_iTeam));

public fw_BotForwardRegister_Post(iPlayer)
{
	if (!is_user_bot(iPlayer))
		return;

	unregister_forward(FM_PlayerPostThink, g_fwBotForwardRegister, true);
	
	RegisterHamFromEntity(Ham_TraceAttack, iPlayer, "HamF_TraceAttack");
}
