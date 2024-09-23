/* AMXX编写头版 by Devzone */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <offset>

#include <cstrike_pdatas/pdatas_stocks>
#include "Library/LibWeapons.sma"

#pragma semicolon 1

#define PLUGIN		"CS Weapons"
#define VERSION		"1.0.0"
#define AUTHOR		"xhsu"

#define WEAPON_LIST_TASK_ID	5156438

native Uranus_DropShield(iPlayer);

new g_rgiCurIndex[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_forward(FM_ClientCommand, "fw_ClientCommand");
}

public client_putinserver(iPlayer)
{
	// For some reason, a for loop here doesn't take any effect.
	g_rgiCurIndex[iPlayer] = 0;
	set_task(0.1, "Task_WeaponList", iPlayer + WEAPON_LIST_TASK_ID, _, _, "a", sizeof WEAPON_CLASSNAME);
}

public Task_WeaponList(iPlayer)
{
	iPlayer -= WEAPON_LIST_TASK_ID;

	if (WEAPON_CLASSNAME[g_rgiCurIndex[iPlayer]][0])
	{
		UTIL_WeaponList(iPlayer, g_rgiCurIndex[iPlayer], WEAPON_CLASSNAME[g_rgiCurIndex[iPlayer]]);
	}

	g_rgiCurIndex[iPlayer]++;
}

public fw_ClientCommand(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return FMRES_IGNORED;

	new szCommand[32];
	read_argv(0, szCommand, charsmax(szCommand));

	// Handle weapons

	for (new i = 0; i < sizeof WEAPON_BUY_COMMANDS; ++i)
	{
		if (strcmp(szCommand, WEAPON_BUY_COMMANDS[i]))
			continue;

		new iMoney = get_pdata_int(iPlayer, m_iAccount);

		if (iMoney < WEAPON_CS_COST[i])
		{
			UTIL_TestMsg(iPlayer, print_center, "#Not_Enough_Money");
			UTIL_BlinkAccount(iPlayer, 2);
			return FMRES_SUPERCEDE;
		}

		if (i == CSW_HEGRENADE || i == CSW_FLASHBANG || i == CSW_SMOKEGRENADE)
		{
			new iAmmoId = WEAPON_BPAMMO_INDEX[i];
			new iMaxGrenade = AMMO_MAX_CAPACITY[iAmmoId];
			new iResult = GiveGrenade(iPlayer, i, iMaxGrenade);	// Entity id or grenade amount.

			if (iResult > 0)
			{
				if (iResult < 33)
				{
					UTIL_AmmoPickup(iPlayer, iAmmoId, 1);
					engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				}

				set_pdata_int(iPlayer, m_iAccount, iMoney - WEAPON_CS_COST[i]);
				UTIL_RefreshAccount(iPlayer);
			}

			return FMRES_SUPERCEDE;
		}

		if (HasWeapon(iPlayer, i))
		{
			client_print(iPlayer, print_center, "你已經有一把%s了!", WEAPON_NAME[i]);
			return FMRES_SUPERCEDE;
		}

		DropFirearmIfNecessary(iPlayer);

		new iWeapon = -1;
		if ((iWeapon = GiveItem(iPlayer, WEAPON_CLASSNAME[i])) > 0)
		{
			new szClassName[32];
			pev(iWeapon, pev_classname, szClassName, charsmax(szClassName));

			engclient_cmd(iPlayer, szClassName);

			set_pdata_int(iPlayer, m_iAccount, iMoney - WEAPON_CS_COST[i]);
			UTIL_RefreshAccount(iPlayer);

			if (WEAPON_SLOT[i] == 1 && get_pdata_bool(iPlayer, m_bOwnsShield))
			{
				Uranus_DropShield(iPlayer);
			}
		}

		return FMRES_SUPERCEDE;
	}

	// Handle ammo

	if (!strcmp(szCommand, "buyammo1"))
	{
		if (GiveClipInSlot(iPlayer, 1))
			engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		return FMRES_SUPERCEDE;
	}
	else if (!strcmp(szCommand, "buyammo2"))
	{
		if (GiveClipInSlot(iPlayer, 2))
			engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		return FMRES_SUPERCEDE;
	}
	else if (!strcmp(szCommand, "primammo"))
	{
		BuyAmmoInSlot(iPlayer, 1);
		return FMRES_SUPERCEDE;
	}
	else if (!strcmp(szCommand, "secammo"))
	{
		BuyAmmoInSlot(iPlayer, 2);
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

BuyAmmoInSlot(iPlayer, iSlot)
{
	new iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[iSlot], XO_CBASEPLAYER);

	while (pev_valid(iWeapon) == 2)
	{
		BuyWeaponAmmo(iPlayer, iWeapon);
		iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
	}
}

BuyWeaponAmmo(iPlayer, iWeapon)
{
	new Float:flMoney = float(get_pdata_int(iPlayer, m_iAccount));
	new iId = get_pdata_int(iWeapon, m_iId);
	new iAmmoId = WEAPON_BPAMMO_INDEX[iId];
	new iAmmoMost_Cap = AMMO_MAX_CAPACITY[iAmmoId] - get_pdata_int(iPlayer, m_rgAmmo[iAmmoId]);
	new iAmmoMost_Cost = floatround(flMoney / AMMO_ZR_COST_PER_BULLET[iAmmoId], floatround_tozero);

	if (iAmmoMost_Cap == 0)
		return;

	if (iAmmoMost_Cost == 0)
	{
		UTIL_TestMsg(iPlayer, print_center, "#Not_Enough_Money");
		UTIL_BlinkAccount(iPlayer, 2);
		return;
	}

	new iAmmoToAdd = min(iAmmoMost_Cap, iAmmoMost_Cost);
	GiveAmmo(iPlayer, iAmmoId, iAmmoToAdd);
	engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	set_pdata_int(iPlayer, m_iAccount, floatround(flMoney - float(iAmmoToAdd) * AMMO_ZR_COST_PER_BULLET[iAmmoId]));
	UTIL_RefreshAccount(iPlayer);
}

GiveClipInSlot(iPlayer, iSlot, bool:bFree = false)
{
	new iCost = 0;
	new iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[iSlot], XO_CBASEPLAYER);

	while (pev_valid(iWeapon) == 2)
	{
		iCost += GiveClip(iPlayer, iWeapon, bFree);
		iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
	}

	return iCost;
}

