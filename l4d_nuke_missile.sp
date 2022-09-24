#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <colors>

#pragma newdecls required
#pragma semicolon 1

ConVar g_hNukeDamage, g_hNukeRadius, g_hNukeVelocity, g_hNukeLimit, g_hNukeTime;

float ProjectileVelo;

int Rocketparts[2000][2], Limit[MAXPLAYERS+1], Time, g_Particle, iParticle[2000];
    
bool isLaunch[MAXPLAYERS+1] = false;
    
Handle HandleTimer = null;

float beaPos[3];

#define NUKE_SOUND    "nuke/explosion.mp3"
#define NUKE_LAUNCH   "nuke/missile.mp3"
#define COUNT_SOUND   "UI/Beep07.wav"

#define amg65 "models/missiles/f18_agm65maverick.mdl"
#define MOLO  "models/w_models/weapons/w_eq_molotov.mdl"

#define NUKE_PARTICLE "nuke_core"
#define SMOKE_PARTICLE "rpg_smoke"

public Plugin myinfo =
{
    name = "[L4D2] Nuclear Missile",
    author = "King_OXO",
    description = "Call A Nuclear Missile On Crosshair(new codes, thanks Silver)",
    version = "5.0",
    url = "https://forums.alliedmods.net/showthread.php?t=336654"
};

public void OnPluginStart()
{
    g_hNukeDamage   = CreateConVar("l4d2_nuke_damage", "5000.0", "Damage when Missile explodes", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
    g_hNukeLimit    = CreateConVar("l4d2_nuke_limit", "15.0", "Limit to use the nuke missile", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
    g_hNukeTime     = CreateConVar("l4d2_nuke_time", "4", "time for the nuclear missile to be created", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
    g_hNukeRadius   = CreateConVar("l4d2_nuke_radius", "999999.0", "Missile blast distance", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
    g_hNukeVelocity = CreateConVar("l4d2_nuke_velocity", "3000.0", "Missile Velocity", FCVAR_NOTIFY, true, 0.0, true, 999999.0);
    
    HookEvent("player_spawn", Event_spawn);
    HookEvent("player_death", Event_death);
    HookEvent("round_start", Event_start);
    HookEvent("round_end", Event_end);
    HookEvent("finale_vehicle_leaving", Event_Explode);
    
    RegAdminCmd("sm_nuke", Cmd_Nuke, ADMFLAG_KICK);
    RegAdminCmd("sm_nuke_reload", Cmd_NukeReload, ADMFLAG_KICK);
    
    AutoExecConfig(true, "l4d2_nuke_missile");
}

public void OnMapStart()
{
    PrecacheModel(amg65, true);
    
    PrecacheParticle(NUKE_PARTICLE);
    PrecacheParticle(SMOKE_PARTICLE);
    
    iParticle[g_Particle] = 0;
    
    PrecacheSound(NUKE_SOUND, true);
    PrecacheSound(NUKE_LAUNCH, true);
    PrecacheSound(COUNT_SOUND, true);
    
    AddFileToDownloadsTable("sounds/nuke/explosion.mp3");
    AddFileToDownloadsTable("sounds/nuke/launch.mp3");
    AddFileToDownloadsTable("particles/nuke.pcf");
}

public Action Event_death(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client) && GetClientTeam(client) == 2)
    {
        Limit[client] = 0;
        CPrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 Reseted\x05!");
    }
}

public Action Event_spawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client) && GetClientTeam(client) == 3)
    {
        float Pos[3];
        GetEntPropVector( client, Prop_Send, "m_vecOrigin", Pos );
        if(GetVectorDistance(beaPos, Pos) > GetConVarFloat(g_hNukeRadius)) return;
        int entity = iParticle[g_Particle];
        if(IsValidEntRef(entity))
        {
            IgniteEntity(client, 999.9);
        }
    }
}

public Action Event_end(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client) && GetClientTeam(client) == 2)
    {
        Limit[client] = 0;
        CPrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 Reseted\x05!");
    }
    
    iParticle[g_Particle] = 0;
}

public Action Event_start(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidClient(client) && GetClientTeam(client) == 2)
    {
        Limit[client] = 0;
        CPrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 Reseted\x05!");
    }
    
    iParticle[g_Particle] = 0;
}

