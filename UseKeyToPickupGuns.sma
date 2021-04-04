/* Header Template by Devzone */

#define NULL	0

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <offset>
#include <xs>

#tryinclude <cstrike_pdatas/pdatas_stocks>

#if !defined _pdatas_stocks_included
		#assert Cstrike Pdatas and Offsets library required! Read the below instructions:   \
				1. Download it at forums.alliedmods.net/showpost.php?p=1712101#post1712101   \
				2. Put it into amxmodx/scripting/include/ folder   \
				3. Compile this plugin locally, details: wiki.amxmodx.org/index.php/Compiling_Plugins_%28AMX_Mod_X%29   \
				4. Install compiled plugin, details: wiki.amxmodx.org/index.php/Configuring_AMX_Mod_X#Installing
#endif

#define PLUGIN		"E鍵撿槍"
#define VERSION		"2.2.7 Orpheu-freed"
#define AUTHOR		"Luna the Reborn(xhsu)"

/**--------------編譯選項：是否啟用提示文字？*/
#define SHOW_PICKUP_HINT	1

/**--------------編譯選項：是否在丟棄武器的同時一併丟棄它的彈藥？*/
#define DROP_AMMO_AS_WELL	1

/**--------------編譯選項：認定為榨取彈藥的按住時間有多長？*/
#define TIME_FOR_AMMO_REFILL	0.75

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

stock const AMMO_MAX_CAPACITY[] = { -1, 30, 90, 200, 90, 32, 100, 100, 35, 52, 120, 2, 1, 1, 1 };
stock const AMMO_TYPE[][] = { "", "338Magnum", "762Nato", "556NatoBox", "556Nato", "buckshot", "45ACP", "57mm", "50AE", "357SIG", "9mm", "Flashbang", "HEGrenade", "SmokeGrenade", "C4" };
stock const AMMO_NAME[][] = { "", ".338馬格南", "7.62mm北約", "5.56mm北約(盒裝)", "5.56mm北約", "鹿彈", "柯特自動手槍彈", "5.7mm", ".50AE", ".357SIG", "9mm巴拉貝魯姆", "閃光彈", "高爆手榴彈", "煙霧彈", "C4炸藥包" };

stock const WEAPON_CLASSNAME[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven",
										"weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1",
										"weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" };

stock const WEAPON_NAME[CSW_P90+1][] = { "", "P228 手槍", "錯誤 - 請聯繫插件作者", "SCOUT 狙擊槍", "高爆手榴彈", "XM1014 半自動霰彈槍", "C4 炸藥包", "MAC10 衝鋒槍",
	"AUG 步槍", "煙霧彈", "ELITE 雙持手槍", "FIVESEVEN 手槍", "UMP45 衝鋒槍", "SG550 半自動狙擊槍", "GALIL 步槍", "FAMAS 步槍",
	"USP 手槍", "GLOCK18 手槍", "AWP 狙擊槍", "MP5 衝鋒槍", "M249 輕機槍", "M3 壓動式霰彈槍", "M4A1 步槍",
	"TMP 衝鋒槍", "G3SG1 半自動狙擊槍", "閃光彈", "DEAGLE 手槍", "SG552 步槍", "AK47 步槍", "海豹短刀", "P90 衝鋒槍" };

stock const WEAPON_MAXCLIP[] = { -1, 13, -1, 10, 1, 7, 1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 };

// Use some unused values.
#define m_flTimeStartUsing		m_flStartThrow
#define m_iLastUsingPlayerId	m_iSwing

#if defined SHOW_PICKUP_HINT
new g_msgSync = 0;
#endif

new cvar_maxtotalwpns = 0;
new g_rgiszAmmoName[sizeof AMMO_TYPE];


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Touch, "weaponbox", "HamF_Touch");
	RegisterHam(Ham_ObjectCaps, "weaponbox", "HamF_ObjectCaps");
	RegisterHam(Ham_Use, "weaponbox", "HamF_Use");
	RegisterHam(Ham_Think, "weaponbox", "HamF_Think");

