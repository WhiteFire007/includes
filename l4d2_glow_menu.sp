#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#include <LMCCore>

int FlashLight[MAXPLAYERS+1];

char classname[64];

int GlowColor[MAXPLAYERS+1];

ConVar RainbowSpeed;

static const char
    COLOR_NAME[][] =
{
    "-Desactive-\n ",
    "-Green-",
    "-Blue-",
    "-Violet-",
    "-Cyan-",
    "-Orange-",
    "-Red-",
    "-Gray-",
    "-Yellow-",
    "-Lime-",
    "-Maroon-",
    "-Teal-",
    "-Pink-",
    "-Purple-",
    "-White-",
    "-Golden-",
    "-Rainbow-"
};

static const int
	COLOR_VALUE[] = 
{
	0x000000,	//   0
	0x00FF00,	//   0 + (255 * 256) + (  0 * 65536));
	0xFA1307,	//   7 + ( 19 * 256) + (250 * 65536));
	0xFA13F9,	// 249 + ( 19 * 256) + (250 * 65536));
	0xFAFA42,	//  66 + (250 * 256) + (250 * 65536));
	0x549BF9,	// 249 + (155 * 256) + ( 84 * 65536));
	0x0000FF,	// 255 + (  0 * 256) + (  0 * 65536));
	0x323232,	//  50 + ( 50 * 256) + ( 50 * 65536));
	0x00FFFF,	// 255 + (255 * 256) + (  0 * 65536));
	0x00FF80,	// 128 + (255 * 256) + (  0 * 65536));
	0x000080,	// 128 + (  0 * 256) + (  0 * 65536));
	0x808000,	//   0 + (128 * 256) + (128 * 65536));
	0x9600FF,	// 255 + (  0 * 256) + (150 * 65536));
	0xFF009B,	// 155 + (  0 * 256) + (255 * 65536));
	0xFFFFFF,	//  -1 + ( -1 * 256) + ( -1 * 65536));
	0x009BFF,	// 255 + (155 * 256) + (  0 * 65536));
	0x000000
};

static const char 
    LIGHT_VALUE[][] = 
{
    "0 0 0",    //   0
    "0 255 0",    //   0 + (255 * 256) + (  0 * 65536));
    "7 19 250",    //   7 + ( 19 * 256) + (250 * 65536));
    "249 19 250",    // 249 + ( 19 * 256) + (250 * 65536));
    "66 250 250",    //  66 + (250 * 256) + (250 * 65536));
    "249 155 84",    // 249 + (155 * 256) + ( 84 * 65536));
    "255 0 0",    // 255 + (  0 * 256) + (  0 * 65536));
    "50 50 50",    //  50 + ( 50 * 256) + ( 50 * 65536));
    "255 255 0",    // 255 + (255 * 256) + (  0 * 65536));
    "128 255 0",    // 128 + (255 * 256) + (  0 * 65536));
    "128 0 0",    // 128 + (  0 * 256) + (  0 * 65536));
    "0 128 128",    //   0 + (128 * 256) + (128 * 65536));
    "255 0 150",    // 255 + (  0 * 256) + (150 * 65536));
    "155 0 255",    // 155 + (  0 * 256) + (255 * 65536));
    "255 255 255",    //  -1 + ( -1 * 256) + ( -1 * 65536));
    "255 155 0",    // 255 + (155 * 256) + (  0 * 65536));
    "rainbow"
};

Handle
    cookie;
int
    GlowType[MAXPLAYERS+1];

public Plugin myinfo =
{
    name        = "[L4D2] Glow Survivor",
    author        = "King_OXO(edited, now have cookie)",
    description    = "Aura or glow for the survivors",
    version        = "5.0.0 (rewritten by Grey83)",
    url            = "https://forums.alliedmods.net/showthread.php?t=332956"
}

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_Player_Spawn);
    HookEvent("player_death", Event_Player_Death);
    HookEvent("player_team", Event_Player_Death, EventHookMode_Pre);

    RegConsoleCmd("sm_aura", SetAura, "Set your aura.");
    RegConsoleCmd("sm_glow", SetAura, "Set your aura.");
    RegConsoleCmd("sm_delet_attach", RemoveAttachs);
    
    RainbowSpeed = CreateConVar("l4d2_glow_rgb_speed", "3.5", "glow speed", FCVAR_NOTIFY);
    
    AutoExecConfig(true, "l4d2_glow");

    cookie = RegClientCookie("l4d2_glow", "cookie for aura id", CookieAccess_Private);
}

public Action RemoveAttachs(int client, int args)
{
    for( int i = 1; i < 2048; i++ )
    {
        if( IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == client )
        {
            AcceptEntityInput(i, "Kill");
        }
    }
}

