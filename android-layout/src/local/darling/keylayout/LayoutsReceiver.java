package local.darling.keylayout;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public final class LayoutsReceiver extends BroadcastReceiver {
    @Override public void onReceive(Context context, Intent intent) {
        // The system reads the keyboard-layout metadata; no background work is needed.
    }
}
