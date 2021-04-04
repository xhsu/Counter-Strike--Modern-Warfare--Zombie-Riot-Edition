/*

Created Date: Apr 02 2021

Modern Warfare Dev Team
 - Luna the Reborn

*/

stock OrpheuFunction:g_pfn_CBP_DropShield;
stock OrpheuFunction:g_pfn_CBP_SelectItem;
stock OrpheuFunction:g_pfn_CBP_SetAnimation;
stock OrpheuFunction:g_pfn_CBPW_ReloadSound;
stock OrpheuFunction:g_pfn_CBPW_KickBack;

enum PLAYER_ANIM
{
	PLAYER_IDLE,
	PLAYER_WALK,
	PLAYER_JUMP,
	PLAYER_SUPERJUMP,
	PLAYER_DIE,
	PLAYER_ATTACK1,
	PLAYER_ATTACK2,
	PLAYER_FLINCH,
	PLAYER_LARGE_FLINCH,
	PLAYER_RELOAD,
	PLAYER_HOLDBOMB
};

/**--------------請勿更改：整理自weapons.h*/
enum _:ARMOURY_TYPES
{
	ARMOURY_MP5NAVY = 0,
	ARMOURY_TMP,
	ARMOURY_P90,
	ARMOURY_MAC10,
	ARMOURY_AK47,
	ARMOURY_SG552,
	ARMOURY_M4A1,
	ARMOURY_AUG,
	ARMOURY_SCOUT,
	ARMOURY_G3SG1,
	ARMOURY_AWP,
	ARMOURY_M3,
	ARMOURY_XM1014,
	ARMOURY_M249,
	ARMOURY_FLASHBANG,
	ARMOURY_HEGRENADE,
	ARMOURY_KEVLAR,
	ARMOURY_ASSAULT,
	ARMOURY_SMOKEGRENADE,

	// Added by ReGameDLL-CS
	ARMOURY_SHIELD,
	ARMOURY_FAMAS,
	ARMOURY_SG550,
	ARMOURY_GALIL,
	ARMOURY_UMP45,
	ARMOURY_GLOCK18,
	ARMOURY_USP,
	ARMOURY_ELITE,
	ARMOURY_FIVESEVEN,
	ARMOURY_P228,
	ARMOURY_DEAGLE,
};

stock const ARMOURY_AMMOTYPE[][] = { "9mm", "9mm", "57mm", "45acp", "762Nato", "556Nato", "556Nato", "556Nato", "762Nato", "762Nato", "338Magnum", "buckshot", "buckshot", "556NatoBox" };
stock const ARMOURY_AMMOAMOUNT[] = { 60, 60, 100, 60, 60, 60, 60, 60, 20, 40, 20, 24, 21, 100 };
stock const ARMOURY_AMMOMAX[] = { 120, 120, 100, 100, 90, 90, 90, 90, 90, 90, 30, 32, 32, 200 };

enum _:AMMO_LIST
{
	AMMO_NOT_USED = 0,
	AMMO_338Magnum,
	AMMO_762Nato,
	AMMO_556NatoBox,
	AMMO_556Nato,
	AMMO_buckshot = 5,
	AMMO_45ACP,
	AMMO_57mm,
	AMMO_50AE,
	AMMO_357SIG,
	AMMO_9mm = 10,
	AMMO_Flashbang,
	AMMO_HEGrenade,
	AMMO_SmokeGrenade,
	AMMO_C4,
};

stock const AMMO_MAX_CAPACITY[] = { -1, 30, 90, 200, 90, 32, 100, 100, 35, 52, 120, 2, 1, 1, 1 };
stock const AMMO_TYPE[][] = { "", "338Magnum", "762Nato", "556NatoBox", "556Nato", "buckshot", "45ACP", "57mm", "50AE", "357SIG", "9mm", "Flashbang", "HEGrenade", "SmokeGrenade", "C4" };
stock const AMMO_CLASSNAME[][] = { "", "ammo_338magnum", "ammo_762nato", "ammo_556natobox", "ammo_556nato", "ammo_buckshot", "ammo_45acp", "ammo_57mm", "ammo_50ae", "ammo_357sig", "ammo_9mm" };
stock const AMMO_NAME[][] = { "", ".338馬格南", "7.62mm北約", "5.56mm北約(盒裝)", "5.56mm北約", "鹿彈", "柯特自動手槍彈", "5.7mm", ".50AE", ".357SIG", "9mm巴拉貝魯姆", "閃光彈", "高爆手橊彈", "急凍手橊彈", "C4炸藥包" };

