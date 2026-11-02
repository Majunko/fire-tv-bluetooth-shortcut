package com.majunko.btshortcut;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;
import android.provider.Settings;

/**
 * Zero-UI shortcut: launches the Fire TV "Controllers & Bluetooth Devices"
 * settings page and finishes immediately (Theme.NoDisplay, nothing is drawn).
 */
public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // 1) Fire OS "Other Bluetooth Devices" list: paired devices, press
        //    SELECT to connect. This is what the shortcut should open.
        if (!tryStart(new Intent("com.amazon.device.settings.action.INPUT_DEVICES"))
                // 2) Explicit component (Fire OS 8), opens the same activity.
                && !tryStart(new Intent().setComponent(new ComponentName(
                        "com.amazon.tv.settings.v2",
                        "com.amazon.tv.settings.v2.tv.controllers_bluetooth_devices.ControllersAndBluetoothActivity")))
                // 3) Parent "Controllers & Bluetooth Devices" page as last resort.
                && !tryStart(new Intent("com.amazon.device.settings.action.HURLEY"))
                // 3) Generic Android Bluetooth settings, just in case.
                && !tryStart(new Intent(Settings.ACTION_BLUETOOTH_SETTINGS))) {
            // nothing worked, just close silently
        }

        finish();
    }

    private boolean tryStart(Intent intent) {
        try {
            intent.addCategory(Intent.CATEGORY_DEFAULT);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
