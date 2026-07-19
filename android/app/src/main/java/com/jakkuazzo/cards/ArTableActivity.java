package com.jakkuazzo.cards;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.opengl.GLSurfaceView;
import android.os.Bundle;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.TextView;

import com.google.ar.core.ArCoreApk;
import com.google.ar.core.AugmentedImageDatabase;
import com.google.ar.core.Config;
import com.google.ar.core.Session;

/** Camera-backed AR table: place a digital table ahead or on any scanned surface. */
public final class ArTableActivity extends Activity {
    public static final String EXTRA_SURFACE_TITLE = "surface_title";
    private Session session;
    private boolean installRequested;
    private TextView status;
    private GLSurfaceView surface;
    private ArTableRenderer renderer;
    private String surfaceTitle = "Shared table";

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        surfaceTitle = getIntent().getStringExtra(EXTRA_SURFACE_TITLE);
        if (surfaceTitle == null || surfaceTitle.trim().isEmpty()) surfaceTitle = "Shared table";
        buildContent();
    }

    private void buildContent() {
        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.rgb(8, 10, 16));
        surface = new GLSurfaceView(this);
        surface.setEGLContextClientVersion(2);
        renderer = new ArTableRenderer(this, this::setStatus);
        surface.setRenderer(renderer);
        surface.setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
        surface.setOnTouchListener((view, event) -> {
            if (event.getAction() == MotionEvent.ACTION_UP) renderer.requestPlacement(event.getX(), event.getY());
            return true;
        });
        root.addView(surface, new FrameLayout.LayoutParams(-1, -1));

        status = new TextView(this);
        status.setGravity(Gravity.CENTER);
        status.setPadding(dp(16), dp(12), dp(16), dp(12));
        status.setTextSize(14);
        status.setTextColor(Color.WHITE);
        status.setBackgroundColor(0xC010131D);
        FrameLayout.LayoutParams statusParams = new FrameLayout.LayoutParams(-1, -2, Gravity.TOP);
        statusParams.setMargins(dp(12), dp(18), dp(12), 0);
        root.addView(status, statusParams);

        Button placeAhead = new Button(this);
        placeAhead.setText("Place table ahead");
        placeAhead.setAllCaps(false);
        placeAhead.setOnClickListener(view -> renderer.requestPlacementAhead());
        FrameLayout.LayoutParams buttonParams = new FrameLayout.LayoutParams(-1, -2, Gravity.BOTTOM);
        buttonParams.setMargins(dp(24), 0, dp(24), dp(28));
        root.addView(placeAhead, buttonParams);
        setContentView(root);
        setStatus("Checking ARCore…");
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
                setStatus("Install Google Play Services for AR, then return to Cards.");
                return;
            }
            if (session == null) {
                session = new Session(this);
                AugmentedImageDatabase markers = new AugmentedImageDatabase(session);
                markers.addImage("cards-table-marker-v1", BitmapFactory.decodeResource(getResources(), R.drawable.cards_table_marker_v1), 0.16f);
                Config configuration = new Config(session);
                configuration.setPlaneFindingMode(Config.PlaneFindingMode.HORIZONTAL);
                configuration.setAugmentedImageDatabase(markers);
                session.configure(configuration);
            }
            renderer.setSession(session);
            session.resume();
            surface.onResume();
            setStatus(surfaceTitle + ": tap a scanned horizontal surface, or use Place table ahead. The printed marker is optional shared alignment.");
        } catch (Exception error) {
            setStatus("AR is unavailable on this device. Use the normal Table, Your deck, or Combined screen instead.\n\n" + error.getMessage());
        }
    }

    @Override protected void onPause() {
        if (surface != null) surface.onPause();
        if (session != null) session.pause();
        super.onPause();
    }

    @Override protected void onDestroy() {
        if (renderer != null) renderer.clearSession();
        if (session != null) session.close();
        super.onDestroy();
    }

    private void setStatus(String value) { runOnUiThread(() -> status.setText(value)); }
    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }
}
