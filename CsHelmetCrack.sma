/* AMXX编写头版 by Devzone */

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#include <offset>

#define PLUGIN		"Helmet Crack"
#define VERSION		"1.0"
#define AUTHOR		"xhsu"


new gmsgArmorType;
new g_hBotRegister;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	gmsgArmorType = get_user_msgid("ArmorType");

	g_hBotRegister = register_forward(FM_PlayerPostThink, "BotRegister", true);

	RegisterHam(Ham_TraceAttack, "player", "HamF_TraceAttack_Post", true);
}

public plugin_precache()
{
	precache_sound("debris/r_metal3.wav");
	precache_sound("debris/r_metal4.wav");
}

public HamF_TraceAttack_Post(iVictim, iAttacker, Float:flDamage, Float:vecDir[3], tr, bitsDamageTypes)
{
	if (flDamage < 33.0)
		return;

	new Float:flArmor;
	pev(iVictim, pev_armorvalue, flArmor);
	new iArmorType = get_pdata_int(iVictim, m_iKevlar);
	if (flArmor < 1.0 || iArmorType != 2)
		return;

	new iLastHitGroup = get_pdata_int(iVictim, m_LastHitGroup);
	if (iLastHitGroup != HIT_HEAD)
		return;

	set_pdata_int(iVictim, m_iKevlar, 1);

	emessage_begin(MSG_ONE, gmsgArmorType, _, iVictim);
	ewrite_byte(0);
	emessage_end();

	if (random_num(0, 1))
		emit_sound(iVictim, CHAN_ITEM, "debris/r_metal3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	else
		emit_sound(iVictim, CHAN_ITEM, "debris/r_metal4.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

public BotRegister(iPlayer)
{
	if (!is_user_bot(iPlayer))
		return;

	unregister_forward(FM_PlayerPostThink, g_hBotRegister, true);

	RegisterHamFromEntity(Ham_TraceAttack, iPlayer, "HamF_TraceAttack_Post", true);
}