public void Event_Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!client || IsFakeClient(client))
        return;

    int team = GetClientTeam(client);
    if(team == 3)
        DisableGlow(client);
    else if(team == 2) {
        ReadCookies(client);
        CreateTimer(0.001, Timer_CheckGlow, client, TIMER_REPEAT);
    }
}

public Action Timer_CheckGlow(Handle timer, int client)
{
    int team = GetClientTeam(client);
    
    int color = GlowColor[client];
    if(color > 0 && team != 3) 
    {
        int iOverlayModel = LMC_GetClientOverlayModel(client);
        if(iOverlayModel > -1)
        {
            GlowTarget(iOverlayModel, color);
            SetEntProp(client, Prop_Send, "m_iGlowType", 0);
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
        }
        else
        {
            GlowTarget(client, color);
        }
    
        for(int i = 1; i< 2048; i++)
    
        if( IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == client )
        {
            GetEdictClassname(i, classname, sizeof(classname));
            if( StrEqual(classname, "prop_dynamic", false))
            {
                GlowTarget(i, color);
            }
        }
    }
    else if(color <= 0)
    {
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

public void Event_Player_Death(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client && !IsFakeClient(client)) DisableGlow(client);
}

stock void DisableGlow(int client)
{
    for( int i = 1; i < 2048; i++ )
    {
        if( IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == client && GetClientTeam(client) == 2 )
        {
            GetEdictClassname(i, classname, sizeof(classname));
            if( StrEqual(classname, "prop_dynamic", false))
            {
                SetEntProp(i, Prop_Send, "m_iGlowType", 0);
                SetEntProp(client, Prop_Send, "m_iGlowType", 0);
                SetEntProp(i, Prop_Send, "m_glowColorOverride", 0);
                SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
                SetEntityRenderColor(i, 255, 255, 255, 255);
            }
        }
        else
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
            SetEntProp(client, Prop_Send, "m_iGlowType", 0);
        }
    }
    
    GlowColor[client] = 0;
    
    if(FlashLight[client] && IsValidEdict(FlashLight[client]))
    {
        AcceptEntityInput(FlashLight[client], "Kill");
    }
    
    FlashLight[client] = 0;
    
    SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
}

public void ReadCookies(int client)
{
    if(client < 1 || MaxClients < client || !IsClientInGame(client) || IsFakeClient(client)
    || !AreClientCookiesCached(client))
        return;

    char str[4];
    GetClientCookie(client, cookie, str, sizeof(str));
    if(str[0]) GetAura(client, StringToInt(str));
}

