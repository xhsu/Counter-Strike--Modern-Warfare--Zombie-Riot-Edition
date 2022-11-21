/* Contains 3 functions which AMX Mod X modules used to check entities.
*
* by Luna the Reborn (xhsu)
*
* Mail: xujiananxm@gmail.com
*/

#if defined _metamod_checkfunc_included
  #endinput
#endif
#define _metamod_checkfunc_included

#include <amxmodx>
#include <fakemeta>

#define METAMOD_CHECKFUNC_VERSION	2

/* Check if it is a valid player.
 */
stock bool:CHECK_PLAYER(x, bool:bSendError = false)
{
	if (x < 1 || x > global_get(glb_maxClients))
	{
		if (bSendError)
			log_error(AMX_ERR_NATIVE, "Player out of range (%d)", x);

		return false;
	}
	else
	{
		if (!is_user_connected(x))
		{
			if (bSendError)
				log_error(AMX_ERR_NATIVE, "Invalid player %d (not in-game)", x);

			return false;
		}
		else if (pev_valid(x) != 2)
		{
			if (bSendError)
				log_error(AMX_ERR_NATIVE, "Invalid player %d (no private data)", x);

			return false;
		}
	}

	return true;
}

/* Check if it is a valid non-player stuff.
 */
stock bool:CHECK_NONPLAYER(x, bool:bSendError = false)
{
	if (x < 1 || x <= global_get(glb_maxClients) || x > global_get(glb_maxEntities))
	{
		if (bSendError)
			log_error(AMX_ERR_NATIVE, "Non-player entity %d out of range", x);

		return false;
	}
	else
	{
		if (pev_valid(x) != 2)
		{
			if (bSendError)
				log_error(AMX_ERR_NATIVE, "Invalid non-player entity %d", x);

			return false;
		}
	}

	return true;
}

/* Check if it is a valid entity in general.
 */
stock bool:CHECK_ENTITY(x, bool:bSendError = false)
{
	if (x < 0 || x > global_get(glb_maxEntities))
	{
		if (bSendError)
			log_error(AMX_ERR_NATIVE, "Entity out of range (%d)", x);

		return false;
	}
	else
	{
		if (x <= global_get(glb_maxClients))
		{
			if (!is_user_connected(x))
			{
				if (bSendError)
					log_error(AMX_ERR_NATIVE, "Invalid player %d (not in-game)", x);

				return false;
			}
		}
		else
		{
			if (x != 0 && pev_valid(x) != 2)
			{
				if (bSendError)
					log_error(AMX_ERR_NATIVE, "Invalid entity %d", x);

				return false;
			}
		}
	}

	return true;
}
