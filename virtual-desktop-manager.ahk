#Requires AutoHotkey v2.0
#UseHook

; ======================================================================
; virtual-desktop-manager.ahk
; (https://github.com/Dovias)
;
; Below is an example configuration section. Feel free to bind your
; hotkeys and functions through simple AutoHotkey v2 syntax.
; ======================================================================

#q::GracefullyCloseWindow(GetFocusedWindow())
#e::ToggleWindowPinnedState(GetFocusedWindow())
#w::WinSetAlwaysOnTop(-1, GetFocusedWindow())
#f::ToggleWindowMaximizedState(GetFocusedWindow())

#a::SwitchToDesktop(1)
#s::SwitchToDesktop(2)
#d::SwitchToDesktop(3)
#x::ToggleIntoDesktop(4)

#+e::ToggleApplicationPinnedState(GetFocusedWindow())
#+a::ActivateAndMoveWindowToSwitchedDesktop(GetFocusedWindow(), 1)
#+s::ActivateAndMoveWindowToSwitchedDesktop(GetFocusedWindow(), 2)
#+d::ActivateAndMoveWindowToSwitchedDesktop(GetFocusedWindow(), 3)
#+x::ActivateAndMoveWindowToToggledDesktop(GetFocusedWindow(), 4)

ActivateAndMoveWindowToSwitchedDesktop(window, desktop) {
    if (!WinExist(window)) {
        return
    }

    _ActivateAndMoveWindowToSwitchedDesktop(window, desktop)
}

ActivateAndMoveWindowToToggledDesktop(window, desktop) {
    if (!WinExist(window)) {
        return
    }

    ActivateAndMoveWindowToDesktop(window, desktop)
    ToggleIntoDesktop(desktop)
    WinActivate(window)
}

ActivateMaximizeAndMoveWindowToSwitchedDesktop(window, desktop) {
    ActivateAndMoveWindowToSwitchedDesktop(window, desktop)
    TryToMaximizeWindow(window)
}

desktops := {
    1: [
        ; Open all file explorer windows in first virtual desktop except for legacy control panel
        {
            process: "explorer.exe",
            title: "^(?!Control Panel$).*$",
        },

        {
            process: "WindowsTerminal.exe|cmd.exe|powershell.exe|pwsh.exe"
        }
    ],
    2: [
        {
            process: "Vesktop.exe",
            action: ActivateMaximizeAndMoveWindowToSwitchedDesktop
         }
    ],
    3: [
        {
            process: "chrome.exe",
            action: ActivateMaximizeAndMoveWindowToSwitchedDesktop
                
        }
    ]
}


; ======================================================================
; Implementation logic.
; Do not change, unless you know what you are doing!
; ======================================================================

A_MenuMaskKey := "vk07"

GetFocusedWindow() {
    return WinExist("A")
}

GracefullyCloseWindow(window) {
    if (!WinExist(window)) {
        return
    }

    ; We need to send window message instead of closing it via WinClose(window) because we need to
    ; make sure that application windows it gracefully (as if user clicked window close button)
    ;
    ; Magic values:
    ; 0x0112: WM_SYSCOMMAND
    ; 0xF060: SC_CLOSE
    PostMessage(0x0112, 0xF060,,, window)
}

IsAlwaysOnTop(window) {
    ; Check if window is always on top of the window stack
    ;
    ; Magic values:
    ; 0x8: WS_EX_TOPMOST
    return WinGetExStyle(window) & 0x8
}

; Wraps `WinMaximize` function in a way that it would not to try to maximize window which does not
; exist or is already maximized.
;
; Some applications remember their previous window state, for example "File Explorer".
; This function prevents unnecessary state restoring that AutoHotkey does to remaximize window
; with `WinMaximize` function.
TryToMaximizeWindow(window) {
    if (WinExist(window) and !WinGetMinMax(window)) {
        WinMaximize(window)
    }
}


ToggleWindowMaximizedState(window) {
    if (!WinExist(window)) {
        return
    }

    if (WinGetMinMax(window)) {
        WinRestore(window)
    } else {
        WinMaximize(window)
    }
}

global previous := 0
ToggleIntoDesktop(desktop) {
    global previous
    if (previous != 0) {
        SwitchToDesktop(previous)
    } else {
        previous := GetCurrentDesktopNumber()
        _SwitchToDesktop(desktop)
    }
}

ToggleApplicationPinnedState(window) {
    if (!WinExist(window)) {
        return
    }

    return IsApplicationPinned(window) ? !UnpinApplication(Window) : PinApplication(window)
}

ToggleWindowPinnedState(window) {
    if (!WinExist(window)) {
        return
    }

    return IsWindowPinned(window) ? !UnpinWindow(window) : PinWindow(window)
}


GetVirtualDesktopFunctionAddress(name) {
    static address := DllCall("LoadLibrary", "Str", "VirtualDesktopAccessor.dll", "Ptr")
    return DllCall("GetProcAddress", "Ptr", address, "AStr", name, "Ptr")
}

GetDesktopCount() {
    static address := GetVirtualDesktopFunctionAddress("GetDesktopCount")
    return DllCall(address, "Int")
}

GetCurrentDesktopNumber() {
    static address := GetVirtualDesktopFunctionAddress("GetCurrentDesktopNumber")
    return DllCall(address, "Int") + 1
}

PinApplication(window) {
    static address := GetVirtualDesktopFunctionAddress("PinApp")
    return DllCall(address, "UInt", window, "Int")
}

PinWindow(window) {
    static address := GetVirtualDesktopFunctionAddress("PinWindow")
    return DllCall(address, "UInt", window, "Int")
}

UnpinApplication(window) {
    static address := GetVirtualDesktopFunctionAddress("UnpinApp")
    return DllCall(address, "UInt", window, "Int")
}

UnpinWindow(window) {
    static address := GetVirtualDesktopFunctionAddress("UnPinWindow")
    return DllCall(address, "UInt", window, "Int")
}

IsApplicationPinned(window) {
    static address := GetVirtualDesktopFunctionAddress("IsPinnedApp")
    return DllCall(address, "UInt", window, "Int")
}

IsWindowPinned(window) {
    static address := GetVirtualDesktopFunctionAddress("IsPinnedWindow")
    return DllCall(address, "UInt", window, "Int")
}

_RegisterWindowMessage(message) {
    return DllCall("RegisterWindowMessage", "Str", message, "UInt")
}

_SwitchToDesktop(desktop) {
    static address := GetVirtualDesktopFunctionAddress("GoToDesktopNumber")
    return DllCall(address, "Int", desktop - 1, "Int")
}

SwitchToDesktop(desktop) {
    if (desktop == GetCurrentDesktopNumber()) {
        return
    }
    ; Reset previous desktop if we switched the desktop directly
    ; 
    ; This is needed to reset the toggled desktop state if we
    ; did not called toggle function prior calling this function
    global previous := 0
    _SwitchToDesktop(desktop)
}


ValueMatchesRuleProperty(value, rule, property) {
    return !HasProp(rule, property) or RegExMatch(value, rule.%property%)
}

WindowMatchesRule(window, rule) {
    try
        return ValueMatchesRuleProperty(WinGetProcessName(window), rule, "process") and
               ValueMatchesRuleProperty(WinGetClass(window), rule, "class") and
               ValueMatchesRuleProperty(WinGetTitle(window), rule, "title")
    catch
        return false
}


ActivateAndMoveWindowToDesktop(window, desktop) {
    static address := GetVirtualDesktopFunctionAddress("MoveWindowToDesktopNumber")
    return DllCall(address, "UInt", window, "UInt", desktop - 1, "Int")
}


_ActivateAndMoveWindowToSwitchedDesktop(window, desktop) {
    SwitchToDesktop(desktop)
    ActivateAndMoveWindowToDesktop(window, desktop)
    WinActivate(window)
}

DllCall("RegisterShellHookWindow", "UInt", A_ScriptHwnd)
OnMessage(DllCall("RegisterWindowMessage", "Str", "SHELLHOOK", "UInt"), _OnWindowCreate)
_OnWindowCreate(flag, window, *) {
    ; Check if callback is being called when window is being created:
    ;
    ; Magic values:
    ; 0x01: HSHELL_WINDOWCREATED 
    if (flag != 0x01) {
        return
    }

    for desktop, rules in desktops.OwnProps() {
        for rule in rules {
            if (!WindowMatchesRule(window, rule)) {
                continue
            }

            WinWait(window)
            action := HasProp(rule, "action") ? rule.action : _ActivateAndMoveWindowToSwitchedDesktop
            action.Call(window, desktop)
        }
    }
}
