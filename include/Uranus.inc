/*

Created Date: Sep 24 2024

Modern Warfare Dev Team
 - Luna the Reborn

*/

#if defined _uranus_lib
	#endinput
#endif
#define _uranus_lib

/*
 * Purpose: Calling "void CBasePlayer::DropShield(bool bDeploy = true);"
 * @Argument iPlayer: player entity id.
 * @Returning: NONE.
*/
native Uranus_DropShield(iPlayer);

/*
 * Purpose: Calling "bool CBasePlayer::CanPlayerBuy(bool display = true);"
 * @Argument iPlayer: player entity id.
 * @Returning: Whether player is capable of purchasing anything right now.
*/
native bool:Uranus_CanPlayerBuy(iPlayer);