#if defined DROP_AMMO_AS_WELL
	register_forward(FM_SetModel, "fw_SetModel_Post", true);
#endif
	
#if defined SHOW_PICKUP_HINT
	g_msgSync = CreateHudSyncObj();
#endif

	cvar_maxtotalwpns = register_cvar("uktpg_MaxiumTotalWeaponCounts", "2");
}

public plugin_precache()
{
	// For a long time running game.
	for (new i = 1; i < sizeof AMMO_TYPE; i++)
		g_rgiszAmmoName[i] = engfunc(EngFunc_AllocString, AMMO_TYPE[i]);
}

public HamF_Touch(iEntity, iPlayer)
{
	if (pev_valid(iEntity) != 2 || !is_user_alive(iPlayer))
		return HAM_IGNORED;
	
	if (is_user_bot(iPlayer) || !(pev(iEntity, pev_flags) & FL_ONGROUND))
		return HAM_IGNORED;
	
	new iWeapon = RevealWeaponFromWeaponBox(iEntity);
	new iSlot = ExecuteHamB(Ham_Item_ItemSlot, iWeapon);
	if (iSlot != 1 && iSlot != 2)
		return HAM_IGNORED;
	
	// No more than one player can interact with it at the same time.
	new iPlayerWithBox = get_pdata_int(iEntity, m_iLastUsingPlayerId, XO_CWEAPONBOX);
	if (is_user_alive(iPlayerWithBox) && iPlayerWithBox != iPlayer)
		return HAM_IGNORED;

#if defined SHOW_PICKUP_HINT
	set_hudmessage(0, 200, 0, -1.0, 0.64, 0, 6.0, 0.2, 0.0, 0.0, -1);

	new iWeaponCounts = 0;
	for (new i = 1; i <= 2; i++)	// Only primary and secondary weapons counts.
	{
		new iMyWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[i], XO_CBASEPLAYER);

		while (pev_valid(iMyWeapon) == 2)
		{
			iWeaponCounts++;
			iMyWeapon = get_pdata_cbase(iMyWeapon, m_pNext, XO_CBASEPLAYERITEM);
		}
	}

	new iWeaponId = get_pdata_int(iWeapon, m_iId, XO_CBASEPLAYERITEM);
	new iAmmoId = RevealAmmoTypeFromWeaponBox(iEntity);
	new bool:bShowSeizeAmmoHint = !!(get_pdata_int(iPlayer, m_rgAmmo[iAmmoId], XO_CBASEPLAYER) < GetMaxAmmoStockpileWithBuffer(iPlayer, iAmmoId));
	new bool:bOwnsShield = get_pdata_bool(iPlayer, m_bOwnsShield, XO_CBASEPLAYER);

	if (bOwnsShield && iSlot == 1)
	{
		// Can only grab the ammo. You can't own both a shield and a rifle. That's OP.
		if (bShowSeizeAmmoHint)
			ShowSyncHudMsg(iPlayer, g_msgSync, "按住［使用鍵］獲取［%s］彈藥", AMMO_NAME[iAmmoId]);
	}
	else if (HasWeapon(iPlayer, iWeaponId))
	{
		// Either way you can only grab the ammo.
		if (bShowSeizeAmmoHint)
			ShowSyncHudMsg(iPlayer, g_msgSync, "按下［使用鍵］獲取［%s］彈藥", AMMO_NAME[iAmmoId]);
	}
	else if (iWeaponCounts < get_pcvar_num(cvar_maxtotalwpns))
	{
		if (bShowSeizeAmmoHint)
			ShowSyncHudMsg(iPlayer, g_msgSync, "按下［使用鍵］拾起［%s］^n按住［使用鍵］獲取［%s］彈藥", WEAPON_NAME[iWeaponId], AMMO_NAME[iAmmoId]);
		else
			ShowSyncHudMsg(iPlayer, g_msgSync, "按下［使用鍵］拾起［%s］", WEAPON_NAME[iWeaponId]);
	}
	else
	{
		new iActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, XO_CBASEPLAYER);
		new iActiveItemSlot = ExecuteHamB(Ham_Item_ItemSlot, iActiveItem);
		new iIdToBeReplaced = 0;

		// In this case, drop current weapon.
		if (iActiveItemSlot == 1 || iActiveItemSlot == 2)
		{
			iIdToBeReplaced = get_pdata_int(iActiveItem, m_iId, XO_CBASEPLAYERITEM);
		}
		
		// Or, drop the "first" weapon.
		else
		{
			for (new i = 0; i < sizeof m_rgpPlayerItems; i++)
			{
				new iMyWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[i], XO_CBASEPLAYER);

				if (pev_valid(iMyWeapon) == 2)
				{
					iIdToBeReplaced = get_pdata_int(iMyWeapon, m_iId, XO_CBASEPLAYERITEM);
					break;
				}
			}
		}

		// Hint player which weapon to be replaced.
		if (bShowSeizeAmmoHint)
			ShowSyncHudMsg(iPlayer, g_msgSync, "按下［使用鍵］將［%s］替換為［%s］^n按住［使用鍵］獲取［%s］彈藥", WEAPON_NAME[iIdToBeReplaced], WEAPON_NAME[iWeaponId], AMMO_NAME[iAmmoId]);
		else
			ShowSyncHudMsg(iPlayer, g_msgSync, "按下［使用鍵］將［%s］替換為［%s］", WEAPON_NAME[iIdToBeReplaced], WEAPON_NAME[iWeaponId]);
	}