public Action SetAura(int client, int args)
{
    int team = GetClientTeam(client);
    
    if(!client || !IsClientInGame(client))
        return Plugin_Handled;

    if(!IsPlayerAlive(client))
    {
        CPrintToChat(client, "{blue}[{orange}GLOW MENU{blue}] {olive}You must be {blue}alive {default}to use this {green}command {default}!");
        return Plugin_Handled;
    }
    
    if(team != 2)
        return Plugin_Handled;

    Menu menu = new Menu(AuraMenuHandler);
    menu.SetTitle("• GLOW MENU •\n ");
    for(int i; i < sizeof(COLOR_NAME); i++)
        menu.AddItem("", COLOR_NAME[i], GlowType[client] == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public int AuraMenuHandler(Menu menu, MenuAction action, int client, int param)
{
    switch(action)
    {
        case MenuAction_End:
            delete menu;
        case MenuAction_Select:
        {
            if(!IsPlayerAlive(client) || GetClientTeam(client) != 2)
            {
                CPrintToChat(client, "{blue}[{orange}GLOW MENU{blue}] {olive}You must be {blue}alive (survivor) {olive}to use this {green}command {default}!");
            }

            GetAura(client, param);
            SetCookie(client, cookie, param);
        }
    }

    return 0;
}


public void SetCookie(int client, Handle hCookie, int n)
{
    char strCookie[4];
    IntToString(n, strCookie, 4);
    SetClientCookie(client, hCookie, strCookie);
}

stock void GetAura(int client, int id)
{
    GlowType[client] = id;

    if(id == 16)
    {
        DisableGlow(client);
        Light(client, LIGHT_VALUE[id]);
        SDKHook(client, SDKHook_PreThink, RainbowPlayer);
        
        GlowColor[client] = 0;
    }
    else if(!id)
    {
        DisableGlow(client);
        
        GlowColor[client] = 0;
    }
    else
    {
        DisableGlow(client);
        SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
        EnableGlow(client, COLOR_VALUE[id]);
        Light(client, LIGHT_VALUE[id]);
		
		GlowColor[client] = COLOR_VALUE[id];
        
        CreateTimer(0.001, Timer_CheckGlow, client, TIMER_REPEAT);
    }
}

public Action RainbowPlayer(int client)
{
    if(!IsPlayerAlive(client))
        SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
    else
    {
        int color[3];
        float time = client + RainbowSpeed.FloatValue * GetGameTime();
        color[0] = RoundToNearest(Cosine(time + 1) * 127.5 + 127.5);
        color[1] = RoundToNearest(Cosine(time + 3) * 127.5 + 127.5);
        color[2] = RoundToNearest(Cosine(time + 5) * 127.5 + 127.5);
        
        char sTemp[16];        
        if(FlashLight[client] && IsValidEdict(FlashLight[client]))
        {
            Format(sTemp, sizeof(sTemp), "%i %i %i 255", color[0], color[1], color[2]);
            DispatchKeyValue(FlashLight[client], "_light", sTemp);
        }
        
        for( int i = 1; i < 2048; i++ )
        {
            if( IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == client )
            {
                GetEdictClassname(i, classname, sizeof(classname));
                if( StrEqual(classname, "prop_dynamic", false))
                {
                    SetEntProp(i, Prop_Send, "m_glowColorOverride", color[0] + (color[1] * 256) + (color[2] * 65536));
                    SetEntProp(i, Prop_Send, "m_iGlowType", 3);
                    SetEntProp(i, Prop_Send, "m_nGlowRange", 99999);
                    SetEntProp(i, Prop_Send, "m_nGlowRangeMin", 0);
                }
            }
        }
        
        int iOverlayModel = LMC_GetClientOverlayModel(client);
        if(iOverlayModel > -1)
        {
            SetEntProp(iOverlayModel, Prop_Send, "m_glowColorOverride", color[0] + (color[1] * 256) + (color[2] * 65536));
            SetEntProp(iOverlayModel, Prop_Send, "m_iGlowType", 3);
            SetEntProp(iOverlayModel, Prop_Send, "m_nGlowRange", 99999);
            SetEntProp(iOverlayModel, Prop_Send, "m_nGlowRangeMin", 0);
            
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
            SetEntProp(client, Prop_Send, "m_iGlowType", 0);
        }
        else
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", color[0] + (color[1] * 256) + (color[2] * 65536));
            SetEntProp(client, Prop_Send, "m_iGlowType", 3);
            SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
            SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
        }
    }
}

int Light(int client, const char[] color)
{
    int iLight = CreateEntityByName("light_dynamic");
    if(IsValidEntity(iLight))
    {
        if( strcmp(color, "rainbow", false) == 0 )
        {
            SDKHook(client, SDKHook_PreThink, RainbowPlayer);
            DispatchKeyValue(iLight, "_light", "255 0 0 255");
        }
        else
        {
            char sTempL[12];
            char sSplit[3][4];
            ExplodeString(color, " ", sSplit, sizeof(sSplit), sizeof(sSplit[]));
            Format(sTempL, sizeof(sTempL), "%d %d %d 255", StringToInt(sSplit[0]), StringToInt(sSplit[1]), StringToInt(sSplit[2]));
            DispatchKeyValue(iLight, "_light", sTempL);
        }
        DispatchKeyValue(iLight, "brightness", "3");
        DispatchKeyValueFloat(iLight, "spotlight_radius", 32.0);
        DispatchKeyValueFloat(iLight, "distance", 255.0);
        DispatchKeyValue(iLight, "style", "0");
        DispatchSpawn(iLight);
        AcceptEntityInput(iLight, "TurnOn");

        SetVariantString("!activator");
        AcceptEntityInput(iLight, "SetParent", client);
        
        TeleportEntity(iLight, view_as<float>({ 0.0, 0.0, -10.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), NULL_VECTOR);
    }
    
    FlashLight[client] = iLight;
}

stock void EnableGlow(int client, int color)
{

    int iOverlayModel = LMC_GetClientOverlayModel(client);
    if(iOverlayModel > -1)
    {
        GlowTarget(iOverlayModel, color);
    }
    else
    {
        GlowTarget(client, color);
    }
    
    for(int i = 1; i< 2048; i++)
    
    if( IsValidEntity(i) && HasEntProp(i, Prop_Send, "moveparent") && GetEntPropEnt(i, Prop_Send, "moveparent") == client )
    {
        GetEdictClassname(i, classname, sizeof(classname));
        if( StrEqual(classname, "prop_dynamic", false))
        {
            GlowTarget(i, color);
        }
    }
}

stock void GlowTarget(int target, int color)
{
    SetEntProp(target, Prop_Send, "m_glowColorOverride", color);
    SetEntProp(target, Prop_Send, "m_iGlowType", 3);
    SetEntProp(target, Prop_Send, "m_nGlowRange", 99999);
    SetEntProp(target, Prop_Send, "m_nGlowRangeMin", 0);
}