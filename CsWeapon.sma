/* AMXX编写头版 by Devzone */

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <offset>

#include <Uranus>
#include <cstrike_pdatas/pdatas_stocks>
#include "Library/LibWeapons.sma"

#pragma semicolon 1

#define PLUGIN		"CS Weapons"
#define VERSION		"1.2.0"
#define AUTHOR		"xhsu"

#define WEAPON_LIST_TASK_ID	5156438


new g_rgiCurIndex[33];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_forward(FM_ClientCommand, "fw_ClientCommand");

	register_clcmd("lastinv", "Command_LastInv");
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

		if (!Uranus_CanPlayerBuy(iPlayer))
			return FMRES_SUPERCEDE;

		new iMoney = get_pdata_int(iPlayer, m_iAccount);

		if (iMoney < WEAPON_CS_COST[i])
		{
			UTIL_TextMsg(iPlayer, print_center, "#Not_Enough_Money");
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
			UTIL_TextMsg(iPlayer, print_center, "#Cstrike_Already_Own_Weapon");
			return FMRES_SUPERCEDE;
		}

		// #BUGBUG somehow bugged, if player trys to buy a prim weapon when he has two pistols and a shield.
		DropFirearmIfNecessary(iPlayer);

		new iWeapon = -1;
		if ((iWeapon = GiveItem(iPlayer, WEAPON_CLASSNAME[i])) > 0)
		{
			new szClassName[32];
			pev(iWeapon, pev_classname, szClassName, charsmax(szClassName));

			engclient_cmd(iPlayer, szClassName);

			set_pdata_int(iPlayer, m_iAccount, iMoney - WEAPON_CS_COST[i]);
			UTIL_RefreshAccount(iPlayer);

			if ((WEAPON_SLOT[i] == 1 || i == CSW_ELITE) && get_pdata_bool(iPlayer, m_bOwnsShield))
			{
				Uranus_DropShield(iPlayer);
			}
		}

		return FMRES_SUPERCEDE;
	}

	// Handle ammo

	if (!strcmp(szCommand, "buyammo1"))
	{
		if (!Uranus_CanPlayerBuy(iPlayer))
			return FMRES_SUPERCEDE;

		new iSlot = get_pdata_bool(iPlayer, m_bOwnsShield) ? 2 : 1;

		if (GiveClipInSlot(iPlayer, iSlot))
			engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		return FMRES_SUPERCEDE;
	}
	else if (!strcmp(szCommand, "buyammo2"))
	{
		if (!Uranus_CanPlayerBuy(iPlayer))
			return FMRES_SUPERCEDE;

		if (GiveClipInSlot(iPlayer, 2))
			engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		return FMRES_SUPERCEDE;
	}
	else if (!strcmp(szCommand, "primammo"))
	{
		if (!Uranus_CanPlayerBuy(iPlayer))
			return FMRES_SUPERCEDE;

		new iSlot = get_pdata_bool(iPlayer, m_bOwnsShield) ? 2 : 1;

		BuyAmmoInSlot(iPlayer, iSlot);
		return FMRES_SUPERCEDE;
	}
	else if (!strcmp(szCommand, "secammo"))
	{
		if (!Uranus_CanPlayerBuy(iPlayer))
			return FMRES_SUPERCEDE;

		BuyAmmoInSlot(iPlayer, 2);
		return FMRES_SUPERCEDE;
	}

	// Handle shield

	else if (!strcmp(szCommand, "shield"))
	{
		if (!Uranus_CanPlayerBuy(iPlayer))
			return FMRES_SUPERCEDE;

		if (get_pdata_bool(iPlayer, m_bOwnsShield))
		{
			UTIL_TextMsg(iPlayer, print_center, "#Cstrike_Already_Own_Weapon");
			return FMRES_SUPERCEDE;
		}

		new iMoney = get_pdata_int(iPlayer, m_iAccount);

		if (iMoney < 2200)
		{
			UTIL_TextMsg(iPlayer, print_center, "#Not_Enough_Money");
			UTIL_BlinkAccount(iPlayer, 2);
			return FMRES_SUPERCEDE;
		}

		DropWeapons(iPlayer, 1);
		engclient_cmd(iPlayer, "drop", WEAPON_CLASSNAME[CSW_ELITE]);

		emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		GiveUserShield(iPlayer);

		set_pdata_int(iPlayer, m_iAccount, iMoney - 2200);
		UTIL_RefreshAccount(iPlayer);
	}

	return FMRES_IGNORED;
}

public Command_LastInv(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return PLUGIN_CONTINUE;

	new iCurWeapon = get_pdata_cbase(iPlayer, m_pActiveItem);
	new iSwitchTo = -1;

	for (new i = 1; i <= 3; ++i)
	{
		iSwitchTo = get_pdata_cbase(iPlayer, m_rgpPlayerItems[i]);
		while (pev_valid(iSwitchTo) == 2 && iSwitchTo == iCurWeapon)
		{
			iSwitchTo = get_pdata_cbase(iSwitchTo, m_pNext, XO_CBASEPLAYERITEM);
		}

		if (pev_valid(iSwitchTo) == 2 && iSwitchTo != iCurWeapon)
			break;
	}

	if (pev_valid(iSwitchTo) != 2 || iSwitchTo == iCurWeapon)
		return PLUGIN_CONTINUE;

	new szWeaponClass[32];
	pev(iSwitchTo, pev_classname, szWeaponClass, charsmax(szWeaponClass));

	engclient_cmd(iPlayer, szWeaponClass);

	return PLUGIN_HANDLED;
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
	new iAmmoMost_Cap = GetMaxAmmoStockpileWithBuffer(iPlayer, iAmmoId) - get_pdata_int(iPlayer, m_rgAmmo[iAmmoId]);
	new iAmmoMost_Cost = floatround(flMoney / AMMO_ZR_COST_PER_BULLET[iAmmoId], floatround_tozero);

	if (iAmmoMost_Cap == 0)
		return;

	if (iAmmoMost_Cost == 0)
	{
		UTIL_TextMsg(iPlayer, print_center, "#Not_Enough_Money");
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
	new iClip = min(WEAPON_MAXCLIP[iId], GetMaxAmmoStockpileWithBuffer(iPlayer, iAmmoId) - get_pdata_int(iPlayer, m_rgAmmo[iAmmoId]));
	new iCost = floatround(AMMO_ZR_COST_PER_BULLET[iAmmoId] * float(iClip));

	if (iClip <= 0)
		return 0;

	if (!bFree)
	{
		new iMoney = get_pdata_int(iPlayer, m_iAccount);
		if (iMoney < iCost)
		{
			UTIL_TextMsg(iPlayer, print_center, "#Not_Enough_Money");
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

stock UTIL_TextMsg(iPlayer, dest, const szMessage[])
{
	static gmsgTextMsg;
	if (!gmsgTextMsg)
		gmsgTextMsg = get_user_msgid("TextMsg");

	emessage_begin(MSG_ONE, gmsgTextMsg, _, iPlayer);
	ewrite_byte(dest);
	ewrite_string(szMessage);
	emessage_end();
}
