package com.jakkuazzo.cards;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.TextView;

import com.google.ar.core.ArCoreApk;
import com.google.ar.core.Session;

public final class ArTableActivity extends Activity {
    private Session session;
    private boolean installRequested;
    private TextView status;

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        status = new TextView(this);
        status.setGravity(Gravity.CENTER);
        status.setPadding(48, 48, 48, 48);
        status.setTextSize(20);
        status.setTextColor(Color.WHITE);
        status.setBackgroundColor(Color.rgb(8, 10, 16));
        status.setText("Checking ARCore capability…");
        setContentView(status);
    }

    @Override protected void onResume() {
        super.onResume();
        if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[] { Manifest.permission.CAMERA }, 200);
            return;
        }
        try {
            ArCoreApk.InstallStatus install = ArCoreApk.getInstance().requestInstall(this, !installRequested);
            if (install == ArCoreApk.InstallStatus.INSTALL_REQUESTED) {
                installRequested = true;
                status.setText("Install Google Play Services for AR, then return to Cards.");
                return;
            }
            if (session == null) session = new Session(this);
            session.resume();
            status.setText("ARCore session ready.\n\nThe conventional table remains playable while shared-marker surface rendering is completed.");
        } catch (Exception error) {
            status.setText("AR is unavailable on this device.\n\n" + error.getMessage());
        }
    }

    @Override protected void onPause() {
        if (session != null) session.pause();
        super.onPause();
    }

    @Override protected void onDestroy() {
        if (session != null) session.close();
        super.onDestroy();
    }
}