#endif

	return HAM_SUPERCEDE;
}

public HamF_ObjectCaps(iEntity)
{
	new iWeapon = RevealWeaponFromWeaponBox(iEntity);
	new iSlot = ExecuteHamB(Ham_Item_ItemSlot, iWeapon);

	// This plugin does not work on Grenades.
	if (iSlot != 1 && iSlot != 2)
		return HAM_IGNORED;

	new bitsOriginalCaps = FCAP_ACROSS_TRANSITION;	// Default value for any CBaseEntity.
	GetOrigHamReturnInteger(bitsOriginalCaps);

	SetHamReturnInteger(bitsOriginalCaps | FCAP_ONOFF_USE);	// That's for two calls on CWeaponBox::Use(). One on pressing E, the other one on releasing E.
	return HAM_OVERRIDE;
}

public HamF_Use(iEntity, iCaller, iActivator, iUseType, Float:flValue)
{
	// It doesn't matter, both caller and activator are the player who wants to pick it up.
	// Reference: CBasePlayer::PlayerUse()
	new iPlayer = iActivator;

	// No more than one player can interact with it at the same time.
	new iPlayerWithBox = get_pdata_int(iEntity, m_iLastUsingPlayerId, XO_CWEAPONBOX);
	if (is_user_alive(iPlayerWithBox) && iPlayerWithBox != iPlayer)
		return HAM_SUPERCEDE;

	// On pressing E.
	if (flValue == 1.0)
	{
		set_pdata_float(iEntity, m_flTimeStartUsing, get_gametime(), XO_CWEAPONBOX);
		set_pdata_int(iEntity, m_iLastUsingPlayerId, iPlayer, XO_CWEAPONBOX);
		set_pev(iEntity, pev_nextthink, get_gametime() + 0.1);

		return HAM_SUPERCEDE;
	}

	// On releasing E.
	else
	{
		// Save value before removing it.
		new Float:flTimeStartUsing = get_pdata_float(iEntity, m_flTimeStartUsing, XO_CWEAPONBOX);

		set_pdata_float(iEntity, m_flTimeStartUsing, -1.0, XO_CWEAPONBOX);
		set_pdata_int(iEntity, m_iLastUsingPlayerId, -1, XO_CWEAPONBOX);
		set_pev(iEntity, pev_nextthink, 0.0);

		// It should goes to CWeaponBox::Think() instead of here.
		if (get_gametime() - flTimeStartUsing > TIME_FOR_AMMO_REFILL)
		{
			return HAM_SUPERCEDE;
		}
	}

	// Normal flow. i.e., pressing E and quickly release it == picking it up.

	// HACKHACK
	// Save VIP status. The VIP cannot buy anything at all in vanilla game, thus we have to do some.. HACK...
	new bool:bIsVIP = get_pdata_bool(iPlayer, m_bIsVIP, XO_CBASEPLAYER);
	set_pdata_bool(iPlayer, m_bIsVIP, false, XO_CBASEPLAYER);

	new iWeaponCounts = 0, iSlotCounts[3] = {0, 0, 0};
	for (new i = 1; i <= 2; i++)	// Only primary and secondary weapons counts.
	{
		new iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[i], XO_CBASEPLAYER);

		while (pev_valid(iWeapon) == 2)
		{
			iWeaponCounts++;
			iSlotCounts[i]++;
			iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
		}
	}

	new iWeaponInBox = RevealWeaponFromWeaponBox(iEntity);
	new iSlot = ExecuteHamB(Ham_Item_ItemSlot, iWeaponInBox);

	if (get_pdata_bool(iPlayer, m_bOwnsShield, XO_CBASEPLAYER) && iSlot == 1)
	{
		// You can't grab any primary weapon if you already owns a shield.
		goto LAB_HAMF_USE_LAST;
	}

	if (HasWeapon(iPlayer, get_pdata_int(iWeaponInBox, m_iId, XO_CBASEPLAYERITEM)))
	{
		ExtractAmmunitionFromWeaponBox(iEntity, iPlayer, false);
	}
	else if (iWeaponCounts < get_pcvar_num(cvar_maxtotalwpns))
	{
		// The weapon on my hand is occuping different slot.
		if (iSlotCounts[iSlot] == 0 && iWeaponCounts <= 1)
		{
			ExecuteHam(Ham_Touch, iEntity, iPlayer);	// Bypass our hook.
		}
		else
		{
			ExtractItemsFromWeaponBox(iEntity, iPlayer);
		}
	}
	else	// Having more than limited number? Interfere by other plugins?
	{
		new iActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, XO_CBASEPLAYER);
		new iActiveItemSlot = ExecuteHamB(Ham_Item_ItemSlot, iActiveItem);
		new szClassname[32];

		// In this case, drop current weapon.
		if (iActiveItemSlot == 1 || iActiveItemSlot == 2)
		{
			pev(iActiveItem, pev_classname, szClassname, charsmax(szClassname));
		}
		
		// Or, drop the "first" weapon.
		else
		{
			for (new i = 0; i < sizeof m_rgpPlayerItems; i++)
			{
				new iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[i], XO_CBASEPLAYER);

				if (pev_valid(iWeapon) == 2)
				{
					pev(iWeapon, pev_classname, szClassname, charsmax(szClassname));
					break;
				}
			}
		}

		engclient_cmd(iPlayer, "drop", szClassname);

		// Add weapon after drop one.
		ExtractItemsFromWeaponBox(iEntity, iPlayer);
	}

