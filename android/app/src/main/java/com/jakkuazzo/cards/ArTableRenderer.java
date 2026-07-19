package com.jakkuazzo.cards;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.opengl.Matrix;
import android.view.Surface;
import android.view.WindowManager;

import com.google.ar.core.Anchor;
import com.google.ar.core.AugmentedImage;
import com.google.ar.core.Camera;
import com.google.ar.core.Coordinates2d;
import com.google.ar.core.Frame;
import com.google.ar.core.HitResult;
import com.google.ar.core.Plane;
import com.google.ar.core.Pose;
import com.google.ar.core.Session;
import com.google.ar.core.TrackingState;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;
import java.util.List;

/** Draws ARCore's camera stream and one small horizontal Cards table. */
final class ArTableRenderer implements GLSurfaceView.Renderer {
    interface Listener { void onStatus(String value); }

    private static final float[] SCREEN = {-1, -1, 1, -1, -1, 1, 1, 1};
    private static final float[] TABLE = {-0.31f, 0, -0.21f, 0.31f, 0, -0.21f, -0.31f, 0, 0.21f, 0.31f, 0, 0.21f};
    private final Context context;
    private final Listener listener;
    private final FloatBuffer screen = floats(SCREEN);
    private final FloatBuffer texture = floats(new float[8]);
    private final FloatBuffer table = floats(TABLE);
    private final float[] projection = new float[16];
    private final float[] view = new float[16];
    private final float[] model = new float[16];
    private final float[] mvp = new float[16];
    private volatile Session session;
    private int cameraProgram;
    private int tableProgram;
    private int cameraTexture;
    private int width;
    private int height;
    private Anchor tableAnchor;
    private float requestedX = Float.NaN;
    private float requestedY = Float.NaN;
    private boolean placeAhead;
    private boolean markerReported;

    ArTableRenderer(Context context, Listener listener) { this.context = context; this.listener = listener; }

    void setSession(Session session) { this.session = session; }
    void clearSession() { this.session = null; }
    void requestPlacement(float x, float y) { requestedX = x; requestedY = y; }
    void requestPlacementAhead() { placeAhead = true; }