stock const WEAPON_CLASSNAME[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven",
										"weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
										"weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" };

stock const WEAPON_NAME[CSW_P90+1][] = { "", "P228 手槍", "錯誤 - 請聯繫插件作者", "SCOUT 狙擊槍", "高爆手橊彈", "XM1014 半自動霰彈槍", "C4 炸藥包", "MAC10 衝鋒槍",
	"AUG 步槍", "急凍手橊彈", "ELITE 雙持手槍", "FIVESEVEN 手槍", "UMP45 衝鋒槍", "SG550 半自動狙擊槍", "GALIL 步槍", "FAMAS 步槍",
	"USP 手槍", "GLOCK18 手槍", "AWP 狙擊槍", "MP5 衝鋒槍", "M249 輕機槍", "M3 壓動式霰彈槍", "M4A1 步槍",
	"TMP 衝鋒槍", "G3SG1 半自動狙擊槍", "閃光彈", "DEAGLE 手槍", "SG552 步槍", "AK47 步槍", "海豹短刀", "P90 衝鋒槍" };

stock const WEAPON_MAXCLIP[] = { -1, 13, -1, 10, 1, 7, 1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 };
stock const WEAPON_BPAMMO_INDEX[] = { AMMO_NOT_USED, 9, -1, 2, 12, 5, 14, 6, 4, 13, 10, 7, 6, 4, 4, 4, 6, 10, 1, 10, 3, 5, 4, 10, 2, 11, 8, 4, 2, -1, 7 };
stock const WEAPON_POS_IN_SLOT[] = { -1, 3, -1, 9, 1, 12, 3, 13, 14, 3, 5, 6, 15, 16, 17, 18, 4, 2, 2, 7, 4, 5, 6, 11, 3, 2, 1, 10, 1, 1, 8 };
stock const WEAPON_SLOT[] = { -1, 1, -1, 0, 3, 0, 4, 0, 0, 3, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 3, 1, 0, 0, 2, 0 };
stock const WEAPON_ZR_BUYSLOT[] = { -1, 2, -1, 1, 3, 1, -1, 1, 1, 3, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 3, 2, 1, 1, -1, 1 };
stock const WEAPON_ZR_COST[] = { -1, 600, -1, 1500, 800, 1900, -1, 1300, 1650, 1400, 800, 750, 1250, 2500, 1450, 1450, 550, 400, 2500, 1350, 8000, 1800, 1500, 1000, 2500, 500, 900, 1650, 1550, -1, 1400 };

enum _:EZRSpecialEquipments
{
	BUY_ZR_EQP_CUR_BPAMMO = 0,
	BUY_ZR_EQP_ALL_BPAMMO,
	BUY_ZR_EQP_ARMOUR,
	BUY_ZR_EQP_NVG,
};

enum _:ArmorType
{
	ARMOR_NONE = 0,	// No armor
	ARMOR_KEVLAR,	// Body vest only
	ARMOR_VESTHELM,	// Vest and helmet
};

stock const ZR_EQUIPMENT_NAME[][] = { "當前武器彈藥", "所有武器彈藥", "護甲", "夜視鏡" };
stock const ZR_EQUIPMENT_COST[] = { 1000, 2000, 100, 2500 };

stock LibWeapons_Init()
{
	g_pfn_CBP_DropShield = OrpheuGetFunction("DropShield", "CBasePlayer");
	g_pfn_CBP_SelectItem = OrpheuGetFunction("SelectItem", "CBasePlayer");
	g_pfn_CBP_SetAnimation = OrpheuGetFunction("SetAnimation", "CBasePlayer");	// Unsupported by zombieriot_amxx.dll
	g_pfn_CBPW_ReloadSound = OrpheuGetFunction("ReloadSound", "CBasePlayerWeapon");
	g_pfn_CBPW_KickBack = OrpheuGetFunction("KickBack", "CBasePlayerWeapon");
}

