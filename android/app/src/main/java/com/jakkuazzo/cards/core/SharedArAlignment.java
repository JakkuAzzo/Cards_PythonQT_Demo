package com.jakkuazzo.cards.core;

/** Marker-relative placement data; it never participates in rule validation. */
public final class SharedArAlignment {
    public static final String MARKER_ID = "cards-table-marker-v1";
    public static final double MARKER_WIDTH_METRES = 0.16;

    public final String markerId;
    public final double markerWidthMetres;
    public final int revision;
    public final float[] position;
    public final float[] orientation;

    public SharedArAlignment(String markerId, double markerWidthMetres, int revision, float[] position, float[] orientation) {
        this.markerId = markerId;
        this.markerWidthMetres = markerWidthMetres;
        this.revision = revision;
        this.position = position.clone();
        this.orientation = orientation.clone();
    }

    public boolean isValid() {
        return MARKER_ID.equals(markerId) && markerWidthMetres == MARKER_WIDTH_METRES && revision >= 0 && position.length == 3 && orientation.length == 4;
    }
}