public Action Event_Explode(Event event, const char[] name, bool dontBroadcast)
{
    float vPos[3], vAng[3], vPosEnd[3];
    char buffer[32];
    GetCurrentMap(buffer, sizeof(buffer));
    if ( strcmp(buffer, "c5m5_bridge")==0 )
    {
        vPos[0] = 9460.0, vAng[0] = 15.0, vPosEnd[0] = 4272.0;
        vPos[1] = 3156.0, vAng[1] = 154.0, vPosEnd[1] = 4403.0;
        vPos[2] = 1359.0, vAng[2] = 0.00, vPosEnd[2] = -195.0;
        CallMissile(vPos, vAng, vPosEnd);
    }
    else if ( strcmp(buffer, "c6m3_port")==0 )
    {
        vPos[0] = 2804.0, vAng[0] = 11.0, vPosEnd[0] = 749.0;
        vPos[1] = -2574.0, vAng[1] = 169.0, vPosEnd[1] = -1834.0;
        vPos[2] = 638.0, vAng[2] = 0.00, vPosEnd[2] = -583.0;
        CallMissile(vPos, vAng, vPosEnd);
    }
    
    else if ( strcmp(buffer, "c11m5_runway")==0 )
    {
        vPos[0] = 4108.0, vAng[0] = 5.0, vPosEnd[0] = 4544.0;
        vPos[1] = -319.0, vAng[1] = 87.0, vPosEnd[1] = 10916.0;
        vPos[2] = 896.0, vAng[2] = 0.00, vPosEnd[2] = -274.0;
        CallMissile(vPos, vAng, vPosEnd);
    }
    else if ( strcmp(buffer, "c8m5_rooftop")==0 )
    {
        vPos[0] = 10912.0, vAng[0] = 17.0, vPosEnd[0] = 7149.0;
        vPos[1] = 7105.0, vAng[1] = 159.0, vPosEnd[1] = 8563.0;
        vPos[2] = 7123.0, vAng[2] = -0.00, vPosEnd[2] = 5980.0;
        CallMissile(vPos, vAng, vPosEnd);
    }
    else return;
}

public Action Cmd_NukeReload(int client, int args)
{
    if(IsValidClient(client) && GetClientTeam(client) == 2)
    {
        Limit[client] = 0;
        CPrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 Reseted\x05!");
    }
}
public Action Cmd_Nuke(int client, int args)
{
    if (!(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2))
    {
        CPrintToChat(client, "\x04[\x03NM\x04] \x05only \x03survivor \x01can use this \x04command \x01!");

        return Plugin_Handled;
    }
    
    int NukeLimit = GetConVarInt(g_hNukeLimit);
    if(!isLaunch[client])
    {
        Time = GetConVarInt(g_hNukeTime);
        if (HandleTimer == null)
        {
            HandleTimer = CreateTimer(1.0, TacticalNuke, client, TIMER_REPEAT); //do not change the time value
        }
        isLaunch[client] = true;
        Limit[client] += 1;
        CPrintToChat(client, "\x04[\x03NM\x04] \x01Nuke Limit\x01:\x03 %d \x01/ \x03%d", Limit[client], NukeLimit);
    }
    else
    {
        CPrintToChat(client, "\x04[\x03NM\x04]\x01Have you ever called a nuclear missile");
    }
    
    return Plugin_Handled;
}

public Action TacticalNuke(Handle timer, int client)
{
    if (HandleTimer == null)
    {
        return Plugin_Stop;
    }
    
    if(Time == 0)
    {
        if(IsPlayerAlive(client) && GetClientTeam(client) == 2)
        {
            NukeMissile(client);
        }
        
        if (HandleTimer != null)
        {
            KillTimer(HandleTimer);
            HandleTimer = null;
        }
        
        isLaunch[client] = false;
    }
    else if(Time > 0)
    {
        Time -= 1;
        PrintHintText(client, "A NUCLEAR MISSILE IS COMING\n TIME\n ==> [ %d ] <==", Time);
        for(int i = 1; i <= MaxClients; i++)
        {
            if(i > 0 && IsClientInGame(i) && !IsFakeClient(i))
            {
                EmitSoundToClient(i, COUNT_SOUND);
            }
        }
    }
    
    return Plugin_Continue;
}