stock DropShield(iPlayer)
{
	OrpheuCallSuper(g_pfn_CBP_DropShield, iPlayer, true);
}

stock SelectItem(iPlayer, const szItem[])
{
	OrpheuCallSuper(g_pfn_CBP_SelectItem, iPlayer, szItem);
}

stock SetAnimation(iPlayer, PLAYER_ANIM:iAnim)
{
	OrpheuCallSuper(g_pfn_CBP_SelectItem, iPlayer, iAnim);
}

stock MakeReloadSound(iWeapon)
{
	OrpheuCallSuper(g_pfn_CBPW_ReloadSound, iWeapon);
}

stock KickBack(iWeapon, Float:up_base, Float:lateral_base, Float:up_modifier, Float:lateral_modifier, Float:up_max, Float:lateral_max, direction_change)
{
	OrpheuCallSuper(g_pfn_CBPW_KickBack, iWeapon, up_base, lateral_base, up_modifier, lateral_modifier, up_max, lateral_max, direction_change);
}

stock GetMaxAmmoStockpileWithBuffer(iPlayer, iAmmoType)
{
	new iAmmoBuffer = 0;

	for (new i = 0; i < sizeof m_rgpPlayerItems; i++)
	{
		new iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[i], XO_CBASEPLAYER);

		while (pev_valid(iWeapon) == 2)
		{
			if (get_pdata_int(iWeapon, m_iPrimaryAmmoType, XO_CBASEPLAYERWEAPON) == iAmmoType)
			{
				iAmmoBuffer += max(0, WEAPON_MAXCLIP[get_pdata_int(iWeapon, m_iId, XO_CBASEPLAYERITEM)] - get_pdata_int(iWeapon, m_iClip, XO_CBASEPLAYERWEAPON));
			}

			iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
		}
	}

	return iAmmoBuffer + AMMO_MAX_CAPACITY[iAmmoType];
}

stock GiveAmmo(iPlayer, iAmmoType, iNum, iMax = -1)
{
	return ExecuteHamB(Ham_GiveAmmo, iPlayer, iNum, AMMO_TYPE[iAmmoType], iMax > 0 ? iMax : GetMaxAmmoStockpileWithBuffer(iPlayer, iAmmoType));
}

stock ReplenishAmmunition(iPlayer, iWeapon = -1)
{
	new iAmmoId = -1;

	// HACKHACK: Special usage.
	// Replenish slot.
	if (0 < iWeapon < sizeof m_rgpPlayerItems)
	{
		iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[iWeapon], XO_CBASEPLAYER);

		while (pev_valid(iWeapon) == 2)
		{
			iAmmoId = get_pdata_int(iWeapon, m_iPrimaryAmmoType, XO_CBASEPLAYERWEAPON);

			if (iAmmoId > 0)
				GiveAmmo(iPlayer, iAmmoId, AMMO_MAX_CAPACITY[iAmmoId]);

			iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
		}

		return;
	}

	// Replenish a specific weapon.
	if (pev_valid(iWeapon) == 2)
	{
		iAmmoId = get_pdata_int(iWeapon, m_iPrimaryAmmoType, XO_CBASEPLAYERWEAPON);

		if (iAmmoId > 0)
			GiveAmmo(iPlayer, iAmmoId, AMMO_MAX_CAPACITY[iAmmoId]);

		return;
	}

	// Replenish every weapon.
	for (new i = 0; i < 2; i++)	// Only do it for primary and pistol.
	{
		iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[i], XO_CBASEPLAYER);

		while (pev_valid(iWeapon) == 2)
		{
			iAmmoId = get_pdata_int(iWeapon, m_iPrimaryAmmoType, XO_CBASEPLAYERWEAPON);

			if (iAmmoId > 0 && pev(iPlayer, pev_weapons) & (1<<get_pdata_int(iWeapon, m_iId, XO_CBASEPLAYERITEM)))	// You have to own it, and it appears in your inventory.
				GiveAmmo(iPlayer, iAmmoId, AMMO_MAX_CAPACITY[iAmmoId]);

			iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
		}
	}
}