GiveClip(iPlayer, iWeapon, bool:bFree = false)
{
	new iId = get_pdata_int(iWeapon, m_iId);
	new iAmmoId = WEAPON_BPAMMO_INDEX[iId];
	new iClip = min(get_pdata_int(iWeapon, m_iClip), AMMO_MAX_CAPACITY[iAmmoId] - get_pdata_int(iPlayer, m_rgAmmo[iAmmoId]));
	new iCost = floatround(AMMO_ZR_COST_PER_BULLET[iAmmoId] * float(iClip));

	if (iClip <= 0)
		return 0;

	if (!bFree)
	{
		new iMoney = get_pdata_int(iPlayer, m_iAccount);
		if (iMoney < iCost)
		{
			UTIL_TestMsg(iPlayer, print_center, "#Not_Enough_Money");
			UTIL_BlinkAccount(iPlayer, 2);
			return 0;
		}

		set_pdata_int(iPlayer, m_iAccount, iMoney - iCost);
		UTIL_RefreshAccount(iPlayer);
	}

	GiveAmmo(iPlayer, iAmmoId, iClip);
	return iCost;
}

stock UTIL_RefreshAccount(iPlayer)
{
	static gmsgMoney;
	if (!gmsgMoney)
		gmsgMoney = get_user_msgid("Money");

	emessage_begin(MSG_ONE, gmsgMoney, _, iPlayer);
	ewrite_long(get_pdata_int(iPlayer, m_iAccount));
	ewrite_byte(true);
	emessage_end();
}

stock UTIL_BlinkAccount(iPlayer, iBlinkTimes)
{
	static gmsgBlinkAcct;
	if (!gmsgBlinkAcct)
		gmsgBlinkAcct = get_user_msgid("BlinkAcct");

	emessage_begin(MSG_ONE, gmsgBlinkAcct, _, iPlayer);
	ewrite_byte(iBlinkTimes);
	emessage_end();
}

stock UTIL_TestMsg(iPlayer, dest, const szMessage[])
{
	static gmsgTextMsg;
	if (!gmsgTextMsg)
		gmsgTextMsg = get_user_msgid("TextMsg");

	emessage_begin(MSG_ONE, gmsgTextMsg, _, iPlayer);
	ewrite_byte(dest);
	ewrite_string(szMessage);
	emessage_end();
}