void CallMissile( float vPos[3], float vAng[3], float vPosEnd[3])
{
    float bfVol[3];
    int body = CreateEntityByName( "molotov_projectile" );
    if( body != -1 )
    {
        DispatchKeyValue( body, "model", MOLO );
        DispatchKeyValueVector( body, "origin", vPos );
        DispatchKeyValueVector( body, "Angles", vAng );
        SetEntPropFloat( body, Prop_Send,"m_flModelScale",0.00001 );
        SetEntityGravity( body, 0.001 );
        DispatchSpawn( body );
    }
    
    int atth = CreateAttachment( body, amg65, 1.0, 5.0 );
    int smoke = AttachParticle( body );

    Rocketparts[body][0] = atth;
    Rocketparts[body][1] = smoke;
    
    SDKHook( body, SDKHook_StartTouch, OnNukeCollide );
        
    MakeVectorFromPoints( vPos, vPosEnd, bfVol );
    NormalizeVector( bfVol, bfVol );
    GetVectorAngles( bfVol, vAng );
    ProjectileVelo = GetConVarFloat(g_hNukeVelocity);
    ScaleVector( bfVol, ProjectileVelo );
    TeleportEntity( body, NULL_VECTOR, vAng, bfVol );
     
    EmitSoundToAll(NUKE_LAUNCH, body);
}

void NukeMissile( int client )
{
    float vAng[3];
    float vPos[3];
    
    GetClientEyePosition( client,vPos );
    GetClientEyeAngles( client, vAng );
    Handle hTrace = TR_TraceRayFilterEx( vPos, vAng, MASK_SHOT, RayType_Infinite, bTraceEntityFilterPlayer );
    
    if ( TR_DidHit( hTrace ) )
    {
        float vBuffer[3];
        float vStart[3];
        float vDistance = -35.0;
        
        TR_GetEndPosition( vStart, hTrace );
        GetVectorDistance( vPos, vStart, false );
        GetAngleVectors( vAng, vBuffer, NULL_VECTOR, NULL_VECTOR );
        
        vPos[0] = vStart[0] + ( vBuffer[0] * vDistance );
        vPos[1] = vStart[1] + ( vBuffer[1] * vDistance );
        vPos[2] = vStart[2] + ( vBuffer[2] * vDistance );
        
        float ClientPos[3];
        float bfAng[3];
        float bfVol[3];
        GetEntPropVector( client, Prop_Send, "m_vecOrigin", ClientPos );
        GetEntPropVector( client, Prop_Data, "m_angRotation", bfAng );
    
        int body = CreateEntityByName( "molotov_projectile" );
        if( body != -1 )
        {
            DispatchKeyValue( body, "model", MOLO );
            DispatchKeyValueVector( body, "origin", ClientPos );
            DispatchKeyValueVector( body, "Angles", bfAng );
            SetEntPropFloat( body, Prop_Send,"m_flModelScale",0.00001 );
            SetEntityGravity( body, 0.001 );
            SetEntPropEnt( body, Prop_Data, "m_hOwnerEntity", client );
            DispatchSpawn( body );
        }
    
        int atth = CreateAttachment( body, amg65, 1.0, 5.0 );
        int smoke = AttachParticle( body );

        Rocketparts[body][0] = atth;
        Rocketparts[body][1] = smoke;
    
        SDKHook( body, SDKHook_StartTouch, OnNukeCollide );
        ClientPos[2] += GetRandomFloat( 5.0, 10.0 );
        
        MakeVectorFromPoints( ClientPos, vPos, bfVol );
        NormalizeVector( bfVol, bfVol );
        GetVectorAngles( bfVol, bfAng );
        ProjectileVelo = GetConVarFloat(g_hNukeVelocity);
        ScaleVector( bfVol, ProjectileVelo );
        TeleportEntity( body, NULL_VECTOR, bfAng, bfVol );
        
        EmitSoundToAll(NUKE_LAUNCH, body);
    }
    delete hTrace;
}

public Action OnNukeCollide( int ent, int target )
{
    int entity = Rocketparts[ent][0];
    int smoke = Rocketparts[ent][1];
    Rocketparts[ent][0] = -1;
    Rocketparts[ent][1] = -1;
    
    NukeExplosion( ent );

    SDKUnhook( ent, SDKHook_StartTouch, OnNukeCollide );
    if ( IsValidEntity( entity )) AcceptEntityInput(entity, "kill" );
    if ( IsValidEntity( smoke )) AcceptEntityInput(smoke, "kill" );
    if ( IsValidEntity( ent )) AcceptEntityInput( ent, "kill" );
}

