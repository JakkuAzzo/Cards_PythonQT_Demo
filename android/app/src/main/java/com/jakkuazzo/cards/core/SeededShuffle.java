package com.jakkuazzo.cards.core;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class SeededShuffle {
    private SeededShuffle() {}

    public static <T> List<T> shuffle(List<T> input, long seed) {
        List<T> result = new ArrayList<>(input);
        SplitMix64 generator = new SplitMix64(seed);
        for (int index = result.size() - 1; index >= 1; index--) {
            int other = (int) Long.remainderUnsigned(generator.next(), index + 1L);
            Collections.swap(result, index, other);
        }
        return result;
    }

    private static final class SplitMix64 {
        private long state;

        SplitMix64(long seed) { state = seed; }

        long next() {
            state += 0x9E3779B97F4A7C15L;
            long value = state;
            value = (value ^ (value >>> 30)) * 0xBF58476D1CE4E5B9L;
            value = (value ^ (value >>> 27)) * 0x94D049BB133111EBL;
            return value ^ (value >>> 31);
        }
    }
}

