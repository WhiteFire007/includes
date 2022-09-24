#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>
#include <left4dhooks>

#pragma newdecls required
#pragma semicolon 1

float Pos[3];

public void OnPluginStart()
{
    RegAdminCmd("sm_respawn", Cmd_Respawn, ADMFLAG_ROOT);
}

public Action Cmd_Respawn(int client, int args)
{
    if ( args < 1 )
	{
	    if(!IsPlayerAlive(client))
		    CPrintToChat( client, "{blue}[\x04RES{blue}]\x05You \x01are respawned" );
		else
		    RespawnTarget(client, client);
			
		return Plugin_Handled;
	}
	
	char sArgs[MAX_TARGET_LENGTH];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargetList[MAXPLAYERS];
	int  iTargetCount;
	bool bTN_IS_ML;
	
	GetCmdArg( 1, sArgs, sizeof( sArgs ) );
	
	if ( ( iTargetCount = ProcessTargetString( sArgs, client, iTargetList, MAXPLAYERS, 0, sTargetName, sizeof( sTargetName ), bTN_IS_ML ) ) <= 0 )
	{
		ReplyToTargetError( client, iTargetCount );
		return Plugin_Handled;
	}
	
	for ( int i = 0; i < iTargetCount; i ++ )
		if ( IsValidClient( iTargetList[i] ) && !IsPlayerAlive( iTargetList[i] ) )
			RespawnTarget( client, iTargetList[i] );
		else if ( IsValidClient( iTargetList[i] ) )
			CPrintToChat( client, "{blue}[\x04RES{blue}] \x05%N \x01No Need To Respawn", iTargetList[i] );
	
	return Plugin_Handled;
}

void RespawnTarget(int client, int target)
{
    bool bCanTeleport = bSetTeleportEndPoint( client );
	L4D_RespawnPlayer( target );
	GiveItems(target);
	if ( bCanTeleport )
	{
		Pos[2] += 1.0;
	    TeleportEntity( target, Pos, NULL_VECTOR, NULL_VECTOR );
		CPrintToChat(client, "{blue}[\x04RES{blue}]\x05You \x01are respawned: {blue}%N", target);
    }
}

bool bSetTeleportEndPoint( int client )
{
    float vAngles[3];
    float vOrigin[3];
    
    GetClientEyePosition( client,vOrigin );
    GetClientEyeAngles( client, vAngles );
    Handle hTrace = TR_TraceRayFilterEx( vOrigin, vAngles, MASK_SHOT, RayType_Infinite, bTraceEntityFilterPlayer );
    
    if ( TR_DidHit( hTrace ) )
    {
        float vBuffer[3];
        float vStart[3];
        float vDistance = -35.0;
        
        TR_GetEndPosition( vStart, hTrace );
        GetVectorDistance( vOrigin, vStart, false );
        GetAngleVectors( vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR );
        
        Pos[0] = vStart[0] + ( vBuffer[0] * vDistance );
        Pos[1] = vStart[1] + ( vBuffer[1] * vDistance );
        Pos[2] = vStart[2] + ( vBuffer[2] * vDistance );
    }
    
    delete hTrace;
    return true;
}

stock bool IsValidClient(int client)
{
    return (1 <= client <= MaxClients && IsClientInGame(client));
}

stock bool IsValidSurvivor(int client)
{
    return (1 <= client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

public bool bTraceEntityFilterPlayer( int entity, int contentsMask )
{
    return ( entity > MaxClients || !entity );
}

void GiveItems(int client)
{
    if(IsValidSurvivor(client))
	{
	    int Flags = GetCommandFlags( "give" );
        SetCommandFlags("give", Flags & ~FCVAR_CHEAT );
    
        FakeClientCommand(client, "give rifle" );
        FakeClientCommand(client, "give fireaxe" );
        FakeClientCommand(client, "give pain_pills" );
        FakeClientCommand(client, "give first_aid_kit" );
        FakeClientCommand(client, "give pipe_bomb" );
        FakeClientCommand(client, "upgrade_add LASER_SIGHT");
    
        SetCommandFlags( "give", Flags|FCVAR_CHEAT ); 
	}
}