stock bool:HasWeapon(iPlayer, iId)
{
	for (new i = 1; i < sizeof m_rgpPlayerItems; i++)
	{
		new iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[i], XO_CBASEPLAYER);

		while (pev_valid(iWeapon) == 2)
		{
			if (get_pdata_int(iWeapon, m_iId, XO_CBASEPLAYERITEM) == iId)
				return true;

			iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
		}
	}

	return false;
}

stock DropWeapons(iPlayer, iSlot)
{
	// Treat shield specially.
	if (iSlot == 1 && get_pdata_bool(iPlayer, m_bOwnsShield, XO_CBASEPLAYER))
	{
		DropShield(iPlayer);
		return;
	}

	new iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[iSlot], XO_CBASEPLAYER);
	while (pev_valid(iWeapon) == 2)
	{
		static szClassname[32];
		pev(iWeapon, pev_classname, szClassname, charsmax(szClassname));
		
		engclient_cmd(iPlayer, "drop", szClassname);
		
		iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
	}
	
	set_pdata_cbase(iPlayer, m_rgpPlayerItems[0], -1, XO_CBASEPLAYER);	// -1 is nullptr in Hamsandwich.
}

stock DropFirearmIfNecessary(iPlayer)
{
	static cvar_maxweapon;
	if (!cvar_maxweapon)
		cvar_maxweapon = get_cvar_pointer("uktpg_MaxiumTotalWeaponCounts");
	
	if (cvar_maxweapon <= 0)
		return false;
	
	new iLimit = get_pcvar_num(cvar_maxweapon) - 1;	// Assume you will add a weapon after this call.
	new iWeaponCounts, iSlotCounts[3] = {0, 0, 0};

	CountFirearms(iPlayer, iWeaponCounts, iSlotCounts);

	if (iWeaponCounts <= iLimit)
		return false;
	
	new iActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, XO_CBASEPLAYER);
	new iActiveItemSlot = ExecuteHamB(Ham_Item_ItemSlot, iActiveItem);
	new iId = 0;

	// In this case, drop current weapon.
	if (iActiveItemSlot == 1 || iActiveItemSlot == 2)
	{
		iId = get_pdata_int(iActiveItem, m_iId, XO_CBASEPLAYERITEM);
	}

	// Or, drop the "first" weapon.
	else
	{
		for (new i = 0; i < sizeof m_rgpPlayerItems; i++)
		{
			new iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[i], XO_CBASEPLAYER);

			if (pev_valid(iWeapon) == 2)
			{
				iId = get_pdata_int(iWeapon, m_iId, XO_CBASEPLAYERITEM);
				break;
			}
		}
	}

	if (iId)
		engclient_cmd(iPlayer, "drop", WEAPON_CLASSNAME[iId]);
	
	return !!(iId > 0);
}

stock GiveItem(iPlayer, const szClassname[], iSpecialCode = 0)
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szClassname));

	if (pev_valid(iEntity) != 2)
		return -1;
	
	// Do it right now. Before CBasePlayerWeapon::AddToPlayer() and CBasePlayerWeapon::Deploy().
	set_pev(iEntity, pev_weapons, iSpecialCode);

	new Float:vecOrigin[3];
	pev(iPlayer, pev_origin, vecOrigin);
	set_pev(iEntity, pev_origin, vecOrigin);
	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, iEntity);
	
	new iTemp = pev(iEntity, pev_solid);
	dllfunc(DLLFunc_Touch, iEntity, iPlayer);
	
	if (pev(iEntity, pev_solid) != iTemp)
		return iEntity;
	
	engfunc(EngFunc_RemoveEntity, iEntity);
	return -1;
}