LAB_HAMF_USE_LAST:
	// HACKHACK
	// Restore VIP identity before we leave.
	set_pdata_bool(iPlayer, m_bIsVIP, bIsVIP, XO_CBASEPLAYER);
	return HAM_SUPERCEDE;
}

// Should ALWAYS supercede when dealing with this. Since normally the next think means removal.
public HamF_Think(iEntity)
{
	new Float:flTimeStartUsing = get_pdata_float(iEntity, m_flTimeStartUsing, XO_CWEAPONBOX);
	new iPlayer = get_pdata_int(iEntity, m_iLastUsingPlayerId, XO_CWEAPONBOX);

	if (flTimeStartUsing <= 0.0)
		return HAM_IGNORED;

	// Do the ammo refill instead of picking up weapon.
	if (get_gametime() - flTimeStartUsing > TIME_FOR_AMMO_REFILL && is_user_alive(iPlayer))
	{
		new iWeapon = RevealWeaponFromWeaponBox(iEntity);
		new iAmmoType = get_pdata_int(iWeapon, m_iPrimaryAmmoType, XO_CBASEPLAYERITEM);

		if (get_pdata_int(iPlayer, m_rgAmmo[iAmmoType], XO_CBASEPLAYER) >= GetMaxAmmoStockpileWithBuffer(iPlayer, iAmmoType))
			return HAM_SUPERCEDE;

		// Seize the ammo from the weapon but keep the entity on the ground.
		ExtractAmmunitionFromWeaponBox(iEntity, iPlayer, false);

		// Remove the saved info avoiding confusion.
		set_pdata_float(iEntity, m_flTimeStartUsing, -1.0, XO_CWEAPONBOX);
		set_pdata_int(iEntity, m_iLastUsingPlayerId, -1, XO_CWEAPONBOX);
	}
	else if (flTimeStartUsing > 0.0)
		set_pev(iEntity, pev_nextthink, get_gametime() + 0.01);

	return HAM_SUPERCEDE;
}

