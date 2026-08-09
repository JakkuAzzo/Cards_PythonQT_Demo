package com.jakkuazzo.cards.core;

/** Shared marker readiness; each device anchors locally and no AR world pose is exchanged. */
public final class SharedArAlignment {
    public static final String MARKER_ID = "cards-table-marker-v1";
    public static final double MARKER_WIDTH_METRES = 0.16;

    public final String markerId;
    public final double markerWidthMetres;
    public final int revision;
    public final String status;

    public SharedArAlignment(String markerId, double markerWidthMetres, int revision, String status) {
        this.markerId = markerId;
        this.markerWidthMetres = markerWidthMetres;
        this.revision = revision;
        this.status = status;
    }

    public boolean isValid() {
        return MARKER_ID.equals(markerId) && markerWidthMetres == MARKER_WIDTH_METRES && revision >= 0 && ("ready".equals(status) || "lost".equals(status));
    }
}