void NukeExplosion( int entity )
{
    float vPos[3];
    GetEntPropVector( entity, Prop_Send, "m_vecOrigin", vPos );
    
    beaPos[0] = vPos[0];
    beaPos[1] = vPos[1];
    beaPos[2] = vPos[2];
    
    iParticle[g_Particle] = CreateEntityByName("info_particle_system");
    if( iParticle[g_Particle] != -1 )
    {
        DispatchKeyValue(iParticle[g_Particle], "effect_name", NUKE_PARTICLE);

        DispatchSpawn(iParticle[g_Particle]);
        ActivateEntity(iParticle[g_Particle]);
        AcceptEntityInput(iParticle[g_Particle], "start");

        TeleportEntity(iParticle[g_Particle], vPos, NULL_VECTOR, NULL_VECTOR);
    }
    
    CreateTimer(30.0, ParticleDel);
    
    float Pos[3];
    char tName[64];
    for (int i = 1; i <= GetEntityCount(); i++)
    {
        if ( !IsValidEntity( i )) continue;
        
        if ( IsValidClient( i ) && GetClientTeam( i ) == 3 )
        {
            Fade(i, 255, 50, 80, 100, 800, 1);
            GetEntPropVector( i, Prop_Send, "m_vecOrigin", Pos );
            if(GetVectorDistance(beaPos, Pos) > GetConVarFloat(g_hNukeRadius)) return;
            CreateTimer(GetVectorDistance(vPos, Pos)/10000.0, ShockWave, i);
        }
        if ( IsValidClient( i ) && GetClientTeam( i ) == 2 )
        {
            Fade(i, 255, 120, 80, 100, 800, 1);
            GetEntPropVector( i, Prop_Send, "m_vecOrigin", Pos );
            if(GetVectorDistance(beaPos, Pos) > GetConVarFloat(g_hNukeRadius)) return;
            CreateTimer(GetVectorDistance(vPos, Pos)/10000.0, ShockWave, i);
        }
        
        else
        {
            GetEntityClassname( i, tName, sizeof( tName ));
            if ( StrEqual( tName, "witch", false))
            {
                GetEntPropVector( i, Prop_Send, "m_vecOrigin", Pos );
                CreateTimer(GetVectorDistance(vPos, Pos)/10000.0, ShockWave, i);
            }
            else if ( StrEqual( tName, "infected", false))
            {
                GetEntPropVector( i, Prop_Send, "m_vecOrigin", Pos );
                CreateTimer(GetVectorDistance(vPos, Pos)/10000.0, ShockWave, i);
            }
            else if ( StrEqual( tName, "prop_physics", false))
            {
                GetEntPropVector( i, Prop_Send, "m_vecOrigin", Pos );
                CreateTimer(GetVectorDistance(vPos, Pos)/10000.0, ShockWave, i);
            }
            else if ( StrEqual( tName, "prop_physics_multiplayer", false))
            {
                GetEntPropVector( i, Prop_Send, "m_vecOrigin", Pos );
                CreateTimer(GetVectorDistance(vPos, Pos)/10000.0, ShockWave, i);
            }
            else if ( StrEqual( tName, "prop_physics_override", false))
            {
                GetEntPropVector( i, Prop_Send, "m_vecOrigin", Pos );
                CreateTimer(GetVectorDistance(vPos, Pos)/10000.0, ShockWave, i);
            }
        }
    }
}

