package com.jakkuazzo.cards.core;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;

/**
 * Scores a five-to-seven-card Hold'em hand without Android dependencies.
 *
 * The returned score sorts by category then kickers, so the host can compare
 * two private hands without exposing either hand to the shared table state.
 */
public final class PokerHandEvaluator {
    private PokerHandEvaluator() { }

    public static long score(List<String> privateCards, List<String> communityCards) {
        List<String> cards = new ArrayList<>(communityCards);
        cards.addAll(privateCards);
        if (cards.size() < 5) return 0;
        int[] counts = new int[15];
        HashMap<String, List<Integer>> suits = new HashMap<>();
        for (String card : cards) {
            int rank = cardRank(card);
            counts[rank]++;
            String suit = card.substring(card.length() - 1);
            suits.computeIfAbsent(suit, key -> new ArrayList<>()).add(rank);
        }
        int straight = straightHigh(ranks(cards));
        int straightFlush = 0;
        long flushScore = 0;
        for (List<Integer> suitRanks : suits.values()) if (suitRanks.size() >= 5) {
            straightFlush = Math.max(straightFlush, straightHigh(suitRanks));
            flushScore = Math.max(flushScore, encode(5, descendingRanks(suitRanks)));
        }
        List<Integer> fours = ranksWithCount(counts, 4);
        List<Integer> threes = ranksWithCount(counts, 3);
        List<Integer> pairs = ranksWithCount(counts, 2);
        if (straightFlush > 0) return encode(8, straightFlush);
        if (!fours.isEmpty()) return encode(7, with(fours.get(0), topExcluding(counts, 1, fours.get(0))));
        if (!threes.isEmpty() && (threes.size() > 1 || !pairs.isEmpty())) return encode(6, threes.get(0), threes.size() > 1 ? threes.get(1) : pairs.get(0));
        if (flushScore > 0) return flushScore;
        if (straight > 0) return encode(4, straight);
        if (!threes.isEmpty()) return encode(3, with(threes.get(0), topExcluding(counts, 2, threes.get(0))));
        if (pairs.size() >= 2) return encode(2, with(pairs.get(0), pairs.get(1), topExcluding(counts, 1, pairs.get(0), pairs.get(1))));
        if (pairs.size() == 1) return encode(1, with(pairs.get(0), topExcluding(counts, 3, pairs.get(0))));
        return encode(0, descendingCards(cards));
    }

    public static String label(long score) {
        int category = (int) (score / 759375L);
        String[] names = {"high card", "pair", "two pair", "three of a kind", "straight", "flush", "full house", "four of a kind", "straight flush"};
        return names[Math.max(0, Math.min(category, names.length - 1))];
    }

    private static int cardRank(String card) {
        String rank = card.substring(0, card.length() - 1);
        return "A".equals(rank) ? 14 : "K".equals(rank) ? 13 : "Q".equals(rank) ? 12 : "J".equals(rank) ? 11 : Integer.parseInt(rank);
    }
    private static List<Integer> ranks(List<String> cards) { List<Integer> values = new ArrayList<>(); for (String card : cards) values.add(cardRank(card)); return values; }
    private static int straightHigh(List<Integer> ranks) { boolean[] seen = new boolean[15]; for (int rank : ranks) { seen[rank] = true; if (rank == 14) seen[1] = true; } for (int high = 14; high >= 5; high--) if (seen[high] && seen[high - 1] && seen[high - 2] && seen[high - 3] && seen[high - 4]) return high; return 0; }
    private static List<Integer> ranksWithCount(int[] counts, int count) { List<Integer> values = new ArrayList<>(); for (int rank = 14; rank >= 2; rank--) if (counts[rank] == count) values.add(rank); return values; }
    private static List<Integer> topExcluding(int[] counts, int limit, int... excluded) { List<Integer> values = new ArrayList<>(); outer: for (int rank = 14; rank >= 2 && values.size() < limit; rank--) { for (int value : excluded) if (rank == value) continue outer; if (counts[rank] > 0) values.add(rank); } return values; }
    private static List<Integer> descendingCards(List<String> cards) { List<Integer> values = ranks(cards); Collections.sort(values, Collections.reverseOrder()); return values; }
    private static List<Integer> descendingRanks(List<Integer> values) { List<Integer> sorted = new ArrayList<>(values); Collections.sort(sorted, Collections.reverseOrder()); return sorted; }
    private static List<Integer> with(int first, List<Integer> rest) { List<Integer> values = new ArrayList<>(); values.add(first); values.addAll(rest); return values; }
    private static List<Integer> with(int first, int second, List<Integer> rest) { List<Integer> values = new ArrayList<>(); values.add(first); values.add(second); values.addAll(rest); return values; }
    private static long encode(int category, int... values) { long score = category; for (int index = 0; index < 5; index++) score = score * 15 + (index < values.length ? values[index] : 0); return score; }
    private static long encode(int category, List<Integer> values) { int[] ranks = new int[Math.min(5, values.size())]; for (int index = 0; index < ranks.length; index++) ranks[index] = values.get(index); return encode(category, ranks); }
}