#if defined DROP_AMMO_AS_WELL
public fw_SetModel_Post(iEntity, const szModel[])
{
	if (pev_valid(iEntity) != 2)
		return;
	
	static szClassname[32];
	pev(iEntity, pev_classname, szClassname, charsmax(szClassname));
	if (strcmp(szClassname, "weaponbox"))
		return;
	
	new iAmmoType = RevealAmmoTypeFromWeaponBox(iEntity);
	new iPlayer = pev(iEntity, pev_owner);

	if (!is_user_alive(iPlayer))
		return;

	for (new i = 1; i < sizeof m_rgpPlayerItems; i++)
	{
		new iWeapon = get_pdata_cbase(iPlayer, m_rgpPlayerItems[i], XO_CBASEPLAYER);

		while (pev_valid(iWeapon) == 2)
		{
			// If there're still another gun using this ammo type, then don't drop it.
			if (get_pdata_int(iWeapon, m_iPrimaryAmmoType, XO_CBASEPLAYERWEAPON) == iAmmoType)
				return;

			iWeapon = get_pdata_cbase(iWeapon, m_pNext, XO_CBASEPLAYERITEM);
		}
	}

	if (iAmmoType && is_user_alive(iPlayer))
	{
		set_pdata_int(iEntity, m_rgAmmo2[1], get_pdata_int(iEntity, m_rgAmmo2[1], XO_CWEAPONBOX) + get_pdata_int(iPlayer, m_rgAmmo[iAmmoType]), XO_CWEAPONBOX);
		set_pdata_int(iEntity, m_rgiszAmmo[1], g_rgiszAmmoName[iAmmoType], XO_CWEAPONBOX);
		set_pdata_int(iPlayer, m_rgAmmo[iAmmoType], 0, XO_CBASEPLAYER);
	}
}
#endif

ExtractItemsFromWeaponBox(iEntity, iPlayer, bool:bShouldRemove = true)
{
	new i, iAmmoType = 0;
	for (i = 0; i < sizeof m_rgpPlayerItems2; i++)
	{
		new iWeapon = get_pdata_cbase(iEntity, m_rgpPlayerItems2[i], XO_CWEAPONBOX);

		if (pev_valid(iWeapon) == 2)
		{
			if (ExecuteHamB(Ham_AddPlayerItem, iPlayer, iWeapon))
				ExecuteHamB(Ham_Item_AttachToPlayer, iWeapon, iPlayer);

			set_pdata_cbase(iEntity, m_rgpPlayerItems2[i], -1, XO_CWEAPONBOX);	// -1 == nullptr

			// Remember this for later use.
			iAmmoType = get_pdata_int(iWeapon, m_iPrimaryAmmoType, XO_CBASEPLAYERWEAPON);
			break;
		}
	}

	GiveAmmo(iPlayer, iAmmoType, SumAmmunitionOfWeaponBox(iEntity));

	// Use pev->flags to remove entity here instead. Otherwise it would cause CTD on DispatchTouch() function.
	if (bShouldRemove)
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
	
	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}

