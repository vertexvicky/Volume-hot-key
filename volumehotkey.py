import keyboard 
import ctypes 
import time 
 
VK_VOLUME_MUTE = 0xAD 
VK_VOLUME_DOWN = 0xAE 
VK_VOLUME_UP = 0xAF 
 
def press_key(vk_code, times=2, delay_after=0): 
    for _ in range(times): 
        ctypes.windll.user32.keybd_event(vk_code, 0, 0, 0) 
        ctypes.windll.user32.keybd_event(vk_code, 0, 2, 0) 
        time.sleep(0.05) 
 
    if delay_after > 0: 
        time.sleep(delay_after) 
 
keyboard.add_hotkey("win+page up", lambda: press_key(VK_VOLUME_UP, 2)) 
keyboard.add_hotkey("win+page down", lambda: press_key(VK_VOLUME_DOWN, 2)) 
keyboard.add_hotkey("win+end", lambda: press_key(VK_VOLUME_MUTE, 1, 0.5)) 
keyboard.wait() 
