﻿#Requires AutoHotkey v2.0
#UseHook

; ======================================================================
; virtual-desktop-manager.ahk
; (https://github.com/Dovias/virtual-desktop-manager.ahk)
;
; Below is an example configuration section. Feel free to bind your
; hotkeys and functions through simple AutoHotkey v2 syntax.
; ======================================================================

#a::SwitchToDesktop(1)
#+a::SwitchToDesktop(1) and MoveWindowToDesktop() and FocusWindow()

#s::SwitchToDesktop(2)
#+s::SwitchToDesktop(2) and MoveWindowToDesktop() and FocusWindow()

#d::SwitchToDesktop(3)
#+d::SwitchToDesktop(3) and MoveWindowToDesktop() and FocusWindow()

#x::ToggleIntoDesktop(4)
#+x::ToggleIntoDesktop(4) and MoveWindowToDesktop() and FocusWindow()

#e::ToggleWindowPinnedState()
#+e::ToggleApplicationPinnedState()
#w::ToggleWindowAlwaysOnTopState()
#f::ToggleWindowMaximizedState()

#q::GracefullyCloseWindow()

desktops := {
    1: [
        ; Open all file explorer windows in first virtual desktop except for legacy control panel
        {
            process: "explorer",
            title: "^(?!Control Panel(?:\\[^\\]+)*$).*$",
            class: "CabinetWClass"
        },
        {
            process: "WindowsTerminal|cmd|powershell|pwsh|7zFM|WinRAR"
        }
    ],
    2: [
        {
            process: "Discord|Vesktop",
            action: (window, desktop) => SwitchToDesktop(desktop) and MoveWindowToDesktop(window) and MaximizeWindow() and FocusWindow()
         }
    ],
    3: [
        {
            process: "chrome|brave|vivaldi|opera|firefox|librewolf|floorp",
            action: (window, desktop) => SwitchToDesktop(desktop) and MoveWindowToDesktop(window) and MaximizeWindow() and FocusWindow()
                
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

FocusWindow(window := focused) {
    if (!WinExist(window)) {
        return false
    }

    WinActivate(window)
    return true
}


GracefullyCloseWindow(window := GetFocusedWindow()) {
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

IsWindowAlwaysOnTop(window) {
    ; Check if window is always on top of the window stack
    ;
    ; Magic values:
    ; 0x8: WS_EX_TOPMOST
    return WinGetExStyle(window) & 0x8
}

; Wraps `WinMaximize` function in a way that it would not to try to maximize window which does not
; exist or is already maximized.
;
; Some applications remember their toggled window state, for example "File Explorer".
; This function prevents unnecessary state restoring that AutoHotkey does to remaximize window
; with `WinMaximize` function.
MaximizeWindow(window := GetFocusedWindow()) {
    if (WinExist(window) and !WinGetMinMax(window)) {
        WinMaximize(window)
    }
}


ToggleWindowMaximizedState(window := GetFocusedWindow()) {
    if (!WinExist(window)) {
        return
    }

    if (WinGetMinMax(window)) {
        WinRestore(window)
    } else {
        WinMaximize(window)
    }
}

global toggled := 0
ToggleIntoDesktop(desktop) {
    global toggled
    if (toggled != 0) {
        desktop := toggled
        toggled := 0
    } else {
        toggled := GetCurrentDesktopNumber()
    }

    global focused := GetFocusedWindow()
    _SwitchToDesktop(desktop)
    return desktop
}

ToggleApplicationPinnedState(window := GetFocusedWindow()) {
    return IsApplicationPinned(window) ? !UnpinApplication(Window) : PinApplication(window)
}

ToggleWindowPinnedState(window := GetFocusedWindow()) {
    return IsWindowPinned(window) ? !UnpinWindow(window) : PinWindow(window)
}

ToggleWindowAlwaysOnTopState(window := GetFocusedWindow()) {
    return WinSetAlwaysOnTop(-1, window)
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
    static address := GetVirtualDesktopFunctionAddress("UnPinApp")
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
    DllCall(address, "Int", desktop - 1)
}

SwitchToDesktop(desktop) {
    current := GetCurrentDesktopNumber()
    if (desktop == current) {
        return false
    }
    ; Reset toggled desktop if we switched the desktop directly
    ; 
    ; This is needed to reset the toggled desktop state if we
    ; did not called toggle function prior calling this function
    global toggled := 0
    global focused := GetFocusedWindow()
    _SwitchToDesktop(desktop)
    return true
}

MoveWindowToDesktop(window := focused, desktop := GetCurrentDesktopNumber()) {
    static address := GetVirtualDesktopFunctionAddress("MoveWindowToDesktopNumber")
    return DllCall(address, "UInt", window, "UInt", desktop - 1, "Int") > 0
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
            action := HasProp(rule, "action") ? rule.action : (window, desktop) => SwitchToDesktop(desktop) and MoveWindowToDesktop(window) and FocusWindow()
            action.Call(window, desktop)
        }
    }
}