public Action ShockWave( Handle timer, int entity )
{
    char tName[64];
    
    if ( !IsValidEntity( entity )) return Plugin_Continue;
    
    if ( IsValidClient( entity ) && GetClientTeam( entity ) == 3 )
    {
        IgniteEntity(entity, 999.9);
        EmitSoundToClient(entity, NUKE_SOUND);
        ThrowEntity(entity);
        Shake(entity, 32.0);
        switch(GetRandomInt(0, 1))
        {
            case 0: SDKHooks_TakeDamage(entity, 0, 0, GetConVarFloat(g_hNukeDamage), DMG_BURN);
            case 1: SDKHooks_TakeDamage(entity, 0, 0, GetConVarFloat(g_hNukeDamage), DMG_BLAST);
        }
    }
    if ( IsValidClient( entity ) && GetClientTeam( entity ) == 2 )
    {
        EmitSoundToClient(entity, NUKE_SOUND);
        StaggerClient(GetClientUserId(entity), beaPos);
        Shake(entity, 32.0);
    }
    else
    {
        GetEntityClassname( entity, tName, sizeof( tName ));
        if ( StrEqual( tName, "witch", false))
        {
            IgniteEntity(entity, 999.9);
            switch(GetRandomInt(0, 1))
            { 
                case 0: SDKHooks_TakeDamage(entity, 0, 0, GetConVarFloat(g_hNukeDamage), DMG_BURN);
                case 1: SDKHooks_TakeDamage(entity, 0, 0, GetConVarFloat(g_hNukeDamage), DMG_BLAST);
            } 
        }
        else if ( StrEqual( tName, "infected", false))
        {
            IgniteEntity(entity, 999.9);
            switch(GetRandomInt(0, 1))
            { 
                case 0: SDKHooks_TakeDamage(entity, 0, 0, GetConVarFloat(g_hNukeDamage), DMG_BURN);
                case 1: SDKHooks_TakeDamage(entity, 0, 0, GetConVarFloat(g_hNukeDamage), DMG_BLAST);
            } 
        }
        
        else if ( StrEqual( tName, "prop_physics", false))
        {
            IgniteEntity(entity, 999.9);
            ThrowEntity(entity);
        }
        else if ( StrEqual( tName, "prop_physics_multiplayer", false))
        {
            IgniteEntity(entity, 999.9);
            ThrowEntity(entity);
        }
        else if ( StrEqual( tName, "prop_physics_override", false))
        {
            IgniteEntity(entity, 999.9);
            ThrowEntity(entity);
        }
        
    }
    
    return Plugin_Handled;
}

public Action ParticleDel(Handle timer)
{
    int entity = iParticle[g_Particle];
    if(IsValidEntRef(entity))
    {
        AcceptEntityInput(entity, "Kill");
    }
    
    g_Particle = 0;
    iParticle[g_Particle] = 0;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "infected", false))
    {
        RequestFrame(OnInfectedFrame, EntIndexToEntRef(entity));
    }
    if (StrEqual(classname, "witch", false))
    {
        RequestFrame(OnInfectedFrame, EntIndexToEntRef(entity));
    }
}

void OnInfectedFrame(int iEntRef)
{
    if (!IsValidEntRef(iEntRef))
        return;
    
    int particle = iParticle[g_Particle];
    if(!IsValidEntRef(particle))
        return;
    
    int entity = EntRefToEntIndex(iEntRef);
    
    IgniteEntity(entity, 999.9);
    SDKHooks_TakeDamage(entity, 0, 0, GetConVarFloat(g_hNukeDamage), DMG_BURN);
}

void ThrowEntity(int entity)
{
    float Pos[3];
    float qqAA[3];
    float qqDA[3];
    float qqVv[3];
    GetEntPropVector( entity, Prop_Send, "m_vecOrigin", Pos );
    if(GetVectorDistance(beaPos, Pos) > GetConVarFloat(g_hNukeRadius)) return;
    MakeVectorFromPoints(beaPos, Pos, qqAA);
    GetVectorAngles(qqAA, qqDA);
    qqDA[0] = qqDA[0] - 40.0;
    GetAngleVectors(qqDA, qqVv, NULL_VECTOR, NULL_VECTOR);
    NormalizeVector(qqVv, qqVv);
    ScaleVector(qqVv, 1200.0);
    float Angles[3];
    GetEntPropVector( entity, Prop_Data, "m_angRotation", Angles );
    TeleportEntity(entity, NULL_VECTOR, Angles, qqVv);
}

