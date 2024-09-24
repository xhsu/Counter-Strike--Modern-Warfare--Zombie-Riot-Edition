/* AMXX编写头版 by Devzone */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#include "Library/LibMath.inc"
#include "Library/LibScreenFx.inc"

#pragma semicolon 1

#define PLUGIN		"No Sudden Death"
#define VERSION		"1.0"
#define AUTHOR		"xhsu"

#define TASK_INVINCIBLE 6849387

#define INVINCIBLE_TIME 1.5
#define INVINCIBLE_SFX	"leadermode/attack_out_of_range_01.wav"

new Float:g_rgflLastFullHealth[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHam(Ham_TakeDamage, "player", "HamF_TakeDamage");
}

public HamF_TakeDamage(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageTypes)
{
	new Float:flHealth, Float:flMaxHealth;
	pev(iVictim, pev_health, flHealth);
	pev(iVictim, pev_max_health, flMaxHealth);

	if (floatround(flHealth) == floatround(flMaxHealth))
		g_rgflLastFullHealth[iVictim] = get_gametime();

	if (get_gametime() - g_rgflLastFullHealth[iVictim] > INVINCIBLE_TIME)
		return HAM_IGNORED;

	if (task_exists(iVictim + TASK_INVINCIBLE))
		return HAM_IGNORED;

	if (flDamage > (flHealth - 1.0))
	{
		set_pev(iVictim, pev_takedamage, DAMAGE_NO);
		set_task(INVINCIBLE_TIME, "Task_RemoveInvincible", iVictim + TASK_INVINCIBLE);

		UTIL_ScreenFade(iVictim, 0.5, INVINCIBLE_TIME - 0.5, FFADE_IN, 0x9D, 0x02, 0x08, 64);
		// emit_sound(iVictim, CHAN_AUTO, INVINCIBLE_SFX, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		client_cmd(iVictim, "spk %s", INVINCIBLE_SFX);

		SetHamParamFloat(4, flHealth - 1.0);
	}

	return HAM_HANDLED;
}

public Task_RemoveInvincible(iPlayer)
{
	iPlayer -= TASK_INVINCIBLE;

	if (is_user_alive(iPlayer))
		set_pev(iPlayer, pev_takedamage, DAMAGE_AIM);
}
