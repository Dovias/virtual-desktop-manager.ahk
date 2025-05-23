# 🗂️ virtual-desktop-manager.ahk
Simple AutoHotkey v2 script which allows you to have fine grain control of Windows 10/11 virtual desktops.

## Features 
- Bindable switching between virtual desktops
```ahk
#a::SwitchToDesktop(1)
```
![chrome_tFTwkk16hM](https://github.com/user-attachments/assets/e5459704-790a-4ab2-a2bf-8e6338ed5dbb)
- Bindable toggling between virtual desktops
```ahk
#x::ToggleIntoDesktop(4)
```
![chrome_oU2SnhAIV5](https://github.com/user-attachments/assets/cfeeb3c9-ec84-4826-8e3c-4c97646bc797)

- Bindable movement of windows to specific virtual desktops
```ahk
#+a::SwitchToDesktop(1) and MoveWindowToDesktop() and FocusWindow()
```
![explorer_qNFcuCmEf4](https://github.com/user-attachments/assets/8d8d1710-6c22-4ff3-929b-890a6ea91847)

- Bindable window pinning which can be visible across all virtual desktops
```ahk
#e::ToggleWindowPinnedState()
#+e::ToggleApplicationPinnedState()
```
![explorer_IC2mWCf6VT](https://github.com/user-attachments/assets/96c8fd60-b18c-4a08-85fd-d5c32a25048c)

- Bindable fullscreen window toggle
```ahk
#f::ToggleWindowMaximizedState()
```
![explorer_iZnQR7zqyt](https://github.com/user-attachments/assets/067cf8ca-65d1-4b64-a6f6-acf0275c9f31)
- Bindable graceful close window toggle (Acts if close button was pressed and not like ALT+F4)
```ahk
#q::GracefullyCloseWindow()
```
![explorer_1kF7TINDwm](https://github.com/user-attachments/assets/912ab2bb-817a-4c31-b2a8-402f6739ba73)
- Bindable always on top window toggle
```ahk
#w::ToggleWindowAlwaysOnTopState()
```
![explorer_RLA3URX3hB](https://github.com/user-attachments/assets/b3099b18-8ec5-456e-a6b1-09054851d1e0)
- Window rules which allow you define how the application needs to be placed in specific virtual desktops during window creation phase
```ahk
desktops := {
    1: [
        ; Open all file explorer windows in first virtual desktop except for legacy control panel
        {
            process: "^explorer\.exe$",
            title: "^(?!Control Panel(?:\\[^\\]+)*$).*$",
            class: "^CabinetWClass$"
        },
        {
            process: "^(?:WindowsTerminal|cmd|powershell|pwsh|devenv|idea64|Code|VSCodium|7zFM|WinRAR)\.(?i)exe$"
        }
    ],
    2: [
        {
            process: "^(?:Discord|Vesktop)\.(?i)exe$",
            action: (window, desktop) => SwitchToDesktop(desktop) and MoveWindowToDesktop(window) and MaximizeWindow() and FocusWindow()
         }
    ],
    3: [
        {
            process: "^(?:chrome|brave|vivaldi|opera|firefox|librewolf|floorp)\.(?i)exe$",
            action: (window, desktop) => SwitchToDesktop(desktop) and MoveWindowToDesktop(window) and MaximizeWindow() and FocusWindow()
                
        }
    ],
    4: [
        {
            process: "^(?:WINWORD|POWERPNT|EXCEL|soffice|sbase|scalc|sdraw|simpress|smath|swriter)\.(?i)exe$"
        }
    ]
}
```
![explorer_kbbDWNSTMA](https://github.com/user-attachments/assets/4f5a889b-8179-4c89-b755-ef64bb361041)

## Installation
> [!CAUTION]  
> This project is relying upon Microsoft Windows undocumented Virtual Desktop API. Note that this API is prone to break over updates and is not completely stable.

- Download and install [AutoHotkey v2](https://www.autohotkey.com/download/ahk-v2.exe) which is needed for this script to be run.
- Download [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor/releases) library that's suited for your operating system version and build.
> [!NOTE]  
> **VirtualDesktopAccessor does not support every single build of Windows 10 and 11.** Due to how much time it takes to reverse-engineer undocumented Windows API's, It might take some time for the version dedicated to your operating system to show up. Be patient.
- Download [virtual-desktop-manager.ahk](https://github.com/Dovias/virtual-desktop-manager.ahk/blob/main/virtual-desktop-manager.ahk) from this repository.
- Put downloaded `VirtualDesktopAccessor.dll` and `virtual-desktop-manager.ahk` under a single folder.
- Tweak `virtual-desktop-manager.ahk` script by adjusting keybinds to existing virtual desktops on the computer.
- Run `virtual-desktop-manager.ahk` by just double clicking the file and you are good to go!

## Optional recommendations
- Install [ExplorerTabUtility](https://github.com/w4po/ExplorerTabUtility)  (Windows 11 only) to automatically nest the file explorer tabs under one file explorer window instance.
- Install [AltSnap](https://github.com/RamonUnch/AltSnap) in order to have an ability to drag and resize windows using `Alt` or `Windows` key.
- Launching this script via administrator privileges will allow to handle applications which were launched using administrator privileges. 
- Use Task Scheduler to create a task which launches this script at startup, or add this script to `%appdata%\Roaming\Microsoft\Windows\Start Menu\Programs\Startup`.

## Known issues
### Taskbar sometimes flashing when switching between virtual desktops
This is a known issue with Virtual Desktop API that's being exposed via `VirtualDesktopAccessor.dll` library. Check out [this](https://github.com/Ciantic/VirtualDesktopAccessor/issues/101) issue on GitHub for workarounds and the progress of this problem.

## Contributing
Contributions are welcome! Feel free to submit issues and pull requests.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