int CreateAttachment( int ent, char[] Model, float ScaleSize, float fwdPos )
{
    float athPos[3];
    float athAng[3];
    float caPos[3] = { 0.0, 0.0, 0.0 };
    GetEntPropVector( ent, Prop_Send, "m_vecOrigin", athPos );
    GetEntPropVector( ent, Prop_Data, "m_angRotation", athAng );
    int attch = CreateEntityByName( "prop_dynamic_override" );
    if( attch != -1 )
    {
        caPos[1] = fwdPos;
        char namE[20];
        Format( namE, sizeof( namE ), "missile%d", ent );
        DispatchKeyValue( ent, "targetname", namE );
        DispatchKeyValue( attch, "model", Model );  
        DispatchKeyValue( attch, "parentname", namE); 
        DispatchKeyValueVector( attch, "origin", athPos );
        DispatchKeyValueVector( attch, "Angles", athAng );
        SetVariantString( namE );
        AcceptEntityInput( attch, "SetParent", ent );
        DispatchKeyValueFloat( attch, "fademindist", 10000.0 );
        DispatchKeyValueFloat( attch, "fademaxdist", 20000.0 );
        DispatchKeyValueFloat( attch, "fadescale", 0.0 ); 
        SetEntPropFloat( attch, Prop_Send,"m_flModelScale", ScaleSize );
        DispatchSpawn( attch );
        TeleportEntity( attch, caPos, NULL_VECTOR, NULL_VECTOR );
    }
    return attch;
}

public bool bTraceEntityFilterPlayer( int entity, int contentsMask )
{
    return ( entity > MaxClients || !entity );
}

public int Fade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
    Handle msg = StartMessageOne("Fade", target);
    BfWriteShort(msg, 500);
    BfWriteShort(msg, duration);
    if (type == 0)
        BfWriteShort(msg, (0x0002 | 0x0008));
    else
        BfWriteShort(msg, (0x0001 | 0x0010));
    BfWriteByte(msg, red);
    BfWriteByte(msg, green);
    BfWriteByte(msg, blue);
    BfWriteByte(msg, alpha);
    EndMessage();
}

public void Shake(int target, float intensity)
{
    Handle msg;
    msg = StartMessageOne("Shake", target);
    
    BfWriteByte(msg, 0);
    BfWriteFloat(msg, intensity);
    BfWriteFloat(msg, 15.0);
    BfWriteFloat(msg, 12.0);
    EndMessage();
}

stock bool IsValidClient(int client) 
{
    return ((1 <= client <= MaxClients) && IsClientInGame(client));
}

stock bool IsValidEntRef(int entity)
{
    if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
        return true;
    return false;
}

void StaggerClient(int iUserID, const float fPos[3])
{
    static int iScriptLogic = INVALID_ENT_REFERENCE;
    if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
    {
        iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
        if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
            LogError("Could not create 'logic_script");

        DispatchSpawn(iScriptLogic);
    }

    char sBuffer[96];
    Format(sBuffer, sizeof(sBuffer), "GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))", iUserID, RoundFloat(fPos[0]), RoundFloat(fPos[1]), RoundFloat(fPos[2]));
    SetVariantString(sBuffer);
    AcceptEntityInput(iScriptLogic, "RunScriptCode");
    RemoveEntity(iScriptLogic);
}

void PrecacheParticle(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;

    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("ParticleEffectNames");
    }

    if (FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX)
    {
        bool save = LockStringTables(false);
        AddToStringTable(table, sEffectName);
        LockStringTables(save);
    }
}

int AttachParticle(int projectile)
{
    float vPos[3], vAng[3];
    GetEntPropVector(projectile, Prop_Data, "m_vecAbsOrigin", vPos);
    GetEntPropVector(projectile, Prop_Data, "m_angRotation", vAng);
        
    int entity = CreateEntityByName("info_particle_system");
    if( entity != -1 )
    {
        DispatchKeyValue(entity, "effect_name", SMOKE_PARTICLE);
        DispatchSpawn(entity);
        ActivateEntity(entity);
        AcceptEntityInput(entity, "start");
        TeleportEntity(entity, vPos, vAng, NULL_VECTOR);

        SetVariantString("!activator");
        AcceptEntityInput(entity, "SetParent", projectile);

        SetVariantString("OnUser3 !self:Kill::10.0:1");
        AcceptEntityInput(entity, "AddOutput");
        AcceptEntityInput(entity, "FireUser3");

        // Refire
        SetVariantString("OnUser1 !self:Stop::0.65:-1");
        AcceptEntityInput(entity, "AddOutput");
        SetVariantString("OnUser1 !self:FireUser2::0.7:-1");
        AcceptEntityInput(entity, "AddOutput");
        AcceptEntityInput(entity, "FireUser1");

        SetVariantString("OnUser2 !self:Start::0:-1");
        AcceptEntityInput(entity, "AddOutput");
        SetVariantString("OnUser2 !self:FireUser1::0:-1");
        AcceptEntityInput(entity, "AddOutput");
    }
    
    return entity;
}