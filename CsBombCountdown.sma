/* AMXX编写头版 by Devzone */

#include <amxmodx>
#include <fakemeta>
#include <offset>

#pragma semicolon 1

#define PLUGIN		"C4 Countdown"
#define VERSION		"1.0"
#define AUTHOR		"xhsu"

#define TASK_ID	9634368

new gmsgBombDrop, gmsgRoundTime, gmsgBombPickup;
new g_iC4EntityIndex = -1;
new Float:g_vecBombPlant[3];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_forward(FM_SetModel, "fw_SetModel_Post", true);

	gmsgBombDrop = get_user_msgid("BombDrop");
	gmsgRoundTime = get_user_msgid("RoundTime");
	gmsgBombPickup = get_user_msgid("BombPickup");

	register_message(gmsgBombDrop, "Message_BombDrop");
	register_message(gmsgRoundTime, "Message_RoundTime");
	register_message(gmsgBombPickup, "Message_BombPickup");
}

public fw_SetModel_Post(iEntity, const szModel[])
{
	if (pev_valid(iEntity) != 2)
		return;

	if (strcmp(szModel, "models/w_c4.mdl"))
		return;

	g_iC4EntityIndex = iEntity;
}

public Message_BombDrop(msg_dest, msg_id, msg_ent)
{
	if (get_msg_arg_int(4) != 1)
		return PLUGIN_CONTINUE;

	// Prevent hiding timer.
	set_msg_arg_int(4, ARG_BYTE, 0);

	g_vecBombPlant[0] = get_msg_arg_float(1);
	g_vecBombPlant[1] = get_msg_arg_float(2);
	g_vecBombPlant[2] = get_msg_arg_float(3);

	SyncCountdown();
	set_task(0.9527, "Task_SyncCounter", TASK_ID, _, _, "b");

	return PLUGIN_CONTINUE;
}

public Message_RoundTime(msg_dest, msg_id, msg_ent)
{
	if (pev_valid(g_iC4EntityIndex) == 2)
	{
		new iCountDown = floatround(get_pdata_float(g_iC4EntityIndex, m_flC4Blow) - get_gametime(), floatround_ceil);
		set_msg_arg_int(1, ARG_SHORT, iCountDown);
	}

	return PLUGIN_CONTINUE;
}

public Message_BombPickup(msg_dest, msg_id, msg_ent)
{
	// Don't trigger this if it's just normal dropping and picking.
	if (pev_valid(g_iC4EntityIndex) == 2)
	{
		message_begin(MSG_ALL, gmsgBombDrop);
		engfunc(EngFunc_WriteCoord, g_vecBombPlant[0]);
		engfunc(EngFunc_WriteCoord, g_vecBombPlant[1]);
		engfunc(EngFunc_WriteCoord, g_vecBombPlant[2]);
		write_byte(1);	// hide timer
		message_end();
	}

	g_iC4EntityIndex = -1;
	remove_task(TASK_ID);

	// Now the pick message will be sent as well.
	return PLUGIN_CONTINUE;
}

public Task_SyncCounter(iTaskId)
{
	SyncCountdown();
}

SyncCountdown()
{
	new iCountDown = floatround(get_pdata_float(g_iC4EntityIndex, m_flC4Blow) - get_gametime(), floatround_ceil);

	message_begin(MSG_ALL, gmsgRoundTime);
	write_short(iCountDown);
	message_end();
}
