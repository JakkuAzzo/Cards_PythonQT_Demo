package com.jakkuazzo.cards.core;

import java.util.Objects;

public final class CardRecord {
    public final String id;
    public final String text;

    public CardRecord(String id, String text) {
        this.id = Objects.requireNonNull(id);
        this.text = Objects.requireNonNull(text);
    }
}

