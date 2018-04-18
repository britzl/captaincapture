#include "capture.h"
#include "luautils.h"
#include <dmsdk/sdk.h>

#define LIB_NAME "Capture"
#define MODULE_NAME "capture"
#define DLIB_LOG_DOMAIN LIB_NAME

static int Capture_Start(lua_State* L) {
	int top = lua_gettop(L);
	dmLogDebug("Capture_Start");

	const char* path = luaL_checkstring(L, 1);
	dmLogDebug("Capture_Start %s", path);
	Capture_PlatformStart(path);

	dmLogDebug("Capture_Start - done");

	assert(top == lua_gettop(L));
	return 0;
}

static int Capture_Stop(lua_State* L) {
	int top = lua_gettop(L);
	dmLogDebug("Capture_Stop");

	Capture_PlatformStop();

	dmLogDebug("Capture_Stop - done");

	assert(top == lua_gettop(L));
	return 0;
}



static const luaL_reg Module_methods[] = {
	{"start", Capture_Start},
	{"stop", Capture_Stop},
	{0, 0}
};

static void LuaInit(lua_State* L) {
	int top = lua_gettop(L);
	luaL_register(L, MODULE_NAME, Module_methods);

	lua_pop(L, 1);
	assert(top == lua_gettop(L));
}

dmExtension::Result AppInitializeCaptureExtension(dmExtension::AppParams* params) {
	return dmExtension::RESULT_OK;
}

dmExtension::Result InitializeCaptureExtension(dmExtension::Params* params) {
	LuaInit(params->m_L);
	return dmExtension::RESULT_OK;
}

dmExtension::Result AppFinalizeCaptureExtension(dmExtension::AppParams* params) {
	return dmExtension::RESULT_OK;
}

dmExtension::Result FinalizeCaptureExtension(dmExtension::Params* params) {
	return dmExtension::RESULT_OK;
}

dmExtension::Result UpdateCaptureExtension(dmExtension::Params* params) {
	return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(Capture, LIB_NAME, AppInitializeCaptureExtension, AppFinalizeCaptureExtension, InitializeCaptureExtension, UpdateCaptureExtension, 0, FinalizeCaptureExtension)
