/* AMXX编写头版 by Devzone */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <offset>

#include "Library/LibMath"
#include <cstrike_pdatas/pdatas_stocks>

#pragma semicolon 1

#define PLUGIN		"Passive Healing"
#define VERSION		"1.1.1"
#define AUTHOR		"xhsu"

new gmsgFade;
#define FFADE_IN			0x0000		// Just here so we don't pass 0 into the function
#define FFADE_OUT			0x0001		// Fade out (not in)
#define FFADE_MODULATE		0x0002		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0004		// ignores the duration, stays faded out until new ScreenFade message received

// Spectator Movement modes (stored in pev->iuser1, so the physics code can get at them)
#define OBS_NONE				0
#define OBS_CHASE_LOCKED		1
#define OBS_CHASE_FREE			2
#define OBS_ROAMING				3		
#define OBS_IN_EYE				4
#define OBS_MAP_FREE			5
#define OBS_MAP_CHASE			6

new g_hBotRegister;
new Float:g_flNextHealing[33];
new bool:g_flShouldDoFx[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	gmsgFade = get_user_msgid("ScreenFade");

	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink_Post", true);
	g_hBotRegister = register_forward(FM_PlayerPostThink, "BotRegister", true);

	RegisterHam(Ham_Spawn, "player", "HamF_Spawn_Post", true);
	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage_Post", true);

	// register_concmd("test_fade", "cmd_test");
	// register_concmd("test_sethp", "cmd_sethp");	// test_fade 0.5 0 0 5 152 205 96
	// register_concmd("test_obs", "cmd_obs");
}
/*
public cmd_test(iPlayer)
{
	new szDur[8], szHold[8], szFlags[8], szR[4], szG[4], szB[4], szA[4];
	read_argv(1, szDur, charsmax(szDur));
	read_argv(2, szHold, charsmax(szHold));
	read_argv(3, szFlags, charsmax(szFlags));
	read_argv(4, szR, charsmax(szR));
	read_argv(5, szG, charsmax(szG));
	read_argv(6, szB, charsmax(szB));
	read_argv(7, szA, charsmax(szA));

	new colors[3];
	colors[0] = str_to_num(szR);
	colors[1] = str_to_num(szG);
	colors[2] = str_to_num(szB);

	UTIL_ScreenFade(
		iPlayer,
		str_to_float(szDur),
		str_to_float(szHold),
		str_to_num(szFlags),
		str_to_num(szR),
		str_to_num(szG),
		str_to_num(szB),
		str_to_num(szA)
	);
}

public cmd_sethp(iPlayer)
{
	new szHealth[8];
	read_argv(1, szHealth, charsmax(szHealth));

	set_pev(iPlayer, pev_health, str_to_float(szHealth));

	g_flNextHealing[iPlayer] = get_gametime() + 5.0;
	g_flShouldDoFx[iPlayer] = true;
}

public cmd_obs(iPlayer)
{
	new iMode = pev(iPlayer, pev_iuser1);

	if (iMode != OBS_NONE)
	{
		new szName[32], Float:flHealth;
		new iObs = get_pdata_ehandle(iPlayer, m_hObserverTarget);

		pev(iObs, pev_netname, szName, charsmax(szName));
		pev(iObs, pev_health, flHealth);
		client_print(iPlayer, print_chat, "Mode: %d, on %s (%d)", pev(iPlayer, pev_iuser1), szName, floatround(flHealth));
	}
	else
	{
		client_print(iPlayer, print_chat, "Mode: OBS_NONE");
	}
}
*/
public fw_PlayerPostThink_Post(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return;

	if (g_flNextHealing[iPlayer] > get_gametime())
		return;
	
	g_flNextHealing[iPlayer] = get_gametime() + 0.5;

	static Float:flMaxHealth;
	pev(iPlayer, pev_max_health, flMaxHealth);

	static Float:flCurHealth;
	pev(iPlayer, pev_health, flCurHealth);

	if (flCurHealth < flMaxHealth)
	{
		flCurHealth += flMaxHealth * 0.05;

		if (flCurHealth > flMaxHealth)
			flCurHealth = flMaxHealth;

		set_pev(iPlayer, pev_health, flCurHealth);
	}

	if (g_flShouldDoFx[iPlayer])
	{
		g_flShouldDoFx[iPlayer] = false;

		client_cmd(iPlayer, "spk %s", "items/medshot4.wav");

		// This is just a VFX, dont cheese it against flashbang.
		if (!PlayerUtl_IsBlind(iPlayer))
		{
			UTIL_ScreenFade(iPlayer, 0.5, 0.0, FFADE_IN, 5, 152, 205, 64);

			// Sync the effect to whoever watching this character.
			new iObsMode = 0;
			for (new i = 1; i <= global_get(glb_maxClients); ++i)
			{
				iObsMode = pev(i, pev_iuser1);
				if (iObsMode != OBS_CHASE_LOCKED && iObsMode != OBS_CHASE_FREE && iObsMode != OBS_IN_EYE)
					continue;

				if (get_pdata_ehandle(i, m_hObserverTarget) == iPlayer)
				{
					UTIL_ScreenFade(i, 0.5, 0.0, FFADE_IN, 5, 152, 205, 64);
					client_cmd(i, "spk %s", "items/medshot4.wav");
				}
			}
		}
	}
}

public HamF_Spawn_Post(iPlayer)
{
	g_flShouldDoFx[iPlayer] = false;
}

public HamF_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageTypes)
{
	g_flNextHealing[iVictim] = get_gametime() + 5.0;
	g_flShouldDoFx[iVictim] = true;
}

public BotRegister(iPlayer)
{
	if (!is_user_bot(iPlayer))
		return;

	unregister_forward(FM_PlayerPostThink, g_hBotRegister, true);

	RegisterHamFromEntity(Ham_Spawn, iPlayer, "HamF_Spawn_Post", true);
	RegisterHamFromEntity(Ham_TakeDamage, iPlayer, "HamF_TakeDamage_Post", true);
}

stock UTIL_ScreenFade(iPlayer, Float:flFxTime, Float:flColorHold, bitsFlags, r, g, b, alpha)
{
	emessage_begin(MSG_ONE_UNRELIABLE, gmsgFade, _, iPlayer);
	ewrite_short(FixedUnsigned16(flFxTime, 1 << 12));
	ewrite_short(FixedUnsigned16(flColorHold, 1 << 12));
	ewrite_short(bitsFlags);
	ewrite_byte(r);
	ewrite_byte(g);
	ewrite_byte(b);
	ewrite_byte(alpha);
	emessage_end();
}

stock bool:PlayerUtl_IsBlind(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return false;

	new Float:flEndTime = get_pdata_float(iPlayer, m_blindFadeTime) + get_pdata_float(iPlayer, m_blindHoldTime) + get_pdata_float(iPlayer, m_blindStartTime);

	return flEndTime > get_gametime();
}
