/* ammx编写头版 by moddev*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <celltrie>
#include <offset>

#define PLUGIN	"Zoom"
#define VERSION	"2.0"
#define AUTHOR	"DSHGFHDS, Luna"

stock const g_szSupportedWeapon[][] = { "weapon_awp", "weapon_scout", "weapon_g3sg1", "weapon_sg550" };
stock const SNIPER_RIFLES = (1<<CSW_AWP)|(1<<CSW_SCOUT)|(1<<CSW_G3SG1)|(1<<CSW_SG550);
new Trie:g_hTrie = Invalid_Trie;
new g_szEntityIndex[8];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_forward(FM_RemoveEntity, "fw_RemoveEntity_Post", true);

	for (new i = 0; i < sizeof g_szSupportedWeapon; i++)
	{
		RegisterHam(Ham_Spawn, g_szSupportedWeapon[i], "HamF_Spawn_Post", true);
		RegisterHam(Ham_Weapon_SecondaryAttack, g_szSupportedWeapon[i], "HamF_Weapon_SecondaryAttack");
	}

	register_clcmd("zoomin", "Command_ZoomIn");
	register_clcmd("zoomout", "Command_ZoomOut");

	g_hTrie = TrieCreate();
}

public HamF_Spawn_Post(iEntity)
{
	num_to_str(iEntity, g_szEntityIndex, charsmax(g_szEntityIndex));

	TrieSetCell(g_hTrie, g_szEntityIndex, 40);
}

public fw_RemoveEntity_Post(iEntity)
{
	num_to_str(iEntity, g_szEntityIndex, charsmax(g_szEntityIndex));

	TrieDeleteKey(g_hTrie, g_szEntityIndex);
}

public HamF_Weapon_SecondaryAttack(iEntity)
{
	new iPlayer = get_pdata_cbase(iEntity, m_pPlayer, XO_CBASEPLAYERITEM);
	if (pev_valid(iPlayer) != 2)
		return HAM_IGNORED;
	
	new iFOV = get_pdata_int(iPlayer, m_iFOV, XO_CBASEPLAYER);
	if (iFOV <= 40)
	{
		iFOV = 90;
	}
	else
	{
		num_to_str(iEntity, g_szEntityIndex, charsmax(g_szEntityIndex));
		TrieGetCell(g_hTrie, g_szEntityIndex, iFOV);
	}

	set_pdata_float(iEntity, m_flNextSecondaryAttack, 0.3, XO_CBASEPLAYERWEAPON);
	
	set_pdata_int(iPlayer, m_iFOV, iFOV, XO_CBASEPLAYER);
	set_pev(iPlayer, pev_fov, float(iFOV));

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "weapons/zoom.wav", 0.2, 2.4, 0, 100);

	return HAM_SUPERCEDE;
}

public Command_ZoomIn(iPlayer)
{
	new iEntity = get_pdata_cbase(iPlayer, m_pActiveItem, XO_CBASEPLAYER);
	if (iEntity <= 0)
		return PLUGIN_HANDLED;
	
	new iId = get_pdata_int(iEntity, m_iId, XO_CBASEPLAYERITEM);
	if (!((1<<iId) & SNIPER_RIFLES))
		return PLUGIN_HANDLED;

	new iFOV = 0;
	num_to_str(iEntity, g_szEntityIndex, charsmax(g_szEntityIndex));
	if (!TrieGetCell(g_hTrie, g_szEntityIndex, iFOV))
		return PLUGIN_HANDLED;

	if (iFOV < 10 || iFOV > 40)
		return PLUGIN_HANDLED;
	
	iFOV = clamp(iFOV - 3, 10, 40);
	TrieSetCell(g_hTrie, g_szEntityIndex, iFOV);
	set_pdata_int(iPlayer, m_iFOV, iFOV, XO_CBASEPLAYER);
	set_pev(iPlayer, pev_fov, float(iFOV));

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "weapons/zoom.wav", 0.2, 2.4, 0, 100);

	return PLUGIN_HANDLED;
}

public Command_ZoomOut(iPlayer)
{
	new iEntity = get_pdata_cbase(iPlayer, m_pActiveItem, XO_CBASEPLAYER);
	if (iEntity <= 0)
		return PLUGIN_HANDLED;
	
	new iId = get_pdata_int(iEntity, m_iId, XO_CBASEPLAYERITEM);
	if (!((1<<iId) & SNIPER_RIFLES))
		return PLUGIN_HANDLED;
	
	new iFOV = 0;
	num_to_str(iEntity, g_szEntityIndex, charsmax(g_szEntityIndex));
	if (!TrieGetCell(g_hTrie, g_szEntityIndex, iFOV))
		return PLUGIN_HANDLED;

	if (iFOV < 10 || iFOV > 40)
		return PLUGIN_HANDLED;
	
	iFOV = clamp(iFOV + 3, 10, 40);
	TrieSetCell(g_hTrie, g_szEntityIndex, iFOV);
	set_pdata_int(iPlayer, m_iFOV, iFOV, XO_CBASEPLAYER);
	set_pev(iPlayer, pev_fov, float(iFOV));

	engfunc(EngFunc_EmitSound, iPlayer, CHAN_ITEM, "weapons/zoom.wav", 0.2, 2.4, 0, 100);

	return PLUGIN_HANDLED;
}
