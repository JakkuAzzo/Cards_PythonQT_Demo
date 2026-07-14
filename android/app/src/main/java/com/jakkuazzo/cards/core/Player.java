package com.jakkuazzo.cards.core;

import java.util.Objects;

public final class Player {
    public final String id;
    public final String name;
    public final boolean host;

    public Player(String id, String name, boolean host) {
        this.id = Objects.requireNonNull(id);
        this.name = Objects.requireNonNull(name);
        this.host = host;
    }
}

