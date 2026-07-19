package com.jakkuazzo.cards;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.os.Handler;
import android.view.Gravity;
import android.widget.TextView;

import com.google.ar.core.ArCoreApk;
import com.google.ar.core.AugmentedImage;
import com.google.ar.core.AugmentedImageDatabase;
import com.google.ar.core.Config;
import com.google.ar.core.Frame;
import com.google.ar.core.Session;

public final class ArTableActivity extends Activity {
    public static final String EXTRA_SURFACE_TITLE = "surface_title";
    private Session session;
    private boolean installRequested;
    private TextView status;
    private String surfaceTitle = "Shared table";
    private final Handler markerHandler = new Handler();
    private final Runnable markerCheck = new Runnable() {
        @Override public void run() {
            if (session == null) return;
            try {
                Frame frame = session.update();
                for (AugmentedImage image : frame.getUpdatedTrackables(AugmentedImage.class)) {
                    if ("cards-table-marker-v1".equals(image.getName())) {
                        status.setText(surfaceTitle + "\n\nShared marker ready. This phone is anchored locally to the same physical 160 mm marker as the other players.\n\nUse the digital Table or Combined view for the live game state.");
                        break;
                    }
                }
            } catch (Exception ignored) {
                // ARCore can briefly reject a frame while the camera is resuming.
            }
            markerHandler.postDelayed(this, 250);
        }
    };

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        surfaceTitle = getIntent().getStringExtra(EXTRA_SURFACE_TITLE);
        if (surfaceTitle == null || surfaceTitle.trim().isEmpty()) surfaceTitle = "Shared table";
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
            if (session == null) {
                session = new Session(this);
                AugmentedImageDatabase markers = new AugmentedImageDatabase(session);
                markers.addImage("cards-table-marker-v1", BitmapFactory.decodeResource(getResources(), R.drawable.cards_table_marker_v1), 0.16f);
                Config configuration = new Config(session);
                configuration.setAugmentedImageDatabase(markers);
                session.configure(configuration);
            }
            session.resume();
            status.setText(surfaceTitle + " AR mode is ready.\n\nFind the printed 160 mm Cards table marker to align this shared surface. The digital Table, Your deck, and Combined views remain available.");
            markerHandler.post(markerCheck);
        } catch (Exception error) {
            status.setText("AR is unavailable on this device.\n\n" + error.getMessage());
        }
    }

    @Override protected void onPause() {
        markerHandler.removeCallbacks(markerCheck);
        if (session != null) session.pause();
        super.onPause();
    }

    @Override protected void onDestroy() {
        markerHandler.removeCallbacks(markerCheck);
        if (session != null) session.close();
        super.onDestroy();
    }
}
