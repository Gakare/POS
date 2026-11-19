#include <windows.h>
#include <winuser.h>
#include <processthreadsapi.h>

int WINAPI
WinMain(HINSTANCE Instance, HINSTANCE PrevInstance, LPSTR CmdLine, int CmdShow)
{
    STARTUPINFOEXW StartupInfo = {};
    StartupInfo.StartupInfo.cb = sizeof(StartupInfo.StartupInfo);
    
    PROCESS_INFORMATION ProcessInformation = {};
    
    if (CreateProcessW(0, (LPWSTR)CmdLine, 0, 0, 0,
                       DEBUG_ONLY_THIS_PROCESS | CREATE_NEW_CONSOLE,
                       0, 0, &StartupInfo.StartupInfo, &ProcessInformation))
    {
        DEBUG_EVENT DebugEvent = {};
        WaitForDebugEventEx(&DebugEvent, INFINITE);
        while (1)
        {
            switch(DebugEvent.dwDebugEventCode)
            {
                case EXCEPTION_DEBUG_EVENT:
                {
                    OutputDebugStringA("Exception debug event\n");
                } break;
                
                case CREATE_THREAD_DEBUG_EVENT:
                {
                    OutputDebugStringA("Create thread debug event\n");
                } break;
                
                case CREATE_PROCESS_DEBUG_EVENT:
                {
                    OutputDebugStringA("Create process debug event\n");
                } break;
                
                case EXIT_THREAD_DEBUG_EVENT:
                {
                    OutputDebugStringA("Exit thread debug event\n");
                } break;
                
                case EXIT_PROCESS_DEBUG_EVENT:
                {
                    OutputDebugStringA("Exit process debug event\n");
                } break;
                
                case LOAD_DLL_DEBUG_EVENT:
                {
                    OutputDebugStringA("Load dll debug event\n");
                } break;
                
                case UNLOAD_DLL_DEBUG_EVENT:
                {
                    OutputDebugStringA("Unload dll debug event\n");
                } break;
                
                case OUTPUT_DEBUG_STRING_EVENT:
                {
                    OutputDebugStringA("Output debug string event");
                } break;
                
                case RIP_EVENT:
                {
                    OutputDebugStringA("Rip event");
                } break;
                
                default:
                {
                    OutputDebugStringA("Error: Unexpected debug event");
                } break;
            }
            
            if (DebugEvent.dwDebugEventCode == EXIT_PROCESS_DEBUG_EVENT)
            {
                break;
            }
        }
        
        ContinueDebugEvent(DebugEvent.dwProcessId, DebugEvent.dwThreadId, DBG_EXCEPTION_NOT_HANDLED);
    }
    else
    {
        // TODO(Patrick): Logging
        DWORD Error = GetLastError();
    }
    
    return 0;
}