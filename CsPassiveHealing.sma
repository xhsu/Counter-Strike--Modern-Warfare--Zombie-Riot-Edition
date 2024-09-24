/* AMXX编写头版 by Devzone */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <offset>

#include "Library/LibMath.inc"
#include "Library/LibScreenFx.inc"
#include <cstrike_pdatas/pdatas_stocks>

#pragma semicolon 1

#define PLUGIN		"Passive Healing"
#define VERSION		"1.1.2"
#define AUTHOR		"xhsu"

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

	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink_Post", true);
	g_hBotRegister = register_forward(FM_PlayerPostThink, "BotRegister", true);

	RegisterHam(Ham_Spawn, "player", "HamF_Spawn_Post", true);
	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage_Post", true);
}

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
		{
			flCurHealth = flMaxHealth;
			UTIL_ScreenFade(iPlayer, 0.3, 0.0, FFADE_IN, 0x98, 0xF5, 0x4B, 32);
		}

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
	new bool:bIsDamaged;
	GetHamReturnInteger(bIsDamaged);
	if (!bIsDamaged)
		return;

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