stock GetItemIdByArmoury(iArmouryIndex)
{
	switch (iArmouryIndex)
	{
		case ARMOURY_MP5NAVY: return CSW_MP5NAVY;
		case ARMOURY_TMP: return CSW_TMP;
		case ARMOURY_P90: return CSW_P90;
		case ARMOURY_MAC10: return CSW_MAC10;
		case ARMOURY_AK47: return CSW_AK47;
		case ARMOURY_SG552: return CSW_SG552;
		case ARMOURY_M4A1: return CSW_M4A1;
		case ARMOURY_AUG: return CSW_AUG;
		case ARMOURY_SCOUT: return CSW_SCOUT;
		case ARMOURY_G3SG1: return CSW_G3SG1;
		case ARMOURY_AWP: return CSW_AWP;
		case ARMOURY_M3: return CSW_M3;
		case ARMOURY_XM1014: return CSW_XM1014;
		case ARMOURY_M249: return CSW_M249;
		case ARMOURY_FLASHBANG: return CSW_FLASHBANG;
		case ARMOURY_HEGRENADE: return CSW_HEGRENADE;
		case ARMOURY_KEVLAR: return CSW_VEST;	// You should treat specially on this one!!
		case ARMOURY_ASSAULT: return CSW_VESTHELM;	// You should treat specially on this one!!
		case ARMOURY_SMOKEGRENADE: return CSW_SMOKEGRENADE;
		case ARMOURY_SHIELD: return 99;	// You should treat specially on this one!!
		case ARMOURY_GLOCK18: return CSW_GLOCK18;
		case ARMOURY_USP: return CSW_USP;
		case ARMOURY_ELITE: return CSW_ELITE;
		case ARMOURY_FIVESEVEN: return CSW_FIVESEVEN;
		case ARMOURY_P228: return CSW_P228;
		case ARMOURY_DEAGLE: return CSW_DEAGLE;
		case ARMOURY_FAMAS: return CSW_FAMAS;
		case ARMOURY_SG550: return CSW_SG550;
		case ARMOURY_GALIL: return CSW_GALIL;
		case ARMOURY_UMP45: return CSW_UMP45;
		default: return 0;
	}

	return 0;
}

stock GiveUserShield(iPlayer)
{
	set_pdata_bool(iPlayer, m_bOwnsShield, true, XO_CBASEPLAYER);
	set_pdata_bool(iPlayer, m_bHasPrimary, true, XO_CBASEPLAYER);

	// NOTE: Moved above, because CC4::Deploy can reset hitbox of shield.
	set_pev(iPlayer, pev_gamestate, HITGROUP_SHIELD_ENABLED);

	new iActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, XO_CBASEPLAYER);
	if (iActiveItem > 0)
	{
		new ammoIndex = get_pdata_int(iActiveItem, m_iPrimaryAmmoType, XO_CBASEPLAYERWEAPON);
		if (ammoIndex > 0 && get_pdata_int(iPlayer, m_rgAmmo_CBasePlayer[ammoIndex], XO_CBASEPLAYER) > 0)
		{
			ExecuteHamB(Ham_Item_Holster, iActiveItem, 0);
		}

		if (!ExecuteHamB(Ham_Item_Deploy, iActiveItem))
		{
			ExecuteHamB(Ham_Weapon_RetireWeapon, iActiveItem);
		}
	}
}

stock RemoveUserShield(iPlayer)
{
	if (get_pdata_bool(iPlayer, m_bOwnsShield, XO_CBASEPLAYER))
	{
		set_pdata_bool(iPlayer, m_bOwnsShield, false, XO_CBASEPLAYER);
		set_pdata_bool(iPlayer, m_bHasPrimary, false, XO_CBASEPLAYER);
		set_pdata_bool(iPlayer, m_bShieldDrawn, false, XO_CBASEPLAYER);
		set_pev(iPlayer, pev_gamestate, HITGROUP_SHIELD_DISABLED);

		new iHideHUD = get_pdata_int(iPlayer, m_iHideHUD, XO_CBASEPLAYER);
		if (iHideHUD & HIDEHUD_CROSSHAIR)
		{
			set_pdata_int(iPlayer, m_iHideHUD, iHideHUD & ~HIDEHUD_CROSSHAIR, XO_CBASEPLAYER);
		}
	}
}

stock RevealWeaponFromWeaponBox(iEntity, &iSlot = 0)
{
	for (new i = 0; i < sizeof m_rgpPlayerItems2; i++)
	{
		new iWeapon = get_pdata_cbase(iEntity, m_rgpPlayerItems2[i], XO_CWEAPONBOX);

		if (pev_valid(iWeapon) == 2)
		{
			iSlot = i;
			return iWeapon;
		}
	}

	return 0;
}

