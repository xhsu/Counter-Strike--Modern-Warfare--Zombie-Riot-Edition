/*

Created Date: Sep 22 2024

Modern Warfare Dev Team
 - Luna the Reborn

*/

#if defined _csmwzr_lib_screen_fx
	#endinput
#endif
#define _csmwzr_lib_screen_fx

// MUST include: LibMath.inc

#define FFADE_IN			0x0000		// Just here so we don't pass 0 into the function
#define FFADE_OUT			0x0001		// Fade out (not in)
#define FFADE_MODULATE		0x0002		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0004		// ignores the duration, stays faded out until new ScreenFade message received

stock UTIL_ScreenFade(iPlayer, Float:flFxTime, Float:flColorHold, bitsFlags, r, g, b, alpha)
{
	static gmsgFade;
	if (!gmsgFade)
		gmsgFade = get_user_msgid("ScreenFade");

	emessage_begin(MSG_ONE_UNRELIABLE, gmsgFade, _, iPlayer);
	ewrite_short(FixedUnsigned16(flFxTime, 1 << 12));
	ewrite_short(FixedUnsigned16(flColorHold, 1 << 12));
	ewrite_short(bitsFlags);
	ewrite_byte(r);
	ewrite_byte(g);
	ewrite_byte(b);
	ewrite_byte(alpha);
	emessage_end();
}

stock bool:PlayerUtl_IsBlind(iPlayer)
{
	if (!is_user_alive(iPlayer))
		return false;

	new Float:flEndTime = get_pdata_float(iPlayer, m_blindFadeTime) + get_pdata_float(iPlayer, m_blindHoldTime) + get_pdata_float(iPlayer, m_blindStartTime);

	return flEndTime > get_gametime();
}