    @Override public void onSurfaceCreated(javax.microedition.khronos.opengles.GL10 ignored, javax.microedition.khronos.egl.EGLConfig config) {
        cameraProgram = program(CAMERA_VERTEX, CAMERA_FRAGMENT);
        tableProgram = program(TABLE_VERTEX, TABLE_FRAGMENT);
        int[] textures = new int[1];
        GLES20.glGenTextures(1, textures, 0);
        cameraTexture = textures[0];
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTexture);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR);
        GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR);
    }

    @Override public void onSurfaceChanged(javax.microedition.khronos.opengles.GL10 ignored, int width, int height) {
        this.width = width; this.height = height;
        GLES20.glViewport(0, 0, width, height);
        configureDisplayGeometry();
    }

    @Override public void onDrawFrame(javax.microedition.khronos.opengles.GL10 ignored) {
        Session active = session;
        if (active == null || width == 0 || height == 0) return;
        try {
            active.setCameraTextureName(cameraTexture);
            configureDisplayGeometry();
            Frame frame = active.update();
            drawCamera(frame);
            Camera camera = frame.getCamera();
            if (camera.getTrackingState() != TrackingState.TRACKING) return;
            processPlacement(frame, camera, active);
            processMarker(frame);
            drawTable(camera);
        } catch (Exception ignoredError) {
            // Resume/installation may invalidate a frame briefly; ARCore recovers next frame.
        }
    }

    private void processPlacement(Frame frame, Camera camera, Session active) {
        if (!Float.isNaN(requestedX) && !Float.isNaN(requestedY)) {
            float x = requestedX, y = requestedY;
            requestedX = Float.NaN; requestedY = Float.NaN;
            List<HitResult> hits = frame.hitTest(x, y);
            for (HitResult hit : hits) {
                if (hit.getTrackable() instanceof Plane && ((Plane) hit.getTrackable()).isPoseInPolygon(hit.getHitPose())) {
                    replaceAnchor(hit.createAnchor());
                    listener.onStatus("Table placed on this surface. Tap another surface to move it.");
                    return;
                }
            }
            listener.onStatus("No horizontal surface there yet. Move the phone slowly and try again.");
        }
        if (placeAhead) {
            placeAhead = false;
            float[] point = camera.getPose().transformPoint(new float[] {0, -0.24f, -0.72f});
            replaceAnchor(active.createAnchor(Pose.makeTranslation(point)));
            listener.onStatus("Table placed in front of you. Tap a real surface to lock it in place.");
        }
    }

    private void processMarker(Frame frame) {
        for (AugmentedImage image : frame.getUpdatedTrackables(AugmentedImage.class)) {
            if ("cards-table-marker-v1".equals(image.getName()) && image.getTrackingState() == TrackingState.TRACKING && !markerReported) {
                markerReported = true;
                listener.onStatus("Shared marker ready. Each phone uses this physical print as its own local AR origin.");
            }
        }
    }

    private void drawCamera(Frame frame) {
        screen.position(0); texture.position(0);
        frame.transformCoordinates2d(Coordinates2d.OPENGL_NORMALIZED_DEVICE_COORDINATES, screen, Coordinates2d.TEXTURE_NORMALIZED, texture);
        screen.position(0); texture.position(0);
        GLES20.glDisable(GLES20.GL_DEPTH_TEST);
        GLES20.glUseProgram(cameraProgram);
        int position = GLES20.glGetAttribLocation(cameraProgram, "aPosition");
        int coordinate = GLES20.glGetAttribLocation(cameraProgram, "aTexCoord");
        GLES20.glEnableVertexAttribArray(position);
        GLES20.glVertexAttribPointer(position, 2, GLES20.GL_FLOAT, false, 0, screen);
        GLES20.glEnableVertexAttribArray(coordinate);
        GLES20.glVertexAttribPointer(coordinate, 2, GLES20.GL_FLOAT, false, 0, texture);
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTexture);
        GLES20.glUniform1i(GLES20.glGetUniformLocation(cameraProgram, "uTexture"), 0);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        GLES20.glDisableVertexAttribArray(position);
        GLES20.glDisableVertexAttribArray(coordinate);
    }

    private void drawTable(Camera camera) {
        if (tableAnchor == null || tableAnchor.getTrackingState() != TrackingState.TRACKING) return;
        tableAnchor.getPose().toMatrix(model, 0);
        camera.getProjectionMatrix(projection, 0, 0.05f, 20f);
        camera.getViewMatrix(view, 0);
        Matrix.multiplyMM(mvp, 0, projection, 0, view, 0, model, 0);
        GLES20.glEnable(GLES20.GL_DEPTH_TEST);
        GLES20.glEnable(GLES20.GL_BLEND);
        GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA);
        GLES20.glUseProgram(tableProgram);
        int position = GLES20.glGetAttribLocation(tableProgram, "aPosition");
        GLES20.glEnableVertexAttribArray(position);
        GLES20.glVertexAttribPointer(position, 3, GLES20.GL_FLOAT, false, 0, table);
        GLES20.glUniformMatrix4fv(GLES20.glGetUniformLocation(tableProgram, "uMvp"), 1, false, mvp, 0);
        GLES20.glUniform4f(GLES20.glGetUniformLocation(tableProgram, "uColor"), 0.06f, 0.42f, 0.25f, 0.88f);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        GLES20.glDisableVertexAttribArray(position);
        GLES20.glDisable(GLES20.GL_BLEND);
    }

    private void replaceAnchor(Anchor anchor) { if (tableAnchor != null) tableAnchor.detach(); tableAnchor = anchor; }
    private void configureDisplayGeometry() {
        Session active = session;
        if (active == null || width == 0 || height == 0) return;
        int rotation = ((WindowManager) context.getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay().getRotation();
        active.setDisplayGeometry(rotation, width, height);
    }
    private static FloatBuffer floats(float[] values) { return ByteBuffer.allocateDirect(values.length * 4).order(ByteOrder.nativeOrder()).asFloatBuffer().put(values).position(0); }
    private static int program(String vertex, String fragment) {
        int vertexShader = shader(GLES20.GL_VERTEX_SHADER, vertex), fragmentShader = shader(GLES20.GL_FRAGMENT_SHADER, fragment);
        int program = GLES20.glCreateProgram(); GLES20.glAttachShader(program, vertexShader); GLES20.glAttachShader(program, fragmentShader); GLES20.glLinkProgram(program); return program;
    }
    private static int shader(int type, String source) { int shader = GLES20.glCreateShader(type); GLES20.glShaderSource(shader, source); GLES20.glCompileShader(shader); return shader; }

    private static final String CAMERA_VERTEX = "attribute vec2 aPosition; attribute vec2 aTexCoord; varying vec2 vTexCoord; void main(){ gl_Position=vec4(aPosition,0.0,1.0); vTexCoord=aTexCoord; }";
    private static final String CAMERA_FRAGMENT = "#extension GL_OES_EGL_image_external : require\nprecision mediump float; varying vec2 vTexCoord; uniform samplerExternalOES uTexture; void main(){ gl_FragColor=texture2D(uTexture,vTexCoord); }";
    private static final String TABLE_VERTEX = "attribute vec3 aPosition; uniform mat4 uMvp; void main(){ gl_Position=uMvp*vec4(aPosition,1.0); }";
    private static final String TABLE_FRAGMENT = "precision mediump float; uniform vec4 uColor; void main(){ gl_FragColor=uColor; }";
}