stock RevealAmmoTypeFromWeaponBox(iEntity)
{
	for (new i = 0; i < sizeof m_rgpPlayerItems2; i++)
	{
		new iWeapon = get_pdata_cbase(iEntity, m_rgpPlayerItems2[i], XO_CWEAPONBOX);

		if (pev_valid(iWeapon) == 2)
		{
			return get_pdata_int(iWeapon, m_iPrimaryAmmoType, XO_CWEAPONBOX);
		}
	}

	return 0;
}

stock SumAmmunitionOfWeaponBox(iEntity)
{
	new iSum = 0;

	for (new i = 0; i < sizeof m_rgAmmo2; i++)
	{
		iSum += get_pdata_int(iEntity, m_rgAmmo2[i], XO_CWEAPONBOX);
	}

	return iSum;
}

stock CountFirearms(iPlayer, &iWeaponCounts, iSlotCounts[])
{
	for (new i = 1; i <= 2; i++)	// Only primary and secondary weapons count as firearms.
	{
		new iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[i], XO_CBASEPLAYER);

		while (pev_valid(iWeapon) == 2)
		{
			iWeaponCounts++;
			iSlotCounts[i]++;
			iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
		}
	}
}

#define ITEM_FLAG_SELECTONEMPTY		1
#define ITEM_FLAG_NOAUTORELOAD		2
#define ITEM_FLAG_NOAUTOSWITCHEMPTY	4
#define ITEM_FLAG_LIMITINWORLD		8
#define ITEM_FLAG_EXHAUSTIBLE		16  // A player can totally exhaust their ammo supply and lose this weapon

stock UTIL_WeaponList(iPlayer, iId, const szHudText[], iMaxAmmo = -1, iSlot = -1, iAmmoType = -1, iPosInSlot = -1)
{
	static gmsgWeaponList;
	if (!gmsgWeaponList)
		gmsgWeaponList = get_user_msgid("WeaponList");

	message_begin(MSG_ONE, gmsgWeaponList, _, iPlayer);
	write_string(szHudText);
	write_byte(iAmmoType < 0 ? WEAPON_BPAMMO_INDEX[iId] : iAmmoType);
	write_byte(iMaxAmmo < 0 ? AMMO_MAX_CAPACITY[WEAPON_BPAMMO_INDEX[iId]] : iMaxAmmo);
	write_byte(-1);
	write_byte(-1);
	write_byte(iSlot < 0 ? WEAPON_SLOT[iId] : iSlot - 1);
	write_byte(iPosInSlot < 0 ? WEAPON_POS_IN_SLOT[iId] : iPosInSlot);
	write_byte(iId);

	if (iId == CSW_C4 || iId == CSW_HEGRENADE || iId == CSW_FLASHBANG || iId == CSW_SMOKEGRENADE)
		write_byte(ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE);
	else
		write_byte(0);

	message_end();
}

stock UTIL_WeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(pev(iPlayer, pev_body));
	message_end();
}

stock UTIL_ForceWeaponAnim(iPlayer, iEntity, Float:flTime = 0.0)
{
	set_pdata_float(iPlayer, m_flNextAttack,			flTime);
	set_pdata_float(iEntity, m_flNextPrimaryAttack,		flTime, 4);
	set_pdata_float(iEntity, m_flNextSecondaryAttack,	flTime, 4);
	set_pdata_float(iEntity, m_flTimeWeaponIdle,		flTime, 4);
}

stock UTIL_RemovePlayerWeapon(iPlayer, iEntity)
{
	ExecuteHamB(Ham_Weapon_RetireWeapon, iEntity);
	ExecuteHamB(Ham_RemovePlayerItem, iPlayer, iEntity);
	ExecuteHamB(Ham_Item_Kill, iEntity);
	set_pev(iPlayer, pev_weapons, pev(iPlayer, pev_weapons) & ~(1<<get_pdata_int(iEntity, m_iId, XO_CBASEPLAYERITEM)));
}

stock UTIL_AmmoPickup(iPlayer, iAmmoId, iAmount)
{
	static gmsgAmmoPickup;
	if (!gmsgAmmoPickup)
		gmsgAmmoPickup = get_user_msgid("AmmoPickup");

	message_begin(MSG_ONE_UNRELIABLE, gmsgAmmoPickup, _, iPlayer);
	write_byte(iAmmoId);
	write_byte(iAmount);
	message_end();
}