ExtractAmmunitionFromWeaponBox(iEntity, iPlayer, bool:bRemoveOnEmpty = true, bool:bAlwaysRemove = false)
{
	new i, iAmmoType = 0, iAmmoSum = 0, iWeapon = 0, iClip = 0;
	for (i = 0; i < sizeof m_rgpPlayerItems2; i++)
	{
		iWeapon = get_pdata_cbase(iEntity, m_rgpPlayerItems2[i], XO_CWEAPONBOX);

		if (pev_valid(iWeapon) == 2)
		{
			// Get the clip ammo.
			iAmmoSum += get_pdata_int(iWeapon, m_iClip, XO_CBASEPLAYERWEAPON);

			// Empty the clip.
			iClip = get_pdata_int(iWeapon, m_iClip, XO_CBASEPLAYERWEAPON);
			set_pdata_int(iWeapon, m_iClip, 0, XO_CBASEPLAYERWEAPON);

			// Remember this for later use.
			iAmmoType = get_pdata_int(iWeapon, m_iPrimaryAmmoType, XO_CBASEPLAYERWEAPON);

			break;
		}
	}

	iAmmoSum += SumAmmunitionOfWeaponBox(iEntity);

	for (new i = 0; i < sizeof m_rgAmmo2; i++)
	{
		// Empty its ammo stock. Remember, remove the string as well.
		set_pdata_int(iEntity, m_rgAmmo2[i], 0, XO_CWEAPONBOX);
		set_pdata_int(iEntity, m_rgiszAmmo[i], 0, XO_CWEAPONBOX);
	}

	if (iAmmoSum > 0)
	{
		new iMax = GetMaxAmmoStockpileWithBuffer(iPlayer, iAmmoType);

		// Copy from CBasePlayerWeapon::ItemPostFrame()
		new j = min(iMax - get_pdata_int(iPlayer, m_rgAmmo[iAmmoType], XO_CBASEPLAYER), iAmmoSum);

		// Add them to the inventory.
		GiveAmmo(iPlayer, iAmmoType, j, iMax);
		emit_sound(iPlayer, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

		// Remove the same number from stash.
		iAmmoSum -= j;

		// Some bullets left? Stuff back to magazine.
		if (iAmmoSum > 0)
		{
			iClip = min(iAmmoSum, iClip);
			iAmmoSum -= iClip;

			set_pdata_int(iWeapon, m_iClip, iClip, XO_CBASEPLAYERWEAPON);
		}

		// Put the rest into CWeaponBox's inventory.
		if (iAmmoSum > 0)
		{
			set_pdata_int(iEntity, m_rgAmmo2[1], iAmmoSum, XO_CWEAPONBOX);
			set_pdata_int(iEntity, m_rgiszAmmo[1], g_rgiszAmmoName[iAmmoType], XO_CWEAPONBOX);
		}
	}

	// Use pev->flags to remove entity here instead. Otherwise it would cause CTD on DispatchTouch() function.
	if ((iAmmoSum <= 0 && bRemoveOnEmpty) || bAlwaysRemove)
		set_pev(iEntity, pev_flags, pev(iEntity, pev_flags) | FL_KILLME);
}

GetMaxAmmoStockpileWithBuffer(iPlayer, iAmmoType)
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

GiveAmmo(iPlayer, iAmmoType, iNum, iMax = -1)
{
	return ExecuteHamB(Ham_GiveAmmo, iPlayer, iNum, AMMO_TYPE[iAmmoType], iMax > 0 ? iMax : GetMaxAmmoStockpileWithBuffer(iPlayer, iAmmoType));
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
		RemoveUserShield(iPlayer);
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
	
	set_pdata_cbase(iPlayer, m_rgpPlayerItems[0], -1, XO_CBASEPLAYER);
}

stock fm_give_item(iPlayer, const szClassname[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szClassname));
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
