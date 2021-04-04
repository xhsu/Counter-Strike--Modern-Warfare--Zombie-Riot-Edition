/* AMXX Template by Devzone */
/*

Created Date: Apr 04 2021

Modern Warfare Dev Team
 - Luna the Reborn

*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <offset>
#include <orpheu>
#include <zombieriot>

#include <cstrike_pdatas/pdatas_stocks>
#include "Library/LibMath.inc"
#include "Library/LibWeapons.sma"

#define PLUGIN	"Zr Weapon"
#define VERSION	"2.0 CSMW:ZR"
#define AUTHOR	"Luna the Reborn"

stock const BOMBER_ID = 4;			//爆破者的ID

new g_rgiWeaponIndices[sizeof WEAPON_CLASSNAME], g_rgiEquipmentIndices[EZRSpecialEquipments];
new Float:g_rgflBotThink[33];
new cvar_despawningtime, cvar_armorperbuy, cvar_bombergrcap;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_forward(FM_SetModel, "fw_SetModel_Post", true);
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink_Post", true);

	new szText[64];

	for (new i = 0; i < EZRSpecialEquipments; i ++)
	{
		formatex(szText, charsmax(szText), "%s	\y%d", ZR_EQUIPMENT_NAME[i], ZR_EQUIPMENT_COST[i]);
		g_rgiEquipmentIndices[i] = zr_register_item(szText, HUMAN, 3);	// Always placed at slot 3.
	}

	for (new i = 0; i < sizeof WEAPON_CLASSNAME; i++)
	{
		if (WEAPON_ZR_BUYSLOT[i] <= 0 || WEAPON_ZR_COST[i] <= 0)
			continue;

		formatex(szText, charsmax(szText), "%s	\y%d", WEAPON_NAME[i], WEAPON_ZR_COST[i]);
		g_rgiWeaponIndices[i] = zr_register_item(szText, HUMAN, WEAPON_ZR_BUYSLOT[i]);
	}

	cvar_despawningtime = register_cvar("zr_weaponbox_despawn_time", "120.0")	// How long should it stays before removed?
	cvar_armorperbuy = register_cvar("zr_armorgain_per_buy", "100");
	cvar_bombergrcap = register_cvar("zr_bomber_grenade_capacity", "3");
}

public plugin_precache()
{
	precache_sound("items/ammopickup2.wav");
	precache_sound("items/kevlar.wav");
	precache_sound("items/gunpickup1.wav");
}

public fw_SetModel_Post(iEntity, const szModel[])
{
	if (strlen(szModel) < 8)
		return;

	if (szModel[7] != 'w' || szModel[8] != '_')
		return;

	static szClassName[32];
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	if (strcmp(szClassName, "weaponbox"))
		return;

	set_pev(iEntity, pev_nextthink, get_gametime() + get_pcvar_float(cvar_despawningtime));
}

public fw_PlayerPostThink_Post(iPlayer)
{
	if (pev(iPlayer, pev_deadflag) != DEAD_NO)
		return;
	
	if (!is_user_bot(iPlayer))
		return;
	
	if (zr_is_user_zombie(iPlayer))
		return;
	
	static Float:fCurTime;
	global_get(glb_time, fCurTime);
	
	if (g_rgflBotThink[iPlayer] > fCurTime)
		return;

	new iMoney = zr_get_user_money(iPlayer);
	new rgiAffordable[sizeof WEAPON_CLASSNAME], iCount = 0;
	
	if (pev_valid(get_pdata_cbase(iPlayer, m_rgpPlayerItems[1])) != 2)
	{
		BuildAffordableWeaponList(iMoney, 1, rgiAffordable, iCount);

		if (iCount)
			zr_set_user_item(iPlayer, rgiAffordable[random_num(1, iCount)]);
	}
	
	if (pev_valid(get_pdata_cbase(iPlayer, m_rgpPlayerItems[2])) != 2)
	{
		BuildAffordableWeaponList(iMoney, 2, rgiAffordable, iCount);

		if (iCount)
			zr_set_user_item(iPlayer, rgiAffordable[random_num(1, iCount)]);
	}
	
	zr_set_user_item(iPlayer, g_rgiEquipmentIndices[BUY_ZR_EQP_ALL_BPAMMO]);

	new Float:flArmor;
	pev(iPlayer, pev_armorvalue, flArmor)
	if (flArmor <= 0.0)
		zr_set_user_item(iPlayer, g_rgiEquipmentIndices[BUY_ZR_EQP_ARMOUR]);
	
	g_rgflBotThink[iPlayer] = fCurTime + random_float(4.0, 6.0);
}

public zr_being_human(iPlayer)
{
	if (!is_user_bot(iPlayer))
		return;
	
	g_rgflBotThink[iPlayer] = get_gametime() + random_float(10.0, 15.0);
	
	new iMoney = zr_get_user_money(iPlayer);
	new rgiAffordable[sizeof WEAPON_CLASSNAME], iCount = 0;

	BuildAffordableWeaponList(iMoney, 1, rgiAffordable, iCount);

	if (iCount)
		zr_set_user_item(iPlayer, rgiAffordable[random_num(1, iCount)]);
	
	BuildAffordableWeaponList(iMoney, 2, rgiAffordable, iCount);

	if (iCount)
		zr_set_user_item(iPlayer, rgiAffordable[random_num(1, iCount)]);

	zr_set_user_item(iPlayer, g_rgiEquipmentIndices[BUY_ZR_EQP_ALL_BPAMMO]);
	zr_set_user_item(iPlayer, g_rgiEquipmentIndices[BUY_ZR_EQP_ARMOUR]);
	zr_set_user_item(iPlayer, g_rgiWeaponIndices[CSW_HEGRENADE]);

	zr_set_user_money(iPlayer, iMoney, false);	// Just.. for free... this time only.
}

public zr_item_event(iPlayer, iItemIndex, iSlot)
{
	new iMoney = zr_get_user_money(iPlayer);

	for (new i = 0; i < sizeof g_rgiWeaponIndices; i++)
	{
		if (iItemIndex != g_rgiWeaponIndices[i])
			continue;
		
		if (iMoney < WEAPON_ZR_COST[i])
		{
			client_print(iPlayer, print_center, "金錢不足!");
			return;
		}

		if (i == CSW_HEGRENADE || i == CSW_FLASHBANG || i == CSW_SMOKEGRENADE)
		{
			new iAmmoId = WEAPON_BPAMMO_INDEX[i];
			new iCurGrenade = get_pdata_int(iPlayer, m_rgAmmo[iAmmoId]);
			new iMaxGrenade = AMMO_MAX_CAPACITY[iAmmoId];

			if (zr_get_human_id(iPlayer) == BOMBER_ID)	// Increased capacity.
				iMaxGrenade = get_pcvar_num(cvar_bombergrcap);

			if (pev(iPlayer, pev_weapons) & (1<<i))	// Special treatment for these three.
			{
				if (iCurGrenade >= iMaxGrenade)
				{
					client_print(iPlayer, print_center, "%s已補滿(上限為%d個), 無法繼續購買!", WEAPON_NAME[i], iMaxGrenade);
					return;
				}

				set_pdata_int(iPlayer, m_rgAmmo[iAmmoId], ++iCurGrenade);

				UTIL_AmmoPickup(iPlayer, m_rgAmmo[iAmmoId], 1);
				zr_print_chat(iPlayer, GREENCHAT, "%s庫存: %d/%d", WEAPON_NAME[i], iCurGrenade, iMaxGrenade);
				engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/gunpickup1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

				zr_set_user_money(iPlayer, iMoney - WEAPON_ZR_COST[i], true);
				return;
			}
			else if (iCurGrenade > 0)	// You have inventory, but have no access to the item. Hmmm..
				set_pdata_int(iPlayer, m_rgAmmo[iAmmoId], 0);
			
			if (GiveItem(iPlayer, WEAPON_CLASSNAME[i]) > 0)
			{
				zr_print_chat(iPlayer, GREENCHAT, "%s庫存: %d/%d", WEAPON_NAME[i], 1, iMaxGrenade);
				zr_set_user_money(iPlayer, iMoney - WEAPON_ZR_COST[i], true);
			}

			return;
		}

		DropFirearmIfNecessary(iPlayer);

		if (GiveItem(iPlayer, WEAPON_CLASSNAME[i]) > 0)
		{
			zr_print_chat(iPlayer, GREENCHAT, "你購買了%s!", WEAPON_NAME[i]);

			zr_set_user_money(iPlayer, iMoney - WEAPON_ZR_COST[i], true);
			GiveAmmo(iPlayer, WEAPON_BPAMMO_INDEX[i], AMMO_MAX_CAPACITY[WEAPON_BPAMMO_INDEX[i]]);
		}
		
		return;
	}

	if (iItemIndex == g_rgiEquipmentIndices[BUY_ZR_EQP_ALL_BPAMMO])
	{
		if (iMoney < ZR_EQUIPMENT_COST[BUY_ZR_EQP_ALL_BPAMMO])
		{
			client_print(iPlayer, print_center, "金錢不足!");
			return;
		}

		ReplenishAmmunition(iPlayer);
		zr_set_user_money(iPlayer, iMoney - ZR_EQUIPMENT_COST[BUY_ZR_EQP_ALL_BPAMMO], true);

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		return;
	}

	else if (iItemIndex == g_rgiEquipmentIndices[BUY_ZR_EQP_CUR_BPAMMO])
	{
		if (iMoney < ZR_EQUIPMENT_COST[BUY_ZR_EQP_CUR_BPAMMO])
		{
			client_print(iPlayer, print_center, "金錢不足!");
			return;
		}

		new iWeapon = get_pdata_cbase(iPlayer, m_pActiveItem);
		if (get_pdata_int(iWeapon, m_iPrimaryAmmoType, XO_CBASEPLAYERWEAPON) <= 0 || get_pdata_int(iWeapon, m_iClip, XO_CBASEPLAYERWEAPON) <= 0)
		{
			client_print(iPlayer, print_center, "當前武器不適用彈藥補充!");
			return;
		}

		ReplenishAmmunition(iPlayer, iWeapon);
		zr_set_user_money(iPlayer, iMoney - ZR_EQUIPMENT_COST[BUY_ZR_EQP_CUR_BPAMMO], true);

		engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		return;
	}

	else if (iItemIndex == g_rgiEquipmentIndices[BUY_ZR_EQP_ARMOUR])
	{
		if (iMoney < ZR_EQUIPMENT_COST[BUY_ZR_EQP_ARMOUR])
		{
			client_print(iPlayer, print_center, "金錢不足!");
			return;
		}

		new Float:flArmor, Float:flMaxArmor = zr_get_human_health(zr_get_human_id(iPlayer));
		pev(iPlayer, pev_armorvalue, flArmor);

		if (flArmor >= flMaxArmor)
		{
			zr_print_chat(iPlayer, REDCHAT, "%s已滿。", ZR_EQUIPMENT_NAME[BUY_ZR_EQP_ARMOUR]);
			return;
		}

		new Float:flArmorAdd = get_pcvar_float(cvar_armorperbuy);
		set_pev(iPlayer, pev_armorvalue, floatmin(flMaxArmor, flArmor + flArmorAdd));
		set_pdata_int(iPlayer, m_iKevlar, ARMOR_VESTHELM);

		zr_print_chat(iPlayer, REDCHAT, "%d點%s已獲得。", floatround(flArmorAdd), ZR_EQUIPMENT_NAME[BUY_ZR_EQP_ARMOUR]);
		zr_set_user_money(iPlayer, iMoney - ZR_EQUIPMENT_COST[BUY_ZR_EQP_ARMOUR], true);
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/ammopickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		return;
	}

	else if (iItemIndex == g_rgiEquipmentIndices[BUY_ZR_EQP_NVG])
	{
		if (iMoney < ZR_EQUIPMENT_COST[BUY_ZR_EQP_NVG])
		{
			client_print(iPlayer, print_center, "金錢不足!");
			return;
		}
		
		if (get_pdata_bool(iPlayer, m_bHasNightVision))
		{
			zr_print_chat(iPlayer, REDCHAT, "你已經持有%s了。", ZR_EQUIPMENT_NAME[BUY_ZR_EQP_NVG]);
			return;
		}

		set_pdata_bool(iPlayer, m_bHasNightVision, true);

		zr_print_chat(iPlayer, REDCHAT, "你購買了一個%s!", ZR_EQUIPMENT_NAME[BUY_ZR_EQP_NVG]);
		zr_set_user_money(iPlayer, iMoney - ZR_EQUIPMENT_COST[BUY_ZR_EQP_NVG], true);
		engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "items/kevlar.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		return;
	}
}

BuildAffordableWeaponList(iMoney, iSlot, rgIndices[], &iCount)
{
	iCount = 0;

	for (new i = 0; i < sizeof WEAPON_ZR_COST; i++)
	{
		if (iMoney < WEAPON_ZR_COST[i])
			continue;
			
		if (iSlot > 0 && WEAPON_SLOT[i] != (iSlot - 1))	// Start from 0.
			continue;
			
		iCount++;
		rgIndices[iCount] = g_rgiWeaponIndices[i];
	}
}
